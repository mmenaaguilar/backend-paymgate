<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\JsonResponse;
use App\Models\User; // ◄ Importamos tu modelo User ajustado

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
        // 1. Validar datos de entrada
        $request->validate([
            'usuario_o_correo' => 'required|string',
            'contrasena' => 'required|string',
        ]);

        // 2. Buscar usuario en la BD mediante el Stored Procedure
        $resultado = DB::select("CALL sp_obtener_usuario_por_credencial(?)", [$request->input('usuario_o_correo')]);

        if (empty($resultado)) {
            return response()->json([
                'error' => 'Credenciales incorrectas',
                'mensaje' => 'El usuario o correo ingresado no existe.'
            ], 401);
        }

        $usuarioBD = $resultado[0];

        // 3. Validar estado del usuario (Borrado lógico o Inactivo)
        if ($usuarioBD->activo == 0 || !is_null($usuarioBD->fecha_eliminacion)) {
            return response()->json([
                'error' => 'Acceso denegado',
                'mensaje' => 'Esta cuenta de usuario se encuentra inactiva o ha sido dada de baja.'
            ], 403);
        }

        // 4. Verificar la contraseña encriptada
        if (!Hash::check($request->input('contrasena'), $usuarioBD->contrasena_hash)) {
            return response()->json([
                'error' => 'Credenciales incorrectas',
                'mensaje' => 'La contraseña ingresada es incorrecta.'
            ], 401);
        }

        // 5. AJUSTE CRÍTICO: Generar el Token de Sanctum usando el Modelo User
        $userModel = User::find($usuarioBD->id);
        $token = $userModel->createToken('auth_token')->plainTextToken;

        // 6. Registrar auditoría de acceso en la BD
        DB::statement("CALL sp_registrar_ultimo_acceso(?, ?)", [$usuarioBD->id, 'SISTEMA_AUTH']);

        // 7. Responder con éxito incluyendo el TOKEN para el Frontend
        return response()->json([
            'mensaje' => 'Autenticación exitosa. Bienvenido al sistema.',
            'token' => $token, // ◄ El frontend (React/Vue/Postman) debe guardar este token
            'usuario' => [
                'id' => $usuarioBD->id,
                'usuario' => $usuarioBD->usuario,
                'correo' => $usuarioBD->correo,
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
            0, // ID 0 indica que es un nuevo registro
            $request->input('usuario'),
            $request->input('correo'),
            Hash::make($request->input('contrasena')), // Encriptamos la contraseña
            $request->input('nombre'),
            $request->input('apellido'),
            $request->input('telefono'),
            1, // Activo por defecto
            $this->obtenerUsuarioActivo() // Retornará 'SISTEMA' al ser ruta pública
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
            // Si el cliente envía una nueva contraseña se encripta, de lo contrario viaja null
            $request->filled('contrasena') ? Hash::make($request->input('contrasena')) : null,
            $request->input('nombre'),
            $request->input('apellido'),
            $request->input('telefono'),
            $request->input('activo', 1),
            $this->obtenerUsuarioActivo() // Retornará el usuario autenticado gracias al Token
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
}