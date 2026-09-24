# Consigna

El departamento de ciencia y técnica de una facultad necesita un almacén de datos para gestionar al equipo de investigadores y los proyectos. Se busca responder las siguientes preguntas:

1. ¿Cuál es la cantidad total de proyectos que son de larga duración? (menos de 10 días son cortos, de 10 a 30 son intermedios y el resto largos)
2. ¿Cuál es el presupuesto total para un cierto tipo de proyecto?
3. ¿Cuál es el costo por hora presupuestado promedio de un departamento dado?

El sistema transaccional debe cumplir los siguientes requisitos:

Para cada empleado del equipo investigador se debe registrar el legajo, nombre, rol (becario, investigador, administrativo), nombre y código del equipo al que pertenece. Además para cada proyecto al que la persona está asignada, registrar el código y nombre del proyecto, el tiempo de dedicación, el total de horas dedicadas en el proyecto.

Para cada proyecto de investigación, se debe registrar el codigo y descripcion del proyecto, el nombre del departamento que lo genero, el nombre de la persona de contacto del departamento, el tipo de proyecto, el estado del proyecto, las fechas de inicio y fin, las horas hombre presupuestadas, el monto presupuestado y la persona asignada como líder del proyecto.

## 1) Generen un diagrama Entidad-Relación para este caso.

Identifico las entidades y relaciones según lo que dice el enunciado:
- INVESTIGADORES (legajo PK, nombre, rol, nombre equipo, código equipo FK) — pertenece a un EQUIPO (N:1)
- EQUIPOS (código PK, nombre del equipo)
- PROYECTOS (código proyecto PK, nombre proyecto, código departamento FK, nombre del contacto del departamento, tipo de proyecto, estado, fecha inicio, fecha fin, HH presupuestadas, monto presupuestado, nombre líder) — pertenece a un DEPARTAMENTO (N:1)
- DEPARTAMENTO (código PK, nombre del departamento)
- Relación ASIGNACIÓN entre INVESTIGADORES y PROYECTOS (N:M), con PK compuesta (legajo, código proyecto) y atributos propios: tiempo dedicado y tiempo ejecutado

**Corrección respecto a mi primera versión:** el líder del proyecto no se modela como una relación con INVESTIGADORES, sino como un atributo de texto (`Nombre lider`) dentro de PROYECTOS — no hay una FK que lo vincule formalmente a la tabla de investigadores. Tampoco hay una relación LIDERA. El contacto del departamento se guarda como atributo dentro de PROYECTOS (no en DEPARTAMENTO), y DEPARTAMENTO queda solo con código y nombre.

## 2) Elijan las dimensiones y medidas adecuadas.

La granularidad del hecho es un proyecto (cada fila = un proyecto de investigación).

**Tabla de hechos: FACT_PROYECTO**

Medidas:
- horas_hombre_presupuestadas
- monto_presupuestado
- duracion_dias (fecha_fin - fecha_inicio, calculada; permite clasificar en corto/intermedio/largo)
- costo_por_hora_presupuestado (monto_presupuestado / horas_hombre_presupuestadas, calculada)

Dimensiones:
- DIM_TIEMPO (fecha, día, mes, año) — para fecha de inicio y fecha de fin del proyecto
- DIM_PROYECTO (código, nombre, tipo de proyecto, estado del proyecto, nombre líder) — como en el modelo transaccional el líder es solo un atributo de texto (sin FK a investigadores), queda como atributo dentro de esta dimensión en vez de una dimensión propia
- DIM_DEPARTAMENTO (código, nombre)
- DIM_CONTACTO (nombre del contacto del departamento) — dato que en el transaccional vive en PROYECTOS, no en DEPARTAMENTO

Con estas dimensiones y medidas se pueden responder las tres preguntas:
1. Cantidad de proyectos por rango de duración → agrupando por duracion_dias (o una categoría derivada corto/intermedio/largo)
2. Presupuesto total por tipo de proyecto → SUM(monto_presupuestado) agrupado por DIM_PROYECTO.tipo
3. Costo por hora presupuestado promedio por departamento → AVG(costo_por_hora_presupuestado) agrupado por DIM_DEPARTAMENTO

## 3) Diseñen un esquema con jerarquías y un esquema con dimensiones combinadas.

### Esquema con jerarquías

Parto del mismo esquema estrella del punto 2 (FACT_PROYECTO en el centro), pero explicitando las jerarquías dentro de cada dimensión:

- DIM_TIEMPO: Día → Mes → Trimestre → Año
- DIM_PROYECTO: Tipo de proyecto → Proyecto (código, nombre, estado, nombre líder)
- DIM_DEPARTAMENTO: Departamento → Contacto del departamento

FACT_PROYECTO se conecta a las 3 dimensiones (DIM_TIEMPO, DIM_PROYECTO, DIM_DEPARTAMENTO), y cada una despliega su jerarquía interna de niveles, permitiendo hacer drill-down/roll-up (por ejemplo, ver presupuesto total por año y luego por mes; o por departamento y luego por contacto/proyecto puntual).

### Esquema con dimensiones combinadas

Acá combino DIM_DEPARTAMENTO y el contacto del departamento en una única dimensión, en vez de mantener el contacto en una tabla aparte (evitando el snowflake):

- DIM_DEPARTAMENTO (código, nombre del departamento, nombre del contacto)

De esta forma FACT_PROYECTO queda con las dimensiones DIM_TIEMPO, DIM_PROYECTO y DIM_DEPARTAMENTO (esta última ya combinada), simplificando las consultas ya que no hace falta un join adicional para llegar al nombre del contacto.

## 4) Dimensiones temporales y esquema copo de nieve

### 1) Identifiquen dimensiones temporales en el caso

En el caso hay dos fechas en PROYECTOS que dan lugar a una dimensión temporal usada en dos roles distintos (role-playing dimension):

- Fecha de inicio del proyecto
- Fecha de fin del proyecto

Ambas se modelan con una única DIM_TIEMPO (día, mes, trimestre, año), a la que FACT_PROYECTO se conecta dos veces con alias distintos: fecha_inicio_id y fecha_fin_id. Esto permite responder, por ejemplo, cuántos proyectos empezaron en un año dado o calcular la duración cruzando ambas fechas.

### 2) Diseñen un esquema copo de nieve con dimensiones temporales

A diferencia del esquema estrella (donde DIM_TIEMPO es una sola tabla plana con las columnas día/mes/trimestre/año), en el copo de nieve la dimensión temporal se normaliza en varias tablas, una por nivel de la jerarquía, conectadas por FK:

- DIM_DIA (id_dia PK, fecha, nombre_dia, id_mes FK)
- DIM_MES (id_mes PK, nombre_mes, numero_mes, id_trimestre FK)
- DIM_TRIMESTRE (id_trimestre PK, numero_trimestre, id_anio FK)
- DIM_ANIO (id_anio PK, anio)

FACT_PROYECTO se conecta a DIM_DIA a través de dos FK con roles distintos (fecha_inicio_id, fecha_fin_id), y desde ahí, siguiendo la cadena de FKs, se puede subir hasta mes, trimestre y año (snowflake), en vez de tener esos niveles repetidos como columnas dentro de una única tabla como en el esquema estrella.
