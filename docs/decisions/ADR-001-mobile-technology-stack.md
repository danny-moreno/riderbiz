# ADR-001 · Stack tecnológico móvil de RiderBiz V1

## Estado

Propuesto

## Fecha

2026-08-28

## Issue relacionada

#3

## 1. Decisión que debe tomarse

Seleccionar la base tecnológica inicial para construir RiderBiz V1 en Android e iOS sin sobredimensionar su arquitectura.

Este ADR decide principalmente la tecnología de la aplicación móvil. La persistencia, el backend, los mapas y la optimización de rutas se delimitan, pero requerirán decisiones específicas posteriores.

## 2. Contexto de RiderBiz

RiderBiz se dirige inicialmente a repartidores autónomos multioperador de última milla.

La aplicación deberá poder evolucionar para:

- Registrar paquetes y operadores.
- Organizar carga, sectores y rutas.
- Funcionar durante jornadas con conectividad limitada.
- Consultar información operativa rápidamente.
- Utilizar cámara, códigos, geolocalización y almacenamiento local.
- Generar resúmenes operativos y económicos.
- Incorporar sincronización futura sin hacerla obligatoria para la primera vertical slice.
- Proteger datos personales y de localización desde el diseño.

## 3. Alcance de esta decisión

Este ADR evalúa:

- Flutter.
- React Native.
- Desarrollo nativo con Swift y Kotlin.
- Aplicación web progresiva.

Este ADR no selecciona todavía:

- Proveedor de mapas.
- Motor de optimización de rutas.
- Servicio de OCR o inteligencia artificial.
- Backend definitivo.
- Proveedor cloud.
- Sistema de analítica.
- Integraciones con operadores logísticos.

## 4. Restricciones iniciales

- Equipo de desarrollo inicial reducido.
- Mac mini M2 con Xcode disponible.
- Necesidad prevista de Android e iOS.
- Primera vertical slice local-first.
- Desarrollo con datos sintéticos.
- Presupuesto limitado durante la validación.
- Cumplimiento europeo y privacidad desde el diseño.
- Necesidad de evitar complejidad prematura.

## 5. Criterios de evaluación

| Criterio | Peso | Justificación |
|---|---:|---|
| Cobertura Android e iOS | 15 | RiderBiz debe servir a repartidores con ambos sistemas |
| Capacidad offline y persistencia local | 15 | La operación no puede depender totalmente de conectividad |
| Acceso a capacidades del dispositivo | 15 | Cámara, códigos y ubicación son funciones relevantes |
| Mantenibilidad con equipo reducido | 15 | La V1 debe poder evolucionar con recursos limitados |
| Rendimiento y fiabilidad | 10 | La aplicación se utilizará durante una jornada operativa |
| Calidad de pruebas y herramientas | 10 | Los cambios deben poder verificarse y automatizarse |
| Curva de aprendizaje | 8 | El tiempo de formación afecta al plazo de construcción |
| Madurez del ecosistema | 5 | Reduce riesgo técnico y dependencias abandonadas |
| Seguridad y privacidad | 5 | RiderBiz tratará potencialmente datos sensibles |
| Riesgo de dependencia tecnológica | 2 | Debe existir una estrategia razonable de evolución |
| **Total** | **100** | |

## 6. Escala de puntuación

Cada alternativa recibirá una puntuación de 1 a 5:

- 1: muy deficiente.
- 2: deficiente.
- 3: aceptable.
- 4: buena.
- 5: excelente.

La puntuación ponderada se calculará multiplicando la puntuación por el peso del criterio.

## 7. Alternativas evaluadas

### 7.1 Flutter

Flutter permite construir aplicaciones compiladas para Android e iOS desde una base de código principalmente compartida.

Ventajas para RiderBiz:

- Una base de código para las dos plataformas.
- Acceso a cámara, ubicación y almacenamiento mediante plugins.
- Posibilidad de escribir código específico en Swift o Kotlin.
- Herramientas integradas de análisis, formato y pruebas.
- Interfaz consistente.
- Arquitectura adecuada para un equipo inicial reducido.
- Soporte oficial para múltiples plataformas.

Limitaciones:

- Requiere aprender Dart y Flutter.
- Algunas capacidades dependen de plugins.
- Determinadas funciones pueden requerir integración nativa.
- Debe validarse el mantenimiento de cada dependencia.
- El resultado debe comprobarse en dispositivos físicos.

Conclusión: ofrece la relación más favorable entre cobertura móvil, mantenimiento, rendimiento y coste inicial.

### 7.2 React Native

React Native permite construir aplicaciones Android e iOS utilizando React y JavaScript o TypeScript, con componentes respaldados por capacidades nativas.

Ventajas:

- Cobertura Android e iOS.
- Ecosistema amplio.
- Uso de TypeScript.
- Acceso a módulos nativos.
- Herramientas maduras de pruebas.
- React Native New Architecture está orientada a producción.

Limitaciones:

- Requiere tomar decisiones adicionales sobre navegación, persistencia y acceso a APIs.
- Una aplicación nueva suele apoyarse en un framework complementario como Expo.
- Combina herramientas JavaScript, dependencias comunitarias y configuración nativa.
- RiderBiz no dispone actualmente de una ventaja previa documentada en React.
- Debe comprobarse la compatibilidad de las dependencias con la arquitectura vigente.

Conclusión: alternativa viable, pero ligeramente menos favorable para el equipo y contexto inicial de RiderBiz.

### 7.3 Swift y Kotlin nativos

Esta alternativa construiría dos aplicaciones independientes:

- Swift y tecnologías Apple para iOS.
- Kotlin y tecnologías Android para Android.

Ventajas:

- Acceso directo a todas las capacidades del dispositivo.
- Máximo control sobre rendimiento y comportamiento.
- Herramientas oficiales maduras.
- Menor dependencia de una capa multiplataforma.
- Integración inmediata con novedades de cada plataforma.

Limitaciones:

- Dos bases de código.
- Duplicación de interfaz, pruebas y mantenimiento.
- Mayor curva de aprendizaje.
- Mayor coste y tiempo de construcción.
- Riesgo de divergencia funcional entre Android e iOS.

Conclusión: proporciona el máximo control técnico, pero resulta desproporcionada para la etapa inicial y un equipo reducido.

### 7.4 Aplicación web progresiva

Una PWA es una aplicación web instalable que puede utilizar almacenamiento local, cámara, geolocalización y mecanismos offline mediante APIs del navegador.

Ventajas:

- Una base web compartida.
- Distribución rápida.
- Actualizaciones sin tiendas.
- Menor barrera inicial de instalación.
- Posibilidad de reutilización futura como panel administrativo.

Limitaciones:

- Capacidades variables según navegador y sistema operativo.
- Integración menos predecible con tareas en segundo plano.
- Instalación diferente entre Android e iOS.
- Mayor dependencia de compatibilidad web.
- Riesgo operativo para una aplicación intensiva en cámara, ubicación y uso durante toda la jornada.

Conclusión: puede servir como panel o complemento futuro, pero no es la opción principal recomendada para la aplicación operativa.

## 8. Matriz comparativa

Escala:

- 1: muy deficiente.
- 2: deficiente.
- 3: aceptable.
- 4: buena.
- 5: excelente.

| Criterio | Peso | Flutter | React Native | Nativo | PWA |
|---|---:|---:|---:|---:|---:|
| Cobertura Android e iOS | 15 | 5 | 5 | 2 | 5 |
| Capacidad offline | 15 | 5 | 4 | 5 | 3 |
| Capacidades del dispositivo | 15 | 4 | 4 | 5 | 2 |
| Mantenibilidad con equipo reducido | 15 | 5 | 4 | 2 | 5 |
| Rendimiento y fiabilidad | 10 | 4 | 4 | 5 | 3 |
| Pruebas y herramientas | 10 | 5 | 4 | 5 | 4 |
| Curva de aprendizaje | 8 | 3 | 3 | 1 | 4 |
| Madurez del ecosistema | 5 | 5 | 5 | 5 | 4 |
| Seguridad y privacidad | 5 | 4 | 4 | 5 | 3 |
| Dependencia tecnológica | 2 | 3 | 4 | 5 | 5 |
| **Resultado ponderado** | **100** | **92,2** | **82,4** | **75,6** | **74,4** |

Las puntuaciones son una evaluación técnica razonada, no mediciones experimentales. Deberán revisarse después de la prueba técnica.

## 9. Decisión provisional

RiderBiz V1 adoptará provisionalmente Flutter para construir la aplicación móvil Android e iOS desde una base de código compartida.

La aplicación seguirá una arquitectura local-first. Las operaciones críticas de la primera vertical slice deberán funcionar sin backend y sin una conexión permanente.

La aprobación definitiva queda condicionada a una prueba técnica que valide:

- Ejecución en Android e iOS.
- Persistencia local.
- Funcionamiento sin conexión.
- Acceso a cámara.
- Lectura de un código sintético.
- Geolocalización controlada.
- Pruebas automatizadas.
- Rendimiento en dispositivos físicos.
- Mantenimiento y seguridad de dependencias.

Esta decisión no selecciona todavía la base de datos, backend, mapas, OCR ni motor de optimización.

## 10. Consecuencias positivas

- Reducción de duplicación entre Android e iOS.
- Una sola base principal de código.
- Menor coste inicial de mantenimiento.
- Interfaz coherente.
- Herramientas integradas de calidad.
- Capacidad de integrar código nativo cuando sea necesario.
- Posibilidad de construir primero una vertical slice local.
- Mayor viabilidad para un equipo inicial reducido.

## 11. Consecuencias negativas

- El equipo deberá aprender Dart y Flutter.
- Será necesario evaluar cuidadosamente los plugins.
- Algunas funciones pueden exigir Swift o Kotlin.
- Las actualizaciones de Flutter pueden requerir adaptación.
- La interfaz deberá respetar las convenciones de Android e iOS.
- La decisión crea dependencia parcial del ecosistema Flutter.
- Será obligatorio realizar pruebas en teléfonos reales.

## 12. Riesgos y mitigaciones

### Riesgo 1 — Dependencias comunitarias

Mitigación:

- Priorizar paquetes oficiales o mantenidos activamente.
- Revisar frecuencia de actualizaciones.
- Evitar dependencias innecesarias.
- Encapsular los plugins detrás de interfaces propias.
- Registrar decisiones de dependencias relevantes.

### Riesgo 2 — Funciones móviles insuficientes

Mitigación:

- Probar cámara, códigos, ubicación y persistencia antes de aprobar definitivamente.
- Mantener la posibilidad de implementar código nativo.
- No comprometer la arquitectura con un plugin antes de validarlo.

### Riesgo 3 — Rendimiento durante la jornada

Mitigación:

- Utilizar datos sintéticos equivalentes a cargas reales.
- Probar 60–120 paquetes y escenarios superiores.
- Medir tiempos, memoria, batería y respuesta.
- Validar en dispositivos Android e iPhone físicos.

### Riesgo 4 — Curva de aprendizaje

Mitigación:

- Formación progresiva.
- Documentación de decisiones.
- Laboratorios pequeños.
- Convenciones oficiales.
- Primera vertical slice limitada.

### Riesgo 5 — Dependencia tecnológica

Mitigación:

- Mantener lógica de dominio separada de la interfaz.
- Evitar que las reglas centrales dependan directamente de plugins.
- Utilizar formatos de datos portables.
- Documentar integraciones nativas.
- Revisar periódicamente el ADR.

## 13. Plan de validación técnica

La prueba técnica deberá demostrar:

1. Proyecto Flutter reproducible.
2. Aplicación ejecutable en simulador iOS.
3. Aplicación ejecutable en emulador Android.
4. Ejecución en al menos un dispositivo físico.
5. Registro local de un paquete sintético.
6. Lectura posterior sin conexión.
7. Cambio de estado de entrega.
8. Lectura de un código sintético.
9. Obtención de ubicación con permiso explícito.
10. Pruebas unitarias y de interfaz.
11. Análisis estático sin errores.
12. Registro de resultados y limitaciones.

La prueba no utilizará etiquetas, direcciones, teléfonos ni datos personales reales.

## 14. Condiciones de revisión

Este ADR deberá revisarse si:

- Flutter no cumple una capacidad esencial.
- La integración nativa resulta desproporcionada.
- El rendimiento operativo es insuficiente.
- Una dependencia crítica deja de mantenerse.
- Cambia significativamente el tamaño o experiencia del equipo.
- Los requisitos validados contradicen las restricciones iniciales.
- El coste de mantener Android e iOS deja de ser favorable.
- Aparece una obligación regulatoria incompatible con la arquitectura.

## 15. Decisiones expresamente aplazadas

Requerirán ADR independientes:

- Persistencia local.
- Arquitectura de sincronización.
- Backend.
- Autenticación.
- Mapas y geocodificación.
- Optimización de rutas.
- OCR y lectura de etiquetas.
- Analítica y observabilidad.
- Arquitectura regulatoria y fiscal por jurisdicción.
- Envío seguro de informes a gestoría.

## 16. Fuentes oficiales consultadas

- Flutter Architectural Overview: https://docs.flutter.dev/resources/architectural-overview
- Flutter Platform Integration: https://docs.flutter.dev/platform-integration
- Flutter Platform Channels: https://docs.flutter.dev/platform-integration/platform-channels
- Flutter Supported Platforms: https://docs.flutter.dev/reference/supported-platforms
- Flutter Architecture Recommendations: https://docs.flutter.dev/app-architecture/recommendations
- React Native Introduction: https://reactnative.dev/docs/getting-started
- React Native Architecture: https://reactnative.dev/architecture/landing-page
- React Native Platform-Specific Code: https://reactnative.dev/docs/platform-specific-code
- React Native Testing: https://reactnative.dev/docs/testing-overview
- Android Offline-First Architecture: https://developer.android.com/topic/architecture/data-layer/offline-first
- Progressive Web Apps: https://web.dev/learn/pwa/progressive-web-apps
- MDN Progressive Web Apps: https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Guides/What_is_a_progressive_web_app

## 17. Estado y aprobación

Estado actual:

```text

PROPUESTO — pendiente de prueba técnica
```

El ADR podrá pasar a `ACEPTADO` cuando la prueba técnica cumpla los criterios definidos y no aparezca un riesgo bloqueante.

## 18. Historial

- Versión 0.1: estructura y criterios iniciales.
- Versión 0.2: evaluación comparativa, decisión provisional, consecuencias, riesgos y plan de validación.
