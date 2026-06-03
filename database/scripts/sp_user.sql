USE bipay;

-- ==========================================================================
-- 1. SP: sp_guardar_usuario
-- Maneja tanto la Creación (ID = 0) como la Edición (ID > 0) de usuarios.
-- Considera si se actualiza o no la contraseña (si llega NULL, la mantiene).
-- Devuelve siempre el registro afectado con un código de éxito para Laravel.
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
        
        -- AJUSTE CRÍTICO: Retorna el usuario recién creado para que el controlador responda con éxito
        SELECT *, 'OK' AS respuesta_codigo FROM usuarios WHERE id = LAST_INSERT_ID();

    ELSE
        -- OPERACIÓN: EDITAR (Mapeado al método editar del controlador)
        -- Si p_contrasena_hash viene NULL significa que el usuario no cambió su clave en el formulario.
        IF p_contrasena_hash IS NULL THEN
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
            -- Si p_contrasena_hash NO es NULL, actualizamos también la clave encriptada.
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
        
        -- AJUSTE CRÍTICO: Retorna el usuario editado para el flujo del controlador
        SELECT *, 'OK' AS respuesta_codigo FROM usuarios WHERE id = p_id;
        
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
    
    -- Retorno opcional de confirmación para evitar advertencias de ejecución vacía
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
    
    -- Retorno de confirmación para mutaciones de borrado
    SELECT p_id AS id, 'OK' AS respuesta_codigo;
END$$
DELIMITER ;