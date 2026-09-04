# RB-SPIKE-015 · Identificación de operadores y tarifas

## Estado

APROBADO — con condiciones no bloqueantes

## Fecha

2026-09-04

## Issue relacionada

#15

## Decisión relacionada

`ADR-003-personal-data-retention.md`

## 1. Objetivo

Validar que RiderBiz puede identificar el operador logístico de una etiqueta sintética, asociar una tarifa vigente a una entrega y generar informes agregados por operador sin conservar datos personales del destinatario.

La prueba también verifica que una modificación posterior de la tarifa no cambia los importes históricos de entregas ya confirmadas.

## 2. Alcance validado

La prueba técnica cubrió:

- Catálogo local de operadores logísticos.
- Estado activo o inactivo de operadores.
- Perfiles sintéticos de etiquetas.
- Identificación determinista del operador.
- Nivel de confianza.
- Detección de etiquetas desconocidas.
- Detección de resultados ambiguos.
- Selección manual del operador.
- Configuración inicial obligatoria de operador y tarifa.
- Tarifas versionadas por fecha de vigencia.
- Copia contable de la tarifa al confirmar una entrega.
- Informes diarios, semanales y mensuales.
- Persistencia local con Drift sobre SQLite.
- Migración del esquema.
- Ejecución nativa en Android e iOS.
- Funcionamiento sin servicios externos.
- Separación entre información operativa temporal y contabilidad.

## 3. Elementos fuera de alcance

No se validaron:

- OCR de producción.
- Etiquetas reales.
- Datos personales reales.
- Entrenamiento de modelos de inteligencia artificial.
- Servicios cloud de inteligencia artificial.
- Reconocimiento de todos los operadores europeos.
- Interfaz definitiva de primera configuración.
- Interfaz definitiva de administración de tarifas.
- Facturación o fiscalidad.
- Tarifas por peso, volumen, servicio o zona.
- Sincronización remota.
- Ejecución en dispositivos físicos durante esta prueba.
- Rendimiento con grandes volúmenes de etiquetas.

## 4. Entorno validado

- Flutter: `3.47.2`.
- Dart: `3.13.2`.
- Persistencia: Drift sobre SQLite.
- Drift: `2.34.3`.
- Android: Android 16, API 36, emulador ARM64.
- iOS: iOS 26.5, simulador iPhone 17.
- macOS: 26.6.2.
- Arquitectura de desarrollo: Apple Silicon ARM64.
- Ejecución local y sin backend.
- Datos exclusivamente sintéticos.

## 5. Evolución del esquema

El esquema Drift evolucionó de la versión `2` a la versión `3`.

Se conservaron snapshots de:

- `drift_schema_v1.json`.
- `drift_schema_v2.json`.
- `drift_schema_v3.json`.

Se validaron las rutas:

- `v1 → v2 → v3`.
- `v2 → v3`.

Los registros creados con versiones anteriores permanecieron disponibles después de la migración.

Los campos nuevos recibieron valores nulos o valores predeterminados seguros cuando no existía información histórica que permitiera completarlos.

## 6. Modelo de operadores

La tabla `logistics_operators` contiene:

- `id`.
- `name`.
- `created_at`.
- `is_active`.

El identificador interno `operator_id` permite separar el operador normalizado del texto capturado en una etiqueta.

Un operador inactivo:

- No se utiliza para identificación automática.
- No permite completar la configuración operativa.
- Conserva sus relaciones históricas.
- No se elimina si existen entregas o tarifas asociadas.

## 7. Perfiles de etiquetas

La tabla `operator_label_profiles` contiene:

- `id`.
- `operator_id`.
- `marker`.
- `priority`.
- `is_active`.
- `created_at`.

Los perfiles probados utilizaron marcadores inventados para:

- Operador Alfa.
- Operador Beta.
- Operador Gamma.

Ejemplos sintéticos:

- `LOGISTICA ALFA`.
- `ALF-EXP`.
- `TRANSPORTES BETA`.
- `BET-PACK`.
- `DISTRIBUCION GAMMA`.
- `GAM-DEL`.

No se almacenaron imágenes ni textos OCR reales.

## 8. Identificación determinista

El identificador:

1. Normaliza mayúsculas y minúsculas.
2. Normaliza determinados caracteres acentuados.
3. Elimina separadores irrelevantes.
4. Compara el texto con los marcadores activos.
5. Calcula la proporción de marcadores coincidentes.
6. Selecciona un operador únicamente si supera el umbral.
7. Evita la asignación automática si existe un empate.
8. Devuelve un resultado desconocido si no hay coincidencias.

Estados utilizados:

- `identified`.
- `low_confidence`.
- `unknown`.
- `manual`.

Una etiqueta desconocida no genera una asignación falsa.

Un resultado de confianza insuficiente puede sugerir un operador, pero no lo asigna automáticamente.

## 9. Selección manual

Cuando la identificación automática no es concluyente, el usuario puede seleccionar manualmente un operador activo.

La selección guarda:

- `identified_operator_id`.
- Estado `manual`.
- Fecha de actualización.
- Marca de cambio pendiente de sincronización futura.

La selección manual no conserva:

- Imagen de la etiqueta.
- Texto OCR completo.
- Nombre del destinatario.
- Dirección.
- Código postal.
- Coordenadas.

No se permite cambiar el operador de un paquete después de confirmar su entrega, porque alteraría el resultado contable histórico.

## 10. Configuración inicial

Se validó la regla de que RiderBiz necesita al menos:

- Un operador activo.
- Una tarifa activa.
- Un precio mayor que cero.
- Una moneda con código de tres letras.
- Una fecha de inicio de vigencia.

La moneda se normaliza a mayúsculas.

Ejemplo:

- Entrada: `eur`.
- Valor almacenado: `EUR`.

La validación se implementó en la capa de servicio.

La interfaz definitiva de onboarding queda pendiente de una fase posterior.

## 11. Modelo de tarifas

La tabla `operator_tariffs` contiene:

- `id`.
- `operator_id`.
- `version`.
- `unit_price_minor`.
- `currency`.
- `valid_from`.
- `valid_until`.
- `is_active`.
- `created_at`.

Los importes se almacenan en unidades monetarias menores.

Ejemplo:

- `120` representa `1,20 EUR`.
- `150` representa `1,50 EUR`.

Esta decisión evita errores de precisión producidos por números decimales binarios.

## 12. Versionado de tarifas

Una actualización de precio:

1. Conserva la tarifa anterior.
2. Cierra su periodo mediante `valid_until`.
3. Crea una nueva tarifa.
4. Incrementa la versión.
5. Establece una nueva fecha de vigencia.
6. Rechaza fechas anteriores o iguales a la tarifa precedente.

Ejemplo validado:

| Versión | Precio | Vigencia |
|---|---:|---|
| 1 | 1,20 EUR | Hasta el inicio de la versión 2 |
| 2 | 1,35 EUR | Desde su nueva fecha de vigencia |

Las dos versiones permanecen almacenadas.

## 13. Confirmación de entrega

La confirmación de una entrega se ejecuta dentro de una transacción.

La operación:

1. Localiza el paquete.
2. Comprueba que todavía no esté entregado.
3. Comprueba que tenga un operador identificado.
4. Localiza la tarifa vigente en el momento de entrega.
5. Marca el paquete como entregado.
6. Copia la tarifa aplicada.
7. Registra la fecha de entrega.
8. Crea el evento de entrega.

Si falla una parte, la transacción no deja un resultado contable parcial.

## 14. Copia contable invariable

Al confirmar la entrega se conservan:

- `identified_operator_id`.
- `tariff_id`.
- `tariff_version_snapshot`.
- `unit_price_minor_snapshot`.
- `currency_snapshot`.
- `delivered_at`.

Se comprobó que una actualización posterior de la tarifa no modifica:

- La tarifa aplicada.
- La versión aplicada.
- El precio histórico.
- La moneda.
- El importe del informe ya generado.

Esta copia representa el hecho económico de la entrega en el momento en que se produjo.

## 15. Informes agregados

Se validaron informes:

- Diarios.
- Semanales.
- Mensuales.
- Agrupados por operador.
- Separados por versión de tarifa.
- Con cantidad de paquetes entregados.
- Con precio unitario.
- Con importe total.
- Con separación por moneda.

Cuando una tarifa cambia dentro del mismo periodo, el informe conserva líneas separadas para cada versión.

Ejemplo sintético:

| Operador | Versión | Entregados | Precio | Total |
|---|---:|---:|---:|---:|
| Operador Alfa | 1 | 2 | 1,20 EUR | 2,40 EUR |
| Operador Beta | 1 | 1 | 1,50 EUR | 1,50 EUR |

## 16. Privacidad y minimización

Los informes generados contienen exclusivamente información operativa y contable.

No contienen:

- Nombre del destinatario.
- Dirección.
- Código postal.
- Imagen de etiqueta.
- Texto OCR completo.
- Coordenadas.
- Fotografías.
- Firmas.
- Información del interior del domicilio.

El texto sintético utilizado para identificar el operador se procesa en memoria y no se guarda en la base de datos.

La contabilidad depende del identificador normalizado del operador y de la copia de la tarifa, no de los datos personales del destinatario.

## 17. Inteligencia artificial

La prueba no utilizó inteligencia artificial generativa.

La identificación determinista proporciona una línea base:

- Auditable.
- Reproducible.
- Ejecutable sin conexión.
- Fácil de probar.
- Compatible con selección manual.
- Sin transferencia de datos a terceros.

Una futura capacidad de aprendizaje de modelos de etiquetas deberá tratarse mediante una prueba y una decisión independientes.

Esa decisión deberá evaluar:

- Base jurídica.
- Procedencia de los datos.
- Anonimización.
- Entrenamiento local o remoto.
- Proveedores.
- Seguridad.
- Precisión.
- Sesgos.
- Trazabilidad.
- Posibilidad de reversión.
- Costes operativos.

## 18. Pruebas automatizadas

La suite completa alcanzó:

```text
41 pruebas aprobadas

Se añadieron pruebas para:

Migraciones hacia v3.
Tres operadores sintéticos.
Etiquetas conocidas.
Etiquetas desconocidas.
Confianza insuficiente.
Empates entre operadores.
Normalización de texto.
Operadores inactivos.
Configuración obligatoria.
Validación de precios y monedas.
Versionado de tarifas.
Fechas de vigencia.
Confirmación transaccional.
Bloqueo de doble entrega.
Copia histórica de tarifa.
Informes diarios.
Informes semanales.
Informes mensuales.
Separación de versiones.
Persistencia después de reiniciar la base nativa.
Resultado:
00:02 +41: All tests passed!
Análisis estático:
No issues found!

## 19. Validación Android

Dispositivo virtual:

- Android 16.
- API 36.
- Arquitectura ARM64.
- Identificador de ejecución: `emulator-5554`.

Resultado:

```text
+1: All tests passed!
```

La prueba ejecutó sobre SQLite nativo:

- Configuración de operadores y tarifas.
- Perfiles sintéticos.
- Identificación del Operador Beta.
- Confirmación de entrega.
- Actualización posterior de tarifa.
- Informe histórico.
- Cierre y reapertura de la base de datos.

Se observaron advertencias no bloqueantes relacionadas con:

- Acceso nativo de Java.
- Migración futura de plugins a Built-in Kotlin.
- Diferencias de versión en XML del Android SDK.

## 20. Validación iOS

Dispositivo virtual:

- Simulador iPhone 17.
- iOS 26.5.
- Identificador: `3B904EB8-E3C6-4260-9A55-05E6360C616A`.

Resultado:

```text
+1: All tests passed!
```

La misma prueba de integración se ejecutó sin modificar la lógica de negocio.

Esto confirma que la solución comparte:

- Modelo.
- Persistencia.
- Identificación.
- Tarifas.
- Confirmación.
- Informes.

## 21. Riesgos y limitaciones

### Reconocimiento limitado

Los perfiles sintéticos no representan todavía la variedad completa de etiquetas reales.

Mitigación:

- Mantener selección manual.
- No asignar con confianza insuficiente.
- Ampliar perfiles únicamente con evidencia autorizada.
- Medir falsos positivos y falsos negativos.

### OCR no validado

Esta prueba recibió texto sintético previamente disponible.

Mitigación:

- Crear una prueba independiente de OCR.
- Evaluar etiquetas representativas autorizadas.
- Separar extracción de texto e identificación del operador.

### Inteligencia artificial no validada

No se entrenó ni integró ningún modelo.

Mitigación:

- Mantener la línea base determinista.
- Crear una decisión específica antes de incorporar IA.
- No enviar etiquetas a terceros sin evaluación jurídica y técnica.

### Interfaz pendiente

Las reglas de configuración se validaron en servicios y pruebas, pero no mediante una interfaz final.

Mitigación:

- Diseñar onboarding y configuración en una vertical slice posterior.
- Mantener el dominio separado de la interfaz.

### Dispositivos físicos

La prueba se ejecutó en emulador Android y simulador iOS.

Mitigación:

- Repetir la validación en dispositivos físicos.
- Medir tiempos, memoria, batería y comportamiento offline.

### Advertencias de herramientas

Android mostró advertencias de compatibilidad futura.

Mitigación:

- Revisar Flutter, Gradle, Java, Android SDK y plugins antes de cada actualización.
- Mantener versiones fijadas mediante FVM.
- No actualizar dependencias sin pruebas de regresión.

## 22. Resultado por criterio

| Criterio | Resultado |
|---|---|
| Tres operadores ficticios | APROBADO |
| Tarifas vigentes | APROBADO |
| Configuración mínima obligatoria | APROBADO |
| Identificación de etiquetas conocidas | APROBADO |
| Rechazo de etiquetas desconocidas | APROBADO |
| Confianza insuficiente | APROBADO |
| Selección manual | APROBADO |
| Persistencia mediante Drift | APROBADO |
| Migración de esquema | APROBADO |
| Versionado de tarifas | APROBADO |
| Copia histórica del precio | APROBADO |
| Informes diarios | APROBADO |
| Informes semanales | APROBADO |
| Informes mensuales | APROBADO |
| Separación de datos personales | APROBADO |
| Funcionamiento local | APROBADO |
| Pruebas automatizadas | APROBADO |
| Análisis estático | APROBADO |
| Ejecución Android | APROBADO |
| Ejecución iOS | APROBADO |

## 23. Evidencia Git

Commits principales:

- `f3969cc` — esquema de operadores, perfiles y tarifas.
- `8d76b26` — identificador determinista.
- `ded7c91` — configuración obligatoria.
- `244ba70` — versionado temporal de tarifas.
- `29e5979` — copia de versión y fecha de entrega.
- `509f54d` — confirmación y copia contable.
- `857cd1a` — informes agregados.
- `47ef11f` — persistencia de la identificación.
- `41457d5` — ejecución nativa en Android e iOS.

## 24. Conclusión

RiderBiz puede identificar operadores logísticos mediante perfiles sintéticos, gestionar tarifas versionadas y producir informes históricos por operador utilizando una arquitectura local-first.

La solución:

- Funciona sin backend.
- Es compatible con Android e iOS.
- Evita asignaciones automáticas inseguras.
- Permite corrección manual.
- Conserva los precios históricos.
- Separa contabilidad y datos personales.
- No almacena el texto utilizado para identificar el operador.
- Mantiene abierta la incorporación futura de OCR e inteligencia artificial.

No se identificó ningún riesgo bloqueante para continuar con esta arquitectura.

Las condiciones pendientes son no bloqueantes:

- Diseñar la interfaz definitiva.
- Validar OCR mediante una prueba independiente.
- Evaluar jurídicamente cualquier aprendizaje automático.
- Probar etiquetas autorizadas y representativas.
- Ejecutar pruebas en dispositivos físicos.
- Medir rendimiento con volúmenes reales sintéticos.
- Resolver advertencias de compatibilidad antes de futuras actualizaciones.

## 25. Historial

- Versión 1.0: evidencia completa de identificación sintética, tarifas versionadas, copia contable, informes y ejecución Android/iOS.
