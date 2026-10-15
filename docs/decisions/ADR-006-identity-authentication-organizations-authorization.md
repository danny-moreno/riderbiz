# ADR-006: Identidad, autenticación, organizaciones y autorización de RiderBiz V1

- Estado: ACEPTADO
- Fecha: 2026-09-03
- Propietario: CTO
- Decisores: CTO / Product Owner
- Ámbito: RiderBiz V1 móvil y servicios de sincronización
- Relacionados: ADR-001 (stack móvil), RB-PRD-IDENTITY-001, política de retención de datos

## Contexto

RiderBiz necesita crear cuentas con fricción baja, funcionar en condiciones de conectividad irregular y aislar datos de repartidores, organizaciones y operadores. Un usuario puede ser autónomo, empleado o colaborar con varias organizaciones y operadores. Autenticación (quién es), pertenencia (en qué contexto participa) y autorización (qué puede hacer) no son conceptos intercambiables.

La V1 debe cumplir minimización y privacidad por defecto, evitar credenciales propias almacenadas por RiderBiz y sostener un futuro modelo B2B sin imponer complejidad empresarial al repartidor individual.

## Fuerzas de decisión

1. Compatibilidad con Flutter, iOS y Android.
2. PostgreSQL y políticas de autorización verificables en la base de datos.
3. Residencia primaria en región UE y herramientas de cumplimiento contractual.
4. Coste y carga operativa adecuados para una V1.
5. Evitar números de teléfono, contraseñas propias y proveedores sociales como requisito.
6. Portabilidad: esquema de negocio independiente del proveedor de autenticación.
7. Soporte para organizaciones, múltiples pertenencias y mínimo privilegio.

## Decisión

### Proveedor y flujo

Se adopta **Supabase Auth administrado**, con proyecto y base PostgreSQL en una región de la Unión Europea.

- Método principal V1: **email OTP sin contraseña**, con correo verificado.
- OAuth/social login, teléfono y SSO quedan fuera de alcance inicial.
- PKCE será obligatorio en cualquier flujo futuro basado en redirección.
- MFA TOTP será obligatorio para roles administrativos antes de producción B2B; voluntario para repartidores durante V1.
- Access y refresh tokens se guardarán solo en Keychain/Keystore mediante almacenamiento seguro; nunca en Drift/SQLite ni en logs.
- La clave `service_role` nunca estará presente en el cliente móvil.

### Datos mínimos de cuenta

La cuenta requiere únicamente: UUID técnico, correo verificado, estado y marcas temporales técnicas, versión/fecha de aceptación de términos y versión/fecha de confirmación del aviso de privacidad. El nombre visible, contexto laboral, operador y zona pertenecen al onboarding, no al alta de autenticación.

Quedan excluidos del alta: nombre legal, teléfono, DNI/NIE, fotografía, nacimiento, dirección, IBAN, datos fiscales, geolocalización y datos de destinatarios.

### Modelo

```text
auth_user 1---1 person_profile
auth_user 1---* membership *---1 organization
membership 1---* membership_role *---1 role
role 1---* role_permission *---1 permission
organization 1---* organization_operator *---1 operator
membership 1---* work_assignment *---1 operator
work_assignment *---1 work_zone
```

- `auth_user`: identidad del proveedor.
- `person_profile`: nombre visible, locale y zona horaria.
- `organization`: tenant y límite de propiedad; tipo `personal` o `business`.
- `membership`: relación temporal entre usuario y organización; estado invitado/activo/suspendido/finalizado.
- `operator`: entidad logística canónica o propuesta; no es tenant ni IdP por defecto.
- `role`: paquete de permisos asignado a una pertenencia.
- `permission`: acción atómica sobre un recurso.
- `work_assignment`: contexto de trabajo que enlaza pertenencia, operador y zona.

El tipo laboral `self_employed`/`employee` adapta el producto, pero **no concede permisos**. No habrá un campo global `user.role` ni `user.operator_id`.

### Autorización

- RBAC contextual por pertenencia, complementado con ownership del recurso.
- Denegación por defecto y mínimo privilegio.
- RLS habilitada en todas las tablas expuestas; grants mínimos y políticas que validan `auth.uid()` + pertenencia activa + permiso/ownership.
- `organization_id` forma parte de toda fila multi-tenant; no se confía en valores proporcionados por el cliente.
- Cambios de roles, invitaciones, exportaciones y acciones administrativas se auditan.

Roles iniciales: `personal_owner`, `org_owner`, `org_admin`, `dispatcher`, `courier`, `accountant_readonly`.

## Alternativas evaluadas

### Firebase Authentication + Firestore

Rechazada para V1: autenticación madura, pero el modelo documental y las reglas introducen una segunda lógica de autorización menos alineada con PostgreSQL, Drift y reporting relacional.

### Auth0/Okta + backend propio

Rechazada para V1: capacidades empresariales sólidas, pero mayor coste e integración; no aporta valor proporcional antes de validar SSO/B2B.

### Backend propio de contraseñas/JWT

Rechazada: eleva riesgo, carga de seguridad y operación sin diferenciación de producto.

### Passkeys como único método

Aplazada: buena dirección futura, pero exige validar soporte móvil, recuperación, migración de dispositivo y accesibilidad. Se evaluará como mejora, no como bloqueo de V1.

### Autenticación por SMS

Rechazada como método inicial: exige teléfono personal, genera coste y dependencia de entrega SMS/SIM; podrá estudiarse solo con evidencia.

## Consecuencias positivas

- Menos datos y fricción en el alta.
- Integración directa entre JWT, PostgreSQL y RLS.
- Modelo multi-organización preparado sin sobredimensionar el cliente individual.
- Portabilidad: el dominio de negocio no reside en metadatos privados del proveedor.
- Menor superficie de credenciales y recuperación.

## Consecuencias negativas y mitigaciones

- Dependencia de Supabase: encapsular gateway de identidad, migraciones SQL en Git y no usar metadatos de Auth como dominio.
- Dependencia del correo: instrumentar entrega y recuperación; investigar disponibilidad real con usuarios.
- OTP requiere conexión: permitir operación offline tras sesión válida; nunca crear identidad local paralela.
- RLS compleja: pruebas automáticas negativas por rol/tenant y revisión obligatoria de migraciones.
- Región UE no elimina transferencias: revisar DPA, subencargados, soporte y telemetría antes de producción.

## Invariantes

1. Ninguna fila de negocio multi-tenant carece de `organization_id`.
2. Ningún permiso se deriva solo del cliente o de la interfaz.
3. Ningún rol se almacena como atributo global del usuario.
4. Un operador no equivale a organización ni acredita relación oficial.
5. Zona temporal nunca sobrescribe zona habitual.
6. Tokens y OTP nunca se guardan en SQLite ni se registran.
7. La ubicación nunca es requisito de alta.
8. `service_role` permanece exclusivamente en servidor.

## Criterios de implementación y verificación

- Migraciones versionadas y reversibles para todas las entidades.
- RLS y grants en todas las tablas expuestas.
- Tests de acceso permitido y denegado entre al menos dos usuarios y dos organizaciones.
- Alta E2E por OTP, reanudación de onboarding y cierre de sesión.
- Almacenamiento seguro comprobado en iOS y Android.
- Rate limits, respuestas anti-enumeración y logs redactados.
- Flujo de baja, revocación y retención conectado con la política aprobada.
- Revisión de amenazas, privacidad, DPA y DPIA trigger antes de datos reales.

## Disparadores de revisión

- El email falla como identificador accesible para el segmento objetivo.
- Se contrata una organización que exige SSO o aprovisionamiento corporativo.
- Supabase cambia materialmente precio, región, DPA o capacidades.
- Se introduce seguimiento sistemático, perfilado laboral o administración empresarial.
- Passkeys alcanzan el gate técnico y de recuperación definido.

## Referencias

- Reglamento (UE) 2016/679: https://eur-lex.europa.eu/eli/reg/2016/679/oj
- Supabase Auth: https://supabase.com/docs/guides/auth
- Supabase RLS: https://supabase.com/docs/guides/database/postgres/row-level-security
- Supabase PKCE: https://supabase.com/docs/guides/auth/sessions/pkce-flow
- RFC 7636: https://datatracker.ietf.org/doc/html/rfc7636
- OWASP Authentication Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- OWASP MASVS: https://mas.owasp.org/MASVS/


## Historial

- Versión 1.0 (2026-09-03): decisión inicial sobre identidad, autenticación, organizaciones y autorización.
- Versión 1.1 (2026-10-15): renumeración como ADR-006 e incorporación al registro canónico mediante la Issue #17.
