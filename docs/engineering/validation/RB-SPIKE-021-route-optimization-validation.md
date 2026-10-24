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

Las propuestas con tareas sin asignar se rechazan mediante `incompleteSolution`. Las respuestas mal formadas conservan `invalidResponse`. Una propuesta incompleta no demuestra que el problema sea matemáticamente inviable.

Ambos casos pasaron. La validación adicional de tres paradas se documenta en la sección 18.4.

Desde el 2026-10-23, cada caso obtiene una única respuesta de VROOM y utiliza esa misma respuesta para verificar el horario y convertir las métricas. La prueba ya no depende de comparar dos solicitudes independientes.

### 18.3 Reoptimización de tareas pendientes

Validación realizada el 2026-10-23 contra VROOM y OSRM locales.

Se utilizó un escenario de 80 tareas sintéticas, con 20 completadas y 60 pendientes. La ubicación inicial del cálculo se situó en el punto sintético de la última tarea completada.

Resultados:

| Métrica | Resultado |
|---|---:|
| Tareas totales | 80 |
| Tareas completadas | 20 |
| Tareas pendientes | 60 |
| Paradas propuestas | 60 |
| Paradas completadas reintroducidas | 0 |
| Distancia estimada | 7.682 m |
| Conducción | 1.326 s |
| Servicio | 8.640 s |
| Espera | 0 s |
| Retraso de salida | 0 s |
| Duración total | 9.966 s |

La prueba comprobó que todas las paradas pendientes aparecían exactamente una vez y que el cálculo no modificaba el orden ni los estados del plan original.

El escenario no incluye ventanas horarias, bloqueos ni grupos peatonales. El cambio de estados se preparó como dato de prueba; no valida todavía el flujo completo de confirmación de entregas ni su persistencia.

### 18.4 Ventanas horarias en tres paradas

Validación realizada el 2026-10-23 sobre una única respuesta de VROOM.

Se comprobaron individualmente los inicios de servicio mediante `arrival + waiting_time`:

| Parada | Ventana s | Llegada s | Espera s | Inicio del servicio s |
|---|---|---:|---:|---:|
| 1 | 600–1.800 | 1.800 | 0 | 1.800 |
| 2 | 2.400–3.600 | 2.125 | 275 | 2.400 |
| 3 | 4.200–5.400 | 2.702 | 1.498 | 4.200 |

Todos los tiempos son relativos a `departureAt`.

Las tres paradas quedaron asignadas sin duplicados y sus inicios de servicio cumplieron las ventanas. Estas ventanas limitan el inicio del servicio, no su finalización.

La conversión produjo:

- Retraso de salida: 1.654 s.
- Conducción: 533 s.
- Servicio: 360 s.
- Espera: 1.773 s.
- Total desde `departureAt`: 4.320 s.

La suma coincide con la hora final devuelta por el motor.

Este resultado valida un escenario sintético pequeño. No demuestra todavía el comportamiento con ventanas superpuestas, varias tareas por portal o cargas de 60–120 tareas con restricciones horarias.

### 18.5 Destino final explícito

Validación realizada el 2026-10-23 con dos tareas y retorno explícito al origen como escenario de prueba.

El destino final no se añadió al orden de tareas. La propuesta incluyó dos paradas operativas y tres tramos vehiculares.

Resultados:

- Último tramo: 1.077 m y 182 s.
- Distancia total: 3.578 m.
- Conducción: 533 s.
- Servicio: 240 s.
- Duración total: 773 s.

El retorno al origen no se establece como regla general del producto.

### 18.6 Conservación de posiciones bloqueadas

Validación realizada el 2026-10-23 con 60 tareas sintéticas.

La estrategia divide el orden pendiente en tramos delimitados por paradas bloqueadas. Reordena únicamente las paradas de cada tramo, sin moverlas al otro lado de un bloqueo.

Las posiciones bloqueadas fueron 1, 20, 21 y 60, equivalentes a los índices 0, 19, 20 y 59.

Se utilizaron:

- VROOM para optimizar tramos con tareas intermedias.
- Un destino explícito para llegar a la siguiente parada bloqueada.
- OSRM directo para un bloqueo inicial o bloqueos consecutivos.
- Una validación final del orden combinado.

Resultados:

| Métrica | Resultado |
|---|---:|
| Tareas y paradas propuestas | 60 |
| Posiciones bloqueadas conservadas | 4 |
| Tramos vehiculares | 60 |
| Distancia estimada | 9.310 m |
| Conducción | 1.642,1 s |
| Servicio | 8.640 s |
| Duración total | 10.282,1 s |
| Tiempo de cálculo observado | 72,286 ms |

La prueba verificó continuidad de los tramos, servicio contado una sola vez y conservación del plan original.

El coordinador utiliza un presupuesto de tiempo compartido entre solicitudes y comprueba la cancelación entre tramos.

Las pruebas con clientes simulados comprobaron que un fallo de VROOM o de OSRM se propaga sin solicitar los tramos siguientes. También comprobaron que un resultado recibido después de agotar el presupuesto total se rechaza mediante `timeout`.

Esta última prueba verifica el rechazo posterior a la respuesta, no una interrupción inmediata al vencer el plazo. Una prueba adicional comprobó que el segundo tramo recibe un presupuesto reducido por el tiempo consumido en el primero. Sigue pendiente ampliar estos casos a OSRM y comprobar la cancelación durante solicitudes en curso.

Esta estrategia conserva también la pertenencia de cada parada a su tramo, una restricción adicional a fijar solamente la posición del bloqueo. Limita la búsqueda y no garantiza el óptimo global.

La estrategia segmentada rechaza ventanas horarias y grupos peatonales. El adaptador VROOM básico sigue rechazando bloqueos; estos se gestionan mediante el coordinador específico.

### 18.7 Cálculo desde una tablet física

Validación completada el 2026-10-24 en una Samsung SM-X210 con Android 16 (API 36).

La pantalla de validación solicitó una propuesta para dos entregas sintéticas en Pamplona. Se utilizó una conexión USB con redirección de los puertos 3000 y 5000 hacia VROOM y OSRM en el Mac. Los servicios permanecieron publicados únicamente en 127.0.0.1 del Mac.

Resultados mostrados en el dispositivo:

| Métrica | Resultado |
|---|---:|
| Orden propuesto | STOP-A → STOP-B |
| Distancia | 2.501 m |
| Conducción | 351 s |
| Servicio | 240 s |
| Duración total | 591 s |

Se comprobó el flujo desde la interfaz hasta el motor local y la presentación del resultado en la tablet. La propuesta no se guarda, no modifica el paquete local y no utiliza la ubicación del dispositivo.

También se comprobó manualmente la conservación del estado del paquete tras cerrar y abrir la aplicación, la lectura de un QR sintético y el acceso al servicio de ubicación.

La ubicación informó una precisión estimada de 100 m. El código puede utilizar la última posición conocida sin verificar su antigüedad; esta comprobación no valida una posición actual ni precisión suficiente para identificar un portal.

Esta primera prueba se limitó al cálculo mediante USB. La aceptación, persistencia y recuperación ante desconexión se documentan en la sección 18.8. El funcionamiento sin cable y una jornada real de reparto siguen pendientes.

### 18.8 Aceptación, persistencia y recuperación ante desconexión

Validación realizada el 2026-10-24 en la Samsung SM-X210.

Se calculó una propuesta sintética y se guardó mediante «Aceptar propuesta». Tras cerrar la aplicación desde las aplicaciones recientes y abrirla desde su icono, la pantalla recuperó el orden STOP-A → STOP-B, la distancia de 2.501 m y la duración total de 591 s sin solicitar otro cálculo.

El almacenamiento utiliza la tabla AcceptedRouteSnapshots de Drift, incorporada en el esquema 4. Conserva el orden, las métricas y la fecha de aceptación; no contiene geometría ni permite navegación.

Las pruebas automatizadas comprobaron las migraciones 1→4, 2→4 y 3→4, la conservación de datos anteriores y las operaciones del servicio de almacenamiento. Una prueba de pantalla verificó que calcular no sustituye la ruta aceptada y que la sustitución requiere aceptación explícita.

Para comprobar un fallo de conexión, se cerró la aplicación y se retiró el túnel USB del puerto 3000. Al volver a abrirla e intentar calcular, apareció el mensaje de conexión no disponible y la ruta aceptada permaneció visible.

Tras restablecer el túnel, se obtuvo nuevamente una propuesta.

Esta evidencia no valida todavía interrupciones durante una respuesta, fallos de escritura, recuperación tras cierre inesperado durante el guardado ni una jornada de reparto.

### 18.9 Confirmación de entregas y cálculo de pendientes

Validación realizada el 2026-10-24.

Las paradas STOP-A y STOP-B se vincularon a dos paquetes sintéticos almacenados en Drift. La confirmación reutiliza DeliveryAccountingService: actualiza el paquete, conserva la tarifa aplicada y registra el evento dentro de una transacción.

El escenario utiliza un operador sintético y una tarifa ficticia de 0,01 € por paquete. Estos registros no representan ingresos reales.

Las pruebas automatizadas comprobaron que preparar el escenario nuevamente no reinicia las entregas, que confirmar exige una ruta aceptada y que una segunda confirmación no duplica eventos.

La prueba de pantalla comprobó la recuperación del progreso y una solicitud con STOP-A completada y STOP-B pendiente. El motor simulado propuso únicamente STOP-B.

En la Samsung SM-X210 se confirmaron ambas entregas. Tras cerrar y abrir la aplicación, ambas conservaron el estado Entregado y sus botones quedaron desactivados.

Con ambas entregas completadas, se comprobó en la tablet el mensaje «No quedan entregas pendientes» y la desactivación del cálculo.

El cálculo utiliza todavía un origen sintético fijo. La comprobación posterior con una entrega completada y otra pendiente, ejecutada desde la tablet contra los motores locales, se documenta en la sección 18.11.

### 18.10 Correcciones identificadas durante la revisión

La revisión del código identificó cuatro casos límite, reproducidos mediante pruebas de regresión y corregidos el 2026-10-24:

- Rechazo de ventanas caducadas antes de convertir sus tiempos a segundos, incluido un vencimiento 500 ms anterior a departureAt.
- Cómputo del origen y del destino explícito dentro del límite local de 250 ubicaciones. El conversor permite hasta 249 paradas sin destino explícito y 248 con él.
- Redondeo del servicio por parada en el coordinador segmentado, después de sumar las tareas de esa parada, siguiendo el criterio utilizado en las solicitudes VROOM.
- Comprobación de que el servicio total de la respuesta coincide con la suma del servicio de los trabajos enviados.

Tras las correcciones se ejecutó la suite completa con servicios locales: 246 pruebas superadas, ninguna omitida, en aproximadamente 15 segundos.

Esta ejecución no amplía el alcance de las pruebas físicas ni valida por sí sola el uso en producción.

### 18.11 Reoptimización parcial desde la tablet

Validación realizada el 2026-10-24 en la Samsung SM-X210, con VROOM y OSRM locales mediante USB.

Se utilizó una base de datos separada, denominada riderbiz_partial_delivery_validation, para conservar los registros del escenario anterior. No se modificó la versión 4 del esquema.

Después de aceptar la ruta inicial de dos paradas, se confirmó únicamente STOP-A. STOP-B permaneció pendiente.

Al calcular otra propuesta, la pantalla mostró únicamente STOP-B:

| Métrica | Resultado |
|---|---:|
| Paradas propuestas | 1 |
| Distancia | 1.616 m |
| Conducción | 213 s |
| Servicio | 120 s |
| Duración total | 333 s |

Antes de aceptar, la ruta anterior permaneció guardada. Tras aceptar la propuesta parcial, cerrar la aplicación y abrirla desde su icono, se recuperaron STOP-B, sus métricas y el estado Pendiente sin solicitar otro cálculo.

El cálculo utiliza un origen sintético fijo. No representa el desplazamiento desde STOP-A ni desde la ubicación actual del dispositivo.

La pantalla muestra las paradas de la propuesta aceptada; después de aceptar la propuesta parcial, STOP-A deja de aparecer en esa lista. Esta prueba no comprueba mediante consulta directa el registro contable de STOP-A después de la sustitución.

## 19. Pruebas automatizadas

Estado de la suite habitual al registrar esta fase:

- 233 pruebas superadas.
- Trece pruebas locales omitidas por defecto.
- Análisis estático sin incidencias.

Las pruebas locales se ejecutaron explícitamente:

- Tres pruebas de comparación con el orden inicial sintético: superadas.
- Una prueba de integración mínima: superada.
- Tres pruebas de volumen: superadas.
- Cinco solicitudes por volumen: 15 optimizaciones reales completadas.
- Tres pruebas de ventanas horarias: superadas; caso viable de una parada, caso imposible y tres paradas con ventanas sucesivas.
- Una prueba de reoptimización de tareas pendientes: superada.
- Una prueba de destino final explícito: superada.
- Una prueba de 60 tareas con cuatro posiciones bloqueadas: superada.

Activación:

```bash
cd apps/mobile

fvm flutter test \
  --dart-define=RUN_LOCAL_VROOM=true \
  --concurrency=1 \
  --reporter=expanded \
  test/features/route_optimization/vroom_volume_runtime_test.dart
```
### Ejecución conjunta con servicios locales

El 2026-10-24 se ejecutó la suite completa con VROOM y OSRM disponibles:

```bash
fvm flutter test \
  --dart-define=RUN_LOCAL_VROOM=true \
  --concurrency=1 \
  --timeout=2m
```

Resultado: 242 pruebas superadas, ninguna omitida, en aproximadamente 16 segundos. Incluye las 229 pruebas habituales y las 13 pruebas locales activadas explícitamente.

Esta ejecución confirma el resultado conjunto de la suite en el entorno local descrito; no amplía por sí sola el alcance de las validaciones de campo.
Tras las correcciones de la sección 18.10, se repitió la ejecución el 2026-10-24: 246 pruebas superadas, ninguna omitida, en aproximadamente 15 segundos.

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
| `94b52ea` | Verificación y conversión del horario sobre una única respuesta |
| `8ca1b77` | Distinción entre propuesta incompleta y respuesta inválida |
| `47c213c` | Reoptimización real de 60 tareas pendientes tras completar 20 de 80 |
| `378f4d1` | Verificación individual de ventanas horarias en tres paradas |
| `f0786ba` | Destino explícito en solicitudes VROOM |
| `bdf6046` | Conversión del tramo hasta el destino final |
| `b655f6f` | Destino final verificado contra VROOM real |
| `a391825` | Destino explícito en el adaptador HTTP |
| `6cec8a0` | División y validación de tramos entre bloqueos |
| `a18767e` | Cliente OSRM de desplazamientos directos |
| `edabc7b` | Coordinación de optimización por tramos |
| `6bc8584` | Conservación de cuatro bloqueos con motores reales |
| `c495f00` | Interrupción de la coordinación ante fallos de VROOM y OSRM |
| `af90312` | Rechazo de resultados recibidos después del presupuesto total |
| `fefe6c4` | Presupuesto restante transferido al siguiente tramo |
| `9311017` | Pantalla de rutas sintéticas comprobada en tablet física |
| `52b347e` | Esquema 4 y migraciones para almacenar rutas aceptadas |
| `aae831d` | Servicio de almacenamiento del orden y las métricas aceptadas |
| `d073b27` | Aceptación y recuperación desde la pantalla de validación |
| `6e3b1c4` | Vínculo entre paradas sintéticas y confirmación contable |
| `f3c92bd` | Confirmación y recuperación de entregas desde la pantalla |
| `b8ff810` | Cálculo de pendientes y bloqueo al completar las entregas |
| `f1613d4` | Rechazo de ventanas caducadas antes del redondeo |
| `23f5e41` | Inclusión del destino explícito en el límite de ubicaciones |
| `07e9786` | Redondeo del servicio por parada en rutas segmentadas |
| `ed02a48` | Contraste del servicio devuelto con los trabajos solicitados |
| `d82c0e1` | Base de datos separada para validar entregas parcialmente completadas |

## 22. Validaciones pendientes

- Comparación con órdenes habituales representativos de repartidores; la comparación con el orden inicial sintético ya está completada.
- Priorización bajo restricciones.
- Ampliación de bloqueos a escenarios combinados, fallos entre tramos y verificación exhaustiva del presupuesto temporal; el caso básico de 60 tareas con cuatro bloqueos ya está comprobado.
- Reoptimización con ventanas horarias, bloqueos y grupos peatonales; el caso vehicular básico con tareas completadas ya está comprobado.
- Recorridos peatonales y separación de tramos.
- Control del ajuste de coordenadas a la red.
- Escenarios geográficos y operativos más representativos.
- Fallos reales del servicio y recuperación de la ruta aceptada.
- Evaluación de GraphHopper con acceso autorizado.
- Costes proyectados por repartidor y mes.
- Medición de recursos de infraestructura.
- Persistencia y eliminación de información temporal.
- Ampliación de pruebas físicas a interrupciones durante solicitudes, fallos de guardado y uso en campo; cálculo, aceptación, recuperación tras cierre y desconexión entre solicitudes ya están comprobados en la Samsung SM-X210 mediante USB.
- Evaluación de una versión estable del motor para producción.
- Ampliación de ventanas horarias a escenarios superpuestos, varias tareas por portal y volúmenes de 60–120 tareas; los casos básicos y el escenario de tres paradas ya están comprobados.

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
- Versión 0.4 (2026-10-23): pruebas de ventanas horarias sobre una única respuesta del motor.
- Versión 0.5 (2026-10-23): resultado específico `incompleteSolution` para propuestas con tareas sin asignar.
- Versión 0.6 (2026-10-23): reoptimización vehicular de tareas pendientes y actualización a diez pruebas locales omitidas por defecto.
- Versión 0.7 (2026-10-23): ventanas sucesivas en tres paradas y actualización a once pruebas locales omitidas por defecto.
- Versión 0.8 (2026-10-23): destino explícito, coordinación por tramos y conservación de posiciones bloqueadas; 211 pruebas superadas y trece locales omitidas por defecto.
- Versión 0.9 (2026-10-23): fallos de clientes y rechazo de resultados fuera de plazo; 214 pruebas superadas y trece locales omitidas por defecto.
- Versión 0.10 (2026-10-24): cálculo sintético desde tablet física y comprobación del presupuesto restante entre tramos; 215 pruebas superadas y trece locales omitidas por defecto.
- Versión 0.11 (2026-10-24): aceptación y persistencia de rutas, migraciones al esquema 4 y conservación de la ruta ante desconexión; 223 pruebas superadas y trece locales omitidas por defecto.
- Versión 0.12 (2026-10-24): confirmación persistente de entregas sintéticas y cálculo de pendientes; 229 pruebas superadas y trece locales omitidas por defecto.
- Versión 0.13 (2026-10-24): ejecución conjunta de 242 pruebas, incluidas las trece pruebas con servicios locales, sin omisiones ni fallos.
- Versión 0.14 (2026-10-24): cuatro correcciones de revisión y ejecución completa de 246 pruebas sin omisiones; suite habitual de 233 pruebas y trece locales omitidas por defecto.
- Versión 0.15 (2026-10-24): cálculo, aceptación y recuperación de una propuesta parcial desde la Samsung SM-X210, conservando el escenario anterior en otra base de datos.

## 26. Fallo de VROOM y recuperación en tablet física

Validación realizada el 2026-10-24 en Samsung SM-X210 conectada mediante USB, con la base separada del escenario de entregas parciales.

Estado inicial: STOP-A completada, STOP-B pendiente y una ruta parcial previamente aceptada y guardada.

Procedimiento y resultados observados:

1. Se detuvo únicamente VROOM mediante Docker Compose, manteniendo OSRM activo.
2. Al calcular una propuesta, la aplicación mostró un error de conexión y terminó el estado de cálculo.
3. La ruta aceptada conservó sus datos y STOP-B continuó pendiente.
4. Se cerró la aplicación desde aplicaciones recientes y se volvió a abrir con VROOM detenido.
5. Se recuperó la ruta aceptada con sus datos anteriores y STOP-B pendiente.
6. Se arrancó VROOM y se volvió a calcular.
7. Se obtuvo una propuesta únicamente para STOP-B, con distancia y tiempos visibles y sin error.
8. La ruta aceptada mantuvo su fecha anterior. No se aceptó la nueva propuesta ni se confirmó STOP-B.

Resultado: superado para indisponibilidad del servicio antes de iniciar una solicitud y recuperación posterior.

Alcance: cierre desde aplicaciones recientes, sin borrado de datos. Esta prueba no valida interrupciones durante una solicitud, muerte forzada del proceso, fallos de guardado ni uso en campo.

La Issue #21 permanece abierta y ADR-004 continúa pendiente de validación.
