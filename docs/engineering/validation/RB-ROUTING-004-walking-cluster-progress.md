# RB-ROUTING-004 · Progreso de grupos peatonales

## Estado y alcance

Validación automatizada realizada el 2026-10-26.
Issue #21 abierta. ADR-004 permanece PROPUESTO.

Se incorpora WalkingClusterProgress como representación operativa independiente del proveedor. Separa:
- El ancla declarada para estacionar.
- Los portales con tareas pendientes.
- Las entregas y recogidas pendientes de cada portal.

El ancla no acredita un estacionamiento legal ni accesible.

## Comportamiento comprobado

- Excluye tareas completadas y canceladas.
- Excluye portales sin tareas pendientes.
- Mantiene separadas las tareas ajenas al grupo.
- Permite indicar manualmente el orden completo de los portales pendientes.
- Rechaza órdenes con omisiones, duplicados o portales ajenos.
- Conserva el plan original y expone listas no modificables.
- Un grupo completado queda vacío aunque existan tareas vehiculares pendientes fuera de él.
- Los escenarios de 60, 80 y 120 tareas conservan todas las tareas pendientes agrupadas, sin duplicarlas.

La construcción utiliza el validador existente para comprobar la coherencia del plan.

## Resultados

- Seis pruebas específicas superadas.
- Análisis estático sin incidencias.
- Suite habitual: 297 pruebas superadas y 24 omitidas por defecto.
- git diff --check sin incidencias.

## Límites

No calcula geometría, distancia, duración ni accesibilidad peatonal. El orden manual no acredita cumplimiento de ventanas horarias, prioridades o bloqueos.

No integra todavía la vista con una pantalla ni persiste el orden manual de portales. No conecta automáticamente los tramos vehiculares con un recorrido peatonal calculado.

VROOM y la estrategia segmentada mantienen sus rechazos explícitos de grupos peatonales. No se modifican sus capacidades.

Esta evidencia acredita representación y progreso; no demuestra una optimización peatonal ni uso en campo.
