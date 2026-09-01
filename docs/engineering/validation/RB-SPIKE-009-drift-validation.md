# RB-SPIKE-009 · Validación técnica de Drift

## Estado

Completado

## Fecha

2026-09-01

## Issue relacionada

#9

## ADR relacionada

`docs/decisions/ADR-002-local-persistence.md`

## 1. Objetivo

Determinar mediante evidencia técnica si Drift sobre SQLite cumple los requisitos mínimos de persistencia local estructurada para RiderBiz V1.

## 2. Decisión evaluada

ADR-002 propuso Drift sobre SQLite como alternativa provisional para sustituir el uso experimental de `shared_preferences` como almacenamiento operativo.

La prueba debía validar:

- Modelo relacional.
- Integridad entre entidades.
- Transacciones y rollback.
- Consultas filtradas.
- Persistencia en disco.
- Funcionamiento sin conexión.
- Migraciones de esquema.
- Pruebas automatizadas.
- Compatibilidad real con Android e iOS.

## 3. Entorno validado

- Flutter: 3.47.2 stable.
- Dart: 3.13.2.
- FVM: 4.3.0.
- Drift: 2.34.3.
- drift_flutter: 0.3.1.
- drift_dev: 2.34.5.
- build_runner: 2.16.0.
- macOS: 26.6.2, Apple Silicon.
- Android: Android 16, API 36, emulador ARM64.
- iOS: iOS 26.5, simulador iPhone 17.
- Xcode: 26.6.
- CocoaPods: 1.17.0.

## 4. Modelo relacional validado

La prueba creó las siguientes tablas:

### logistics_operators

Representa un operador logístico sintético.

Campos principales:

- `id`.
- `name`.
- `created_at`.

### delivery_runs

Representa una jornada o ruta.

Campos principales:

- `id`.
- `operator_id`.
- `started_at`.
- `finished_at`.

Relación:

- Una jornada pertenece a un operador.

### synthetic_packages

Representa un paquete exclusivamente sintético.

Campos principales:

- `id`.
- `delivery_run_id`.
- `status`.
- `external_reference`.
- `created_at`.
- `updated_at`.
- `needs_sync`.

Relación:

- Un paquete pertenece a una jornada.

Restricción de estado:

- `pending`.
- `delivered`.
- `failed`.

### delivery_events

Representa un evento operativo sintético.

Campos principales:

- `id`.
- `package_id`.
- `event_type`.
- `occurred_at`.
- `needs_sync`.

Relación:

- Un evento pertenece a un paquete.

## 5. Integridad y transacciones

Se activó explícitamente:

```sql
PRAGMA foreign_keys = ON
```

Resultados:

- Se insertaron correctamente operador, jornada y paquete relacionados.
- Se rechazó un paquete asociado con una jornada inexistente.
- Se actualizó un paquete de `pending` a `delivered`.
- Se consultaron paquetes filtrados por estado.
- Una transacción con error revirtió todos sus cambios.
- No quedaron eventos parcialmente escritos después del rollback.

Resultado: APROBADO.

## 6. Persistencia local

Se creó una base SQLite física en un directorio temporal.

Secuencia validada:

1. Apertura de la base.
2. Inserción de datos sintéticos relacionados.
3. Cierre completo.
4. Reapertura del mismo archivo.
5. Recuperación del paquete.
6. Verificación de estado, relación y referencia externa.
7. Eliminación del directorio temporal.

Resultado: APROBADO.

La operación no requirió backend ni conexión de red.

## 7. Migración de esquema

Se exportaron dos snapshots:

- `drift_schema_v1.json`.
- `drift_schema_v2.json`.

Cambio de v1 a v2:

- Se añadió `external_reference` como columna nullable en `synthetic_packages`.

La prueba automatizada:

1. Creó una base con el esquema v1.
2. Insertó operador, jornada y paquete sintéticos.
3. Ejecutó la migración real a v2.
4. Comparó el esquema resultante con el snapshot v2.
5. Confirmó que los datos anteriores permanecían intactos.
6. Confirmó que `external_reference` tenía inicialmente valor `null`.

Resultado: APROBADO.

## 8. Pruebas automatizadas

Suite local:

```text
8 tests passed
```

Cobertura funcional validada:

- Persistencia experimental previa.
- Relaciones de Drift.
- Restricciones.
- Consultas filtradas.
- Actualización de estado.
- Rollback.
- Migración v1 → v2.
- Persistencia física después de reinicio.

Análisis estático:

```text
No issues found
```

Resultado: APROBADO.

## 9. Validación Android

Entorno:

- Android 16.
- API 36.
- Emulador ARM64.
- Identificador de ejecución: `emulator-5554`.

La prueba de integración abrió una base SQLite nativa, escribió datos relacionados, cerró la base, volvió a abrirla y recuperó correctamente el paquete.

Resultado:

```text
All tests passed
```

También se generó correctamente:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

Tamaño observado del APK debug: 203 MB.

El tamaño corresponde a una compilación de depuración y no representa el tamaño final de distribución.

Resultado: APROBADO.

## 10. Validación iOS

Entorno:

- iOS 26.5.
- Simulador iPhone 17.
- Xcode 26.6.

La misma prueba de integración abrió SQLite en iOS, escribió datos, cerró la base, volvió a abrirla y recuperó correctamente el paquete.

Resultado:

```text
All tests passed
```

También se generó correctamente:

```text
build/ios/iphonesimulator/Runner.app
```

Resultado: APROBADO.

## 11. Datos y privacidad

Se utilizaron exclusivamente identificadores y nombres sintéticos:

- `OP-SYN-*`.
- `RUN-SYN-*`.
- `RB-SYN-*`.
- `EXT-SYN-*`.

No se utilizaron:

- Nombres personales.
- Direcciones.
- Teléfonos.
- Etiquetas reales.
- Coordenadas reales.
- Credenciales.
- Secretos.

Los archivos físicos utilizados por las pruebas locales se crearon en directorios temporales y se eliminaron al finalizar.

## 12. Riesgos y limitaciones

### Cifrado en reposo

La prueba no incorpora cifrado de la base de datos.

Condición:

- Evaluar cifrado y gestión de claves antes de almacenar datos personales o información operativa sensible.

### Sincronización

`needs_sync` y `external_reference` preparan el modelo para una evolución futura, pero no implementan sincronización.

Condición:

- Definir la arquitectura de sincronización mediante una decisión independiente.

### Rendimiento

No se midieron todavía memoria, batería ni rendimiento con 60–120 paquetes.

Condición:

- Ejecutar pruebas de carga antes del uso operativo real.

### Dispositivos físicos

La ejecución nativa de Drift fue validada en emuladores Android e iOS.

Condición:

- Repetir la validación en dispositivos físicos antes de una distribución externa.

### Compatibilidad futura

La compilación Android mostró advertencias no bloqueantes relacionadas con Java, Gradle, herramientas SDK y la futura migración de `mobile_scanner` a Built-in Kotlin.

Estas advertencias no fueron causadas por Drift, pero deberán revisarse al actualizar Flutter o los plugins.

## 13. Evidencia Git

Commits de la prueba:

- `e66b88a`: dependencias de Drift.
- `f7ce52b`: modelo relacional y pruebas.
- `9f7efc2`: snapshot del esquema v1.
- `2c32b64`: migración v1 → v2.
- `dc13443`: persistencia SQLite después de reinicio.
- `2131fad`: ejecución nativa en Android e iOS.

## 14. Resultado por criterio

| Criterio | Resultado |
|---|---|
| Compatibilidad con Flutter fijado | APROBADO |
| Modelo relacional mínimo | APROBADO |
| Integridad referencial | APROBADO |
| Transacciones y rollback | APROBADO |
| Consultas filtradas | APROBADO |
| Persistencia sin conexión | APROBADO |
| Migraciones verificadas | APROBADO |
| Pruebas automatizadas | APROBADO |
| Análisis estático | APROBADO |
| Compilación Android | APROBADO |
| Compilación iOS | APROBADO |
| Ejecución nativa Android | APROBADO |
| Ejecución nativa iOS | APROBADO |
| Datos sintéticos y privacidad | APROBADO |

## 15. Conclusión

Drift sobre SQLite cumple los requisitos técnicos mínimos definidos para la persistencia local estructurada de RiderBiz V1.

No se identificó ningún riesgo bloqueante.

Se recomienda actualizar ADR-002 de `PROPUESTO` a `ACEPTADO`, con las siguientes condiciones no bloqueantes:

- Mantener la persistencia detrás de repositorios o interfaces.
- Diseñar la sincronización en una decisión independiente.
- Evaluar cifrado antes de almacenar información sensible.
- Medir rendimiento con cargas representativas.
- Validar nuevamente en dispositivos físicos.
- Mantener pruebas de migración para cada cambio de esquema.

## 16. Historial

- Versión 1.0: evidencia completa de la validación técnica de Drift.
