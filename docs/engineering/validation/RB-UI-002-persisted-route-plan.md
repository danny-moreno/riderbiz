# Pantalla de rutas conectada al plan persistido

## Implementación

- La preparación del escenario crea la definición de ruta solo si no existe.
- Los identificadores de tarea coinciden con los paquetes sintéticos existentes.
- Cada cálculo recupera paradas, coordenadas, tareas y restricciones mediante RoutePlanStore.
- Los estados de entrega proceden de los paquetes.
- La ruta aceptada y sus métricas se conservan hasta aceptar otra propuesta.

## Validación automatizada

- La prueba específica verifica orden, coordenadas, prioridad y servicio previamente guardados.
- Preparar la pantalla no reinicia la entrega confirmada ni duplica su evento.
- Las pruebas existentes de pantalla y cancelación siguen pasando.
- Flutter analyze sin incidencias.
- Suite habitual: 276 pruebas superadas y 24 pruebas locales omitidas.
- git diff --check sin incidencias.

## Validación manual en Samsung SM-X210

- Dashboard conserva 1 entrega de 2 y 0,01 EUR ficticios.
- Se recupera la ruta aceptada y STOP-B pendiente.
- El cálculo obtiene una propuesta únicamente para STOP-B.
- El estado se conserva al volver al dashboard y entrar nuevamente en rutas.
- Sin errores observados.
- No se aceptó la propuesta ni se confirmó STOP-B.

## Límites

La pantalla continúa utilizando dos entregas sintéticas y un origen fijo. No constituye una interfaz de jornada para 100–500 paquetes ni valida navegación real.

Validación manual adicional del 2026-10-25 en Samsung SM-X210:
- Cierre desde aplicaciones recientes y reapertura desde el icono.
- Dashboard conserva 1 entrega de 2 y 0,01 EUR ficticios.
- Se recuperan la ruta aceptada y STOP-B pendiente.
- El nuevo cálculo incluye únicamente STOP-B.
- No se aceptó la propuesta ni se confirmó STOP-B.

Esta comprobación valida la reapertura normal; no acredita muerte forzada del proceso.

La issue #21 permanece abierta y ADR-004 no cambia de estado.
