# RB-UI-001 — Dashboard inicial e icono Android

## Referencias

Diseños: RiderBiz_App_UI_v1.0_APPROVED, en Google Drive:
https://drive.google.com/drive/folders/1o_FB3fdYzk4vOs0GNk6VJmGUGDve8giU

Iconos: 03_APP_WEB_ICONS de RiderBiz_Corporate_Identity_v1.3.2_PRODUCTION_FINAL.

## Implementación

- Dashboard activado con --dart-define=APPROVED_UI=true.
- El arranque habitual de validación se mantiene sin esa opción.
- Lectura del progreso sintético y de los importes EUR guardados.
- Actualización al regresar de otra pantalla.
- Acceso a validaciones locales y prueba de rutas.
- Tema compartido para el arranque de UI aprobada.
- Contenido con ancho máximo de 840 píxeles lógicos.
- Nombre visible RiderBiz e iconos Android convencionales, adaptativos y monocromáticos.
- Inyección de base de datos para pruebas; la pantalla no cierra una conexión proporcionada externamente.

## Validación

- Tres pruebas específicas superadas: progreso y actualización tras navegación a anchuras de 390 y 1000, y estado vacío sin creación de paquetes.
- Flutter analyze sin incidencias.
- Suite habitual: 254 pruebas superadas y 23 pruebas locales omitidas.
- git diff --check sin incidencias.
- Dashboard y sus dos accesos comprobados manualmente en Samsung SM-X210.
- Icono y nombre RiderBiz observados en el lanzador de Android.

## Límites y pendientes

- Implementación inicial basada en la composición aprobada; fidelidad visual final, tipografía y tokens exactos pendientes de contraste con la marca.
- Finanzas, informes y perfil muestran un aviso de función pendiente.
- Operaciones abre las validaciones actuales.
- El paquete mostrado sigue el orden de identificadores, no la ruta aceptada.
- El tiempo no se mide; los importes corresponden a datos sintéticos.
- Las pruebas de anchura no sustituyen una auditoría de accesibilidad ni cubren todas las escalas de texto.
- Confirmación manual de conservación del progreso tras actualizar el icono pendiente de registrar.
- Pruebas persistentes y contables de 100–150 paquetes pendientes.
- La issue #21 permanece abierta; ADR-004 no cambia de estado.
