# RB-ROUTING-006 · Recursos y estimación económica preliminar

## Estado

Evaluación documental y lectura local realizadas el 2026-10-26.
Issue #21 abierta. ADR-004 permanece PROPUESTO.

No se contrataron planes, activó facturación ni ejecutaron solicitudes a GraphHopper durante esta evaluación.

## 1. Recursos locales observados

Entorno: Colima, perfil riderbiz, ARM64, Virtualization.Framework y Docker.

VROOM estaba healthy y OSRM activo. Los contenedores llevaban aproximadamente 27 minutos arrancados.

| Contenedor | CPU mostrada | Memoria mostrada |
|---|---:|---:|
| VROOM | 0,00 % | 30,55 MiB |
| OSRM | 0,00 % | 74,52 MiB |
| Suma de memoria mostrada | — | 105,07 MiB |

El límite mostrado de 5,773 GiB es compartido en la VM; no se suma por contenedor.

Es una instantánea sin carga controlada. No mide picos, actualización de mapas, memoria total de la VM, cachés completas, disco, energía ni capacidad concurrente. No permite dimensionar producción ni extrapolar directamente de Navarra a otros territorios.

## 2. Supuestos de consumo

Escenario de cálculo, no datos reales de utilización:
- Un vehículo por solicitud independiente.
- Una tarea por parada y localizaciones distintas.
- Un origen adicional distinto y sin destino adicional.
- 22 jornadas mensuales.
- Tres optimizaciones completas por jornada: una inicial y dos posteriores.
- Todos los repartidores considerados están activos en el mismo día.
- Sin geocodificación, navegación, matrices contratadas aparte, reintentos ni consultas de seguimiento de trabajos asíncronos.

Mantener todas las paradas en cada cálculo simplifica la proyección. En uso real, las pendientes pueden disminuir y los reintentos o nuevas tareas pueden aumentarla.

Se proyectan 66 ejecuciones mensuales por repartidor.

## 3. GraphHopper: límites y bloqueo

Valores publicados consultados, en EUR y facturación mensual, sin IVA ni descuentos:

| Plan | Precio mensual | Créditos diarios | Localizaciones por solicitud | Vehículos por solicitud |
|---|---:|---:|---:|---:|
| Free | 0 € | 500 | 5 | 1 |
| Basic | 69 € | 5.000 | 30 | 2 |
| Standard | 199 € | 15.000 | 80 | 10 |
| Premium | 479 € | 50.000 | 200 | 20 |
| Custom | Presupuesto | Según acuerdo | Según acuerdo | Según acuerdo |

Free no permite los escenarios actuales de 60, 80 y 120 paradas distintas. No se ha acreditado una ampliación gratuita autorizada. Se documenta el bloqueo sin contratar un plan.

La página de precios limita Free a uso no comercial; los términos contemplan uso comercial durante desarrollo. Debe aclararse la condición aplicable antes de una integración comercial.

Los términos también exigen un acuerdo Custom para redistribuir la API. La aplicabilidad a la arquitectura concreta de RiderBiz debe aclararse: las tablas siguientes evalúan únicamente capacidad publicada y reparto aritmético del precio, no autorizan ni presupuestan un contrato comercial definitivo.

## 4. Créditos proyectados

La fórmula publicada de Route Optimization depende de vehículos y localizaciones únicas, con mínimo de 10 créditos y máximo de diez veces las localizaciones.

Con un vehículo y los supuestos anteriores:

| Tareas/paradas | Localizaciones | Créditos/ejecución | Créditos/día/repartidor | Créditos/mes/repartidor |
|---|---:|---:|---:|---:|
| 60 | 61 | 61 | 183 | 4.026 |
| 80 | 81 | 81 | 243 | 5.346 |
| 120 | 121 | 121 | 363 | 7.986 |

Los créditos diarios son límites diarios: no deben interpretarse como una bolsa mensual intercambiable.

## 5. Proyección por escala

Plan mínimo de la tabla pública según localizaciones y cuota diaria, sujeto a las salvedades comerciales anteriores:

| Repartidores | Paradas por ruta | Créditos diarios totales | Plan por capacidad | Precio mensual publicado | Reparto mensual por repartidor |
|---|---:|---:|---|---:|---:|
| 1 | 60 | 183 | Standard | 199 € | 199 € |
| 1 | 80 | 243 | Premium | 479 € | 479 € |
| 1 | 120 | 363 | Premium | 479 € | 479 € |
| 100 | 60 | 18.300 | Premium | 479 € | 4,79 € |
| 100 | 80 | 24.300 | Premium | 479 € | 4,79 € |
| 100 | 120 | 36.300 | Premium | 479 € | 4,79 € |
| 1.000 | 60 | 183.000 | Custom | No publicado | Pendiente |
| 1.000 | 80 | 243.000 | Custom | No publicado | Pendiente |
| 1.000 | 120 | 363.000 | Custom | No publicado | Pendiente |

Reparto contable del abono entre ejecuciones previstas:
- Un repartidor con 60 paradas: 199 / 66 = aproximadamente 3,0152 €/ejecución.
- Un repartidor con 80 o 120 paradas: 479 / 66 = aproximadamente 7,2576 €/ejecución.
- Cien repartidores: 479 / 6.600 = aproximadamente 0,0726 €/ejecución.
- Mil repartidores: no calculable sin presupuesto Custom.

Estos importes no son tarifas marginales por llamada ni incluyen el resto de RiderBiz.

La cuota diaria no garantiza servicio simultáneo. Los límites publicados incluyen 400 créditos/minuto para Standard y 1.000 para Premium, además de límites de solicitudes por segundo. Se requiere regular las solicitudes; no se ha probado esta integración.

Sensibilidad: con 100 repartidores, 121 localizaciones y cinco cálculos diarios se consumirían 60.500 créditos/día, superando la cuota Premium publicada.

## 6. Alternativa abierta: modelo de coste

El entorno local no generó cargos de un servicio administrado. Esto no significa coste económico cero.

Modelo mensual:
C = alojamiento + almacenamiento + transferencia + copias + observabilidad + actualización de mapas + horas de operación por coste/hora.

Coste asignado por repartidor = C / N.
Coste asignado por ejecución = C / (66 × N), bajo los supuestos anteriores.

Sensibilidad puramente presupuestaria usando C = 150 €/mes:

| Repartidores | Coste mensual asignado por repartidor | Coste asignado por ejecución |
|---|---:|---:|
| 1 | 150 € | 2,2727 € |
| 100 | 1,50 € | 0,0227 € |
| 1.000 | 0,15 € | 0,0023 € |

Los 150 € son una hipótesis de presupuesto total, no una oferta de alojamiento ni un coste medido. No se ha demostrado que ese presupuesto soporte ninguna de las escalas. Mantener C constante muestra únicamente la sensibilidad aritmética al reparto de costes.

Quedan pendientes medición bajo carga y dimensionamiento, presupuesto de infraestructura y esfuerzo operativo. No se concluye que la alternativa abierta sea más barata en producción.

## 7. Conclusión provisional

- La cuota gratuita publicada bloquea la comparación GraphHopper a los volúmenes solicitados, salvo autorización especial no acreditada.
- Existen proyecciones reproducibles de consumo; no hay resultados de rendimiento ni calidad de GraphHopper.
- El coste monetario para 1.000 repartidores depende de presupuesto comercial.
- La alternativa abierta funciona en el entorno sintético local, pero su coste y capacidad productivos siguen sin acreditarse.
- No se acepta ADR-004 ni se selecciona proveedor definitivo con esta evidencia.

## Fuentes oficiales

Consultadas el 2026-10-26:
- https://www.graphhopper.com/pricing/
- https://www.graphhopper.com/faq/what-is-one-credit/
- https://www.graphhopper.com/terms/
- https://support.graphhopper.com/support/solutions/articles/44001038156-what-happens-if-i-exceed-the-location-or-the-vehicle-limit-
