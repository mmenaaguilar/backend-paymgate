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
     * Soporta múltiples filtros dinámicos como fechas, estados o término de búsqueda general.
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
     * Si id = 0 (o no se envía) crea la transacción, si id > 0 la actualiza.
     */
    public function guardar(Request $request): JsonResponse
    {
        $id = $request->input('id', 0);

        $parametros = [
            $id,
            $request->input('id_solicitud'),
            $request->input('id_transaccion_pasarela', null),
            $request->input('telefono'),
            $request->input('nombre_cliente'),
            $request->input('monto'),
            $request->input('otp', null),
            $request->input('estado_id', 1),
            $request->input('codigo_respuesta', null),
            $request->input('descripcion', null),
            $request->input('activo', 1),
            $this->obtenerUsuarioActivo()
        ];

        $codigoHttp = ($id == 0) ? 210 : 200;

        return $this->ejecutarMutacion('sp_guardar_transaccion', $parametros, $codigoHttp);
    }

    /**
     * 4. ANULAR TRANSACCIÓN (CRUD - Eliminar Lógico)
     * Cambia la columna 'activo' a 0 y registra la 'fecha_eliminacion' mediante el SP.
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
     * 5. CAMBIAR ESTADO A REEMBOLSADO (Método de Negocio Particular)
     * Cambia el estado_id de la transacción a 'REEMBOLSADO' (ID 4) de forma directa
     * e inserta en la tabla 'reembolsos' el rastro y motivo de la devolución.
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
}