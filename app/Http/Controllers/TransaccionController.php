<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Http\JsonResponse;

class TransaccionController extends Controller
{
    /**
     * Método privado auxiliar para obtener la auditoría del usuario actual
     */
    private function obtenerUsuarioActivo(): string
    {
        return Auth::check() ? Auth::user()->usuario : 'SISTEMA';
    }

    /**
     * 1. LISTAR TRANSACCIONES (CRUD - Leer Todo)
     * Mapeado al SP: sp_listar_transacciones
     */
    public function index(Request $request): JsonResponse
    {
        $parametros = [
            $request->input('fecha_inicio', null),
            $request->input('fecha_fin', null),
            $request->input('estado_id', null),      
            $request->input('termino_busqueda', ''),  
            $request->input('activo', 1),            
            $this->obtenerUsuarioActivo()
        ];

        return $this->ejecutarConsulta('sp_listar_transacciones', $parametros);
    }

    /**
     * 2. BUSCAR TRANSACCIÓN POR ID (CRUD - Leer Uno)
     * Mapeado al SP: sp_buscar_transaccion
     */
    public function show(mixed $id): JsonResponse
    {
        $parametros = [
            $id,
            $this->obtenerUsuarioActivo()
        ];

        return $this->ejecutarConsulta('sp_buscar_transaccion', $parametros, true);
    }

/**
     * 3. GUARDAR / ACTUALIZAR TRANSACCIÓN (CRUD - Crear y Editar)
     * Mapeado al SP: sp_guardar_transaccion
     */
    public function guardar(Request $request): JsonResponse
    {
        $request->validate([
            'persona_id' => 'required|integer',
            'id_solicitud' => 'required|string|max:100',
            'monto' => 'required|numeric',
        ]);

        $id = $request->input('id', 0);

        $parametros = [
            $id,                                        // 1. p_id (0)
            $request->input('persona_id'),              // 2. p_persona_id (2)
            $request->input('id_solicitud'),            // 3. p_id_solicitud ("REQ-2026-001")
            $request->input('id_transaccion_pasarela'), // 4. p_id_transaccion_pasarela ("1212")
            $request->input('monto'),                   // 5. p_monto ("13")
            $request->input('otp'),                     // 6. p_otp ("12")
            $request->input('estado_id', 1),            // 7. p_estado_id (1)
            $request->input('codigo_respuesta'),        // 8. p_codigo_respuesta ("13")
            $request->input('descripcion'),             // 9. p_descripcion ("sdsssas")
            $request->input('activo', 1),               // 10. p_activo (1)
            $this->obtenerUsuarioActivo()               // 11. p_usuario_activo ("juan99")
        ];

        // 201 Created para registros nuevos, 200 OK para actualizaciones
        $codigoHttp = ($id == 0) ? 201 : 200;

        // Utilizamos tu método base de la plantilla de manera limpia
        return $this->ejecutarMutacion('sp_guardar_transaccion', $parametros, $codigoHttp);
    }
    /**
     * 4. ANULAR TRANSACCIÓN (CRUD - Eliminar Lógico)
     * Mapeado al SP: sp_eliminar_transaccion
     */
    public function destroy(mixed $id): JsonResponse
    {
        $parametros = [
            $id,
            $this->obtenerUsuarioActivo()
        ];

        return $this->ejecutarMutacion('sp_eliminar_transaccion', $parametros);
    }

    /**
     * 5. PROCESAR REEMBOLSO DE TRANSACCIÓN (Método de Negocio)
     * Mapeado al SP: sp_procesar_reembolso_transaccion
     */
    public function cambiarEstadoReembolsado(Request $request): JsonResponse
    {
        $request->validate([
            'id' => 'required|integer',                                       
            'id_solicitud_reembolso' => 'required|string|max:100',    
            'motivo' => 'required|string'                                   
        ]);

        $parametros = [
            $request->input('id'),                      
            $request->input('id_solicitud_reembolso'), 
            $request->input('motivo'),                                 
            $this->obtenerUsuarioActivo()              
        ];

        return $this->ejecutarMutacion('sp_procesar_reembolso_transaccion', $parametros);
    }

/**
     * 6. HISTORIAL DE TRANSACCIONES POR PERSONA (Filtros Avanzados React)
     * Mapeado al SP: sp_listar_transacciones_por_persona
     * Se encarga de listar el historial ejecutando la ruta relacional: transacciones -> personas.
     */
    public function listarPorPersona(Request $request, mixed $personaId): JsonResponse
    {
        $parametros = [
            $personaId,                              
            $request->input('fecha_inicio', null),
            $request->input('fecha_fin', null),
            $request->input('estado_id', null),
            $request->input('termino_busqueda', ''),
            $request->input('activo', 1),
            $this->obtenerUsuarioActivo()
        ];

        return $this->ejecutarConsulta('sp_listar_transacciones_por_persona', $parametros);
    }
}