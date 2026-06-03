<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Http\JsonResponse;

class ReembolsoController extends Controller
{
    /**
     * Método privado auxiliar para obtener la auditoría del usuario actual
     */
    private function obtenerUsuarioActivo(): string
    {
        return Auth::check() ? Auth::user()->usuario : 'SISTEMA';
    }

    /**
     * 1. LISTAR REEMBOLSOS GENERALES (CRUD - Leer Todo)
     * Soporta múltiples filtros dinámicos como estados, rangos de fecha o código de solicitud.
     * Mapeado al SP: sp_listar_reembolsos
     */
    public function index(Request $request): JsonResponse
    {
        $parametros = [
            $request->input('fecha_inicio', null),
            $request->input('fecha_fin', null),
            $request->input('estado_id', null),                
            $request->input('id_solicitud_reembolso', null),   
            $request->input('activo', 1),                       
            $this->obtenerUsuarioActivo()
        ];

        return $this->ejecutarConsulta('sp_listar_reembolsos', $parametros);
    }

    /**
     * 2. BUSCAR REEMBOLSO POR ID (CRUD - Leer Uno)
     * Mapeado al SP: sp_buscar_reembolso
     */
    public function show(mixed $id): JsonResponse
    {
        $parametros = [
            $id,
            $this->obtenerUsuarioActivo()
        ];

        return $this->ejecutarConsulta('sp_buscar_reembolso', $parametros, true);
    }

    /**
     * 3. GUARDAR / ACTUALIZAR REEMBOLSO (CRUD - Crear y Editar)
     * Si en el body viaja id = 0 (o no se envía) crea un nuevo reembolso, si id > 0 lo actualiza.
     * Mapeado al SP: sp_guardar_reembolso
     */
    public function guardar(Request $request): JsonResponse
    {
        $request->validate([
            'transaccion_id' => 'required|integer',
            'persona_id' => 'required|integer', // ◄ Ajuste Crítico: Ahora es obligatorio por el diseño Solo Login
            'id_solicitud_reembolso' => 'required|string|max:100'
        ]);

        $id = $request->input('id', 0);

        $parametros = [
            $id,
            $request->input('transaccion_id'),
            $request->input('persona_id'), // ◄ Inyección del parámetro requerido por la estructura NOT NULL
            $request->input('id_solicitud_reembolso'),
            $request->input('estado_id', 1), 
            $request->input('codigo_respuesta', null),
            $request->input('motivo', null),
            $request->input('activo', 1),
            $this->obtenerUsuarioActivo()
        ];

        // 201 Created para registros nuevos, 200 OK para actualizaciones
        $codigoHttp = ($id == 0) ? 201 : 200;

        return $this->ejecutarMutacion('sp_guardar_reembolso', $parametros, $codigoHttp);
    }

    /**
     * 4. ANULAR REEMBOLSO (CRUD - Eliminar Lógico)
     * Ejecuta una baja lógica cambiando 'activo' a 0 y guardando la 'fecha_eliminacion' mediante el SP.
     * Mapeado al SP: sp_eliminar_reembolso
     */
    public function destroy(mixed $id): JsonResponse
    {
        $parametros = [
            $id,
            $this->obtenerUsuarioActivo()
        ];

        return $this->ejecutarMutacion('sp_eliminar_reembolso', $parametros);
    }

    /**
     * 5. LISTAR REEMBOLSOS FILTRADOS POR PERSONA (Historial del Cliente en React)
     * Permite consultar de forma segura y directa todas las devoluciones que pertenecen a un usuario.
     * Mapeado al SP: sp_listar_reembolsos_por_persona
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

        return $this->ejecutarConsulta('sp_listar_reembolsos_por_persona', $parametros);
    }
}