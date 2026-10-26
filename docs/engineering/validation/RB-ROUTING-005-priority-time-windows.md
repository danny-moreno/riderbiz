# RB-ROUTING-005 · Prioridades bajo restricciones horarias

## Estado

Validación realizada el 2026-10-26 contra VROOM y OSRM locales.
Issue #21 abierta. ADR-004 permanece PROPUESTO.

## Escenarios

Cada caso contiene dos tareas pendientes: una entrega y una recogida independiente, representadas como trabajos separados. Se asignan prioridades normal y urgente, convertidas respectivamente a 30 y 100.

En los casos de competencia, ambas tareas comparten ubicación con el origen. Cada servicio dura 120 segundos y la ventana permite iniciar entre los segundos 0 y 60. Solo una tarea puede iniciarse dentro de esa ventana.

| Caso | Asignadas | Sin asignar | Resultado de conversión |
|---|---|---|---|
| Urgente con identificador 1 | 1 | 2 | incompleteSolution |
| Urgente con identificador 2 | 2 | 1 | incompleteSolution |
| Ventana ampliada hasta 300 segundos | 1 y 2 | Ninguna | Propuesta completa |
| Urgente en otro punto, con ventana de un segundo | Normal | Urgente | incompleteSolution |

Se verifican los identificadores, la ausencia de duplicados, los inicios de servicio dentro de sus ventanas, el servicio acumulado y la ausencia de infracciones declaradas para las tareas asignadas.

La conversión utiliza la misma respuesta comprobada. Las soluciones parciales se rechazan y el plan original conserva su orden y sus tareas pendientes.

## Resultados

- Cuatro pruebas específicas superadas.
- Una solicitud HTTP a VROOM por caso; no se cuentan las llamadas internas entre VROOM y OSRM.
- Análisis estático sin incidencias.
- Suite completa con RUN_LOCAL_VROOM=true, concurrencia 1 y timeout de prueba de dos minutos: 325 pruebas superadas, sin omisiones, en aproximadamente 31 segundos.
- git diff --check sin incidencias.

Tiempos individuales observados en la ejecución conjunta: 15,747; 7,526; 7,132 y 7,299 ms. No constituyen percentiles ni una caracterización de rendimiento.

## Interpretación y límites

En estos casos, la prioridad favorece la inclusión de la tarea urgente cuando solo cabe una. Intercambiar su identificador conserva ese comportamiento.

La prioridad no permite incumplir una ventana ni establece por sí sola un orden obligatorio de visita.

Las distancias cero de las rutas asignadas son coherentes con las ubicaciones compartidas utilizadas para aislar el comportamiento. No representan rendimiento de reparto real.

No se validan aquí volúmenes de 60–120 tareas con ventanas, restricciones combinadas con bloqueos, capacidad de carga ni relaciones de precedencia entre recogida y entrega.

Los resultados corresponden al motor local identificado en RB-SPIKE-021; no garantizan el comportamiento de otros proveedores ni justifican aceptar automáticamente propuestas parciales.

## Referencia

Documentación oficial consultada:
https://github.com/VROOM-Project/vroom/blob/master/docs/API.md

La documentación de la rama master puede evolucionar; la evidencia de ejecución corresponde a la imagen local registrada en la prueba.
