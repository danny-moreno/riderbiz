# RB-ROUTING-008 · Métricas comparables

## Fecha y alcance

2026-10-26. Issue #21 y ADR-004.

Se amplió la prueba comparativa existente, utilizando el benchmark
y el evaluador OSRM existentes. No se modificó la lógica de la aplicación.

Escenarios sintéticos vehiculares, con todas las tareas pendientes,
sin ventanas horarias, bloqueos ni grupos peatonales.
Las recogidas son visitas independientes; no se acredita capacidad
de carga ni precedencia entre recogida y entrega.

## Método y resultados

Cinco optimizaciones consecutivas por volumen. Ambos órdenes se evalúan
con el mismo OSRM, origen y tareas, conservando el tiempo de servicio.

Resultados de la ejecución específica previa a la suite completa:

| Tareas | Entregas | Recogidas | Distancia inicial m | Propuesta m | Duración inicial s | Propuesta s |
|---|---|---|---|---|---|---|
| 60 | 48 | 12 | 22209 | 7342 | 12596.0 | 9953.8 |
| 80 | 64 | 16 | 29745 | 9553 | 16807.8 | 13215.0 |
| 120 | 96 | 24 | 40813 | 13223 | 24744.4 | 19659.1 |

La duración incluye servicio: 8640, 11520 y 17280 segundos,
respectivamente. Espera y retraso de salida fueron cero.

Reducción de duración total: 20.9749 %, 21.3720 % y 20.5504 %.
Los órdenes y las métricas OSRM coincidieron en las cinco repeticiones
de cada escenario. No quedaron paradas pendientes sin asignar.

| Tareas | Mínimo ms | Mediana ms | p95 ms | Máximo ms |
|---|---|---|---|---|
| 60 | 43.837 | 46.824 | 74.050 | 74.050 |
| 80 | 55.884 | 57.971 | 61.703 | 61.703 |
| 120 | 88.302 | 90.344 | 91.623 | 91.623 |

Los tiempos incluyen el proxy local de conteo.
El p95 por rango más próximo sobre cinco muestras coincide con
el máximo; no representa un SLA ni un percentil de producción.

## Llamadas y fallos

Por escenario se observaron cinco solicitudes a VROOM y seis
evaluaciones OSRM: once solicitudes recibidas por los proxies.

La ejecución específica sumó quince solicitudes a VROOM y dieciocho
evaluaciones OSRM. Las llamadas internas entre motores no se midieron
y se representan como null. Este conteo corresponde al benchmark,
no a una jornada de la aplicación.

Los registros contienen agregados sintéticos, sin coordenadas,
claves ni respuestas completas. Los tres escenarios finalizaron
con status success y failure_reason null.
La rama de registro de fallos no se ejercitó en esta comparación.

## Restricciones y límites

Se comprobó cobertura completa, ausencia de duplicados y conservación
del servicio. constraint_violations permanece null: no se acredita
un recuento general de infracciones.

El orden inicial es generado; no representa una ruta real de un
repartidor experimentado. Los porcentajes no acreditan ahorro comercial.

La comparación usa las métricas reevaluadas por OSRM, manteniendo
separadas las métricas informadas por VROOM, que presentan diferencias.

No se hicieron llamadas a proveedores de pago. El coste de infraestructura
por ejecución no se midió; véase RB-ROUTING-006.
GraphHopper continúa sin comparación ejecutada.

## Validación

- Ejecución específica: tres pruebas superadas.
- flutter analyze: sin incidencias.
- Suite completa con RUN_LOCAL_VROOM=true y concurrency=1:
  325 pruebas superadas en aproximadamente 32 segundos.
- Las métricas temporales de la tabla pertenecen a la ejecución específica;
  no se mezclan con los tiempos de la suite completa.

La Issue #21 permanece abierta y ADR-004 continúa PROPUESTO.
