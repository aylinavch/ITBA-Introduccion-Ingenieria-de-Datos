# Introducción a la Ingeniería de Datos - ITBA

Este repositorio contiene los trabajos prácticos y apuntes de la materia **Introducción a la Ingeniería de Datos**, dictada en el ITBA.

## Información de la materia

- **Materia:** Introducción a la Ingeniería de Datos
- **Institución:** ITBA
- **Profesor:** Nicolás Guillermo Tripp

## Autora

- **Bioing. Aylin Agatha Vazquez Chenlo**
  Estudiante del Doctorado en Ingeniería, ITBA.

## Contenido

- `TPs/TP1.ipynb`: Primer trabajo práctico de la materia.
- `TPs/TP2.ipynb` / `TPs/TP2.drawio`: Segundo trabajo práctico — diseño de arquitectura de datos (OLTP + OLAP) para un medio internacional de noticias sobre GDELT 2.0. Incluye el diagrama Entidad-Relación (OLTP) y el Esquema Estrella (OLAP) en Draw.io, y una implementación opcional en SQLite.
- `TPs/TP3.ipynb`: Tercer trabajo práctico — transformación de datos y análisis multivariante sobre una semana de eventos GDELT 2.0 (5–11/10/2026): extensión del almacén del TP2, reducción de cardinalidad y variables dummy, vectores de medias y distancias por país, matrices de correlación y Análisis de Componentes Principales.
- `TPs/TP4.ipynb`: Cuarto trabajo práctico — limpieza y búsqueda de anomalías sobre los últimos 7 días de eventos GDELT 2.0 (15–21/10/2026): One Big Table en parquet, tratamiento de nulos y falsos ceros, ACP y detección de eventos atípicos multivariantes (T² de Hotelling, error de reconstrucción e Isolation Forest). Los atípicos se exportan en `TPs/TP4_eventos_atipicos.csv` / `.parquet`.
- `TP-Final/`: Trabajo práctico final — pipeline completo de datos sobre el *Bitbrain Open Access Sleep (BOAS) dataset* (OpenNeuro `ds005555` v1.1.3, CC0): 128 noches de 100 personas registradas en simultáneo con polisomnografía clínica y una vincha de EEG wearable, con estadificación del sueño por consenso de expertos y por IA. Pregunta de investigación: ¿qué tan bien estadifica el sueño un wearable de EEG frente al estándar clínico, y cómo varía según el estadio y las características de la persona? [Abrir en Google Colab](https://colab.research.google.com/github/aylinavch/ITBA-Introduccion-Ingenieria-de-Datos/blob/main/TP-Final/TP_Final.ipynb).
  - `TP-Final/TP_Final.ipynb`: cuaderno reproducible con:
    - Declaración de uso de IA y guía de instrucciones para reproducir el trabajo realizado con IA.
    - **Extracción:** descarga desde la réplica de OpenNeuro en GitHub con versión fijada, carga optimizada (proyección de columnas y tipado reducido) y controles de integridad.
    - **Transformación:** códigos especiales como faltantes explícitos, decisión justificada sobre edad e IMC faltantes, indicadores por noche (arquitectura del sueño y κ de Cohen) y detección de noches atípicas (cercos de Tukey e Isolation Forest).
    - **Base transaccional SQLite en 3FN:** 9 tablas con llaves primarias y foráneas, restricciones de dominio y dos tablas puente (etiquetas por evaluador y sensores por sesión), cargadas en una transacción y validadas con reconstrucción de ida y vuelta.
    - **Almacén de datos en esquema estrella (constelación):** cubo de concordancia y hechos por noche, cargados con SQL desde la base transaccional.
    - **Tablero interactivo en Dash** con el mensaje: *la vincha wearable estadifica el sueño casi tan bien como el PSG clínico, pero pierde precisión en el sueño profundo (N3)*.
  - `TP-Final/requirements.txt`: dependencias necesarias para ejecutar la notebook (local o en Google Colab).
  - `TP-Final/src/`: código auxiliar que usa la notebook (cada archivo tiene un encabezado que explica su contenido):
    - `oltp_esquema.sql` y `dw_esquema.sql`: esquemas (DDL) de la base transaccional y del almacén.
    - `dw_etl.sql`: carga del almacén desde la base transaccional, en una única transacción.
    - `dw_cubo.sql`: consulta del cubo de concordancia, usada por las consultas OLAP y el tablero.
    - `metricas.py`: indicadores por noche y cálculo del acuerdo y κ de Cohen a partir de conteos.
    - `tablero.py`: gráficos, filtros y diseño del tablero en Dash.
  - `TP-Final/TP_Final.pdf`: versión en PDF de la notebook ejecutada.
  - `TP-Final/img/`: diagrama entidad-relación de la base transaccional, diagrama del esquema estrella (con sus fuentes `.dot` de Graphviz) y vista estática del tablero.
- `Clase06-Practica.ipynb`: Práctica de la Clase 6 (Bases de Datos) - normalización de un dataset (1FN, 2FN, 3FN) y carga del resultado en una base de datos SQLite.
- `clase-06.md` / `clase-07.md`: Apuntes de las clases 6 y 7.
- `other_files/`: Archivos adicionales y material de apoyo.

Este contenido se irá actualizando a medida que avance el curso con nuevos trabajos prácticos y apuntes de clase.
