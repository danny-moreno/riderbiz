# ADR-004 · Optimización adaptativa de rutas de RiderBiz V1

## Estado

Propuesto

## Fecha

2026-10-15

## Issue relacionada

#19

## 1. Decisión que debe tomarse

Definir el modelo operativo y arquitectónico mediante el cual RiderBiz ayudará a ordenar entregas y recogidas durante una jornada sin imponer una ruta rígida ni sustituir el criterio del repartidor.

Este ADR decide el comportamiento del gestor adaptativo de rutas. No selecciona todavía un proveedor definitivo de mapas, geocodificación, tráfico, navegación o resolución del problema de rutas de vehículos.

## 2. Contexto

RiderBiz se dirige inicialmente a repartidores autónomos y colaboradores de última milla, incluidos repartidores multioperador.

La evidencia aportada por repartidores muestra que:

- Un repartidor experimentado puede tener una secuencia habitual muy eficiente.
- El orden óptimo puede cambiar por tráfico, horarios, incidencias, recogidas o nuevas prioridades.
- En calles cortas se estaciona una vez y se realizan varias entregas próximas a pie.
- La parada del vehículo no equivale necesariamente a una única dirección.
- La ruta de vehículo y la microrruta peatonal son problemas relacionados, pero diferentes.
- El repartidor puede necesitar combinar entregas de varios operadores.
- Las aplicaciones oficiales de los operadores continuarán siendo necesarias.
- La conectividad puede ser irregular durante la jornada.
- Una recomendación que exige demasiadas confirmaciones pierde valor operativo.

## 3. Principios de producto

La decisión se regirá por estos principios:

- Optimización, simplificación y eficiencia para el repartidor.
- Control final del usuario.
- Recomendaciones explicables y reversibles.
- Interacción mínima durante la conducción.
- Funcionamiento local-first.
- Privacidad y minimización desde el diseño.
- Separación entre dominio y proveedor cartográfico.
- Degradación segura cuando no exista conexión.
- No presentar una estimación como garantía exacta.

## 4. Alcance

Este ADR decide:

- Los modos de planificación disponibles.
- El comportamiento predeterminado.
- La optimización inicial y la reoptimización bajo demanda.
- La relación entre ruta vehicular y microrruta peatonal.
- La incorporación de entregas y recogidas.
- El control final del repartidor.
- Los datos mínimos del problema de optimización.
- Las reglas de privacidad y seguridad.
- La frontera entre RiderBiz y los proveedores de rutas.
- Las condiciones de una prueba técnica posterior.

Este ADR no decide:

- Proveedor definitivo de mapas.
- Geocodificador definitivo.
- Navegación giro a giro.
- Interfaz de voz definitiva.
- Ejecución permanente en segundo plano.
- Integraciones API con operadores logísticos.
- Seguimiento empresarial de trabajadores.
- Almacenamiento de históricos de ubicación.

## 5. Evidencias e hipótesis

### 5.1 Evidencias operativas

- Algunos repartidores conocen suficientemente bien su zona para preferir su orden habitual.
- Una calle puede contener varios portales y varias entregas por portal.
- En determinados grupos de portales, el vehículo se estaciona una vez y el resto se completa a pie.
- Las recogidas pueden estar programadas antes de la ruta o aparecer durante la jornada.
- El conductor no siempre puede detenerse para interactuar con la pantalla.
- La organización por zonas dentro del vehículo reduce el tiempo de búsqueda del paquete.

### 5.2 Hipótesis que deberán medirse

- La optimización adaptativa reduce tiempo o kilómetros frente a la ruta habitual.
- Mostrar el ahorro estimado aumenta la aceptación de una recomendación útil.
- El orden por proximidad mejora la microrruta peatonal sin limitar la autonomía.
- Un modo habitual asistido aporta valor incluso sin cambiar el orden de ruta.
- La combinación de matriz de tiempos y preferencias históricas supera a una optimización puramente cartográfica.

## 6. Modos de ruta

### 6.1 Usar mi ruta habitual

Será el modo predeterminado para usuarios que indiquen que conocen y prefieren su secuencia de reparto.

RiderBiz:

- Conservará el orden introducido o utilizado por el repartidor.
- Agrupará paquetes por parada y portal.
- Mostrará entregas y recogidas pendientes.
- Indicará la próxima parada según ese orden.
- Permitirá alterar cualquier parada.
- Podrá advertir de restricciones o ahorros relevantes.
- No modificará automáticamente la secuencia.

El gestor no queda desactivado. Funciona como asistente operativo y mantiene estados, paradas, recogidas, paquetes y recomendaciones opcionales.

### 6.2 Ruta recomendada

RiderBiz propondrá un orden inicial utilizando los datos disponibles.

La propuesta podrá considerar:

- Ubicación inicial.
- Direcciones geocodificadas.
- Código postal y sector del vehículo.
- Ventanas horarias.
- Prioridades.
- Entregas y recogidas.
- Duración de servicio estimada.
- Restricciones declaradas.
- Preferencias del repartidor.

El usuario podrá aceptar, modificar o ignorar el orden.

### 6.3 Optimizar esta ruta

Durante una jornada activa existirá una acción directa:

```text
OPTIMIZAR ESTA RUTA
```

La acción recalculará únicamente las tareas pendientes. Las operaciones completadas quedarán fuera del nuevo problema.

Antes de aplicar la recomendación, RiderBiz mostrará cuando sea técnicamente posible:

- Tiempo estimado del orden actual.
- Tiempo estimado del orden recomendado.
- Ahorro aproximado.
- Distancia estimada evitada.
- Principales cambios.
- Restricciones no satisfechas o datos incompletos.

La recomendación requerirá aceptación. El repartidor podrá cancelarla o seleccionar manualmente otra parada.

### 6.4 Optimización automática continua

No se adopta para RiderBiz V1.

Podría aumentar consumo, dependencia de red, coste, distracción y cambios inesperados. Solo podrá estudiarse después de medir valor real y seguridad.

## 7. Ruta vehicular y microrruta peatonal

### 7.1 Ruta vehicular

Ordena los desplazamientos y puntos de estacionamiento entre grupos operativos.

Una parada vehicular podrá contener:

- Un portal.
- Varios portales próximos.
- Entregas y recogidas.
- Paquetes de uno o varios operadores.

### 7.2 Microrruta peatonal

Ordena portales próximos después de estacionar.

La primera pantalla mostrará:

```text
ENTREGAS ACTIVAS
3 PORTALES
7 PAQUETES
ZONA A
```

Al abrirla se mostrarán las tarjetas de portales, destinatarios y cantidades. RiderBiz podrá ordenarlas por proximidad estimada, pero el repartidor podrá comenzar por cualquiera.

Al resolver un portal, la aplicación regresará automáticamente a los portales pendientes.

## 8. Entregas y recogidas

Antes de comenzar la jornada, RiderBiz preguntará si existen recogidas programadas.

Datos mínimos de una recogida:

- Identificador técnico.
- Dirección.
- Código postal.
- Operador logístico.
- Franja horaria, si existe.
- Cantidad estimada.
- Prioridad.
- Observación estrictamente necesaria.

Las recogidas puntuales podrán añadirse durante la jornada y activar una recomendación de reoptimización, nunca un cambio automático.

## 9. Modelo mínimo del problema

La capa de dominio deberá representar, sin depender de un proveedor:

- `route_plan`.
- `operational_stop`.
- `delivery_task`.
- `pickup_task`.
- `vehicle_leg`.
- `walking_cluster`.
- `time_window`.
- `service_duration`.
- `priority`.
- `constraint`.
- `route_candidate`.
- `optimization_explanation`.

Cada propuesta deberá poder compararse con el orden actual mediante métricas normalizadas.

## 10. Arquitectura

Se adoptará una arquitectura independiente del proveedor:

```text
Dominio RiderBiz
      ↓
RouteOptimizationPort
      ↓
Adaptador de proveedor o motor
      ↓
Matriz de tiempos + optimizador
```

El contrato interno deberá admitir:

- Planificar una ruta inicial.
- Reoptimizar únicamente tareas pendientes.
- Mantener paradas bloqueadas por el usuario.
- Aplicar ventanas horarias y prioridades.
- Integrar entregas y recogidas.
- Separar tramos vehiculares y grupos peatonales.
- Devolver métricas, advertencias y motivo de la propuesta.
- Cancelar o agotar el tiempo de cálculo.

La interfaz, el dominio y la persistencia no conocerán tipos específicos de Google, HERE, Mapbox, GraphHopper, VROOM, OSRM u OR-Tools.

## 11. Conectividad y degradación

La optimización completa podrá requerir red, pero la jornada no deberá quedar bloqueada.

Sin conexión, RiderBiz deberá:

- Conservar el último plan aceptado.
- Permitir seleccionar manualmente la siguiente parada.
- Mantener estados de entrega y recogida.
- Conservar datos pendientes de sincronización.
- Evitar afirmar que una ruta está actualizada.
- Reintentar una solicitud solo cuando sea seguro.

La navegación y la disponibilidad offline de mapas se decidirán por separado.

## 12. Privacidad

El cálculo utilizará únicamente los datos necesarios para ordenar las tareas.

Reglas:

- El nombre del destinatario no se enviará al motor de optimización.
- Se preferirán identificadores técnicos efímeros.
- Las direcciones y coordenadas tendrán conservación limitada.
- No se crearán históricos continuos de ubicación por defecto.
- La ubicación en tiempo real se utilizará para la operación activa y con información transparente.
- La telemetría de producto deberá estar agregada o seudonimizada.
- Todo proveedor externo requerirá revisión contractual, DPA, región, subencargados y transferencias.
- Se aplicarán las reglas de eliminación de ADR-003.

## 13. Seguridad durante la conducción

RiderBiz no exigirá interacción táctil compleja con el vehículo en movimiento.

Las recomendaciones podrán anunciarse mediante voz en una decisión posterior. La aceptación por voz deberá admitir expresiones equivalentes, confirmar la acción interpretada y permitir cancelación.

ADR-008 decidirá activación por voz, segundo plano, pantalla apagada y límites específicos de Android e iOS.

## 14. Alternativas funcionales evaluadas

Escala: 1 insuficiente, 3 aceptable, 5 excelente.

| Criterio | Peso | Manual | Habitual asistida | Inicial completa | Adaptativa bajo demanda | Continua automática |
|---|---:|---:|---:|---:|---:|---:|
| Ahorro operativo | 20 | 2 | 4 | 4 | 5 | 4 |
| Simplicidad | 15 | 5 | 5 | 3 | 4 | 2 |
| Control y flexibilidad | 15 | 5 | 5 | 3 | 5 | 2 |
| Calidad de ruta | 15 | 2 | 3 | 4 | 5 | 5 |
| Entregas y recogidas | 10 | 2 | 4 | 4 | 5 | 5 |
| Conectividad irregular | 5 | 5 | 4 | 2 | 3 | 1 |
| Privacidad | 5 | 5 | 5 | 3 | 4 | 2 |
| Seguridad vial | 5 | 5 | 5 | 4 | 5 | 2 |
| Coste | 5 | 5 | 4 | 3 | 3 | 2 |
| Mantenibilidad | 5 | 5 | 4 | 3 | 4 | 2 |
| **Resultado ponderado** | **100** | **73** | **85** | **69** | **91** | **62** |

La optimización adaptativa bajo demanda obtiene el resultado más favorable. El modo habitual asistido se mantiene como alternativa predeterminada y complementaria.

## 15. Alternativas tecnológicas

### 15.1 Google Route Optimization API

Fortalezas:

- Servicio administrado.
- Capacidades industriales de optimización.
- Integración con el ecosistema Google Maps.

Riesgos:

- Facturación por uso y combinación de varios productos.
- Restricciones de uso y almacenamiento del contenido de mapas.
- Dependencia alta del ecosistema Google.
- La documentación contractual vigente excluye Route Optimization API del SLA de Google Maps Platform.

### 15.2 HERE Tour Planning

Fortalezas:

- Orientación logística.
- Ventanas horarias, capacidades y recogidas/entregas.
- Cobertura internacional.

Riesgos:

- Evaluación comercial y contractual necesaria.
- Coste final dependiente del consumo y acuerdo.
- Dependencia del proveedor.

### 15.3 GraphHopper Directions API

Fortalezas:

- Route Optimization API, matrices, rutas y geocodificación.
- Condiciones comerciales relativamente claras.
- Uso con mapas de distintos proveedores.
- Adecuado para una prueba técnica rápida.

Riesgos:

- Límites de localizaciones y vehículos según plan.
- Coste mensual relevante al crecer el número de paradas.
- Dependencia de servicio externo.

### 15.4 Mapbox Optimization API

Fortalezas:

- Ecosistema móvil y cartográfico maduro.
- Matrices y perfiles de movilidad.

Riesgos:

- Las capacidades avanzadas de Optimization v2 continúan documentadas como beta.
- Restricciones y límites diferentes entre versiones.
- Riesgo de diseñar RiderBiz alrededor de una API aún evolutiva.

### 15.5 VROOM + OSRM

Fortalezas:

- Código abierto.
- VROOM resuelve problemas de rutas y OSRM genera matrices sobre OpenStreetMap.
- Control de infraestructura y menor dependencia contractual.
- Posibilidad de sustituir la matriz por otro proveedor.

Riesgos:

- Operación, actualizaciones, mapas, capacidad y observabilidad a cargo de RiderBiz.
- Sin tráfico en tiempo real por defecto.
- Requiere backend o infraestructura propia.

### 15.6 OR-Tools + proveedor de matriz

Fortalezas:

- Código abierto y modelado flexible.
- Admite capacidades, ventanas horarias, recursos y visitas descartables.
- Independencia entre optimizador y fuente de tiempos.

Riesgos:

- Mayor complejidad de modelado y pruebas.
- RiderBiz asumiría la calidad del solver y su operación.
- No proporciona por sí mismo mapas, geocodificación, tráfico ni matriz vial.

## 16. Decisión provisional

RiderBiz adoptará un modelo híbrido de producto:

1. `Usar mi ruta habitual` como modo inicial para quien lo seleccione.
2. `Ruta recomendada` como propuesta editable antes de comenzar.
3. `OPTIMIZAR ESTA RUTA` para recalcular voluntariamente las tareas pendientes.
4. Selección manual siempre disponible.
5. Sin optimización automática continua en V1.

La arquitectura utilizará `RouteOptimizationPort` y adaptadores reemplazables.

No se selecciona todavía un proveedor definitivo. Se realizará una prueba técnica comparando al menos:

- Un servicio administrado adecuado para validar rápidamente el caso, con GraphHopper como candidato inicial.
- Una alternativa abierta controlable, formada por VROOM y OSRM.

Google Route Optimization y HERE Tour Planning se mantendrán como referencias empresariales. Mapbox Optimization v2 no será candidato principal mientras sus capacidades necesarias permanezcan en beta.

## 17. Prueba técnica requerida

La prueba utilizará datos sintéticos y deberá incluir:

- 60, 80 y 120 tareas.
- Entregas y recogidas.
- Ventanas horarias.
- Prioridades.
- Paradas bloqueadas manualmente.
- Reoptimización después de completar parte de la ruta.
- Grupos peatonales.
- Fallo de red y timeout.
- Comparación con el orden habitual.
- Tiempo de cálculo.
- Distancia y duración estimadas.
- Coste proyectado por repartidor y mes.
- Repetibilidad y explicación del resultado.
- Eliminación de datos temporales.

No se usarán nombres, teléfonos, etiquetas ni direcciones reales.

## 18. Criterios de aceptación

ADR-004 podrá pasar a `ACEPTADO` cuando una prueba demuestre que:

- El dominio funciona sin depender del proveedor.
- Se pueden bloquear decisiones manuales.
- La reoptimización afecta solo a tareas pendientes.
- Entregas y recogidas se representan correctamente.
- La ruta habitual continúa operativa sin red.
- Los resultados son comprensibles para el usuario.
- El coste es compatible con el modelo económico de RiderBiz.
- No aparece un riesgo bloqueante de privacidad o seguridad.

## 19. Consecuencias positivas

- Respeta la experiencia del repartidor.
- Reduce el riesgo de una automatización intrusiva.
- Permite validar valor antes de contratar infraestructura costosa.
- Facilita sustituir proveedores.
- Integra recogidas sin rediseñar toda la jornada.
- Separa claramente vehículo y recorrido peatonal.

## 20. Consecuencias negativas

- Se necesitarán adaptadores y modelos normalizados.
- Las estimaciones pueden diferir de la operación real.
- El modo híbrido exige una interfaz muy clara.
- La ausencia de un proveedor definitivo aplaza algunas decisiones técnicas.
- Una solución abierta requerirá operación de infraestructura.

## 21. Disparadores de revisión

Este ADR deberá revisarse si:

- La prueba no mejora rutas habituales representativas.
- El coste por usuario compromete el precio de suscripción.
- Un proveedor cambia materialmente precios, licencias o límites.
- La regulación o seguridad vial limita las interacciones previstas.
- Se incorpora gestión empresarial de flotas.
- Una integración con operadores aporta datos o restricciones nuevas.
- Se requiere navegación offline completa.

## 22. Decisiones relacionadas

- ADR-001: stack tecnológico móvil.
- ADR-002: persistencia local estructurada.
- ADR-003: conservación de datos personales y flujo de entregas.
- ADR-005: sistema visual y accesibilidad.
- ADR-007: paradas operativas, entregas y recogidas.
- ADR-008: voz, manos libres y segundo plano.
- ADR-009: convivencia con aplicaciones de operadores.
- ADR-010: sectorización del vehículo.
- Futuro ADR-011: integración con operadores logísticos y gobierno de APIs.

## 23. Fuentes oficiales

- Google Route Optimization API: https://developers.google.com/maps/documentation/route-optimization
- Facturación de Google Route Optimization: https://developers.google.com/maps/documentation/route-optimization/usage-and-billing
- Condiciones específicas de Google Maps Platform: https://cloud.google.com/maps-platform/terms/maps-service-terms
- HERE Tour Planning: https://docs.here.com/tour-planning/docs/quick-start
- GraphHopper Directions API: https://docs.graphhopper.com/
- Precios de GraphHopper: https://www.graphhopper.com/pricing/
- Mapbox Optimization API: https://docs.mapbox.com/api/navigation/optimization/
- Google OR-Tools, Vehicle Routing: https://developers.google.com/optimization/routing
- VROOM: https://github.com/VROOM-Project/vroom
- OSRM: https://project-osrm.org/docs/

## 24. Historial

- Versión 0.1: evidencia, alternativas, matriz funcional, arquitectura independiente del proveedor y decisión provisional.

- Revisión del 2026-10-26: evidencia de la prueba técnica #21;
  se mantiene el estado PROPUESTO.

## 25. Revisión tras la prueba técnica de la Issue #21

La evidencia se consolida en
[RB-SPIKE-021](../engineering/validation/RB-SPIKE-021-route-optimization-validation.md).

Se comprobó viabilidad técnica local y acotada de la arquitectura
independiente del proveedor, operación con VROOM/OSRM, reoptimización
de pendientes, persistencia y degradación ante fallos concretos.

GraphHopper no se ejecutó; se documentaron el bloqueo y las proyecciones.
Las mejoras medidas corresponden a órdenes sintéticos generados,
no a rutas habituales representativas de repartidores.

ADR-004 permanece PROPUESTO. No se ha demostrado suficientemente
compatibilidad económica productiva, comprensión y valor operativo
para usuarios ni ausencia de riesgos bloqueantes en producción.

El cierre de la prueba #21 no selecciona proveedor definitivo,
no aprueba despliegue productivo y no amplía sus autorizaciones.
