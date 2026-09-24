# Consigna
El departamento de ciencia y técnica de una facultad necesita un almacén de datos para gestionar al equipo de investigadores y los proyectos. Se busca responder las siguientes preguntas:

1. ¿Cuál es la cantidad total de proyectos que son de larga duración? (menos de 10 días son cortos, de 10 a 30 son intermedios y el resto largos)
2. ¿Cuál es el presupuesto total para un cierto tipo de proyecto?
3. ¿Cuál es el costo por hora presupuestado promedio de un departamento dado?


El sistema transaccional debe cumplir los siguientes requisitos:
Para cada persona se debe registrar el legajo, nombre, rol (becario, investigador, administrativo), nombre y código del equipo al que pertenece. Además para cada proyecto al que la persona está asignada, registrar el código y nombre del proyecto, el tiempo de dedicación, el total de horas dedicadas en el proyecto. Para cada proyecto de investigación, se debe registrar el codigo y descripcion del proyecto, el nombre del departamento que lo genero, el nombre de la persona de contacto del departamento, el tipo de proyecto, el estado del proyecto, las fechas de inicio y fin, las horas hombre presupuestadas, el monto presupuestado y la persona asignada como líder del proyecto.

## 1) Generen un diagrama Entidad-Relación para este caso.

Primero identifico las entidades y relaciones según lo que dice el enunciado:
- PERSONA (legajo, nombre, rol) — pertenece a un EQUIPO (N:1)
- EQUIPO (código, nombre, descripcion)
- PROYECTO (código, nombre, descripción, tipo, estado, fecha inicio, fecha fin, horas hombre presupuestadas, monto prespuesto)
- DEPARTAMENTO (codigo, nombre, director) — genera proyectos (1:N)
- Relación ASIGNACION entre PERSONA y PROYECTO (N:M), con atributos propios: tiempo de dedicación y total de horas dedicadas
- Relación LIDERA entre PERSONA y PROYECTO (1:N — una persona puede liderar varios proyectos, pero cada proyecto tiene un único líder)


## 2) Elijan las dimensiones y medidas adecuadas.

## 3) Diseñen un esquema estrella

1) Diagrama Entidad-Relación (sistema transaccional)

Antes de dibujar, identifico las entidades y relaciones a partir del enunciado:

PERSONA (legajo, nombre, rol) — pertenece a un EQUIPO (N:1)
EQUIPO (código, nombre)
PROYECTO (código, descripción, tipo, estado, fecha inicio, fecha fin, horas hombre presupuestadas, monto presupuestado)
DEPARTAMENTO (nombre, persona de contacto) — genera proyectos (1:N)
Relación ASIGNACION entre PERSONA y PROYECTO (N:M), con atributos propios: tiempo de dedicación y total de horas dedicadas
Relación LIDERA entre PERSONA y PROYECTO (1:N — una persona puede liderar varios proyectos, pero cada proyecto tiene un único líder)