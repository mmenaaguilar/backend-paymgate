USE bipay;

-- ==========================================================================
-- 1. SP: sp_guardar_usuario
-- Mapeado a los métodos: register() [p_id = 0] y editar() [p_id > 0]
-- Si p_contrasena_hash llega NULL al editar, la contraseña actual se mantiene intacta.
-- ==========================================================================
DROP PROCEDURE IF EXISTS sp_guardar_usuario;
DELIMITER $$

CREATE PROCEDURE sp_guardar_usuario(
    IN p_id BIGINT,
    IN p_usuario VARCHAR(100),
    IN p_correo VARCHAR(150),
    IN p_contrasena_hash VARCHAR(255),
    IN p_nombre VARCHAR(100),
    IN p_apellido VARCHAR(100),
    IN p_telefono VARCHAR(20),
    IN p_activo TINYINT(1),
    IN p_usuario_activo VARCHAR(100)
)
BEGIN
    -- Determinar si es Creación o Edición
    IF p_id = 0 THEN
        -- OPERACIÓN: CREAR (Mapeado al método register del controlador)
        INSERT INTO usuarios (
            usuario, 
            correo, 
            contrasena_hash, 
            nombre, 
            apellido, 
            telefono, 
            activo, 
            creado_por
        )
        VALUES (
            p_usuario, 
            p_correo, 
            p_contrasena_hash, 
            p_nombre, 
            p_apellido, 
            p_telefono, 
            p_activo, 
            p_usuario_activo
        );
        
        -- Retorna el usuario recién creado especificando el alias u.*
        SELECT u.*, 'OK' AS respuesta_codigo 
        FROM usuarios u 
        WHERE u.id = LAST_INSERT_ID();

    ELSE
        -- OPERACIÓN: EDITAR (Mapeado al método editar del controlador)
        IF p_contrasena_hash IS NULL OR p_contrasena_hash = '' THEN
            -- Si no se envía contraseña, se actualizan solo los datos básicos
            UPDATE usuarios 
            SET usuario = p_usuario,
                correo = p_correo,
                nombre = p_nombre,
                apellido = p_apellido,
                telefono = p_telefono,
                activo = p_activo,
                actualizado_por = p_usuario_activo
            WHERE id = p_id;
        ELSE
            -- Si se envía una nueva contraseña (encriptada desde Laravel), se actualiza
            UPDATE usuarios 
            SET usuario = p_usuario,
                correo = p_correo,
                contrasena_hash = p_contrasena_hash,
                nombre = p_nombre,
                apellido = p_apellido,
                telefono = p_telefono,
                activo = p_activo,
                actualizado_por = p_usuario_activo
            WHERE id = p_id;
        END IF;
        
        -- Retorna el usuario modificado especificando el alias u.*
        SELECT u.*, 'OK' AS respuesta_codigo 
        FROM usuarios u 
        WHERE u.id = p_id;
        
    END IF;
END$$
DELIMITER ;


-- ==========================================================================
-- 2. SP: sp_obtener_usuario_por_credencial
-- Busca al usuario por su nickname o por su correo electrónico para el Login.
-- ==========================================================================
DROP PROCEDURE IF EXISTS sp_obtener_usuario_por_credencial;
DELIMITER $$

CREATE PROCEDURE sp_obtener_usuario_por_credencial(
    IN p_usuario_o_correo VARCHAR(150)
)
BEGIN
    SELECT id, usuario, correo, contrasena_hash, nombre, apellido, activo, fecha_eliminacion
    FROM usuarios
    WHERE (usuario = p_usuario_o_correo OR correo = p_usuario_o_correo)
    LIMIT 1;
END$$
DELIMITER ;


-- ==========================================================================
-- 3. SP: sp_registrar_ultimo_acceso
-- Almacena la marca de tiempo exacta de la última vez que el usuario se logueó.
-- ==========================================================================
DROP PROCEDURE IF EXISTS sp_registrar_ultimo_acceso;
DELIMITER $$

CREATE PROCEDURE sp_registrar_ultimo_acceso(
    IN p_id BIGINT,
    IN p_usuario_activo VARCHAR(100)
)
BEGIN
    UPDATE usuarios 
    SET ultimo_acceso = NOW(),
        actualizado_por = p_usuario_activo
    WHERE id = p_id;
    
    SELECT p_id AS id, 'OK' AS respuesta_codigo;
END$$
DELIMITER ;


-- ==========================================================================
-- 4. SP: sp_eliminar_usuario
-- Realiza el borrado lógico del usuario apagando su bandera y guardando la fecha.
-- ==========================================================================
DROP PROCEDURE IF EXISTS sp_eliminar_usuario;
DELIMITER $$

CREATE PROCEDURE sp_eliminar_usuario(
    IN p_id BIGINT,
    IN p_usuario_activo VARCHAR(100)
)
BEGIN
    UPDATE usuarios 
    SET activo = 0,
        fecha_eliminacion = NOW(),
        actualizado_por = p_usuario_activo
    WHERE id = p_id;
    
    SELECT p_id AS id, 'OK' AS respuesta_codigo;
END$$
DELIMITER ;