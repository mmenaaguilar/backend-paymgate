<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\JsonResponse;

class UsuarioController extends Controller
{
    private function obtenerUsuarioActivo(): string
    {
        return Auth::check() ? Auth::user()->usuario : 'SISTEMA';
    }

    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'usuario_o_correo' => 'required|string',
            'contrasena' => 'required|string',
        ]);

        $resultado = DB::select("CALL sp_obtener_usuario_por_credencial(?)", [$request->input('usuario_o_correo')]);

        if (empty($resultado)) {
            return response()->json([
                'error' => 'Credenciales incorrectas',
                'mensaje' => 'El usuario o correo ingresado no existe.'
            ], 401);
        }

        $usuarioBD = $resultado[0];

        if ($usuarioBD->activo == 0 || !is_null($usuarioBD->fecha_eliminacion)) {
            return response()->json([
                'error' => 'Acceso denegado',
                'mensaje' => 'Esta cuenta de usuario se encuentra inactiva o ha sido dada de baja.'
            ], 403);
        }

        if (!Hash::check($request->input('contrasena'), $usuarioBD->contrasena_hash)) {
            return response()->json([
                'error' => 'Credenciales incorrectas',
                'mensaje' => 'La contraseña ingresada es incorrecta.'
            ], 401);
        }

        DB::statement("CALL sp_registrar_ultimo_acceso(?, ?)", [$usuarioBD->id, 'SISTEMA_AUTH']);

        return response()->json([
            'mensaje' => 'Autenticación exitosa. Bienvenido al sistema.',
            'usuario' => [
                'id' => $usuarioBD->id,
                'usuario' => $usuarioBD->usuario,
                'correo' => $usuarioBD->correo,
                'nombre' => $usuarioBD->nombre,
                'apellido' => $usuarioBD->apellido
            ]
        ], 200);
    }

    public function register(Request $request): JsonResponse
    {
        $parametros = [
            0,
            $request->input('usuario'),
            $request->input('correo'),
            Hash::make($request->input('contrasena')),
            $request->input('nombre'),
            $request->input('apellido'),
            $request->input('telefono'),
            1, 
            $this->obtenerUsuarioActivo()
        ];

        return $this->ejecutarMutacion('sp_guardar_usuario', $parametros, 210);
    }

    public function editar(Request $request, mixed $id): JsonResponse
    {
        $parametros = [
            $id, 
            $request->input('usuario'),
            $request->input('correo'),
            $request->filled('contrasena') ? Hash::make($request->input('contrasena')) : null,
            $request->input('nombre'),
            $request->input('apellido'),
            $request->input('telefono'),
            $request->input('activo', 1),
            $this->obtenerUsuarioActivo()
        ];

        return $this->ejecutarMutacion('sp_guardar_usuario', $parametros, 200);
    }

    public function destroy(mixed $id): JsonResponse
    {
        $parametros = [
            $id,
            $this->obtenerUsuarioActivo()
        ];

        return $this->ejecutarMutacion('sp_eliminar_usuario', $parametros);
    }
}