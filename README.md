# TFM: Sistema externo de autenticación y gestión de secretos

## Descripción

Este repositorio contiene la implementación del Trabajo Fin de Máster (TFM) titulado **"Sistema Externo de Autenticación y Gestión de Credenciales"**, que propone una capa de seguridad externa para aplicaciones sin sistemas nativos de autenticación. Utiliza **Keycloak** para la gestión de identidad y acceso, y **Vault** para la gestión segura de secretos, todo orquestado con **Docker**, **Docker Compose** y desplegado de forma automática mediante **Terraform**.

## Características

- Gestión centralizada de usuarios, roles y permisos mediante Keycloak (OpenID Connect, OAuth2, SSO).
- Almacenamiento y gestión de secretos dinámicos y estáticos con Vault (AppRole, tokens, políticas de acceso).
- Despliegue en contenedores Docker y aislamiento de servicios para entornos reproducibles.
- Orquestación de servicios con Docker Compose, incluyendo init-containers para la inicialización de Vault.
- Automatización de la infraestructura como código (IaC) usando Terraform.

## Arquitectura del sistema

```
[Aplicación Cliente] <-- OIDC/OpenID Connect --> [Keycloak]
                                  |
                                  v
                           [Vault (Secrets)]
                                  |
                                  v
                   [Almacenamiento (PostgreSQL, Backends)]
```

- Keycloak actúa como Identity Provider (IdP) y Authorization Server.
- Vault maneja secretos, credenciales dinámicas y proporciona cifrado como servicio.
- Terraform define y provisiona contenedores, redes y volúmenes.

## Tecnologías

- **Keycloak**: Servidor de autenticación y autorización.
- **HashiCorp Vault**: Gestión de secretos y cifrado.
- **Docker** / **Docker Compose**: Contenerización y orquestación local.
- **Terraform**: Infraestructura como código.
- **PostgreSQL**: Base de datos para Keycloak.
- **OpenID Connect (OIDC)** y **OAuth2**: Protocolos de autenticación/ autorización.

## Requisitos previos

- Docker >= 20.x
- Docker Compose >= 1.29.x
- Terraform >= 1.0.x
- Acceso a terminal/bash

## Instalación y despliegue

1. Clona el repositorio:
   ```bash
   git clone https://github.com/tu-usuario/GutHub.git
   cd TFM
   ```
2. Inicializa y arranca servicios con Docker Compose:
   ```bash
   docker-compose up -d
   ```
3. Aplica la infraestructura declarada en Terraform:
   ```bash
   cd infrastructure
   terraform init
   terraform apply
   ```

## Estructura del repositorio

```
├── app-home/           # Aplicación cliente de ejemplo y recursos asociados
├── db/                 # Configuración y datos de la base de datos
├── doc/                # Documentación adicional y artefactos (diagramas, informes)
├── keycloak/           # Configuración de Keycloak y adaptaciones
├── linear-regression/  # Ejemplo de integración con regresión lineal
├── logistic-regression/ # Ejemplo de integración con regresión logística
├── random-forest/      # Ejemplo de integración con Random Forest
├── vault/              # Configuración de Vault y políticas
├── .gitignore
├── README.md
├── docker-compose.yml
├── init.tf             # Módulo inicial de Terraform
├── locals.tf           # Variables locales de Terraform
├── terraform.tfvars    # Valores de variables para Terraform
└── variables.tf        # Definición de variables de Terraform
```
