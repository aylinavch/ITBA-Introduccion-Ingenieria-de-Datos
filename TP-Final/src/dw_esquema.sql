-- =============================================================================
-- dw_esquema.sql — Esquema (DDL) del almacén de datos en estrella (constelación)
-- -----------------------------------------------------------------------------
-- Dimensiones (con llaves subrogadas *_key): DIM_SESION, DIM_EVALUADOR,
-- DIM_ESTADIO y DIM_TERCIO. Hechos: FACT_CONCORDANCIA (cubo de la matriz de
-- confusión, medida aditiva n_epocas) y FACT_NOCHE (indicadores por noche).
-- El parámetro columnas_sensores (entre llaves en el CREATE TABLE) lo completa la notebook con una columna
-- tiene_<sensor> por cada sensor que varía entre noches.
-- =============================================================================
CREATE TABLE dim_sesion (
    sesion_key    INTEGER PRIMARY KEY,
    sesion_id     TEXT    NOT NULL UNIQUE,
    pid           INTEGER NOT NULL,
    sexo          TEXT    NOT NULL,
    edad          INTEGER,
    grupo_etario  TEXT    NOT NULL,
    imc           REAL,
    categoria_imc TEXT    NOT NULL,
    valida_psg    INTEGER NOT NULL,
    valida_hb     INTEGER NOT NULL,
    {columnas_sensores}
);
CREATE TABLE dim_evaluador (
    evaluador_key INTEGER PRIMARY KEY,
    evaluador_id  INTEGER NOT NULL UNIQUE,
    descripcion   TEXT    NOT NULL,
    dispositivo   TEXT    NOT NULL,
    fabricante    TEXT    NOT NULL,
    modelo        TEXT    NOT NULL
);
CREATE TABLE dim_estadio (
    estadio_key   INTEGER PRIMARY KEY,
    estadio_id    INTEGER UNIQUE,                 -- NULL: miembro "Sin etiqueta válida"
    sigla         TEXT    NOT NULL UNIQUE,
    nombre        TEXT    NOT NULL,
    es_sueno      INTEGER,
    es_valido     INTEGER NOT NULL
);
CREATE TABLE dim_tercio (
    tercio_key    INTEGER PRIMARY KEY CHECK (tercio_key BETWEEN 1 AND 3),
    nombre        TEXT    NOT NULL
);
CREATE TABLE fact_concordancia (
    sesion_key       INTEGER NOT NULL REFERENCES dim_sesion(sesion_key),
    evaluador_key    INTEGER NOT NULL REFERENCES dim_evaluador(evaluador_key),
    estadio_ref_key  INTEGER NOT NULL REFERENCES dim_estadio(estadio_key),
    estadio_pred_key INTEGER NOT NULL REFERENCES dim_estadio(estadio_key),
    tercio_key       INTEGER NOT NULL REFERENCES dim_tercio(tercio_key),
    n_epocas         INTEGER NOT NULL CHECK (n_epocas > 0),
    PRIMARY KEY (sesion_key, evaluador_key, estadio_ref_key, estadio_pred_key, tercio_key)
);
CREATE TABLE fact_noche (
    sesion_key         INTEGER PRIMARY KEY REFERENCES dim_sesion(sesion_key),
    horas_registro     REAL NOT NULL,
    tst_min            REAL NOT NULL,
    eficiencia         REAL NOT NULL,
    latencia_sueno_min REAL,
    latencia_rem_min   REAL,
    waso_min           REAL,
    pct_n1 REAL, pct_n2 REAL, pct_n3 REAL, pct_rem REAL,
    pct_artefacto_hb   REAL NOT NULL,
    acuerdo_psg REAL, kappa_psg REAL, acuerdo_hb REAL, kappa_hb REAL
);
