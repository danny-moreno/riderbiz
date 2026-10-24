# Persistencia de la definición de ruta — esquema v5

## Implementación

- Nueva tabla RoutePlanDefinitions vinculada a una jornada.
- Migración aditiva v4 → v5.
- JSON versionado para orden inicial, paradas, coordenadas, tareas y restricciones.
- Los estados de entrega se recuperan de los paquetes; no se duplican en el JSON.
- RoutePlanStore guarda y recupera el plan mediante transacciones.
- Admite entregas cuyo identificador de tarea coincide con el identificador del paquete.
- Rechaza jornadas inexistentes, paquetes ajenos y estados no soportados.

## Evidencia

- Prueba v4 → v5: conserva paquete entregado, tarifa, evento y ruta aceptada; permite escribir en la nueva tabla.
- Cinco pruebas del servicio: recuperación en disco de 150 paquetes/60 paradas, estados actuales, aislamiento de jornadas, rechazo de estados no soportados y conservación de restricciones.
- Se conservan orden, coordenadas, asociaciones, prioridades, ventanas horarias, bloqueos, grupos peatonales y precisión del tiempo de servicio.
- La prueba integrada con VROOM recupera ahora la definición desde SQLite después de reabrir, en lugar de reconstruir sus tareas y paradas desde el generador.
- La reoptimización conserva la parada parcialmente entregada y excluye la completada.

## Validación conjunta

- Flutter analyze sin incidencias.
- 299 pruebas superadas, ninguna omitida, con RUN_LOCAL_VROOM=true y concurrencia 1.
- git diff --check sin incidencias.
- Los archivos históricos generados v1–v4 quedan sin modificaciones.

Regeneración de ayudas de migración:
dart run drift_dev schema generate --data-classes --companions drift_schemas/ test/generated_migrations/

## Límites

El servicio aún no está conectado a las pantallas. La migración no rellena definiciones para rutas antiguas: conserva sus datos existentes.

El origen, la salida y el timeout se aportan al construir cada solicitud. No se validan posición cambiante, sincronización, borrado de datos personales ni uso real en campo.

La conservación de restricciones no implica que el adaptador local pueda resolverlas todas combinadas. Los paquetes failed y las tareas de recogida no están soportados por este servicio.

La issue #21 permanece abierta y ADR-004 no cambia de estado.
