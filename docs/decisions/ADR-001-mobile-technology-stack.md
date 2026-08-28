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

## 7. Alternativas

### 7.1 Flutter

Pendiente de evaluación documentada.

### 7.2 React Native

Pendiente de evaluación documentada.

### 7.3 Swift y Kotlin nativos

Pendiente de evaluación documentada.

### 7.4 Aplicación web progresiva

Pendiente de evaluación documentada.

## 8. Matriz comparativa

| Criterio | Peso | Flutter | React Native | Nativo | PWA |
|---|---:|---:|---:|---:|---:|
| Cobertura Android e iOS | 15 | — | — | — | — |
| Capacidad offline | 15 | — | — | — | — |
| Capacidades del dispositivo | 15 | — | — | — | — |
| Mantenibilidad | 15 | — | — | — | — |
| Rendimiento y fiabilidad | 10 | — | — | — | — |
| Pruebas y herramientas | 10 | — | — | — | — |
| Curva de aprendizaje | 8 | — | — | — | — |
| Madurez del ecosistema | 5 | — | — | — | — |
| Seguridad y privacidad | 5 | — | — | — | — |
| Dependencia tecnológica | 2 | — | — | — | — |

## 9. Decisión provisional

Pendiente de completar la investigación, la matriz ponderada y una prueba técnica limitada.

La hipótesis inicial es que Flutter puede ofrecer una relación favorable entre cobertura multiplataforma, mantenimiento y acceso a capacidades móviles, pero todavía no constituye una decisión aprobada.

## 10. Consecuencias

Pendientes de la decisión final.

## 11. Riesgos y mitigaciones

Pendientes de la evaluación comparativa.

## 12. Validación necesaria

Antes de aceptar este ADR deberán verificarse:

- Aplicación mínima ejecutable en Android e iOS.
- Persistencia local sin conexión.
- Acceso controlado a cámara.
- Lectura de un código sintético.
- Prueba básica de geolocalización.
- Ejecución de pruebas automatizadas.
- Revisión del mantenimiento y soporte de dependencias.

## 13. Condiciones de revisión

Este ADR deberá revisarse si:

- Una capacidad esencial requiere código nativo desproporcionado.
- El rendimiento operativo resulta insuficiente.
- El ecosistema elegido deja de recibir soporte adecuado.
- Cambia significativamente el tamaño o experiencia del equipo.
- Los requisitos validados de RiderBiz contradicen las restricciones actuales.

## 14. Fuentes

Pendientes de incorporar durante la investigación.

## 15. Historial

- Versión 0.1: estructura inicial del ADR y criterios de evaluación.
