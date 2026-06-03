DROP DATABASE IF EXISTS bipay;
CREATE DATABASE bipay CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE bipay;

-- ==========================================
-- 1. ESTADOS
-- ==========================================
CREATE TABLE estados (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(255) NULL,
    permite_modificar TINYINT(1) DEFAULT 1,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO estados (nombre, descripcion, permite_modificar) VALUES
('PENDIENTE', 'La transacción ha sido iniciada pero no procesada', 1),
('EXITOSO', 'El pago fue procesado correctamente por la pasarela', 1),
('FALLIDO', 'La pasarela rechazó el pago (no descuenta saldo)', 0),
('REEMBOLSADO', 'El dinero fue devuelto al cliente. Transacción deshabilitada', 0);


-- ==========================================
-- 2. PERSONAS (Nueva Tabla - Datos Básicos)
-- ==========================================
CREATE TABLE personas (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) NULL,
    activo TINYINT(1) DEFAULT 1,
    creado_por VARCHAR(100) NULL,
    actualizado_por VARCHAR(100) NULL,
    fecha_eliminacion DATETIME NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Insert de prueba para la persona del administrador
INSERT INTO personas (id, nombre, apellido, telefono, creado_por) VALUES
(1, 'Super', 'Admin', '123456789', 'SISTEMA');


-- ==========================================
-- 3. USUARIOS (Credenciales y Acceso)
-- ==========================================
CREATE TABLE usuarios (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    persona_id BIGINT NOT NULL, 
    usuario VARCHAR(100) NOT NULL UNIQUE,
    correo VARCHAR(150) NOT NULL UNIQUE,
    contrasena_hash VARCHAR(255) NOT NULL,
    activo TINYINT(1) DEFAULT 1,         
    ultimo_acceso DATETIME NULL,
    creado_por VARCHAR(100) NULL,
    actualizado_por VARCHAR(100) NULL,
    fecha_eliminacion DATETIME NULL,     
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_usuario_persona FOREIGN KEY (persona_id) REFERENCES personas(id)
);

-- Insert de prueba para el usuario administrador vinculado a la persona ID 1
INSERT INTO usuarios (persona_id, usuario, correo, contrasena_hash, creado_por) VALUES
(1, 'admin', 'admin@bipay.local', '$2y$12$cl31fA3o5M8nclQGq3lQeexM5D/1X3v6Z8n6w/p3R2N6lO2oBbeo6', 'SISTEMA');


-- ==========================================
-- 4. TRANSACCIONES
-- ==========================================
CREATE TABLE transacciones (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_solicitud VARCHAR(100) NOT NULL UNIQUE,     
    id_transaccion_pasarela VARCHAR(100) NULL,     
    persona_id BIGINT NOT NULL,      
    monto DECIMAL(12,2) NOT NULL,
    otp VARCHAR(20) NULL,
    estado_id INT DEFAULT 1, 
    codigo_respuesta VARCHAR(20) NULL,            
    descripcion TEXT NULL,
    activo TINYINT(1) DEFAULT 1,         
    creado_por VARCHAR(100) NOT NULL,                    
    actualizado_por VARCHAR(100) NULL,                  
    fecha_eliminacion DATETIME NULL,    
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_id_solicitud(id_solicitud),
    INDEX idx_id_pasarela(id_transaccion_pasarela),
    CONSTRAINT fk_transaccion_persona FOREIGN KEY (persona_id) REFERENCES personas(id),
    CONSTRAINT fk_transaccion_estado FOREIGN KEY (estado_id) REFERENCES estados(id)
);


-- ==========================================
-- 5. REEMBOLSOS
-- ==========================================
CREATE TABLE reembolsos (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    transaccion_id BIGINT NOT NULL,                
    id_solicitud_reembolso VARCHAR(100) NOT NULL UNIQUE,
    estado_id INT DEFAULT 1,
    codigo_respuesta VARCHAR(20) NULL,             
    motivo TEXT NULL,                               
    activo TINYINT(1) DEFAULT 1,        
    creado_por VARCHAR(100) NOT NULL,                    
    actualizado_por VARCHAR(100) NULL,                   
    fecha_eliminacion DATETIME NULL,    
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_reembolso_transaccion FOREIGN KEY (transaccion_id) REFERENCES transacciones(id),
    CONSTRAINT fk_reembolso_estado FOREIGN KEY (estado_id) REFERENCES estados(id)
);

SHOW TABLES;