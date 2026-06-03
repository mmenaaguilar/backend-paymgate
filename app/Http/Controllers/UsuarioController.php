<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\JsonResponse;
use App\Models\User; 

class UsuarioController extends Controller
{
    /**
     * Método privado auxiliar para obtener la auditoría del usuario actual
     */
    private function obtenerUsuarioActivo(): string
    {
        return Auth::check() ? Auth::user()->usuario : 'SISTEMA';
    }

    /**
     * AUTENTICACIÓN / LOGIN
     */
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
        $userModel = User::find($usuarioBD->id);
        $token = $userModel->createToken('auth_token')->plainTextToken;

        DB::statement("CALL sp_registrar_ultimo_acceso(?, ?)", [$usuarioBD->id, 'SISTEMA_AUTH']);


        return response()->json([
            'mensaje' => 'Autenticación exitosa. Bienvenido al sistema.',
            'token' => $token, 
            'usuario' => [
                'id' => $usuarioBD->id,
                'id_persona' => $usuarioBD->persona_id,
                'usuario' => $usuarioBD->usuario,
                'correo' => $usuarioBD->correo,
                'telefono' => $usuarioBD->telefono,
                'nombre' => $usuarioBD->nombre,
                'apellido' => $usuarioBD->apellido
            ]
        ], 200);
    }

    /**
     * REGISTRO DE USUARIOS (Ruta Pública)
     */
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

/**
     * EDITAR USUARIO (Ruta Protegida)
     */
    public function editar(Request $request, mixed $id): JsonResponse
    {
        $parametros = [
            $id, 
            $request->input('usuario'),
            $request->input('correo'),
            $request->input('nombre'),
            $request->input('apellido'),
            $request->input('telefono'),
            $request->input('activo', 1),
            $this->obtenerUsuarioActivo() 
        ];

        return $this->ejecutarMutacion('sp_guardar_usuario', $parametros, 200);
    }

    /**
     * ELIMINAR USUARIO (Baja Lógica - Ruta Protegida)
     */
    public function destroy(mixed $id): JsonResponse
    {
        $parametros = [
            $id,
            $this->obtenerUsuarioActivo()
        ];

        return $this->ejecutarMutacion('sp_eliminar_usuario', $parametros);
    }

    /**
     * CIERRE DE SESIÓN / LOGOUT (Ruta Protegida)
     * Elimina el token de acceso actual que se está utilizando.
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'mensaje' => 'Sesión cerrada correctamente. El token ha sido revocado.'
        ], 200);
    }
}