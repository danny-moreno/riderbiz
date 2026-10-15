# Registro maestro de ADR de RiderBiz

## Autoridad y regla de sincronización

El directorio `docs/decisions/` del repositorio Git es la fuente canónica de las decisiones arquitectónicas de RiderBiz.

Google Drive conserva copias de consulta, documentos de trabajo y PDF, pero debe utilizar exactamente el mismo número, título y estado que el repositorio.

Reglas obligatorias:

- Cada número ADR se asigna una sola vez y nunca se reutiliza.
- Antes de crear un ADR se consulta este registro y `docs/decisions/`.
- Un ADR nuevo se considera canónico cuando su cambio ha sido integrado en `main`.
- Las copias de Drive deben indicar si están pendientes de incorporación al repositorio.
- El nombre base será `ADR-NNN-titulo-en-kebab-case`.
- El Markdown será la versión editable canónica; el PDF será una representación de consulta.
- Todo cambio de estado o contenido deberá actualizar Git, Drive y este registro en la misma tarea.

## Numeración vigente

| ADR | Decisión | Estado canónico | Ubicación o acción |
|---|---|---|---|
| ADR-001 | Stack tecnológico móvil | ACEPTADO | Git: `docs/decisions/ADR-001-mobile-technology-stack.md` |
| ADR-002 | Persistencia local estructurada | ACEPTADO | Git: `docs/decisions/ADR-002-local-persistence.md` |
| ADR-003 | Conservación de datos personales y flujo de entregas | ACEPTADO | Git: `docs/decisions/ADR-003-personal-data-retention.md` |
| ADR-004 | Optimización adaptativa de rutas | PROPUESTO | Git: `docs/decisions/ADR-004-adaptive-route-optimization.md`; pendiente de validación técnica |
| ADR-005 | Sistema visual y accesibilidad | RESERVADO / PENDIENTE | Ya citado por ADR-003; crear mediante Issue independiente |
| ADR-006 | Identidad, autenticación, organizaciones y autorización | ACEPTADO | Git: `docs/decisions/ADR-006-identity-authentication-organizations-authorization.md` |
| ADR-007 | Paradas operativas, entregas y recogidas | PLANIFICADO | Crear después de delimitarlo frente a ADR-004 |
| ADR-008 | Voz, manos libres y ejecución en segundo plano | PLANIFICADO | Requiere análisis técnico, seguridad vial y privacidad |
| ADR-009 | Convivencia con aplicaciones de operadores | PLANIFICADO | Evaluar Android e iOS por separado |
| ADR-010 | Sectorización del vehículo | PLANIFICADO | No exigir marca ni modelo salvo evidencia de valor |

## Corrección realizada

El documento de identidad que existía únicamente en Google Drive como `ADR-002` colisionaba con el ADR-002 canónico de persistencia local. Se renumera como `ADR-006` porque ADR-004 y ADR-005 ya están reservados expresamente en ADR-003.

ADR-006 queda incorporado al repositorio mediante la Issue #17. Tras la fusión de su pull request en `main`, Git y Google Drive utilizarán la misma numeración canónica.

## Control previo a cada nuevo ADR

1. Actualizar `main` con `git pull --ff-only origin main`.
2. Consultar `docs/decisions/` y este registro.
3. Reservar el siguiente número libre en la Issue.
4. Crear una rama dedicada.
5. Añadir o modificar el Markdown canónico.
6. Verificar enlaces, estado, historial y `git diff --check`.
7. Actualizar la copia o PDF de Drive con el mismo número y título.
8. Fusionar el pull request.
9. Confirmar que `main`, Drive y este registro coinciden.

## Historial

- Versión 1.0 (2026-09-06): creación del registro y corrección de la colisión entre ADR-002 de Git y ADR-002 de Drive.
- Versión 1.1 (2026-10-15): ADR-004 abierto como propuesta de optimización adaptativa de rutas mediante la Issue #19.
