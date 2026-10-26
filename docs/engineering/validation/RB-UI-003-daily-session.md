# Jornada sintética de 150 paquetes y 60 paradas

## Implementación

- Acceso desde Operaciones del dashboard.
- Base separada: riderbiz_daily_session_validation.
- Preparación transaccional del escenario una sola vez.
- Recuperación del plan y estados desde SQLite.
- Lista de paradas con paquetes individuales.
- Cálculo de pendientes, aceptación explícita y confirmación por paquete.
- Solo se confirman paquetes pendientes de una parada incluida en la ruta aceptada.
- Una entrega invalida la propuesta todavía no aceptada.
- Se reutiliza el generador existente desde la aplicación; las pruebas mantienen su importación mediante un archivo de exportación.

## Validación automatizada

- Tres pruebas del servicio superadas: preparación y recuperación en disco, rechazo sin ruta aceptada y rechazo de paquetes ajenos al recorrido.
- Prueba de pantalla superada con adaptador simulado: cálculo, aceptación, entrega individual, recálculo y recuperación al reconstruir la pantalla.
- Flutter analyze sin incidencias.
- Suite habitual: 280 pruebas superadas y 24 pruebas locales omitidas.
- git diff --check sin incidencias.

## Validación manual — 2026-10-25

Samsung SM-X210 conectada por USB, con VROOM y OSRM locales.

- Preparación inicial: 150 paquetes, 60 paradas y cero entregados.
- Cálculo y aceptación de una ruta de 60 paradas.
- Confirmación de un paquete: 1 entregado y 149 pendientes.
- La parada parcialmente entregada conserva paquetes pendientes.
- Nuevo cálculo con 60 paradas, sin aceptar otra vez.
- Al volver al dashboard y entrar en Operaciones se conserva el progreso.
- Sin errores observados.

La captura muestra una ruta aceptada de 7347 metros y STOP-DAILY-055 con un pendiente de dos.

## Límites

Pantalla funcional de simulación; no implementa mapa ni navegación del diseño final. Origen fijo, servicio supuesto de 60 segundos por paquete y tarifa ficticia de 1,20 EUR.

No valida una jornada completa, ubicación cambiante, incidencias, sincronización ni rendimiento con 500 paquetes en interfaz.

El dashboard continúa mostrando el escenario anterior de dos paquetes; sus indicadores todavía no representan esta jornada.

La recuperación tras cerrar y reabrir la aplicación con esta pantalla queda pendiente de comprobar.

La issue #21 permanece abierta y ADR-004 no cambia de estado.

## Dashboard conectado a la jornada diaria

El dashboard consulta la base separada de la jornada sintética de 150 paquetes. «Abrir jornada» y «Operaciones» permiten acceder a esa jornada. El escenario anterior sigue disponible mediante «Prueba anterior · 2 paquetes».

Validación manual en Samsung SM-X210:
- El dashboard muestra el progreso de la jornada diaria.
- Ambos accesos abren la jornada y conservan su progreso.
- El escenario anterior de dos paquetes continúa accesible.
- Al regresar al inicio, los indicadores corresponden a la jornada diaria.
- Tras cerrar desde aplicaciones recientes y reabrir, se conservan la ruta aceptada y las entregas registradas.

Esta comprobación de reapertura normal no acredita muerte forzada del proceso. Este apartado actualiza las limitaciones anteriores sobre los indicadores del dashboard y la reapertura.

Validación automatizada:
- Tres pruebas del dashboard superadas.
- Análisis estático sin incidencias.
- Suite habitual previa al último ajuste de accesos: 280 pruebas superadas y 24 omitidas.

La Issue #21 permanece abierta y ADR-004 continúa pendiente de validación.

## Tiempo agotado, recuperación y salida durante el cálculo

Validación manual realizada el 2026-10-26 en Samsung SM-X210 conectada mediante USB, sobre la jornada sintética de 150 paquetes y 60 paradas, con una ruta previamente aceptada y entregas ya registradas.

Preparación:
- Colima y los servicios locales VROOM y OSRM iniciados.
- Un primer intento mostró «No se pudo conectar con el servicio local».
- Se restablecieron los puertos USB mediante adb reverse y se comprobó que un nuevo cálculo obtenía una propuesta.

Tiempo de espera y recuperación:
- Se pausó VROOM antes de iniciar otro cálculo, manteniendo OSRM activo.
- La pantalla mostró «El cálculo superó el tiempo disponible» tras aproximadamente 40 segundos, según observación manual.
- Finalizó el indicador y volvió a habilitarse el cálculo.
- Los contadores y la ruta aceptada conservaron sus valores.
- Tras reanudar VROOM y comprobar su estado healthy, un nuevo cálculo obtuvo una propuesta y desapareció el error.

Salida durante el cálculo:
- Con VROOM pausado, se inició un cálculo.
- Se volvió al dashboard antes del límite de espera.
- Al reabrir la jornada, se conservaron las entregas y la ruta aceptada, y el cálculo estaba disponible.
- Tras reanudar VROOM, un nuevo cálculo obtuvo una propuesta sin errores.

No se aceptaron las propuestas ni se confirmaron entregas durante estas comprobaciones.

Resultado: superado para tiempo agotado, recuperación y navegación fuera de la pantalla durante el cálculo.

Alcance: comprobación manual del comportamiento visible. El tiempo observado es aproximado. No se instrumentó la cancelación HTTP desde esta pantalla ni la interrupción del trabajo interno de VROOM. No valida muerte forzada del proceso ni fallos de guardado.

La Issue #21 permanece abierta y ADR-004 continúa pendiente de validación.

## Pruebas automatizadas de recuperación y cancelación

Validación realizada el 2026-10-26 mediante dos pruebas de pantalla con un adaptador controlado y SQLite en memoria.

Estado inicial: jornada de 150 paquetes y 60 paradas, ruta aceptada y un paquete entregado.

Se comprueba que:
- Ante un error de tipo timeout, aparece el mensaje correspondiente, termina el indicador y se habilita nuevamente el cálculo.
- Un cálculo posterior obtiene una propuesta y elimina el error.
- Salir mediante navegación atrás activa la señal de cancelación.
- Una propuesta completada después de salir no genera excepciones ni aparece al reabrir.
- Reabrir no inicia automáticamente otro cálculo.
- Se conservan 149 paquetes pendientes, el evento de entrega y la ruta aceptada con su distancia y fecha de aceptación.

Resultados:
- Dos pruebas específicas superadas.
- Análisis estático sin incidencias.
- Suite habitual: 282 pruebas superadas y 24 omitidas por defecto.
- git diff --check sin incidencias.

Alcance: el adaptador de prueba simula el error de tiempo agotado; no mide una espera real de 40 segundos. Estas pruebas no utilizan HTTP ni VROOM. La comprobación manual del servicio local se documenta en el apartado anterior.

La Issue #21 permanece abierta y ADR-004 continúa pendiente de validación.
