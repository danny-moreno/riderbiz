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
