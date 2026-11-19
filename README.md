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
- `TP-Final/`: Trabajo práctico final (en desarrollo) — pipeline completo de datos sobre el *Bitbrain Open Access Sleep (BOAS) dataset* (OpenNeuro `ds005555` v1.1.3): 128 noches de 100 personas registradas en simultáneo con polisomnografía clínica y una vincha de EEG wearable, con estadificación del sueño por consenso de expertos y por IA. Pregunta de investigación: ¿qué tan bien estadifica el sueño un wearable de EEG frente al estándar clínico, y cómo varía según el estadio y las características de la persona?
  - `TP-Final/TP_Final.ipynb`: consigna, declaración de uso de IA, contexto de investigación, set up y **Extracción** (descarga reproducible desde la réplica de OpenNeuro en GitHub con versión fijada, carga optimizada con proyección de columnas y tipado reducido, controles de integridad y diagnóstico inicial de faltantes y atípicos). Próximas secciones: Transformación, base transaccional SQLite normalizada, almacén de datos (modelado dimensional) y tablero interactivo en Dash.
  - `TP-Final/requirements.txt`: dependencias necesarias para ejecutar la notebook (local o en Google Colab).
- `Clase06-Practica.ipynb`: Práctica de la Clase 6 (Bases de Datos) - normalización de un dataset (1FN, 2FN, 3FN) y carga del resultado en una base de datos SQLite.
- `clase-06.md` / `clase-07.md`: Apuntes de las clases 6 y 7.
- `other_files/`: Archivos adicionales y material de apoyo.

Este contenido se irá actualizando a medida que avance el curso con nuevos trabajos prácticos y apuntes de clase.
