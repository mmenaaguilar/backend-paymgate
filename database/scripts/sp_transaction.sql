USE bipay;

-- ==========================================================================
-- 1. SP: sp_listar_transacciones
-- Mapeado al método: index()
-- Soporta filtros por rango de fechas, estado_id, activo y término general 
-- (búsqueda por id_solicitud o nombre_cliente).
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
    SELECT t.*, e.nombre AS estado_nombre
    FROM transacciones t
    LEFT JOIN estados e ON t.estado_id = e.id
    WHERE (t.activo = p_activo)
      AND (p_fecha_inicio IS NULL OR t.fecha_creacion >= p_fecha_inicio)
      AND (p_fecha_fin IS NULL OR t.fecha_creacion <= p_fecha_fin)
      AND (p_estado_id IS NULL OR t.estado_id = p_estado_id)
      AND (
          p_termino_busqueda = '' 
          OR t.id_solicitud LIKE CONCAT('%', p_termino_busqueda, '%')
          OR t.nombre_cliente LIKE CONCAT('%', p_termino_busqueda, '%')
          OR t.telefono LIKE CONCAT('%', p_termino_busqueda, '%')
      )
    ORDER BY t.id DESC;
END$$
DELIMITER ;


-- ==========================================================================
-- 2. SP: sp_buscar_transaccion
-- Mapeado al método: show($id)
-- Obtiene una transacción específica por su ID primario.
-- ==========================================================================
DROP PROCEDURE IF EXISTS sp_buscar_transaccion;
DELIMITER $$

CREATE PROCEDURE sp_buscar_transaccion(
    IN p_id BIGINT,
    IN p_usuario_activo VARCHAR(100)
)
BEGIN
    SELECT t.*, e.nombre AS estado_nombre
    FROM transacciones t
    LEFT JOIN estados e ON t.estado_id = e.id
    WHERE t.id = p_id 
    LIMIT 1;
END$$
DELIMITER ;


-- ==========================================================================
-- 3. SP: sp_guardar_transaccion
-- Mapeado al método: guardar()
-- Maneja la creación (ID = 0) y edición (ID > 0) de transacciones.
-- Devuelve la fila afectada con 'OK' para que el controlador responda.
-- ==========================================================================
DROP PROCEDURE IF EXISTS sp_guardar_transaccion;
DELIMITER $$

CREATE PROCEDURE sp_guardar_transaccion(
    IN p_id BIGINT,
    IN p_id_solicitud VARCHAR(100),
    IN p_id_transaccion_pasarela VARCHAR(150),
    IN p_telefono VARCHAR(20),
    IN p_nombre_cliente VARCHAR(150),
    IN p_monto DECIMAL(10,2),
    IN p_otp VARCHAR(10),
    IN p_estado_id INT,
    IN p_codigo_respuesta VARCHAR(50),
    IN p_descripcion TEXT,
    IN p_activo TINYINT(1),
    IN p_usuario_activo VARCHAR(100)
)
BEGIN
    IF p_id = 0 THEN
        -- OPERACIÓN: CREAR TRANSACCIÓN
        INSERT INTO transacciones (
            id_solicitud,
            id_transaccion_pasarela,
            telefono,
            nombre_cliente,
            monto,
            otp,
            estado_id,
            codigo_respuesta,
            descripcion,
            activo,
            creado_por
        )
        VALUES (
            p_id_solicitud,
            p_id_transaccion_pasarela,
            p_telefono,
            p_nombre_cliente,
            p_monto,
            p_otp,
            p_estado_id,
            p_codigo_respuesta,
            p_descripcion,
            p_activo,
            p_usuario_activo
        );
        
        -- Retorna fila recién creada con el código correspondiente para Laravel
        SELECT *, 'OK' AS respuesta_codigo FROM transacciones WHERE id = LAST_INSERT_ID();

    ELSE
        -- OPERACIÓN: EDITAR / ACTUALIZAR TRANSACCIÓN
        UPDATE transacciones
        SET id_solicitud = p_id_solicitud,
            id_transaccion_pasarela = p_id_transaccion_pasarela,
            telefono = p_telefono,
            nombre_cliente = p_nombre_cliente,
            monto = p_monto,
            otp = p_otp,
            estado_id = p_estado_id,
            codigo_respuesta = p_codigo_respuesta,
            descripcion = p_descripcion,
            activo = p_activo,
            actualizado_por = p_usuario_activo
        WHERE id = p_id;
        
        -- Retorna la fila modificada
        SELECT *, 'OK' AS respuesta_codigo FROM transacciones WHERE id = p_id;
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
    
    -- Retorna confirmación al controlador
    SELECT p_id AS id, 'OK' AS respuesta_codigo;
END$$
DELIMITER ;


-- ==========================================================================
-- 5. SP: sp_procesar_reembolso_transaccion
-- Mapeado al método: cambiarEstadoReembolsado()
-- Cambia directamente el estado_id a 4 (Reembolsado) e inserta el historial 
-- correspondiente en la tabla 'reembolsos' todo en un entorno transaccional.
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
    -- Se abre una transacción para asegurar consistencia en ambas operaciones
    START TRANSACTION;
    
    -- 1. Actualizar el estado en la tabla de transacciones (ID 4 = REEMBOLSADO)
    UPDATE transacciones 
    SET estado_id = 4, 
        actualizado_por = p_usuario_activo
    WHERE id = p_transaccion_id;
    
    -- 2. Insertar el rastro de la devolución en la tabla reembolsos
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
    
    -- Retornar respuesta estructurada para Laravel mutación
    SELECT p_transaccion_id AS id, 'OK' AS respuesta_codigo;
    
END$$
DELIMITER ;