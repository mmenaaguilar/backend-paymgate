USE bipay;

-- ==========================================================================
-- 1. SP: sp_guardar_usuario
-- Mapeado a los métodos: register() [p_id = 0] y editar() [p_id > 0]
-- Inserta/Actualiza en la tabla 'personas' y luego en 'usuarios' de forma transaccional.
-- ==========================================================================
DROP PROCEDURE IF EXISTS sp_guardar_usuario;
DELIMITER $$

CREATE PROCEDURE sp_guardar_usuario(
    IN p_id BIGINT,                     -- ID del usuario (0 para crear, >0 para editar)
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
    -- Declarar variable interna para capturar la relación
    DECLARE v_persona_id BIGINT;

    -- Control de errores: Si algo falla, se deshace todo (Rollback)
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error en la transacción de sp_guardar_usuario';
    END;

    START TRANSACTION;

    IF p_id = 0 THEN
        -- ==================================================================
        -- OPERACIÓN: CREAR
        -- ==================================================================
        
        -- 1. Insertar primero los datos reales de la persona
        INSERT INTO personas (
            nombre,
            apellido,
            telefono,
            creado_por
        )
        VALUES (
            p_nombre,
            p_apellido,
            p_telefono,
            p_usuario_activo
        );

        -- 2. Rescatar el ID generado para esa persona
        SET v_persona_id = LAST_INSERT_ID();

        -- 3. Insertar las credenciales vinculadas en la tabla usuarios
        INSERT INTO usuarios (
            persona_id,
            usuario, 
            correo, 
            contrasena_hash, 
            activo, 
            creado_por
        )
        VALUES (
            v_persona_id,
            p_usuario, 
            p_correo, 
            p_contrasena_hash, 
            p_activo, 
            p_usuario_activo
        );
        
        COMMIT;

        -- Retorna el resultado unificado
        SELECT u.*, p.nombre, p.apellido, p.telefono, 'OK' AS respuesta_codigo 
        FROM usuarios u
        INNER JOIN personas p ON u.persona_id = p.id
        WHERE u.id = LAST_INSERT_ID();

    ELSE
        -- ==================================================================
        -- OPERACIÓN: EDITAR
        -- ==================================================================
        
        -- 1. Obtener el persona_id asignado a este usuario
        SELECT persona_id INTO v_persona_id FROM usuarios WHERE id = p_id;

        -- 2. Actualizar los datos de la Persona
        UPDATE personas 
        SET nombre = p_nombre,
            apellido = p_apellido,
            telefono = p_telefono,
            actualizado_por = p_usuario_activo
        WHERE id = v_persona_id;

        -- 3. Actualizar los datos de seguridad del Usuario
        IF p_contrasena_hash IS NULL OR p_contrasena_hash = '' THEN
            UPDATE usuarios 
            SET usuario = p_usuario,
                correo = p_correo,
                activo = p_activo,
                actualizado_por = p_usuario_activo
            WHERE id = p_id;
        ELSE
            UPDATE usuarios 
            SET usuario = p_usuario,
                correo = p_correo,
                contrasena_hash = p_contrasena_hash,
                activo = p_activo,
                actualizado_por = p_usuario_activo
            WHERE id = p_id;
        END IF;
        
        COMMIT;

        -- Retorna la información actualizada
        SELECT u.*, p.nombre, p.apellido, p.telefono, 'OK' AS respuesta_codigo 
        FROM usuarios u
        INNER JOIN personas p ON u.persona_id = p.id
        WHERE u.id = p_id;
        
    END IF;
END$$
DELIMITER ;


-- ==========================================================================
-- 2. SP: sp_obtener_usuario_por_credencial
-- Mapeado al Login. Busca por nick o correo trayendo los datos de su Persona.
-- ==========================================================================
DROP PROCEDURE IF EXISTS sp_obtener_usuario_por_credencial;
DELIMITER $$

CREATE PROCEDURE sp_obtener_usuario_por_credencial(
    IN p_usuario_o_correo VARCHAR(150)
)
BEGIN
    SELECT u.id, u.persona_id, u.usuario, u.correo, u.contrasena_hash, 
           p.nombre, p.apellido, u.activo, u.fecha_eliminacion
    FROM usuarios u
    INNER JOIN personas p ON u.persona_id = p.id
    WHERE (u.usuario = p_usuario_o_correo OR u.correo = p_usuario_o_correo)
    LIMIT 1;
END$$
DELIMITER ;


-- ==========================================================================
-- 3. SP: sp_registrar_ultimo_acceso
-- Almacena la marca de tiempo exacta del inicio de sesión.
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
-- Realiza el borrado lógico del usuario.
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