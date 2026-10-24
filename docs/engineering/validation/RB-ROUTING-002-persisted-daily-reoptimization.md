# Reoptimización con entregas persistidas

## Escenario

150 paquetes sintéticos agrupados en 60 paradas, SQLite temporal en disco y motores locales VROOM/OSRM.

## Comprobaciones superadas

- Cálculo y almacenamiento de una ruta inicial con las 60 paradas.
- Confirmación contable de todos los paquetes de una parada y de un paquete de otra.
- Cierre y reapertura de SQLite.
- Recuperación de los 150 paquetes y sus estados individuales.
- Recuperación del orden, fecha y distancia de la ruta aceptada.
- Construcción de una nueva solicitud usando los estados recuperados.
- Reoptimización de 59 paradas: se excluye la completada y se conserva la parcialmente entregada.
- Servicio calculado únicamente para los paquetes pendientes.
- Conservación de la ruta anterior hasta aceptar la nueva propuesta.
- Comprobación de eventos e importe acumulado con tarifa ficticia de 120 céntimos EUR.
- Aceptación de la nueva propuesta y recuperación de su orden, fecha, distancia y duración tras otra reapertura.
- Conservación del número de paquetes y de los eventos tras la segunda reapertura.

## Validación

- Prueba específica con servicios locales superada.
- Flutter analyze sin incidencias.
- Suite completa: 293 pruebas superadas, ninguna omitida, con RUN_LOCAL_VROOM=true, concurrencia 1 y timeout de prueba de dos minutos.
- git diff --check sin incidencias.

## Límites

Los estados de entrega y las rutas aceptadas se recuperan de SQLite. La relación entre paquetes y paradas, las coordenadas y los tiempos de servicio proceden del generador sintético.

La solicitud conserva un origen fijo. No se valida posición cambiante, interfaz de jornada, sincronización, incidencias de entrega, ventanas horarias ni división de rutas por capacidad.

No demuestra todavía la recuperación de una jornada completa sin depender del generador.

La issue #21 permanece abierta y ADR-004 no cambia de estado.

## Actualización con esquema v5

La prueba integrada utiliza ahora RoutePlanStore para guardar la definición inicial y recuperar paradas, coordenadas, tareas y tiempos de servicio tras reabrir SQLite. Los estados se recuperan de los paquetes y el orden aceptado de AcceptedRouteStore.

Esto sustituye la reconstrucción desde el generador descrita en los límites anteriores. El generador permanece para preparar los datos iniciales. Véase RB-ROUTING-003-route-plan-persistence.md.
