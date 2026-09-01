æ# ADR-002 · Persistencia local estructurada de RiderBiz V1

## Estado

Aceptado

## Fecha

2026-08-31

## Issue relacionada

#7

## 1. Decisión que debe tomarse

Seleccionar la tecnología de persistencia local estructurada para RiderBiz V1.

La solución deberá permitir que la aplicación gestione su operación principal sin conexión y pueda evolucionar hacia una sincronización remota futura sin sustituir innecesariamente toda la capa de datos.

## 2. Contexto

RB-SPIKE-005 validó Flutter, el funcionamiento local-first y la persistencia básica mediante `shared_preferences`.

`shared_preferences` fue adecuado para la prueba técnica de un único paquete sintético, pero no es una base de datos destinada a gestionar relaciones, consultas complejas, integridad referencial o migraciones del modelo operativo.

RiderBiz necesitará almacenar progresivamente:

- Operadores logísticos.
- Jornadas y rutas.
- Paquetes sintéticos y posteriormente registros operativos autorizados.
- Estados e intentos de entrega.
- Incidencias.
- Marcas temporales.
- Eventos pendientes de sincronización.
- Preferencias de usuario separadas de los datos operativos.

## 3. Alcance

Este ADR decidirá:

- Motor de persistencia local.
- Modelo relacional o NoSQL.
- Capacidad de consulta.
- Gestión de migraciones.
- Estrategia de pruebas de la base de datos.
- Compatibilidad con sincronización futura.

Este ADR no decidirá:

- Backend.
- Proveedor cloud.
- API de sincronización.
- Autenticación.
- Cifrado definitivo de datos sensibles.
- Política completa de conservación de datos.
- Mapas u optimización de rutas.

## 4. Requisitos mínimos

La solución deberá:

- Funcionar sin conexión en Android e iOS.
- Mantener integridad entre paquetes, rutas, operadores y eventos.
- Soportar transacciones.
- Permitir consultas filtradas y ordenadas.
- Permitir índices.
- Gestionar cambios del esquema mediante migraciones.
- Poder probarse automáticamente.
- Mantener separada la lógica de dominio.
- Evitar dependencia directa de la interfaz.
- Facilitar una sincronización futura.
- Permitir eliminación controlada de datos.
- Mantenerse activamente y disponer de documentación suficiente.

## 5. Alternativas que se evaluarán

### 5.1 Drift sobre SQLite

Capa relacional reactiva y tipada para Dart y Flutter construida sobre SQLite.

### 5.2 sqflite sobre SQLite

Integración directa con SQLite mediante consultas, transacciones y migraciones gestionadas principalmente por la aplicación.

### 5.3 ObjectBox

Base de datos NoSQL orientada a objetos, con relaciones, consultas, transacciones y generación de código.

### 5.4 Isar

Base de datos NoSQL diseñada para Flutter, con índices, consultas, relaciones y transacciones.

Su actividad de mantenimiento y compatibilidad actual deberán considerarse riesgos específicos.

### 5.5 Archivos JSON

Persistencia mediante archivos gestionados por la aplicación.

Se incluye como alternativa de control, aunque previsiblemente no cubrirá adecuadamente integridad, concurrencia, consultas y migraciones.

## 6. Criterios de evaluación

| Criterio | Peso |
|---|---:|
| Integridad y transacciones | 15 |
| Consultas y relaciones | 15 |
| Migraciones de esquema | 15 |
| Compatibilidad Android e iOS | 10 |
| Facilidad de pruebas | 10 |
| Mantenibilidad y actividad | 10 |
| Preparación para sincronización futura | 10 |
| Rendimiento local | 5 |
| Seguridad y privacidad | 5 |
| Riesgo de dependencia tecnológica | 5 |
| **Total** | **100** |

## 7. Escala de puntuación

Cada alternativa se puntúa de 1 a 5:

| Puntuación | Interpretación |
|---:|---|
| 1 | No cubre adecuadamente el criterio o presenta un riesgo alto |
| 2 | Cobertura limitada y requiere trabajo adicional considerable |
| 3 | Cobertura suficiente con condiciones o riesgos relevantes |
| 4 | Buena cobertura con limitaciones controlables |
| 5 | Cobertura sólida y directamente alineada con RiderBiz |

El resultado ponderado se calcula multiplicando cada puntuación por el peso del criterio y dividiendo la suma entre cinco. El máximo posible es 100.

## 8. Evaluación de alternativas

### 8.1 Drift sobre SQLite

Ventajas:

- Modelo relacional apropiado para paquetes, rutas, operadores, intentos y eventos.
- Consultas verificadas y tipadas.
- Transacciones e índices proporcionados por SQLite.
- Herramientas específicas para escribir y probar migraciones.
- Consultas reactivas para actualizar la interfaz.
- Base de datos SQLite portable e inspeccionable.
- Proyecto con actividad reciente y documentación extensa.
- Permite aislar la persistencia mediante repositorios.

Limitaciones:

- Requiere generación de código y configuración adicional.
- El equipo debe aprender Drift y fundamentos de SQL.
- El cifrado no está incorporado como comportamiento predeterminado.
- La sincronización futura deberá diseñarse en una capa independiente.

### 8.2 sqflite sobre SQLite

Ventajas:

- Acceso directo a SQLite.
- Transacciones, lotes, índices y consultas SQL.
- Dependencia tecnológica relativamente reducida.
- Proyecto ampliamente utilizado y mantenido.
- Control explícito sobre el esquema.

Limitaciones:

- Más SQL y transformación manual de datos.
- Menor seguridad de tipos en las consultas.
- Las migraciones y sus pruebas requieren más código propio.
- Mayor riesgo de inconsistencias por errores manuales.
- La reactividad deberá implementarse separadamente.

### 8.3 ObjectBox

Ventajas:

- Persistencia orientada a objetos.
- Transacciones ACID.
- Buen rendimiento local.
- Relaciones y consultas integradas.
- Gestión del historial del modelo.
- Soporte para Android e iOS.

Limitaciones:

- Motor propietario distinto de SQLite.
- Mayor dependencia de una tecnología y sus herramientas.
- La sincronización comercial no debe condicionar la arquitectura inicial.
- Menor portabilidad directa de los datos que un esquema SQLite.
- El modelo NoSQL ofrece menos ajuste natural para ciertos informes relacionales.

### 8.4 Isar

Ventajas:

- API adaptada a Dart y Flutter.
- Transacciones ACID.
- Índices, consultas y relaciones.
- Buen rendimiento local.
- Soporte multiplataforma declarado.

Limitaciones:

- La última versión estable publicada presenta una antigüedad considerable.
- La versión 4 continúa publicada como versión de desarrollo.
- Existe riesgo de mantenimiento y compatibilidad con versiones futuras de Flutter.
- Utiliza un motor específico y aumenta la dependencia tecnológica.
- Requeriría una validación más amplia antes de utilizarse en producción.

### 8.5 Archivos JSON

Ventajas:

- Implementación inicial sencilla.
- Formato portable y legible.
- Sin dependencia de un motor de base de datos.

Limitaciones:

- No proporciona integridad referencial.
- No ofrece transacciones de base de datos.
- Consultas, índices y concurrencia deberían implementarse manualmente.
- Las migraciones serían responsabilidad completa de RiderBiz.
- Riesgo elevado de corrupción o escrituras parciales.
- No es adecuado como almacenamiento operativo principal.

## 9. Matriz comparativa

| Criterio | Peso | Drift | sqflite | ObjectBox | Isar | JSON |
|---|---:|---:|---:|---:|---:|---:|
| Integridad y transacciones | 15 | 5 | 5 | 5 | 5 | 2 |
| Consultas y relaciones | 15 | 5 | 5 | 4 | 4 | 1 |
| Migraciones de esquema | 15 | 5 | 3 | 4 | 3 | 1 |
| Compatibilidad Android e iOS | 10 | 5 | 5 | 5 | 5 | 5 |
| Facilidad de pruebas | 10 | 5 | 4 | 4 | 4 | 2 |
| Mantenibilidad y actividad | 10 | 5 | 5 | 5 | 1 | 5 |
| Preparación para sincronización futura | 10 | 4 | 5 | 3 | 3 | 2 |
| Rendimiento local | 5 | 4 | 4 | 5 | 5 | 2 |
| Seguridad y privacidad | 5 | 3 | 4 | 4 | 4 | 3 |
| Riesgo de dependencia tecnológica | 5 | 4 | 5 | 3 | 3 | 5 |
| **Resultado ponderado** | **100** | **94** | **90** | **85** | **74** | **50** |

Las puntuaciones representan una evaluación arquitectónica razonada, no una medición experimental de rendimiento.

Drift obtuvo el resultado más favorable porque combina SQLite, consultas tipadas, modelo relacional y herramientas específicas para migraciones. La diferencia frente a `sqflite` procede principalmente de la reducción de código manual y del soporte para verificar el esquema y sus migraciones.

La prueba `RB-SPIKE-009` confirmó experimentalmente las capacidades esenciales evaluadas.

## 10. Decisión aceptada

RiderBiz V1 utilizará Drift sobre SQLite para su persistencia local estructurada.

La decisión se acepta tras completar `RB-SPIKE-009`, que validó:

- Modelo relacional para operadores, jornadas, paquetes y eventos.
- Integridad referencial mediante claves foráneas.
- Transacciones y rollback.
- Consultas filtradas y actualizaciones.
- Persistencia física después de cerrar y reabrir SQLite.
- Migración verificada desde el esquema v1 al v2.
- Conservación de datos durante la migración.
- Pruebas automatizadas.
- Ejecución nativa en Android e iOS.
- Compilación Android e iOS.
- Funcionamiento sin backend y sin conexión de red.

No se identificó ningún riesgo bloqueante.

Condiciones no bloqueantes:

- Mantener Drift detrás de repositorios o interfaces.
- Crear una decisión independiente para la sincronización.
- Evaluar cifrado antes de almacenar información sensible.
- Probar rendimiento, memoria y batería con cargas representativas.
- Repetir la validación en dispositivos físicos antes de la distribución externa.
- Conservar snapshots y pruebas para cada migración del esquema.

`shared_preferences` podrá seguir utilizándose para preferencias simples, pero no será el almacenamiento principal de datos operativos.


## 11. Fuentes oficiales

- Drift: https://drift.simonbinder.eu/
- Migraciones de Drift: https://drift.simonbinder.eu/migrations/
- sqflite: https://pub.dev/packages/sqflite
- ObjectBox para Dart y Flutter: https://pub.dev/packages/objectbox
- Documentación de ObjectBox: https://docs.objectbox.io/
- Isar: https://isar.dev/
- Versiones publicadas de Isar: https://pub.dev/packages/isar/versions

- Evidencia técnica interna: `docs/engineering/validation/RB-SPIKE-009-drift-validation.md`

## 12. Historial

- Versión 0.1: contexto, alcance, requisitos, alternativas y criterios iniciales.
- Versión 0.2: Drift aceptado tras RB-SPIKE-009, con condiciones no bloqueantes.
