# RB-DEV-001 · Configuración del entorno de desarrollo

## Estado del documento

- Proyecto: RiderBiz V1
- Tipo: fundamento de ingeniería
- Estado: inicial
- Entorno validado: Mac mini M2
- Arquitectura: Apple Silicon arm64

## 1. Objetivo

Este documento registra la configuración mínima utilizada para iniciar el desarrollo profesional de RiderBiz V1.

Su finalidad es permitir que el entorno pueda comprobarse, reproducirse y evolucionar sin depender de conocimiento informal.

## 2. Principios de seguridad

- No almacenar contraseñas en el repositorio.
- No almacenar claves SSH privadas.
- No almacenar códigos de recuperación.
- No almacenar tokens de acceso.
- No utilizar datos personales reales durante el desarrollo.
- Mantener los secretos fuera de Git y GitHub.

## 3. Sistema base validado

El entorno inicial utiliza:

- macOS 26.6.
- Arquitectura arm64.
- Mac mini con Apple Silicon.
- Xcode completo como entorno activo.
- Git integrado con las herramientas de Apple.

## 4. Comprobación del sistema

```bash
sw_vers
uname -m
