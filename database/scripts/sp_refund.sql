USE bipay;

-- ==========================================================================
-- 1. SP: sp_listar_reembolsos
-- Mapeado al método: index()
-- Soporta filtros por rango de fechas, estado_id, activo y código de solicitud.
-- ==========================================================================
DROP PROCEDURE IF EXISTS sp_listar_reembolsos;
DELIMITER $$

CREATE PROCEDURE sp_listar_reembolsos(
    IN p_fecha_inicio DATETIME,
    IN p_fecha_fin DATETIME,
    IN p_estado_id INT,
    IN p_id_solicitud_reembolso VARCHAR(100),
    IN p_activo TINYINT(1),
    IN p_usuario_activo VARCHAR(100)
)
BEGIN
    SELECT r.*, e.nombre AS estado_nombre, t.monto AS transaccion_monto, t.nombre_cliente
    FROM reembolsos r
    LEFT JOIN estados e ON r.estado_id = e.id
    LEFT JOIN transacciones t ON r.transaccion_id = t.id
    WHERE (r.activo = p_activo)
      AND (p_fecha_inicio IS NULL OR r.fecha_creacion >= p_fecha_inicio)
      AND (p_fecha_fin IS NULL OR r.fecha_creacion <= p_fecha_fin)
      AND (p_estado_id IS NULL OR r.estado_id = p_estado_id)
      AND (p_id_solicitud_reembolso IS NULL OR p_id_solicitud_reembolso = '' OR r.id_solicitud_reembolso LIKE CONCAT('%', p_id_solicitud_reembolso, '%'))
    ORDER BY r.id DESC;
END$$
DELIMITER ;


-- ==========================================================================
-- 2. SP: sp_buscar_reembolso
-- Mapeado al método: show($id)
-- Obtiene un reembolso específico por su ID primario.
-- ==========================================================================
DROP PROCEDURE IF EXISTS sp_buscar_reembolso;
DELIMITER $$

CREATE PROCEDURE sp_buscar_reembolso(
    IN p_id BIGINT,
    IN p_usuario_activo VARCHAR(100)
)
BEGIN
    SELECT r.*, e.nombre AS estado_nombre, t.monto AS transaccion_monto, t.nombre_cliente
    FROM reembolsos r
    LEFT JOIN estados e ON r.estado_id = e.id
    LEFT JOIN transacciones t ON r.transaccion_id = t.id
    WHERE r.id = p_id 
    LIMIT 1;
END$$
DELIMITER ;


-- ==========================================================================
-- 3. SP: sp_guardar_reembolso
-- Mapeado al método: guardar()
-- Maneja la creación (ID = 0) y edición (ID > 0) de reembolsos.
-- Incluye la columna 'respuesta_codigo' con 'OK' requerida por tu BaseController.
-- ==========================================================================
DROP PROCEDURE IF EXISTS sp_guardar_reembolso;
DELIMITER $$

CREATE PROCEDURE sp_guardar_reembolso(
    IN p_id BIGINT,
    IN p_transaccion_id BIGINT,
    IN p_id_solicitud_reembolso VARCHAR(100),
    IN p_estado_id INT,
    IN p_codigo_respuesta VARCHAR(50),
    IN p_motivo TEXT,
    IN p_activo TINYINT(1),
    IN p_usuario_activo VARCHAR(100)
)
BEGIN
    IF p_id = 0 THEN
        -- OPERACIÓN: CREAR REEMBOLSO
        INSERT INTO reembolsos (
            transaccion_id,
            id_solicitud_reembolso,
            estado_id,
            codigo_respuesta,
            motivo,
            activo,
            creado_por
        )
        VALUES (
            p_transaccion_id,
            p_id_solicitud_reembolso,
            p_estado_id,
            p_codigo_respuesta,
            p_motivo,
            p_activo,
            p_usuario_activo
        );
        
        -- Retorna la fila recién creada especificando la tabla origen r.* para evitar conflictos
        SELECT r.*, 'OK' AS respuesta_codigo 
        FROM reembolsos r 
        WHERE r.id = LAST_INSERT_ID();

    ELSE
        -- OPERACIÓN: EDITAR / ACTUALIZAR REEMBOLSO
        UPDATE reembolsos
        SET transaccion_id = p_transaccion_id,
            id_solicitud_reembolso = p_id_solicitud_reembolso,
            estado_id = p_estado_id,
            codigo_respuesta = p_codigo_respuesta,
            motivo = p_motivo,
            activo = p_activo,
            actualizado_por = p_usuario_activo
        WHERE id = p_id;
        
        -- Retorna la fila modificada
        SELECT r.*, 'OK' AS respuesta_codigo 
        FROM reembolsos r 
        WHERE r.id = p_id;
    END IF;
END$$
DELIMITER ;


-- ==========================================================================
-- 4. SP: sp_eliminar_reembolso
-- Mapeado al método: destroy($id)
-- Realiza el borrado lógico o anulación del registro de reembolso.
-- ==========================================================================
DROP PROCEDURE IF EXISTS sp_eliminar_reembolso;
DELIMITER $$

CREATE PROCEDURE sp_eliminar_reembolso(
    IN p_id BIGINT,
    IN p_usuario_activo VARCHAR(100)
)
BEGIN
    UPDATE reembolsos 
    SET activo = 0,
        fecha_eliminacion = NOW(),
        actualizado_por = p_usuario_activo
    WHERE id = p_id;
    
    -- Retorna confirmación estructurada
    SELECT p_id AS id, 'OK' AS respuesta_codigo;
END$$
DELIMITER ;