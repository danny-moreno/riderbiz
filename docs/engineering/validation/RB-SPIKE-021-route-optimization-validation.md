# RB-SPIKE-021 · Validación de optimización adaptativa de rutas

## Estado

EN CURSO — evidencia parcial de arquitectura y motor local.

ADR-004 permanece en estado PROPUESTO.

## Fecha

2026-10-18

## Issue relacionada

#21

## ADR relacionado

`docs/decisions/ADR-004-adaptive-route-optimization.md`

## 1. Objetivo

Evaluar una arquitectura independiente del proveedor y comprobar su integración con motores de optimización mediante escenarios sintéticos.

La prueba deberá permitir comparar propuestas con el orden habitual, gestionar únicamente tareas pendientes y evaluar restricciones, conectividad, rendimiento y coste.

Este documento registra resultados parciales. No constituye todavía la aceptación de ADR-004 ni la selección de un proveedor de producción.

## 2. Alcance comprobado

- Modelos de dominio independientes del proveedor.
- Contrato `RouteOptimizationPort`.
- Adaptador falso determinista.
- Validación de coherencia de solicitudes.
- Comparación de métricas.
- Inclusión del tiempo de espera en la duración total.
- Fecha y hora de salida explícitas.
- Generadores sintéticos.
- Ejecutor de benchmarks repetidos.
- Entorno local VROOM y OSRM.
- Conversión de solicitudes y respuestas.
- Adaptador HTTP local.
- Prueba real desde Dart con dos tareas.
- Ejecución real con 60, 80 y 120 tareas.

## 3. Entorno observado

- Mac ARM64.
- Memoria del equipo: 16 GiB.
- macOS 27.0.1.
- Flutter 3.47.2 mediante FVM.
- Dart 3.13.2.
- Colima 0.10.3.
- Docker CLI 29.9.1.
- Docker Compose 5.6.0 mediante `docker-compose`.
- Perfil Colima: `riderbiz`.
- Máquina virtual: 4 CPU, 6 GiB de RAM y disco virtual de 30 GiB.
- Virtualización: Apple Virtualization.Framework.
- Contenedores Linux ARM64.

No se utilizaron servicios de pago para las comprobaciones documentadas.

El uso local tiene consumo de recursos y tiempo de operación. Estos resultados no equivalen a un coste de producción nulo.

## 4. Versiones del motor

OSRM:

- Versión observada: `v26.10.0`.
- Digest ARM64:

```text
sha256:b0045097b8b4ad5e72dce6b900326cd6ee0e98c729709214e674d0472b463f49
```

VROOM:

- Versión observada: `1.16.0-dev`.
- VROOM Express: `0.12.0`.
- Digest ARM64:

```text
sha256:189fabbb238f4891d821008b47b62085357be6a74f178656af5b253ced8f7069
```

La imagen de VROOM contiene una versión de desarrollo. Esta prueba no aprueba su uso en producción.

La configuración reproducible está en:

`tools/route-optimization/README.md`

## 5. Datos cartográficos

- Fuente: Geofabrik, extracto de Navarra.
- Descarga: 2026-10-18.
- Fecha de los datos indicada durante la extracción: `2026-10-17T20:20:51Z`.
- Tamaño aproximado del archivo PBF: 36 MB.
- SHA-256:

```text
be1d8bdbf369f04cc421526e853d39065cbc97892d3f83a6d439498d41fcbfb0
```

El mapa es real. Las tareas y los puntos seleccionados son sintéticos y no representan entregas de personas reales.

El enlace de descarga `latest` puede cambiar. Las reproducciones deben registrar la huella del mapa utilizado.

Atribución:

© OpenStreetMap contributors.

https://www.openstreetmap.org/copyright

## 6. Preparación del motor local

Se completaron:

1. Extracción con el perfil `car.lua`.
2. Partición del grafo.
3. Personalización MLD.
4. Arranque de OSRM.
5. Arranque de VROOM Express.
6. Consulta de ruta mediante OSRM.
7. Optimización mínima mediante VROOM.
8. Integración desde Dart.

Durante la personalización apareció una advertencia sobre nodos de frontera inaccesibles. El proceso terminó y las consultas posteriores funcionaron.

La advertencia no demuestra que todos los puntos del mapa sean accesibles. La conectividad deberá comprobarse para cada escenario.

## 7. Arquitectura neutral

El dominio representa:

- Entregas y recogidas.
- Estados pendientes, completados y cancelados.
- Paradas operativas.
- Prioridades.
- Ventanas horarias.
- Duración de servicio.
- Grupos peatonales.
- Tramos vehiculares.
- Propuestas y explicaciones.
- Métricas.
- Fecha y hora de salida.
- Timeout y señal de cancelación.

El dominio y el contrato no utilizan tipos propios de VROOM u OSRM.

## 8. Validación de solicitudes

El validador comprueba, entre otras condiciones:

- Identificadores de tareas y paradas únicos.
- Referencias existentes.
- Correspondencia entre tareas y paradas.
- Ausencia de tareas omitidas o duplicadas.
- Orden actual sin paradas repetidas.
- Presencia de paradas bloqueadas en el orden actual.
- Coherencia bidireccional de grupos peatonales.
- Coordenadas finitas y dentro de límites.
- Duraciones y ventanas válidas.

Los errores se expresan mediante `RouteOptimizationFailure`.

## 9. Adaptador falso

El adaptador falso permitió probar:

- Priorización.
- Ordenación por inicio de ventana.
- Conservación de posiciones bloqueadas dentro del orden pendiente.
- Exclusión de tareas completadas o canceladas.
- Métricas deterministas.
- Fallos simulados.
- Timeout.
- Cancelación previa y durante una espera.

Sus distancias y tiempos son sintéticos.

Ordenar por el inicio de una ventana no demuestra su cumplimiento horario.

Representar un grupo peatonal no demuestra que se calcule un recorrido a pie.

Estos resultados validan comportamiento de software, no calidad real de rutas.

## 10. Comparación de métricas

La duración total se calcula como:

```text
retraso de salida + conducción + servicio + espera
```

El tiempo de cálculo del optimizador se mide por separado.

El comparador actual prioriza la reducción de duración total. Si la duración es igual, utiliza la distancia como criterio secundario.

Las pruebas comprobaron que una reducción de conducción no se recomienda si la espera provoca una duración total mayor.

La comparación requiere que ambas alternativas representen las mismas tareas y condiciones. La validación de esa equivalencia deberá completarse antes de utilizarla en producto.

## 11. Conversión de solicitudes a VROOM

El conversor:

- Utiliza únicamente tareas pendientes.
- Genera identificadores numéricos para las paradas enviadas.
- Mantiene la correspondencia con identificadores internos.
- Expresa coordenadas como `[longitud, latitud]`.
- Agrupa las tareas de un portal en una visita.
- Suma sus duraciones de servicio.
- Utiliza la mayor prioridad del grupo.
- Convierte ventanas a segundos relativos a `departureAt`.
- Intersecta las ventanas de tareas de una misma parada.
- Rechaza ventanas incompatibles o vencidas.
- Rechaza explícitamente bloqueos y grupos peatonales activos.

La intersección de ventanas es una simplificación de esta primera versión: exige que las tareas agrupadas puedan atenderse en una única visita.

Las recogidas se representan como visitas independientes. No se modelan todavía capacidad de carga ni relaciones de transporte entre recogida y entrega.

## 12. Conversión de respuestas

El conversor comprueba:

- Código de éxito.
- Una única ruta para el vehículo esperado.
- Ausencia de tareas sin asignar.
- Identificadores conocidos y únicos.
- Presencia de todas las paradas solicitadas.
- Métricas no negativas y finitas.
- Distancias presentes.
- Acumulados no decrecientes.
- Coherencia entre totales y última parada.
- Ausencia de infracciones declaradas por el motor.
- Ausencia de tiempo de preparación no soportado.

Convierte acumulados en tramos entre paradas.

Esta primera versión rechaza propuestas parciales.

Las comprobaciones actuales no sustituyen una validación independiente completa de horarios, coordenadas ajustadas y restricciones.

## 13. Transporte HTTP local

El adaptador utiliza `dart:io`, sin dependencias HTTP adicionales.

Características:

- Endpoint limitado a HTTP local.
- Redirecciones desactivadas.
- Límite de respuesta: 4 MiB.
- Timeout por solicitud.
- Comprobación periódica de cancelación.
- Cierre del cliente al terminar, cancelar o agotar el tiempo.
- Errores tipados.
- Respuesta vacía local cuando no quedan tareas pendientes.

Cancelar la conexión del cliente no garantiza que VROOM detenga el cálculo en el servidor.

La integración documentada se ejecutó desde el entorno de pruebas del Mac. No valida todavía conectividad desde Android o iOS.

## 14. Comprobación mínima real

Se enviaron dos tareas sintéticas:

- Una entrega.
- Una recogida independiente.
- 120 segundos de servicio por tarea.
- Sin ventanas horarias.
- Sin retorno obligatorio al origen.

Resultado observado:

| Métrica | Resultado |
|---|---:|
| Tareas asignadas | 2 |
| Tareas sin asignar | 0 |
| Distancia | 2.501 m |
| Conducción | 351 s |
| Servicio | 240 s |
| Espera | 0 s |
| Duración total | 591 s |

La prueba desde Dart comprobó la coherencia del dominio y de los tramos.

## 15. Escenarios de volumen

Se creó un generador separado para la evaluación vehicular.

Características:

- 60, 80 y 120 tareas.
- Una tarea por parada.
- Una recogida independiente por cada cinco tareas.
- Resto de tareas: entregas.
- Prioridad normal.
- Servicio de dos minutos por entrega.
- Servicio de cuatro minutos por recogida.
- Sin ventanas horarias.
- Sin bloqueos.
- Sin grupos peatonales.
- Sin retorno obligatorio al origen.
- Coordenadas sintéticas en una cuadrícula sobre el mapa de Navarra.

OSRM ajusta los puntos a la red vial. No se ha medido todavía la distancia de ese ajuste ni la representatividad operativa de la cuadrícula.

## 16. Método de benchmark

Para cada volumen se ejecutaron cinco solicitudes secuenciales.

Se midió el tiempo transcurrido observado desde Dart, incluida la comunicación local y conversión.

Se registraron:

- Mínimo.
- Mediana.
- Percentil 95 mediante rango más próximo.
- Máximo.
- Repetibilidad del orden.
- Distancia.
- Conducción, servicio, espera y duración total.

Con cinco muestras, el percentil 95 coincide con el máximo. No representa una estimación robusta de latencia de producción.

No se realizó una separación formal entre ejecuciones frías y calientes.

## 17. Resultados de cálculo

Mediciones observadas el 2026-10-18:

| Tareas | Repeticiones | Mínimo ms | Mediana ms | P95 ms | Máximo ms | Orden repetible |
|---:|---:|---:|---:|---:|---:|---|
| 60 | 5 | 42,139 | 44,382 | 59,868 | 59,868 | Sí |
| 80 | 5 | 54,161 | 54,850 | 56,526 | 56,526 | Sí |
| 120 | 5 | 84,815 | 86,607 | 87,755 | 87,755 | Sí |

Todas las tareas fueron incluidas en cada propuesta.

## 18. Resultados de ruta

Las cinco repeticiones de cada volumen devolvieron las mismas métricas:

| Tareas | Distancia m | Conducción s | Servicio s | Espera s | Total s |
|---:|---:|---:|---:|---:|---:|
| 60 | 7.347 | 1.309 | 8.640 | 0 | 9.949 |
| 80 | 9.558 | 1.694 | 11.520 | 0 | 13.214 |
| 120 | 13.231 | 2.379 | 17.280 | 0 | 19.659 |

Estas métricas son estimaciones del escenario sintético. No prueban ahorro frente a la ruta habitual ni tiempos observados en reparto real.

### 18.1 Comparación con el orden inicial sintético

Mediciones realizadas el 2026-10-19.

Se evaluaron con el mismo OSRM ambos órdenes: el inicial generado y el propuesto por VROOM. Se mantuvieron el mismo origen, las mismas tareas y los mismos tiempos de servicio, sin ventanas horarias ni retorno obligatorio al origen.

| Tareas | Distancia inicial m | Distancia propuesta m | Total inicial s | Total propuesto s | Ahorro s | Reducción total |
|---:|---:|---:|---:|---:|---:|---:|
| 60 | 22.209 | 7.342 | 12.596,0 | 9.953,8 | 2.642,2 | 20,97 % |
| 80 | 29.745 | 9.553 | 16.807,8 | 13.215,0 | 3.592,8 | 21,37 % |
| 120 | 40.813 | 13.223 | 24.744,4 | 19.659,1 | 5.085,3 | 20,55 % |

Las tres pruebas terminaron correctamente y comprobaron que la propuesta contenía todas las paradas pendientes, sin duplicados.

Cada volumen se comparó una vez en esta ejecución. La repetibilidad de esta comparación no se ha medido todavía.

El orden inicial corresponde a una cuadrícula sintética. No representa la ruta habitual de un repartidor experimentado y puede favorecer diferencias grandes frente a la propuesta optimizada.

Estas cifras no deben utilizarse como promesa comercial de ahorro.

Las métricas reevaluadas con OSRM difieren ligeramente de las devueltas por VROOM. La comparación utiliza exclusivamente el mismo evaluador OSRM para ambos órdenes; queda pendiente caracterizar esas diferencias.

El evaluador actual no calcula ventanas horarias ni recorridos peatonales y los rechaza explícitamente.

### 18.2 Ventanas horarias y retraso de salida

Se ejecutaron dos casos sintéticos de una parada contra VROOM y OSRM locales. La comprobación inicial se realizó el 2026-10-19 y la corrección del cómputo se verificó el 2026-10-22.

Caso viable:

- Ventana de inicio del servicio: entre 3.600 y 7.200 segundos desde `departureAt`.
- Retraso de salida decidido por VROOM: 3.454 segundos.
- Conducción: 146 segundos.
- Inicio del servicio: segundo 3.600.
- Servicio: 120 segundos.
- Espera en la parada: cero segundos.
- Final: segundo 3.720.

La primera comprobación reveló que las métricas omitían el retraso previo a la salida. Se añadió `departureDelay` al dominio y se incorporó a `totalDuration`.

Resultado corregido:

3.454 + 146 + 120 + 0 = 3.720 segundos desde la hora de salida solicitada.

El conversor exige horarios de inicio y final no negativos y comprueba que el final coincide con la suma de retraso, conducción, servicio y espera.

Caso imposible:

- Ventana de inicio del servicio: entre cero y un segundo desde `departureAt`.
- El motor dejó la tarea sin asignar.
- El adaptador rechazó la propuesta incompleta.

Actualmente ese rechazo utiliza `invalidResponse`. Queda pendiente distinguir una solución inviable de una respuesta mal formada mediante un resultado específico.

Ambos casos pasaron. No se ha validado todavía el cumplimiento independiente de todas las ventanas en rutas de múltiples paradas.

La prueba viable compara el horario de una respuesta directa con otra solicitud independiente del adaptador. Funcionó en este escenario, pero deberá mejorarse para verificar una única respuesta sin depender de la repetibilidad del motor.

## 19. Pruebas automatizadas

Estado de la suite habitual al registrar esta fase:

- 167 pruebas superadas.
- Nueve pruebas locales omitidas por defecto.
- Análisis estático sin incidencias.

Las pruebas locales se ejecutaron explícitamente:

- Tres pruebas de comparación con el orden inicial sintético: superadas.
- Una prueba de integración mínima: superada.
- Tres pruebas de volumen: superadas.
- Cinco solicitudes por volumen: 15 optimizaciones reales completadas.
- Dos pruebas de ventanas horarias: superadas; caso viable y caso imposible.

Activación:

```bash
cd apps/mobile

fvm flutter test \
  --dart-define=RUN_LOCAL_VROOM=true \
  --concurrency=1 \
  --reporter=expanded \
  test/features/route_optimization/vroom_volume_runtime_test.dart
```

## 20. Privacidad y almacenamiento

- No se utilizaron datos personales de destinatarios.
- No se enviaron etiquetas ni texto OCR.
- Los identificadores de tareas y paradas son sintéticos.
- No se contrataron servicios externos de optimización.
- Los puertos se publicaron únicamente en `127.0.0.1`.
- Mapas y archivos procesados están excluidos de Git.
- La geometría devuelta no se conserva en el modelo de dominio.

Las pruebas sintéticas no validan por sí solas la eliminación verificable exigida para datos personales reales en ADR-003.

## 21. Evidencia Git

| Commit | Evidencia |
|---|---|
| `5089b38` | Dominio neutral y adaptador falso |
| `3a49955` | Escenarios sintéticos generales |
| `9cf51cb` | Comparación de propuestas |
| `62537f3` | Ejecutor de benchmarks |
| `507a5ed` | Validación de coherencia de solicitudes |
| `a3acda3` | Cancelación durante ejecución |
| `4f77630` | Entorno local VROOM y OSRM |
| `49574e8` | Tiempo de espera |
| `d8799ba` | Fecha y hora de salida |
| `7e25f98` | Conversión de solicitudes |
| `38930b9` | Conversión y validación de respuestas |
| `29b93b3` | Adaptador HTTP local |
| `298b45c` | Integración real mínima desde Dart |
| `26076c2` | Escenarios vehiculares de volumen |
| `65aa73f` | Benchmark real de 60, 80 y 120 tareas |
| `1bb6cb8` | Evaluador OSRM para órdenes fijos |
| `79dee7d` | Comparación real con el orden inicial sintético |
| `c6f44a4` | Validación real de ventanas horarias |
| `44b9561` | Inclusión del retraso de salida y comprobación del horario total |

## 22. Validaciones pendientes

- Comparación con órdenes habituales representativos de repartidores; la comparación con el orden inicial sintético ya está completada.
- Ventanas horarias de múltiples paradas, con verificación independiente de cada inicio de servicio; los dos casos básicos de una parada ya están comprobados.
- Priorización bajo restricciones.
- Conservación de paradas bloqueadas en el motor real.
- Reoptimización real después de completar tareas.
- Recorridos peatonales y separación de tramos.
- Control del ajuste de coordenadas a la red.
- Escenarios geográficos y operativos más representativos.
- Fallos reales del servicio y recuperación de la ruta aceptada.
- Evaluación de GraphHopper con acceso autorizado.
- Costes proyectados por repartidor y mes.
- Medición de recursos de infraestructura.
- Persistencia y eliminación de información temporal.
- Ejecución pertinente en dispositivos físicos.
- Evaluación de una versión estable del motor para producción.

## 23. Conclusión parcial

La arquitectura permite conectar el dominio de RiderBiz con VROOM y OSRM locales.

El motor resolvió los escenarios vehiculares sintéticos de 60, 80 y 120 tareas, con todas las paradas incluidas y latencias locales bajas en el entorno medido.

Todavía no existe evidencia suficiente para aceptar ADR-004, seleccionar proveedor definitivo o afirmar ahorro operativo para repartidores.

La Issue #21 permanece abierta.

## 24. Fuentes y referencias

- ADR-004: `docs/decisions/ADR-004-adaptive-route-optimization.md`
- Preparación local: `tools/route-optimization/README.md`
- OSRM: https://github.com/Project-OSRM/osrm-backend
- VROOM: https://github.com/VROOM-Project/vroom
- VROOM Docker: https://github.com/VROOM-Project/vroom-docker
- Geofabrik Navarra: https://download.geofabrik.de/europe/spain/navarra.html
- OpenStreetMap: https://www.openstreetmap.org/copyright

## 25. Historial

- Versión 0.1 (2026-10-18): evidencia parcial del dominio neutral, validaciones, integración local y benchmarks vehiculares de 60, 80 y 120 tareas.
- Versión 0.2 (2026-10-19): evaluador OSRM, comparación con el orden inicial sintético y actualización del estado de pruebas.
- Versión 0.3 (2026-10-22): ventanas horarias básicas, corrección del retraso de salida y actualización a 167 pruebas superadas y nueve locales omitidas.
