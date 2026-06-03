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
     * 1. LISTAR REEMBOLSOS (CRUD - Leer Todo)
     * Soporta múltiples filtros dinámicos como estados, rangos de fecha o código de solicitud.
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
     */
    public function guardar(Request $request): JsonResponse
    {
        $id = $request->input('id', 0);

        $parametros = [
            $id,
            $request->input('transaccion_id'),
            $request->input('id_solicitud_reembolso'),
            $request->input('estado_id', 1), 
            $request->input('codigo_respuesta', null),
            $request->input('motivo', null),
            $request->input('activo', 1),
            $this->obtenerUsuarioActivo()
        ];

        $codigoHttp = ($id == 0) ? 210 : 200;

        return $this->ejecutarMutacion('sp_guardar_reembolso', $parametros, $codigoHttp);
    }

    /**
     * 4. ANULAR REEMBOLSO (CRUD - Eliminar Lógico)
     * Ejecuta una baja lógica cambiando 'activo' a 0 y guardando la 'fecha_eliminacion' mediante el SP.
     */
    public function destroy(mixed $id): JsonResponse
    {
        $parametros = [
            $id,
            $this->obtenerUsuarioActivo()
        ];

        return $this->ejecutarMutacion('sp_eliminar_reembolso', $parametros);
    }
}