-- =============================================================================
-- dw_cubo.sql — Consulta del cubo de concordancia (lectura del almacén)
-- -----------------------------------------------------------------------------
-- Une FACT_CONCORDANCIA con sus dimensiones y devuelve, para cada combinación de
-- dispositivo, sexo, grupo etario, IMC, tercio y par (estadio de referencia,
-- estadio predicho), la cantidad de épocas n. Solo incluye épocas con etiqueta
-- válida en ambos evaluadores; noche_valida indica si la noche cumple el criterio
-- de 4 h de señal válida para ese dispositivo. La usan las consultas OLAP y el tablero.
-- =============================================================================
SELECT CASE de.dispositivo WHEN 'psg' THEN 'PSG' ELSE 'Vincha' END AS dispositivo,
       ds.sexo, ds.grupo_etario, ds.categoria_imc, dt.nombre AS tercio,
       CASE de.dispositivo WHEN 'psg' THEN ds.valida_psg ELSE ds.valida_hb END AS noche_valida,
       r.sigla AS referencia, p.sigla AS prediccion, f.n_epocas AS n
FROM fact_concordancia AS f
JOIN dim_sesion    AS ds USING (sesion_key)
JOIN dim_evaluador AS de USING (evaluador_key)
JOIN dim_tercio    AS dt USING (tercio_key)
JOIN dim_estadio   AS r  ON r.estadio_key = f.estadio_ref_key
JOIN dim_estadio   AS p  ON p.estadio_key = f.estadio_pred_key
WHERE r.es_valido = 1 AND p.es_valido = 1
