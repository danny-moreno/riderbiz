# RB-ROUTING-007 · Privacidad y archivos temporales

## Alcance

2026-10-26. Revisión acotada del entorno local de la Issue #21.
Se utilizaron exclusivamente tareas sintéticas.
No se realizaron solicitudes GraphHopper ni se activó facturación.

## Secretos

Gitleaks 8.30.1 examinó 113 commits accesibles mediante referencias
locales, con --log-opts="--all" y redacción completa: ningún hallazgo.
El resultado depende de las reglas y del historial disponible;
no garantiza la ausencia absoluta de secretos.

Se consolidaron reglas duplicadas de .gitignore.
.env.example contiene GRAPHHOPPER_API_KEY vacío; no se carga
automáticamente y ningún adaptador implementado lo consume.
El entorno local no necesita esa credencial.

## Hallazgos y correcciones

Los logs anteriores de OSRM contenían 625 líneas con pares de
coordenadas sintéticas y endpoints de rutas o matrices.

Ambos contenedores utilizan ahora el driver none.
OSRM utiliza además verbosidad WARNING.
VROOM_LOG="false" se interpretaba como una ruta, no como desactivación.
Se retiró esa variable y un parche elimina el registro HTTP de acceso
en una imagen local derivada de la imagen fijada por digest.
La construcción falla si cambia el código esperado del proveedor.
El contexto de construcción excluye configuración y logs.

El driver none reduce también la capacidad diagnóstica:
stdout y stderr no quedan disponibles mediante docker logs.

## Solicitudes temporales

El código inspeccionado escribe cada solicitud JSON en args.logdir
y elimina el archivo en el callback close del proceso VROOM.
Una interrupción anterior puede dejar archivos pendientes.

Se cambió logdir de /conf a /tmp/riderbiz-requests, montado como
tmpfs con un máximo de 16 MiB.
Las nuevas solicitudes dejan de escribirse en la carpeta compartida.

Docker documenta que tmpfs se elimina al detener el contenedor.
Puede existir uso de swap; no se acredita borrado forense.
Un timeout del cliente no garantiza terminación del proceso servidor
ni eliminación inmediata de su archivo.

El arranque del proveedor puede crear /conf/access.log vacío,
aunque el registro HTTP haya sido eliminado.

## Validación observada

- Cinco pruebas locales superadas: vroom_local_runtime_test.dart
  y vroom_priority_runtime_test.dart.
- Montaje confirmado: /tmp/riderbiz-requests, size=16m,mode=1777.
- JSON temporales restantes al finalizar: cero.
- JSON en la carpeta compartida: cero.
- access.log compartido: cero bytes.
- Drivers de ambos servicios: none, comprobados tras la primera recreación.
- git diff --check: sin incidencias comunicadas.

No se simuló muerte abrupta durante una escritura ni se comprobó
experimentalmente la eliminación de un residuo al detener el contenedor.

## Límites

Los mapas y los planes aceptados en SQLite son persistencia intencionada.
Esta corrección no elimina mapas ni bases de datos de la aplicación.

La recreación retiró los contenedores anteriores; no acredita eliminación
forense del disco de la máquina virtual, backups o copias.
No constituye una auditoría completa de seguridad de la aplicación.

La Issue #21 permanece abierta y ADR-004 continúa PROPUESTO.

## Referencia

https://docs.docker.com/engine/storage/tmpfs/
