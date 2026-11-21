-- =============================================================================
-- dw_etl.sql — Carga (ETL) del almacén de datos desde la base transaccional
-- -----------------------------------------------------------------------------
-- Requiere que la base transaccional esté adjunta como "oltp" (ATTACH DATABASE).
-- Todas las sentencias corren dentro de una única transacción (BEGIN … COMMIT):
-- se cargan primero las dimensiones y luego los hechos, respetando las llaves.
-- Parámetros completados por la notebook (entre llaves): columnas_sensores y flags_sensores.
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- Dimensiones: DIM_SESION (grupos derivados con CASE y sensores aplanados desde la tabla puente),
-- DIM_EVALUADOR (solo evaluadores IA, con los atributos del dispositivo), DIM_ESTADIO (más el
-- miembro 'Sin etiqueta válida') y DIM_TERCIO.
-- -----------------------------------------------------------------------------
INSERT INTO dim_sesion (sesion_id, pid, sexo, edad, grupo_etario, imc, categoria_imc,
                        valida_psg, valida_hb, {columnas_sensores})
SELECT s.sesion_id, s.pid, p.sexo, s.edad,
       CASE WHEN s.edad IS NULL THEN 'Sin dato'
            WHEN s.edad <= 30 THEN '18-30' WHEN s.edad <= 45 THEN '31-45'
            WHEN s.edad <= 60 THEN '46-60' ELSE '>60' END,
       s.imc,
       CASE WHEN s.imc IS NULL THEN 'Sin dato'
            WHEN s.imc < 18.5 THEN 'Bajo peso' WHEN s.imc < 25 THEN 'Normal'
            WHEN s.imc < 30 THEN 'Sobrepeso' ELSE 'Obesidad' END,
       s.valida_psg, s.valida_hb,
       {flags_sensores}
FROM oltp.sesion AS s
JOIN oltp.persona AS p USING (pid)
LEFT JOIN oltp.sesion_sensor AS ss USING (sesion_id)
LEFT JOIN oltp.sensor AS se USING (sensor_id)
GROUP BY s.sesion_id
ORDER BY CAST(SUBSTR(s.sesion_id, 5) AS INTEGER);

INSERT INTO dim_evaluador (evaluador_id, descripcion, dispositivo, fabricante, modelo)
SELECT e.evaluador_id, e.descripcion, d.acq, d.fabricante, d.modelo
FROM oltp.evaluador AS e JOIN oltp.dispositivo AS d USING (dispositivo_id)
WHERE e.tipo = 'IA';

INSERT INTO dim_estadio (estadio_id, sigla, nombre, es_sueno, es_valido)
SELECT estadio_id, sigla, nombre, es_sueno, 1 FROM oltp.estadio ORDER BY estadio_id;

INSERT INTO dim_estadio (estadio_id, sigla, nombre, es_sueno, es_valido)
VALUES (NULL, 'S/E', 'Sin etiqueta válida', NULL, 0);

INSERT INTO dim_tercio VALUES (1, 'Primer tercio'), (2, 'Segundo tercio'), (3, 'Tercer tercio');

-- -----------------------------------------------------------------------------
-- FACT_CONCORDANCIA: cada etiqueta de IA frente a la del consenso de la misma época (self-join),
-- tercio de la noche con una función de ventana y agregación con GROUP BY. Los NULL se emparejan
-- con el miembro 'Sin etiqueta válida' mediante el operador IS.
-- -----------------------------------------------------------------------------
WITH ep AS (
    SELECT sesion_id, nro_epoca,
           nro_epoca * 3 / COUNT(*) OVER (PARTITION BY sesion_id) + 1 AS tercio
    FROM oltp.epoca
),
referencia AS (
    SELECT t.sesion_id, t.nro_epoca, t.estadio_id
    FROM oltp.etiqueta AS t JOIN oltp.evaluador AS e USING (evaluador_id)
    WHERE e.tipo = 'humano'
)
INSERT INTO fact_concordancia
SELECT ds.sesion_key, de.evaluador_key, er.estadio_key, epr.estadio_key, ep.tercio, COUNT(*)
FROM oltp.etiqueta AS ia
JOIN referencia AS ref USING (sesion_id, nro_epoca)
JOIN ep USING (sesion_id, nro_epoca)
JOIN dim_sesion AS ds ON ds.sesion_id = ia.sesion_id
JOIN dim_evaluador AS de ON de.evaluador_id = ia.evaluador_id   -- solo los evaluadores IA
JOIN dim_estadio AS er  ON er.estadio_id IS ref.estadio_id
JOIN dim_estadio AS epr ON epr.estadio_id IS ia.estadio_id
GROUP BY 1, 2, 3, 4, 5;

-- -----------------------------------------------------------------------------
-- Vista v_concordancia_noche: acuerdo y κ de Cohen por noche y evaluador, calculados desde la
-- matriz de confusión: κ = (po − pe) / (1 − pe).
-- -----------------------------------------------------------------------------
CREATE VIEW v_concordancia_noche AS
WITH v AS (
    SELECT f.sesion_key, f.evaluador_key, r.estadio_id AS ref, p.estadio_id AS pred, f.n_epocas AS n
    FROM fact_concordancia AS f
    JOIN dim_estadio AS r ON r.estadio_key = f.estadio_ref_key
    JOIN dim_estadio AS p ON p.estadio_key = f.estadio_pred_key
    WHERE r.es_valido = 1 AND p.es_valido = 1
),
total AS (SELECT sesion_key, evaluador_key, SUM(n) AS n,
                 SUM(CASE WHEN ref = pred THEN n ELSE 0 END) AS acuerdos
          FROM v GROUP BY 1, 2),
marg_ref  AS (SELECT sesion_key, evaluador_key, ref  AS k, SUM(n) AS nk FROM v GROUP BY 1, 2, 3),
marg_pred AS (SELECT sesion_key, evaluador_key, pred AS k, SUM(n) AS nk FROM v GROUP BY 1, 2, 3),
azar AS (SELECT r.sesion_key, r.evaluador_key, SUM(r.nk * p.nk) AS suma
         FROM marg_ref AS r JOIN marg_pred AS p USING (sesion_key, evaluador_key, k)
         GROUP BY 1, 2)
SELECT t.sesion_key, t.evaluador_key,
       1.0 * t.acuerdos / t.n AS acuerdo,
       (1.0 * t.acuerdos / t.n - 1.0 * a.suma / (t.n * t.n)) / (1 - 1.0 * a.suma / (t.n * t.n)) AS kappa
FROM total AS t JOIN azar AS a USING (sesion_key, evaluador_key);

-- -----------------------------------------------------------------------------
-- FACT_NOCHE: arquitectura del sueño (sobre el consenso), % de artefactos de la vincha y
-- concordancia de cada IA por noche.
-- -----------------------------------------------------------------------------
WITH hum AS (
    SELECT t.sesion_id, t.nro_epoca, t.estadio_id
    FROM oltp.etiqueta AS t JOIN oltp.evaluador AS e USING (evaluador_id)
    WHERE e.tipo = 'humano'
),
limites AS (
    SELECT sesion_id,
           MIN(CASE WHEN estadio_id BETWEEN 1 AND 4 THEN nro_epoca END) AS primera_sueno,
           MAX(CASE WHEN estadio_id BETWEEN 1 AND 4 THEN nro_epoca END) AS ultima_sueno,
           MIN(CASE WHEN estadio_id = 4 THEN nro_epoca END) AS primera_rem
    FROM hum GROUP BY sesion_id
),
arquitectura AS (
    SELECT h.sesion_id,
           COUNT(*) / 120.0                                      AS horas_registro,
           SUM(h.estadio_id BETWEEN 1 AND 4) / 2.0               AS tst_min,
           1.0 * SUM(h.estadio_id BETWEEN 1 AND 4) / COUNT(h.estadio_id) AS eficiencia,
           NULLIF(l.primera_sueno, 0) / 2.0                      AS latencia_sueno_min,
           (l.primera_rem - l.primera_sueno) / 2.0               AS latencia_rem_min,
           SUM(h.estadio_id = 0 AND h.nro_epoca BETWEEN l.primera_sueno AND l.ultima_sueno) / 2.0 AS waso_min,
           100.0 * SUM(h.estadio_id = 1) / SUM(h.estadio_id BETWEEN 1 AND 4) AS pct_n1,
           100.0 * SUM(h.estadio_id = 2) / SUM(h.estadio_id BETWEEN 1 AND 4) AS pct_n2,
           100.0 * SUM(h.estadio_id = 3) / SUM(h.estadio_id BETWEEN 1 AND 4) AS pct_n3,
           100.0 * SUM(h.estadio_id = 4) / SUM(h.estadio_id BETWEEN 1 AND 4) AS pct_rem
    FROM hum AS h JOIN limites AS l USING (sesion_id)
    GROUP BY h.sesion_id
),
artefactos AS (
    SELECT t.sesion_id, 100.0 * SUM(t.estadio_id IS NULL) / COUNT(*) AS pct_artefacto_hb
    FROM oltp.etiqueta AS t
    JOIN oltp.evaluador AS e USING (evaluador_id)
    JOIN oltp.dispositivo AS d USING (dispositivo_id)
    WHERE e.tipo = 'IA' AND d.acq = 'headband'
    GROUP BY t.sesion_id
),
concordancia AS (
    SELECT c.sesion_key,
           MAX(CASE WHEN de.dispositivo = 'psg'      THEN c.acuerdo END) AS acuerdo_psg,
           MAX(CASE WHEN de.dispositivo = 'psg'      THEN c.kappa   END) AS kappa_psg,
           MAX(CASE WHEN de.dispositivo = 'headband' THEN c.acuerdo END) AS acuerdo_hb,
           MAX(CASE WHEN de.dispositivo = 'headband' THEN c.kappa   END) AS kappa_hb
    FROM v_concordancia_noche AS c JOIN dim_evaluador AS de USING (evaluador_key)
    GROUP BY c.sesion_key
)
INSERT INTO fact_noche
SELECT ds.sesion_key, a.horas_registro, a.tst_min, a.eficiencia, a.latencia_sueno_min,
       a.latencia_rem_min, a.waso_min, a.pct_n1, a.pct_n2, a.pct_n3, a.pct_rem,
       x.pct_artefacto_hb, c.acuerdo_psg, c.kappa_psg, c.acuerdo_hb, c.kappa_hb
FROM arquitectura AS a
JOIN dim_sesion AS ds USING (sesion_id)
JOIN artefactos AS x USING (sesion_id)
JOIN concordancia AS c USING (sesion_key);

COMMIT;
