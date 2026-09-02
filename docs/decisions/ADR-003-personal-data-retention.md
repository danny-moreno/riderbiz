# ADR-003 · Tratamiento temporal y eliminación de datos personales

## Estado

Aceptado con condiciones

## Fecha

2026-09-02

## Issue relacionada

#11

## 1. Decisión

RiderBiz tratará temporalmente los datos personales contenidos en las etiquetas cuando sean necesarios para organizar la carga, localizar paquetes dentro del vehículo, ordenar las entregas activas y registrar el resultado de cada intento.

Los datos personales estructurados se limitarán inicialmente a:

- Nombre del destinatario.
- Componentes de la dirección necesarios en el país correspondiente.
- Código postal, cuando exista en el sistema postal aplicable.
- Piso, puerta, bloque, portal o unidad de entrega cuando figuren en la etiqueta y sean necesarios.
- Relación temporal entre destinatario, punto de entrega y cantidad de paquetes.

El nombre no se utilizará para calcular la ruta. Su finalidad será permitir que el repartidor localice visualmente los paquetes, dado que suele ser el elemento más visible de la etiqueta, y distinguir varias entregas en un mismo portal.

Los datos se eliminarán inmediatamente cuando:

- Se confirme la entrega.
- Se confirme que no habrá otro intento durante la jornada.
- El paquete quede rechazado, devuelto o cancelado y desaparezca la necesidad operativa.

Cuando se seleccione `Reintentar hoy`, los datos podrán conservarse cifrados hasta resolver el reintento o cerrar la jornada. El cierre de jornada será el límite máximo de conservación y purgará cualquier dato personal residual.

## 2. Alcance territorial

RiderBiz se diseñará desde el inicio para interpretar direcciones del conjunto de Europa y quedará preparado para una expansión mundial.

Se diferenciarán:

- Compatibilidad técnica: formatos postales europeos desde el diseño inicial.
- Lanzamiento jurídico: activación país por país, comenzando por España y posteriormente por jurisdicciones de la Unión Europea y del Espacio Económico Europeo.
- Europa no UE/EEE: revisión específica antes de activar Reino Unido, Suiza u otras jurisdicciones.
- Expansión mundial: incorporación modular de perfiles postales, idiomas, mapas y requisitos jurídicos de cada país.

Ninguna jurisdicción se considerará habilitada únicamente porque la aplicación pueda reconocer sus direcciones.

## 3. Contexto y necesidad

RiderBiz está orientado a repartidores que gestionan paquetes de uno o varios operadores y organizan físicamente la carga dentro de una furgoneta u otro vehículo.

La experiencia operativa confirma que:

- Los paquetes se sectorizan por localidades, barrios o zonas del vehículo.
- El código postal suele ser el dato más útil para una primera clasificación.
- La dirección permite determinar la localidad, calle, portal y punto de entrega.
- El nombre facilita localizar visualmente el paquete dentro del vehículo.
- Una dirección puede contener varios destinatarios, pisos y cantidades de paquetes.
- Una calle corta o varias calles próximas pueden atenderse desde una sola parada del vehículo.
- El repartidor puede elegir un portal diferente al sugerido por la aplicación debido a accesos, estacionamiento o condiciones que RiderBiz desconoce.

Estas necesidades justifican un tratamiento temporal, pero no la creación de historiales identificativos.

## 4. Principios obligatorios

### 4.1 Finalidad

Los datos personales se utilizarán exclusivamente para:

- Clasificar paquetes durante la carga.
- Localizar paquetes dentro del vehículo.
- Agrupar entregas por dirección, portal y destinatario.
- Presentar entregas activas.
- Ordenar portales según la ubicación temporal del repartidor.
- Gestionar entregas, ausencias y reintentos durante la jornada.

Queda prohibido utilizarlos para:

- Publicidad o perfilado comercial.
- Entrenamiento de modelos.
- Analítica individual del destinatario.
- Contabilidad.
- Historiales de domicilios o destinatarios.
- Finalidades incompatibles con la operación de reparto.

### 4.2 Minimización

RiderBiz solo estructurará los campos necesarios para la operación. La imagen y el texto OCR completo serán material transitorio y se descartarán inmediatamente después de extraer y validar los campos autorizados.

### 4.3 Conservación

La eliminación se producirá cuando desaparezca la necesidad operativa. El cierre de jornada será una salvaguarda final, no el momento ordinario de eliminación.

### 4.4 Control del repartidor

RiderBiz recomendará un orden de portales mediante geolocalización, pero permitirá que el repartidor seleccione por cuál comenzar. La aplicación automatizará aquello que pueda calcular y solicitará acciones únicamente para decisiones reales que no pueda conocer.

## 5. Captura y OCR

El OCR se ejecutará localmente en el dispositivo por defecto.

La dirección suele aparecer debajo del nombre y la captura puede contener ambos. En consecuencia:

1. La imagen se mantendrá temporalmente en memoria.
2. El OCR podrá interpretar el área necesaria de la etiqueta.
3. RiderBiz estructurará solo los campos autorizados.
4. La imagen, miniaturas, buffers y texto OCR completo se eliminarán inmediatamente.
5. No se enviarán a servidores propios o de terceros sin una decisión independiente.

Cualquier OCR remoto futuro requerirá otro ADR, análisis de riesgos, revisión contractual, evaluación de transferencias y aprobación jurídica.

## 6. Dirección internacional

RiderBiz no asumirá que todos los códigos postales son numéricos, tienen cinco caracteres o son obligatorios.

El modelo temporal admitirá:

```text
country_code
address_lines
locality
region
postal_code
building_number
entrance
floor
unit
```

Reglas:

- `country_code` será obligatorio mediante un código internacional normalizado.
- `address_lines` contendrá los componentes exigidos por el perfil nacional.
- `locality`, `region` y `postal_code` serán obligatorios u opcionales según el país.
- Se conservarán caracteres Unicode, acentos, signos diacríticos y alfabetos compatibles.
- La validación se realizará mediante perfiles postales por país.
- La representación original y la normalizada serán temporales y cifradas.

## 7. Sectorización del vehículo

RiderBiz asignará cada paquete a una zona configurable del vehículo utilizando código postal, localidad, barrio, calle y excepciones configuradas.

Ejemplo:

| Área de reparto | Zona del vehículo |
|---|---|
| Burlada | ZONA A |
| Villava | ZONA B |
| Huarte | ZONA C |
| Arre | ZONA D |
| Gorraiz | ZONA E |

También podrán configurarse barrios, como Ensanche, Milagrosa o Soto Lezkairu.

El orden de decisión será:

1. Excepción específica autorizada.
2. Barrio o sector.
3. Localidad.
4. Código postal.
5. Selección manual cuando no exista una coincidencia segura.

La lectura correcta mostrará durante un máximo de dos segundos:

```text
CONFIRMADO
ZONA A
```

El aviso tendrá fondo verde, texto e icono. Una lectura incompleta o una zona no configurada mostrará un aviso rojo con la causa concreta.

## 8. Entregas activas

Al llegar a una parada del vehículo, la primera tarjeta mostrará:

```text
ENTREGAS ACTIVAS

3 PORTALES
7 PAQUETES
ZONA A
```

La tarjeta completa será pulsable. No habrá confirmaciones de recogida, casillas por paquete ni escaneos adicionales obligatorios.

Al abrirla, cada portal aparecerá por separado con nombres y cantidades:
```text
ULZAMA, 5
2 paquetes
Juan Moreno · 1
María López · 1

ULZAMA, 7
1 paquete
Ana Valdez · 1

ULZAMA, 9
4 paquetes
Pedro Ruiz · 2
Laura Martín · 2
```

El nombre será visible porque facilita encontrar las etiquetas dentro del vehículo. No aparecerá en notificaciones del sistema, pantalla bloqueada, logs ni histórico.

## 9. Orden dinámico de portales

RiderBiz ordenará las tarjetas por proximidad utilizando la ubicación temporal del dispositivo y, cuando sea posible, la distancia peatonal estimada.

El orden se recalculará cuando:

- Cambie significativamente la ubicación.
- Se complete un portal.
- Se programe un reintento.
- Cambie el conjunto de entregas activas.

El primer portal podrá identificarse como `RECOMENDADO`, pero el repartidor podrá seleccionar cualquiera. La geolocalización ayudará a decidir; no impondrá una secuencia rígida.

La ubicación:

- Se utilizará únicamente durante la jornada activa.
- No se almacenará como trayectoria histórica.
- No se vinculará históricamente a destinatarios.
- Se eliminará cuando deje de ser necesaria.
- No aparecerá en logs o telemetría.

## 10. Parada del vehículo y recorrido entre portales

RiderBiz distinguirá:

- Parada del vehículo.
- Conjunto de entregas activas próximas.
- Portal o edificio.
- Piso, puerta, local u oficina.
- Destinatario.
- Paquetes asociados.

Una única parada del vehículo podrá incluir varios portales de una calle corta o de calles próximas. El repartidor llevará desde el vehículo los paquetes necesarios y elegirá el portal por el que comenzará.

RiderBiz no requerirá confirmar que los paquetes han sido recogidos. La lista tendrá carácter visual e informativo.

La optimización completa de conducción, estacionamiento y recorridos peatonales se documentará en `ADR-004`.

## 11. Gestión dentro del portal

Al seleccionar un portal se mostrarán las entregas por piso o unidad:

```text
ULZAMA, 5

2 ENTREGAS · 3 PAQUETES

1.º A
JUAN MORENO
1 paquete
[ ENTREGADO ] [ AUSENTE ]

3.º B
MARÍA LÓPEZ
2 paquetes
[ ENTREGADOS ] [ AUSENTE ]
```

Una sola acción resolverá todos los paquetes del mismo destinatario y unidad. La entrega parcial estará disponible como opción secundaria.

Al completar cada destinatario, RiderBiz avanzará automáticamente. Al resolver el portal, regresará automáticamente a los portales pendientes.

## 12. Resultado de la entrega

### 12.1 Entregado

Al pulsar `ENTREGADO` o `ENTREGADOS`:

1. Se actualizarán los contadores agregados.
2. Se eliminarán inmediatamente los datos personales resueltos.
3. Se mostrará durante un máximo de dos segundos:

```text
ENTREGA CONFIRMADA
```

El aviso tendrá fondo verde, texto e icono de confirmación.

### 12.2 Ausente

Al pulsar `AUSENTE` se mostrará:

```text
¿REINTENTAR HOY?
[ SÍ ] [ NO ]
```

Si se elige `SÍ`:

- La entrega pasará a `REINTENTO`.
- Los datos permanecerán cifrados.
- El portal aparecerá en la sección de reintentos.
- Los datos se eliminarán al resolverlo o cerrar la jornada.

Si se elige `NO`:

- Se registrará solo el resultado agregado.
- Se eliminarán inmediatamente los datos personales.
- No se creará un histórico individual.

La ausencia utilizará color ámbar, texto e icono. No se presentará como error técnico.

## 13. Retención por estado

| Estado | Conservación | Acción |
|---|---|---|
| Pendiente | Temporal y cifrada | Mantener durante la jornada |
| Reintentar hoy | Temporal y cifrada | Mantener hasta resolver o cerrar |
| Entregado | Ninguna | Agregar y eliminar inmediatamente |
| No reintentar | Ninguna | Agregar y eliminar inmediatamente |
| Rechazado, devuelto o cancelado | Ninguna salvo obligación documentada | Agregar y eliminar |
| Cierre de jornada | Ningún dato personal | Purgar y verificar contador cero |

## 14. Separación del almacenamiento

### 14.1 Almacén temporal cifrado

Podrá contener durante la jornada:

- Nombre.
- Dirección y componentes postales.
- Piso, puerta o unidad.
- Relación temporal con paquetes.
- Zona del vehículo.
- Estado operativo y reintentos.
- Última ubicación estrictamente necesaria.

### 14.2 Almacén histórico agregado

Podrá conservar:

- Fecha y operador.
- Totales de paquetes.
- Totales por estado y zona.
- Hora de inicio y cierre.
- Distancia y duración agregadas cuando estén justificadas.

No podrá contener nombres, domicilios, códigos postales asociados a personas, imágenes, texto OCR, coordenadas, identificadores individuales ni historiales de destinatarios.

Las reglas generales de sectorización por localidad, barrio o código postal podrán conservarse si no contienen domicilios individuales ni información de destinatarios.

## 15. Cifrado y eliminación verificable

La base temporal utilizará una clave de jornada generada de forma segura y protegida mediante Apple Keychain o Android Keystore.

Al eliminar deberán tratarse:

- Registros y relaciones.
- Base temporal.
- Archivos WAL y SHM.
- Páginas libres de SQLite.
- Cachés y directorios temporales.
- Imágenes, miniaturas y buffers OCR.
- Colas de sincronización.
- Copias de seguridad aplicables.
- Clave de cifrado de la jornada.

Una sentencia `DELETE` no se considerará suficiente por sí sola. Se evaluarán `PRAGMA secure_delete`, `VACUUM`, limpieza de archivos auxiliares y criptoeliminación.

En almacenamiento flash no se prometerá el borrado físico absoluto de cada celda. Se exigirá que los datos resulten inaccesibles mediante eliminación lógica, limpieza de artefactos y destrucción de claves.

## 16. Cierre de jornada

El cierre deberá:

1. Comprobar el estado de todas las entregas.
2. Calcular resultados agregados.
3. Eliminar nombres, direcciones, códigos postales y unidades.
4. Eliminar imágenes, OCR, coordenadas e identificadores.
5. Limpiar cachés, buffers, WAL, SHM y colas.
6. Destruir la clave de jornada.
7. Verificar cero registros identificativos.
8. Registrar únicamente evidencia no identificativa.

La jornada no se considerará cerrada si falla la eliminación o su verificación.

## 17. Logs, telemetría y visualización

Queda prohibido incluir en logs, analítica, informes de fallos o notificaciones del sistema:

- Nombres.
- Direcciones y códigos postales.
- Piso, puerta o unidad.
- Texto OCR o imágenes.
- Coordenadas.
- Códigos de etiquetas.
- Contenido de la base temporal.

Los datos personales solo serán visibles con la aplicación desbloqueada, en primer plano y dentro de la parada o conjunto de entregas activas.

## 18. Colores y accesibilidad

Los estados utilizarán color, texto e icono; nunca solo color.

| Estado | Tratamiento visual |
|---|---|
| Lectura correcta | Verde + `CONFIRMADO` + icono |
| Entrega confirmada | Verde + texto + icono |
| Ausente o reintento | Ámbar + texto + icono |
| Error o dato incompleto | Rojo + causa + icono |
| Información y navegación | Azul o turquesa con contraste validado |

Todas las combinaciones deberán cumplir WCAG 2.2 AA y probarse bajo iluminación exterior. El sistema visual completo se documentará en `ADR-005`.

## 19. Regla permanente de producto

Toda decisión de RiderBiz deberá someterse a una revisión rigurosa de:

- Optimización del trabajo del repartidor.
- Simplificación de la interacción.
- Eficiencia operativa.
- Seguridad y privacidad.
- Accesibilidad.

Principio de interfaz:

> Una interacción para registrar cada resultado real; ninguna interacción para confirmar información que RiderBiz ya conoce o puede calcular.

## 20. Condiciones jurídicas

Este ADR no declara que RiderBiz quede fuera del RGPD ni garantiza por sí solo el cumplimiento.

Antes de utilizar datos reales deberán completarse:

- Identificación del responsable, encargado o corresponsable.
- Determinación de la base jurídica.
- Información de privacidad.
- Contratos e instrucciones aplicables.
- Registro de actividades cuando proceda.
- Análisis de riesgos y determinación de la necesidad de una EIPD.
- Evaluación de proveedores, SDK y transferencias internacionales.
- Procedimientos de derechos, incidentes y brechas.
- Revisión jurídica por jurisdicción.

Hasta entonces solo se utilizarán etiquetas y datos sintéticos.

## 21. Criterios de aceptación

- El OCR se ejecuta localmente por defecto.
- Solo se estructuran los campos autorizados.
- La imagen y el texto OCR completo se eliminan tras la extracción.
- El nombre se usa únicamente para localizar paquetes y distinguir entregas.
- La aplicación admite perfiles postales por país.
- La sectorización asigna zonas de forma explicable y corregible.
- `ENTREGAS ACTIVAS` muestra portales, destinatarios y cantidades sin confirmaciones de recogida.
- Los portales se ordenan dinámicamente, pero siguen siendo seleccionables.
- Solo `ENTREGADO`, `AUSENTE` y la decisión de reintento requieren interacción habitual.
- La entrega o el no reintento provocan eliminación inmediata.
- El cierre deja cero registros identificativos.
- Los datos personales no aparecen en logs, histórico o notificaciones del sistema.
- La base temporal está cifrada y la clave de jornada se destruye.
- La eliminación se verifica en Android e iOS.
- Se completa la revisión jurídica antes de usar datos reales.

## 22. Riesgos y mitigaciones

### Conservación accidental

- Borrado por estado.
- Caducidad por jornada.
- Purga final y verificación.

### Filtración por servicios técnicos

- Exclusión de logs y telemetría.
- OCR local.
- Revisión de SDK y proveedores.

### Recuperación de datos eliminados

- Cifrado, clave diaria y criptoeliminación.
- Limpieza de SQLite y archivos auxiliares.
- Pruebas de recuperación y fallos.

### Error de clasificación

- Perfil postal por país.
- Umbral de confianza.
- Mensaje rojo explicativo.
- Corrección manual sin crear históricos personales.

### Automatización excesiva

- Recomendaciones no obligatorias.
- Control del repartidor sobre el portal inicial.
- Eliminación de confirmaciones sin valor.

## 23. Decisiones relacionadas

- `ADR-001-mobile-technology-stack.md`.
- `ADR-002-local-persistence.md`.
- Futuro `ADR-004-route-optimization.md`.
- Futuro `ADR-005-visual-system-accessibility.md`.
- `RB-SPIKE-005-flutter-validation.md`.
- `RB-SPIKE-009-drift-validation.md`.
- `DEC-2026-002 — Conservación y eliminación de datos personales RGPD.pdf`.

## 24. Fuentes oficiales

- Reglamento (UE) 2016/679: https://eur-lex.europa.eu/eli/reg/2016/679/oj/spa
- Comisión Europea, protección de datos: https://commission.europa.eu/law/law-topic/data-protection_es
- Agencia Española de Protección de Datos: https://www.aepd.es/
- AEPD, Facilita Emprende: https://emprende.aepd.es/
- AEPD, ValidaCripto RGPD: https://validacriptorgpd.aepd.es/
- Unión Postal Universal, soluciones de direccionamiento: https://www.upu.int/en/Postal-Solutions/Programmes-Services/Addressing-Solutions
- SQLite `secure_delete`: https://www.sqlite.org/pragma.html#pragma_secure_delete
- SQLite `VACUUM`: https://www.sqlite.org/lang_vacuum.html
- Android Keystore: https://developer.android.com/privacy-and-security/keystore
- Apple Keychain: https://developer.apple.com/documentation/security/keychain-services
- WCAG 2.2: https://www.w3.org/TR/WCAG22/

## 25. Historial

- Versión 1.0: tratamiento temporal, conservación por estado y eliminación verificable.
- Versión 1.1: alcance europeo, expansión mundial, sectorización, entregas activas, selección dinámica de portales y minimización de interacciones.
