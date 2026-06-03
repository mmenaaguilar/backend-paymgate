<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\DB;
use Illuminate\Http\JsonResponse;

abstract class Controller
{
    /**
     * Ejecuta Procedimientos Almacenados de Lectura (Listar, Buscar, Reportes)
     */
    protected function ejecutarConsulta(string $procedimiento, array $parametros = [], bool $retornarPrimero = false): JsonResponse
    {
        $placeholders = implode(',', array_fill(0, count($parametros), '?'));
        $registros = DB::select("CALL {$procedimiento}({$placeholders})", $parametros);

        if ($retornarPrimero) {
            if (empty($registros)) {
                return response()->json([
                    'error' => 'No encontrado',
                    'mensaje' => 'El registro solicitado no existe o fue eliminado.'
                ], 404);
            }
            return response()->json($registros[0], 200);
        }

        return response()->json($registros, 200);
    }

    /**
     * Ejecuta Procedimientos Almacenados de Escritura/Mutación (Registrar, Modificar, Eliminar Lógico, Cambiar Estados)
     * Centraliza las respuestas automatizadas y el manejo de errores controlados del SP.
     */
    protected function ejecutarMutacion(string $procedimiento, array $parametros = [], int $codigoExito = 200): JsonResponse
    {
        $placeholders = implode(',', array_fill(0, count($parametros), '?'));
        $resultado = DB::select("CALL {$procedimiento}({$placeholders})", $parametros);

        if (empty($resultado)) {
            return response()->json([
                'error' => 'Error interno',
                'mensaje' => 'No se recibió respuesta del servidor de base de datos.'
            ], 500);
        }

        $respuestaSP = $resultado[0];

        if (isset($respuestaSP->error) && $respuestaSP->error == 1) {
            return response()->json([
                'error' => 'Operación fallida',
                'mensaje' => $respuestaSP->mensaje ?? 'Error en la ejecución del proceso.'
            ], 400);
        }

        return response()->json([
            'mensaje' => $respuestaSP->mensaje ?? 'Operación realizada con éxito',
            'datos' => $respuestaSP
        ], $codigoExito);
    }
}