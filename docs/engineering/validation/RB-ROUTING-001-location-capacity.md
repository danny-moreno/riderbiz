# Capacidad de ubicaciones del mapper local

## Escenarios y resultados

Ocho pruebas específicas superadas, sin llamadas a VROOM ni OSRM.

Se construyen solicitudes de 500 paquetes agrupados en 248, 249 y 250 paradas, con y sin destino final explícito.

| Paradas pendientes | Sin destino final | Con destino final |
|---|---|---|
| 248 | Admitido | Admitido |
| 249 | Admitido | Rechazado |
| 250 | Rechazado | Rechazado |

El límite configurado es de 250 ubicaciones, incluyendo origen y destino explícito.

Los casos admitidos verifican inclusión de todas las paradas pendientes y suma del servicio de todos los paquetes pendientes. Los casos rechazados verifican invalidRequest. En ambos casos se comprueba que la solicitud conserva sus 500 tareas pendientes y su orden inicial.

Dos casos adicionales parten de 500 paquetes distribuidos en 250 paradas:
- Una parada completada permite convertir las 249 restantes sin destino final.
- Dos paradas completadas permiten convertir las 248 restantes con destino final.

Se verifica que las tareas completadas permanecen en el plan y se excluyen del servicio pendiente.

## Validación

- Ocho pruebas específicas superadas.
- Flutter analyze sin incidencias.
- Suite habitual: 269 pruebas superadas y 23 pruebas locales omitidas.
- git diff --check sin incidencias.

## Alcance

La evidencia corresponde al mapper local. No demuestra ejecución del motor con esos volúmenes, rendimiento en dispositivos, conservación de una ruta aceptada ante este error ni división automática de rutas.

500 paquetes no equivalen necesariamente a 500 ubicaciones. El límite de este adaptador no establece un máximo general de paquetes de RiderBiz.

La issue #21 permanece abierta y ADR-004 no cambia de estado.
