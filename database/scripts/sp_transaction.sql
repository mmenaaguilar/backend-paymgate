USE bipay;

-- ==========================================================================
-- 1. SP: sp_listar_transacciones
-- Mapeado al método: index()
-- Soporta filtros por rango de fechas, estado_id, activo y término general 
-- cruzando con la información real de la tabla 'personas'.
-- ==========================================================================
DROP PROCEDURE IF EXISTS sp_listar_transacciones;
DELIMITER $$

CREATE PROCEDURE sp_listar_transacciones(
    IN p_fecha_inicio DATETIME,
    IN p_fecha_fin DATETIME,
    IN p_estado_id INT,
    IN p_termino_busqueda VARCHAR(150),
    IN p_activo TINYINT(1),
    IN p_usuario_activo VARCHAR(100)
)
BEGIN
    SELECT t.*, 
           e.nombre AS estado_nombre,
           p.nombre AS cliente_nombre,
           p.apellido AS cliente_apellido,
           p.telefono AS cliente_telefono
    FROM transacciones t
    LEFT JOIN estados e ON t.estado_id = e.id
    INNER JOIN personas p ON t.persona_id = p.id
    WHERE (t.activo = p_activo)
      AND (p_fecha_inicio IS NULL OR t.fecha_creacion >= p_fecha_inicio)
      AND (p_fecha_fin IS NULL OR t.fecha_creacion <= p_fecha_fin)
      AND (p_estado_id IS NULL OR t.estado_id = p_estado_id)
      AND (
          p_termino_busqueda = '' 
          OR t.id_solicitud LIKE CONCAT('%', p_termino_busqueda, '%')
          OR p.nombre LIKE CONCAT('%', p_termino_busqueda, '%')
          OR p.apellido LIKE CONCAT('%', p_termino_busqueda, '%')
          OR p.telefono LIKE CONCAT('%', p_termino_busqueda, '%')
      )
    ORDER BY t.id DESC;
END$$
DELIMITER ;


-- ==========================================================================
-- 2. SP: sp_buscar_transaccion
-- Mapeado al método: show($id)
-- Obtiene una transacción específica incluyendo los datos personales de la relación.
-- ==========================================================================
DROP PROCEDURE IF EXISTS sp_buscar_transaccion;
DELIMITER $$

CREATE PROCEDURE sp_buscar_transaccion(
    IN p_id BIGINT,
    IN p_usuario_activo VARCHAR(100)
)
BEGIN
    SELECT t.*, 
           e.nombre AS estado_nombre,
           p.nombre AS cliente_nombre,
           p.apellido AS cliente_apellido,
           p.telefono AS cliente_telefono
    FROM transacciones t
    LEFT JOIN estados e ON t.estado_id = e.id
    INNER JOIN personas p ON t.persona_id = p.id
    WHERE t.id = p_id 
    LIMIT 1;
END$$
DELIMITER ;


-- ==========================================================================
-- 3. SP: sp_guardar_transaccion
-- Mapeado al método: guardar()
-- Guarda y edita ÚNICAMENTE el persona_id directo en la transacción (Simplificado).
-- No crea ni modifica registros en la tabla personas.
-- ==========================================================================
DROP PROCEDURE IF EXISTS sp_guardar_transaccion;
DELIMITER $$

CREATE PROCEDURE sp_guardar_transaccion(
    IN p_id BIGINT,
    IN p_persona_id BIGINT,                  -- ID de la persona ya existente en el sistema
    IN p_id_solicitud VARCHAR(100),
    IN p_id_transaccion_pasarela VARCHAR(150),
    IN p_monto DECIMAL(10,2),
    IN p_otp VARCHAR(10),
    IN p_estado_id INT,
    IN p_codigo_respuesta VARCHAR(50),
    IN p_descripcion TEXT,
    IN p_activo TINYINT(1),
    IN p_usuario_activo VARCHAR(100)
)
BEGIN
    -- Manejo de Excepciones de Base de Datos (Garantiza el ROLLBACK)
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error interno en el SP sp_guardar_transaccion';
    END;

    START TRANSACTION;

    IF p_id = 0 THEN
        -- OPERACIÓN: CREAR TRANSACCIÓN (Inserta el ID recibido directo)
        INSERT INTO transacciones (
            persona_id,
            id_solicitud,
            id_transaccion_pasarela,
            monto,
            otp,
            estado_id,
            codigo_respuesta,
            descripcion,
            activo,
            creado_por
        )
        VALUES (
            p_persona_id,
            p_id_solicitud,
            p_id_transaccion_pasarela,
            p_monto,
            p_otp,
            p_estado_id,
            p_codigo_respuesta,
            p_descripcion,
            p_activo,
            p_usuario_activo
        );
        
        COMMIT;
        
        -- Retorna fila recién creada vinculada con la persona mediante INNER JOIN
        SELECT t.*, p.nombre AS cliente_nombre, p.apellido AS cliente_apellido, p.telefono AS cliente_telefono, 'OK' AS respuesta_codigo 
        FROM transacciones t
        INNER JOIN personas p ON t.persona_id = p.id
        WHERE t.id = LAST_INSERT_ID();

    ELSE
        -- OPERACIÓN: EDITAR / ACTUALIZAR TRANSACCIÓN (Actualiza los campos de la transacción)
        UPDATE transacciones
        SET persona_id = p_persona_id,
            id_solicitud = p_id_solicitud,
            id_transaccion_pasarela = p_id_transaccion_pasarela,
            monto = p_monto,
            otp = p_otp,
            estado_id = p_estado_id,
            codigo_respuesta = p_codigo_respuesta,
            descripcion = p_descripcion,
            activo = p_activo,
            actualizado_por = p_usuario_activo
        WHERE id = p_id;
        
        COMMIT;
        
        -- Retorna la fila modificada cruzada con su respectiva persona
        SELECT t.*, p.nombre AS cliente_nombre, p.apellido AS cliente_apellido, p.telefono AS cliente_telefono, 'OK' AS respuesta_codigo 
        FROM transacciones t
        INNER JOIN personas p ON t.persona_id = p.id
        WHERE t.id = p_id;
    END IF;
END$$
DELIMITER ;


-- ==========================================================================
-- 4. SP: sp_eliminar_transaccion
-- Mapeado al método: destroy($id)
-- Realiza el borrado lógico o anulación de la transacción de pago.
-- ==========================================================================
DROP PROCEDURE IF EXISTS sp_eliminar_transaccion;
DELIMITER $$

CREATE PROCEDURE sp_eliminar_transaccion(
    IN p_id BIGINT,
    IN p_usuario_activo VARCHAR(100)
)
BEGIN
    UPDATE transacciones 
    SET activo = 0,
        fecha_eliminacion = NOW(),
        actualizado_por = p_usuario_activo
    WHERE id = p_id;
    
    SELECT p_id AS id, 'OK' AS respuesta_codigo;
END$$
DELIMITER ;


-- ==========================================================================
-- 5. SP: sp_procesar_reembolso_transaccion
-- Mapeado al método: cambiarEstadoReembolsado()
-- Cambia directamente el estado_id a 4 (Reembolsado) e inserta el historial.
-- ==========================================================================
DROP PROCEDURE IF EXISTS sp_procesar_reembolso_transaccion;
DELIMITER $$

CREATE PROCEDURE sp_procesar_reembolso_transaccion(
    IN p_transaccion_id BIGINT,
    IN p_id_solicitud_reembolso VARCHAR(100),
    IN p_motivo TEXT,
    IN p_usuario_activo VARCHAR(100)
)
BEGIN
    START TRANSACTION;
    
    UPDATE transacciones 
    SET estado_id = 4, 
        actualizado_por = p_usuario_activo
    WHERE id = p_transaccion_id;
    
    INSERT INTO reembolsos (
        transaccion_id,
        id_solicitud_reembolso,
        motivo,
        creado_por
    )
    VALUES (
        p_transaccion_id,
        p_id_solicitud_reembolso,
        p_motivo,
        p_usuario_activo
    );
    
    COMMIT;
    
    SELECT p_transaccion_id AS id, 'OK' AS respuesta_codigo;
END$$
DELIMITER ;


-- ==========================================================================
-- 6. SP: sp_listar_transacciones_por_persona
-- Mapeado al Historial de compras por cliente en React con filtros avanzados.
-- Filtra obligatoriamente por persona_id, y permite búsquedas secundarias por 
-- rango de fechas, estado, activo y término general (dentro de sus propias compras).
-- ==========================================================================
DROP PROCEDURE IF EXISTS sp_listar_transacciones_por_persona;
DELIMITER $$

CREATE PROCEDURE sp_listar_transacciones_por_persona(
    IN p_persona_id BIGINT,                  -- ◄ Filtro obligatorio del cliente
    IN p_fecha_inicio DATETIME,              -- Filtros secundarios opcionales
    IN p_fecha_fin DATETIME,
    IN p_estado_id INT,
    IN p_termino_busqueda VARCHAR(150),
    IN p_activo TINYINT(1),
    IN p_usuario_activo VARCHAR(100)
)
BEGIN
    SELECT t.*, 
           e.nombre AS estado_nombre,
           p.nombre AS cliente_nombre,
           p.apellido AS cliente_apellido,
           p.telefono AS cliente_telefono
    FROM transacciones t
    LEFT JOIN estados e ON t.estado_id = e.id
    INNER JOIN personas p ON t.persona_id = p.id
    WHERE (t.persona_id = p_persona_id)      -- ◄ Candado de pertenencia forzoso
      AND (t.activo = p_activo)
      AND (p_fecha_inicio IS NULL OR t.fecha_creacion >= p_fecha_inicio)
      AND (p_fecha_fin IS NULL OR t.fecha_creacion <= p_fecha_fin)
      AND (p_estado_id IS NULL OR t.estado_id = p_estado_id)
      AND (
          p_termino_busqueda = '' 
          OR t.id_solicitud LIKE CONCAT('%', p_termino_busqueda, '%')
          OR t.id_transaccion_pasarela LIKE CONCAT('%', p_termino_busqueda, '%')
          OR p.nombre LIKE CONCAT('%', p_termino_busqueda, '%')
          OR p.apellido LIKE CONCAT('%', p_termino_busqueda, '%')
          OR p.telefono LIKE CONCAT('%', p_termino_busqueda, '%')
      )
    ORDER BY t.id DESC;
END$$
DELIMITER ;