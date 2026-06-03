<p align="center">
  <img src="https://raw.githubusercontent.com/laravel/art/master/logo-lockup/5%20SVG/2%20CMYK/1%20Full%20Color/laravel-logolockup-cmyk-red.svg" width="350" alt="Laravel Logo">
</p>

# 🚀 BiPay Manager - API REST (Backend)

¡Bienvenido al repositorio oficial del backend de **BiPay Manager**! Esta es una API REST robusta, ágil y minimalista construida sobre el framework **Laravel**, diseñada específicamente para la integración, procesamiento y gestión de transacciones y reembolsos a través de la pasarela de pagos.

---

## 📋 ¿En qué consiste el proyecto?

Este sistema actúa como el núcleo de operaciones financieras y de autenticación para la plataforma BiPay. Su arquitectura está optimizada mediante un enfoque híbrido: la lógica de negocios pesada, mutaciones y consultas masivas se procesan directamente en la base de datos a través de **Stored Procedures (Procedimientos Almacenados)** optimizados en MySQL, mientras que Laravel gestiona la capa de transporte HTTP, el formateo automático de datos, los registros de auditoría de entrada y el blindaje de seguridad mediante tokens criptográficos.

### 🛡️ Características principales:
- **Autenticación Segura:** Control de acceso y protección de endpoints mediante tokens nativos con **Laravel Sanctum**.
- **Arquitectura Basada en Procedimientos:** Reducción de la latencia en base de datos delegando las operaciones CRUD a Stored Procedures (`sp_guardar_usuario`, `sp_listar_reembolsos`, etc.).
- **Borrado Lógico Integrado:** Soporte nativo para bajas lógicas (`fecha_eliminacion`) en los módulos de Usuarios, Transacciones y Reembolsos para garantizar la integridad histórica de los datos.
- **Respuestas Estandarizadas:** Control estricto de códigos de estado HTTP (ej: `210` para nuevos registros y `200` para modificaciones exitosas).

---

## ⚙️ Requisitos del Sistema

Antes de comenzar con la instalación, asegúrate de contar con el siguiente entorno configurado en tu servidor o máquina local:

- **PHP:** `^8.2` o superior (Requisito indispensable para las últimas características del framework).
- **Gestor de Dependencias:** [Composer](https://getcomposer.org/) v2.x.
- **Base de Datos:** MySQL v8.0 o MariaDB equivalente.
- **Extensiones de PHP requeridas:** `openssl`, `pdo_mysql`, `mbstring`, `xml`, `ctype`.

---

## 🛠️ Proceso de Instalación y Configuración

Sigue estos pasos detallados en tu terminal para clonar, instalar y desplegar el proyecto en tu entorno local:

### 1. Clonar el repositorio
Si estás configurando una nueva máquina, clona el proyecto (si ya estás dentro de la carpeta raíz, salta este paso):
```bash
git clone [https://github.com/mmenaaguilar/backend-paymgate.git](https://github.com/mmenaaguilar/backend-paymgate.git)
cd backend-paymgate