# RB-SPIKE-005 — Validación técnica de Flutter

## 1. Identificación

- Issue relacionada: `#5`
- ADR relacionada: `ADR-001-mobile-technology-stack.md`
- Rama: `spike/issue-5-flutter-validation`
- Fecha de validación: 2026-08-31
- Estado: APROBADO CON CONDICIONES

## 2. Objetivo

Determinar mediante evidencia práctica si Flutter cumple los requisitos técnicos mínimos para construir RiderBiz V1 en Android e iOS con una única base de código.

La prueba utiliza exclusivamente información sintética y no incluye datos personales, etiquetas reales, ubicaciones reales persistidas, secretos ni integraciones externas.

## 3. Entorno validado

| Componente | Versión o configuración |
|---|---|
| Equipo principal | Mac mini con Apple Silicon M2 |
| macOS | Tahoe 26.6.2 |
| Flutter | 3.47.2 stable |
| Dart | 3.13.2 |
| FVM | 4.3.0 |
| Xcode | 26.6 |
| CocoaPods | 1.17.0 |
| Android Studio | 2026.1.3.8 |
| Android Emulator | Android 16, API 36, ARM64 |
| iOS Simulator | iPhone 17 Pro, iOS 26.5 |
| Dispositivo físico | Samsung SM-X210 |
| Persistencia provisional | shared_preferences 2.5.5 |
| Lectura QR | mobile_scanner 7.4.0 |
| Geolocalización | geolocator 14.0.3 |

La versión de Flutter está fijada mediante `.fvmrc`. El directorio local `.fvm/` permanece excluido del repositorio.

## 4. Alcance ejecutado

La prueba técnica incluyó:

- Creación de una aplicación Flutter para Android e iOS.
- Compilación y ejecución en emulador Android.
- Compilación y ejecución en simulador iOS.
- Ejecución en dispositivo Android físico.
- Registro de un paquete sintético.
- Persistencia local sin conexión.
- Recuperación del estado después de reiniciar la aplicación.
- Cambio de estado de `Pendiente` a `Entregado`.
- Solicitud explícita de permiso de cámara.
- Lectura del QR sintético `RB-SYN-0001`.
- Comparación del QR leído con el paquete local.
- Solicitud explícita de ubicación durante el uso.
- Obtención de posiciones simuladas en Android e iOS.
- Análisis estático.
- Pruebas automatizadas.

## 5. Resultados

| Criterio | Resultado | Evidencia |
|---|---|---|
| Versión de Flutter fijada | APROBADO | Flutter 3.47.2 registrado en `.fvmrc` |
| Entorno reproducible | APROBADO | FVM y archivos de configuración versionables |
| Ejecución Android | APROBADO | APK debug compilado, instalado y ejecutado |
| Ejecución iOS | APROBADO | Compilación Xcode y ejecución en iPhone Simulator |
| Dispositivo físico | APROBADO | Aplicación instalada y ejecutada en Samsung SM-X210 |
| Persistencia sin conexión | APROBADO | Paquete recuperado sin red en Android |
| Persistencia Android e iOS | APROBADO | Estado conservado después de reiniciar |
| Cambio de estado | APROBADO | Transición `Pendiente` a `Entregado` |
| Cámara | APROBADO | Permiso durante el uso y apertura controlada |
| Lectura QR sintético | APROBADO | `RB-SYN-0001` reconocido en dispositivo físico |
| Geolocalización Android | APROBADO | Posición simulada obtenida sin persistir coordenadas |
| Geolocalización iOS | APROBADO | Posición simulada obtenida sin persistir coordenadas |
| Análisis estático | APROBADO | `flutter analyze`: sin incidencias |
| Pruebas automatizadas | APROBADO | 2 pruebas superadas |
| Datos personales reales | APROBADO | No utilizados |

## 6. Evidencias de persistencia

El paquete utilizado fue:

- Identificador: `RB-SYN-0001`
- Estado inicial: `Pendiente`
- Estado final: `Entregado`

La aplicación conservó el estado después de detener y volver a ejecutar el proceso Flutter.

La persistencia con `shared_preferences` se considera válida únicamente para esta prueba técnica. No se aprueba como almacenamiento definitivo para entregas, contabilidad, fiscalidad ni información crítica.

## 7. Evidencias de cámara y QR

La aplicación:

- Solicita acceso a cámara durante el uso.
- Explica que solo deben utilizarse códigos sintéticos.
- Restringe la prueba a códigos QR.
- Lee `RB-SYN-0001`.
- Compara el valor leído con el identificador almacenado.
- No captura ni guarda fotografías.
- No utiliza etiquetas reales.

La lectura se validó con la cámara de una Samsung SM-X210.

La cámara se abrió también en los simuladores configurados. La validación con un iPhone físico queda pendiente antes de publicación en App Store.

## 8. Evidencias de geolocalización

La aplicación solicita únicamente permisos de ubicación durante el uso.

No se añadieron permisos de:

- Ubicación permanente.
- Ubicación en segundo plano.
- Servicio persistente de localización.

Las coordenadas:

- No se muestran en la interfaz.
- No se guardan en almacenamiento local.
- No se escriben en registros.
- No se incorporan al repositorio.

La interfaz solo confirma la obtención y muestra la precisión estimada.

## 9. Pruebas automatizadas

Las pruebas verifican:

1. Serialización y recuperación del paquete sintético.
2. Cambio del estado a `Entregado`.

Resultado:

```text
00:01 +2: All tests passed!
