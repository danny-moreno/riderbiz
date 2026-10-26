# RB-UI-004 · Orden habitual sin optimizador

## Estado

Implementado y comprobado en escenarios sintéticos.
Issue #21 abierta. ADR-004 permanece PROPUESTO.

## Comportamiento

La jornada permite seleccionar expresamente «Usar orden habitual», utilizando el orden almacenado en la definición del escenario.

La selección:
- No solicita optimización.
- Permite confirmar paquetes pertenecientes al orden seleccionado.
- Se conserva junto con el progreso al reabrir la jornada.
- No presenta distancias ni tiempos inventados.
- Puede sustituirse posteriormente mediante la aceptación explícita de una propuesta calculada.

En este escenario, «habitual» designa el orden sintético guardado; no procede de un repartidor real ni demuestra eficiencia operativa.

## Persistencia y compatibilidad

Se utiliza la tabla existente AcceptedRouteSnapshots, sin modificar el esquema 5 de SQLite.

El formato JSON de selección habitual es versión 2 y contiene únicamente versión, modo y orden. No incluye métricas.

Las rutas calculadas mantienen el formato versión 1. loadSelection permite leer ambos modos. La interfaz anterior load conserva su contrato para rutas calculadas y no debe utilizarse para leer selecciones habituales.

## Pruebas automatizadas

- Recuperación del orden habitual desde SQLite en disco, sin métricas.
- Compatibilidad de las rutas calculadas y sustitución entre ambos modos.
- Rechazo de órdenes vacíos, duplicados o con identificadores en blanco, sin reemplazar la selección anterior.
- Selección del modo habitual y confirmación desde la pantalla sin invocar al adaptador.
- Recuperación del progreso y del orden después de reabrir.
- Conservación del orden ante un fallo posterior del optimizador y posibilidad de continuar confirmando entregas.
- Persistencia en disco de entregas, eventos y tarifa ficticia, con rechazo de una confirmación duplicada.

Resultado: análisis estático sin incidencias; suite habitual de 291 pruebas superadas y 24 omitidas por defecto. git diff --check sin incidencias.

## Validación manual

Realizada el 2026-10-26 en Samsung SM-X210 mediante USB, con VROOM y OSRM detenidos.

Se comprobó:
- Selección del orden habitual y presentación de «60 paradas · sin estimaciones».
- Confirmación de un paquete sintético pendiente y actualización coherente de los contadores.
- Actualización de entregas e ingresos ficticios en el dashboard.
- Conservación del modo y del progreso tras cerrar desde aplicaciones recientes y reabrir.
- Error de conexión al intentar optimizar, conservando el orden habitual.

## Límites

No valida mapas offline, navegación, muerte forzada del proceso ni uso en campo. La indisponibilidad de los motores locales no equivale a probar todas las condiciones de pérdida de conectividad del dispositivo.

El escenario mantiene origen fijo, datos sintéticos y una tarifa ficticia. No incorpora todavía captura de un recorrido habitual real ni un editor completo de su secuencia.
