# Entorno local de validación de rutas

## Objetivo

Ejecutar VROOM y OSRM localmente para RB-SPIKE-021, relacionado con la Issue #21 y ADR-004.

Este entorno es exclusivamente de desarrollo y validación. No selecciona todavía un proveedor de producción.

## Entorno comprobado

- Mac ARM64 con 16 GiB de RAM.
- macOS 27.0.1.
- Colima 0.10.3.
- Docker CLI 29.9.1.
- Docker Compose 5.6.0, mediante `docker-compose`.
- Perfil Colima: `riderbiz`.
- Recursos: 4 CPU, 6 GiB de RAM y disco virtual de 30 GiB.
- Runtime: Docker.
- Virtualización: Apple Virtualization.Framework.
- Arquitectura de contenedores: Linux ARM64.

## Imágenes fijadas

OSRM:

- Versión observada: `v26.10.0`.
- Imagen: `ghcr.io/project-osrm/osrm-backend`.
- Digest ARM64: `sha256:b0045097b8b4ad5e72dce6b900326cd6ee0e98c729709214e674d0472b463f49`.

VROOM:

- Versión observada: `1.16.0-dev`.
- VROOM Express: `0.12.0`.
- Imagen: `ghcr.io/vroom-project/vroom-docker`.
- Digest ARM64: `sha256:189fabbb238f4891d821008b47b62085357be6a74f178656af5b253ced8f7069`.

La imagen de VROOM contiene una versión de desarrollo. Su uso en esta prueba no implica aprobación para producción.

## Datos cartográficos

- Fuente: https://download.geofabrik.de/europe/spain/navarra.html
- Descarga: https://download.geofabrik.de/europe/spain/navarra-latest.osm.pbf
- Fecha de descarga: 2026-10-18.
- Fecha de los datos indicada por OSRM: `2026-10-17T20:20:51Z`.
- Tamaño aproximado: 36 MB.
- SHA-256 del archivo utilizado:

```text
be1d8bdbf369f04cc421526e853d39065cbc97892d3f83a6d439498d41fcbfb0
```

El enlace `latest` cambia con el tiempo. Una descarga posterior puede tener otra huella y producir resultados diferentes.

El mapa contiene datos de OpenStreetMap y requiere respetar su licencia y atribución:

- © OpenStreetMap contributors.
- https://www.openstreetmap.org/copyright

Los mapas y los archivos generados se almacenan en `data/`, excluido de Git.

## Privacidad

El mapa geográfico es real. Las tareas y los puntos seleccionados para la prueba son sintéticos y no representan entregas reales.

No se utilizarán nombres, teléfonos, etiquetas ni direcciones de destinatarios reales.

Los puertos publicados se limitan a `127.0.0.1`.

## Instalación y arranque de Colima

Instalar las herramientas, si no existen:

```bash
brew install colima docker docker-compose
```

Crear e iniciar el perfil la primera vez:

```bash
colima start riderbiz \
  --vm-type vz \
  --arch aarch64 \
  --runtime docker \
  --cpus 4 \
  --memory 6 \
  --disk 30
```

En sesiones posteriores:

```bash
colima start riderbiz
```

Comprobar el contexto activo:

```bash
docker context show
```

El contexto esperado es `colima-riderbiz`.

## Preparación del mapa

Ejecutar los comandos desde la raíz del repositorio.

```bash
mkdir -p tools/route-optimization/data
```

Descargar el mapa:

```bash
curl --fail --location --retry 3 \
  --output tools/route-optimization/data/navarra-latest.osm.pbf \
  https://download.geofabrik.de/europe/spain/navarra-latest.osm.pbf
```

Registrar la huella de la descarga:

```bash
shasum -a 256 \
  tools/route-optimization/data/navarra-latest.osm.pbf
```

Extraer la red de vehículos:

```bash
docker run --rm \
  --mount "type=bind,source=$PWD/tools/route-optimization/data,target=/data" \
  ghcr.io/project-osrm/osrm-backend@sha256:b0045097b8b4ad5e72dce6b900326cd6ee0e98c729709214e674d0472b463f49 \
  osrm-extract \
  -p /opt/car.lua \
  /data/navarra-latest.osm.pbf
```

Particionar:

```bash
docker run --rm \
  --mount "type=bind,source=$PWD/tools/route-optimization/data,target=/data" \
  ghcr.io/project-osrm/osrm-backend@sha256:b0045097b8b4ad5e72dce6b900326cd6ee0e98c729709214e674d0472b463f49 \
  osrm-partition \
  /data/navarra-latest.osrm
```

Personalizar:

```bash
docker run --rm \
  --mount "type=bind,source=$PWD/tools/route-optimization/data,target=/data" \
  ghcr.io/project-osrm/osrm-backend@sha256:b0045097b8b4ad5e72dce6b900326cd6ee0e98c729709214e674d0472b463f49 \
  osrm-customize \
  /data/navarra-latest.osrm
```

Cada paso debe terminar correctamente antes de ejecutar el siguiente. No reprocesar los archivos mientras OSRM los está utilizando.

## Arranque de servicios

Ejecutar desde la raíz del repositorio:

```bash
docker-compose -f tools/route-optimization/compose.yml config --quiet
docker-compose -f tools/route-optimization/compose.yml up -d --build
docker-compose -f tools/route-optimization/compose.yml ps -a
```

Esperar a que VROOM aparezca como healthy.
depends_on no garantiza que OSRM esté listo para recibir solicitudes.

VROOM utiliza una imagen local derivada de la imagen fijada por digest.
Un parche elimina el registro HTTP de acceso. La construcción falla
si no encuentra exactamente el código esperado del proveedor.
El contexto de construcción incluye únicamente el Dockerfile y el parche.

Ambos servicios utilizan el driver de logs none. Sus registros de stdout
y stderr no quedan disponibles mediante docker logs.
OSRM utiliza además verbosidad WARNING.

Las solicitudes temporales se escriben en /tmp/riderbiz-requests,
montado como tmpfs con un máximo de 16 MiB.
El arranque del proveedor puede crear /conf/access.log vacío;
su existencia no implica que el registro HTTP esté activo.

Véase [RB-ROUTING-007](../../docs/engineering/validation/RB-ROUTING-007-privacy-and-temporary-data.md).

## Comprobación de OSRM

```bash
curl --fail-with-body --max-time 15 \
  'http://127.0.0.1:5000/route/v1/driving/-1.6458,42.8125;-1.6400,42.8100?overview=false'
```

Resultado observado con el mapa documentado:

- `code: "Ok"`.
- Distancia: 997,8 metros.
- Duración estimada: 146,3 segundos.

## Comprobación de VROOM

```bash
curl --fail-with-body --max-time 40 \
  --header 'Content-Type: application/json' \
  --data '{
    "vehicles": [
      {
        "id": 1,
        "profile": "car",
        "start": [-1.6458, 42.8125]
      }
    ],
    "jobs": [
      {
        "id": 1,
        "location": [-1.6400, 42.8100],
        "service": 120
      },
      {
        "id": 2,
        "location": [-1.6350, 42.8150],
        "service": 120
      }
    ]
  }' \
  http://127.0.0.1:3000/
```

Resultado observado:

- `code: 0`.
- Una ruta.
- Dos tareas asignadas.
- Cero tareas sin asignar.
- Sin infracciones declaradas.
- Conducción: 351 segundos.
- Servicio: 240 segundos.
- Espera: cero segundos.
- Total: 591 segundos.

Las coordenadas de las API se expresan como `[longitud, latitud]`.

## Configuración y límites

- VROOM utiliza `geometry: true` para obtener distancias de la ruta y de cada paso.
- En la comprobación de dos tareas se observaron 2.501 metros en total.
- La geometría devuelta no se almacena en el modelo de dominio.
- OSRM utiliza el algoritmo MLD.
- Perfil de circulación: coche.
- Tamaño máximo de tabla OSRM: 250 ubicaciones.
- Límite VROOM: 250 ubicaciones y un vehículo.
- Timeout del servidor VROOM: 30 segundos.
- OSRM: `http://127.0.0.1:5000`.
- VROOM: `http://127.0.0.1:3000`.
- Los contenedores no se reinician automáticamente.

El perfil de coche no valida recorridos peatonales ni restricciones específicas de todas las furgonetas.

## Detención

Detener y retirar los contenedores y la red de esta prueba:

```bash
docker-compose \
  -f tools/route-optimization/compose.yml \
  down
```

Este comando conserva el mapa y los archivos procesados del directorio `data/`.

Detener la máquina virtual para liberar recursos:

```bash
colima stop riderbiz
```

## Alcance y limitaciones actuales

La integración Dart y las pruebas locales de 60, 80 y 120 tareas,
restricciones, recuperación y persistencia cuentan con evidencia en
[RB-SPIKE-021](../../docs/engineering/validation/RB-SPIKE-021-route-optimization-validation.md).

Los resultados corresponden a los escenarios registrados; no acreditan
todas las combinaciones de restricciones ni funcionamiento en producción.
Los grupos peatonales están representados, sin navegación a pie validada.
GraphHopper continúa sin integración ejecutada; su bloqueo está documentado.
Las estimaciones económicas y de recursos tienen alcance preliminar.

La revisión de logs y temporales no acredita borrado forense, ausencia
de copias anteriores ni ausencia de swap.
La Issue #21 permanece abierta y ADR-004 continúa PROPUESTO.
