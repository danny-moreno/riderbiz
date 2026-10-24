# Persistencia y contabilidad sintética de 100–500 paquetes

## Escenarios

Siete pruebas con 100, 125, 150, 200, 250, 300 y 500 paquetes. Cada prueba utiliza una base SQLite independiente en un directorio temporal.

150 paquetes es una referencia de volumen, no un límite funcional del producto.

## Comprobaciones superadas

- Preparación de todos los paquetes con identificadores únicos.
- Confirmación de aproximadamente la mitad y recuperación tras cerrar y reabrir SQLite.
- Rechazo de confirmaciones repetidas, tanto con el identificador original de evento como con uno diferente.
- Conservación de una única entrega y evento por paquete.
- Cambio de tarifa ficticia de 120 a 150 céntimos de euro.
- Conservación de la tarifa y el importe originales de los paquetes ya entregados.
- Aplicación de la nueva tarifa a las entregas posteriores.
- Reversión de la actualización del paquete ante una colisión de identificador de evento.
- Recuperación final de todos los paquetes, eventos e importes tras una segunda reapertura.
- Comprobación de estados, instantáneas de tarifa, fechas y suma de importes.

## Validación

- Siete pruebas específicas superadas.
- Flutter analyze sin incidencias.
- Suite habitual: 261 pruebas superadas y 23 pruebas locales omitidas.
- git diff --check sin incidencias.

## Alcance y pendientes

Pruebas secuenciales con datos sintéticos, un operador, una jornada y dos tarifas EUR. Se utiliza el servicio contable existente, sin cambios de producción.

El rechazo de duplicados no equivale a devolver éxito idempotente en un reintento.

No se validan concurrencia entre conexiones, sincronización, cierre abrupto del proceso, rendimiento en tablet, interfaz de grandes volúmenes ni integración con rutas y paradas agrupadas.

Las pruebas no establecen límites de rendimiento ni demuestran una jornada completa de 500 paquetes.

La issue #21 permanece abierta y ADR-004 no cambia de estado.
