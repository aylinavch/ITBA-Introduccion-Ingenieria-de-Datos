-- =============================================================================
-- oltp_esquema.sql — Esquema (DDL) de la base de datos transaccional (3FN)
-- -----------------------------------------------------------------------------
-- Crea las 9 tablas normalizadas de la base boas_oltp.db: PERSONA, SESION,
-- DISPOSITIVO, SENSOR, SESION_SENSOR (tabla puente N:M), EVALUADOR, ESTADIO,
-- EPOCA y ETIQUETA (tabla puente entre épocas y evaluadores).
-- Cada tabla declara su llave primaria, sus llaves foráneas y restricciones de
-- dominio (CHECK, NOT NULL). La notebook lo ejecuta con PRAGMA foreign_keys = ON.
-- =============================================================================
CREATE TABLE persona (
    pid         INTEGER PRIMARY KEY,
    sexo        TEXT    NOT NULL CHECK (sexo IN ('F', 'M'))
);
CREATE TABLE sesion (
    sesion_id   TEXT    PRIMARY KEY,
    pid         INTEGER NOT NULL REFERENCES persona(pid),
    edad        INTEGER CHECK (edad BETWEEN 18 AND 120),          -- NULL: dato no informado
    imc         REAL    CHECK (imc BETWEEN 10 AND 60),            -- NULL: dato no informado
    valida_psg  INTEGER NOT NULL CHECK (valida_psg IN (0, 1)),    -- >= 4 h de señal válida
    valida_hb   INTEGER NOT NULL CHECK (valida_hb IN (0, 1))
);
CREATE TABLE dispositivo (
    dispositivo_id INTEGER PRIMARY KEY,
    acq         TEXT    NOT NULL UNIQUE,
    fabricante  TEXT    NOT NULL,
    modelo      TEXT    NOT NULL,
    fs_hz       INTEGER NOT NULL CHECK (fs_hz > 0)
);
CREATE TABLE sensor (
    sensor_id      INTEGER PRIMARY KEY,
    codigo         TEXT    NOT NULL UNIQUE,
    dispositivo_id INTEGER NOT NULL REFERENCES dispositivo(dispositivo_id),
    descripcion    TEXT    NOT NULL
);
CREATE TABLE sesion_sensor (                                      -- tabla puente (N:M)
    sesion_id   TEXT    NOT NULL REFERENCES sesion(sesion_id),
    sensor_id   INTEGER NOT NULL REFERENCES sensor(sensor_id),
    PRIMARY KEY (sesion_id, sensor_id)
);
CREATE TABLE evaluador (
    evaluador_id   INTEGER PRIMARY KEY,
    descripcion    TEXT    NOT NULL UNIQUE,
    tipo           TEXT    NOT NULL CHECK (tipo IN ('humano', 'IA')),
    dispositivo_id INTEGER NOT NULL REFERENCES dispositivo(dispositivo_id)
);
CREATE TABLE estadio (
    estadio_id  INTEGER PRIMARY KEY,                              -- código original de BOAS
    sigla       TEXT    NOT NULL UNIQUE,
    nombre      TEXT    NOT NULL,
    es_sueno    INTEGER NOT NULL CHECK (es_sueno IN (0, 1))
);
CREATE TABLE epoca (
    sesion_id   TEXT    NOT NULL REFERENCES sesion(sesion_id),
    nro_epoca   INTEGER NOT NULL CHECK (nro_epoca >= 0),
    onset_s     INTEGER NOT NULL,
    PRIMARY KEY (sesion_id, nro_epoca)
);
CREATE TABLE etiqueta (
    sesion_id    TEXT    NOT NULL,
    nro_epoca    INTEGER NOT NULL,
    evaluador_id INTEGER NOT NULL REFERENCES evaluador(evaluador_id),
    estadio_id   INTEGER REFERENCES estadio(estadio_id),          -- NULL: desconexión o artefacto
    PRIMARY KEY (sesion_id, nro_epoca, evaluador_id),
    FOREIGN KEY (sesion_id, nro_epoca) REFERENCES epoca(sesion_id, nro_epoca)
);
