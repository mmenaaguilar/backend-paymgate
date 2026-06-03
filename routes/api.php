<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\UsuarioController;
use App\Http\Controllers\TransaccionController;
use App\Http\Controllers\ReembolsoController;

/*
|--------------------------------------------------------------------------
| API Routes - Pasarela BIPAY
|--------------------------------------------------------------------------
*/

// ==========================================
// 1. RUTAS PÚBLICAS (Sin autenticación)
// ==========================================
Route::prefix('usuarios')->group(function () {
    Route::post('/login', [UsuarioController::class, 'login']);
    Route::post('/register', [UsuarioController::class, 'register']);
});


// ==========================================
// 2. RUTAS PROTEGIDAS (Requieren Token Sanctum)
// ==========================================
Route::middleware('auth:sanctum')->group(function () {

    // --- MÓDULO: USUARIOS ---
    Route::prefix('usuarios')->group(function () {
        Route::put('/{id}', [UsuarioController::class, 'editar']);
        Route::delete('/{id}', [UsuarioController::class, 'destroy']);
    });

    Route::prefix('transacciones')->group(function () {
        Route::get('/', [TransaccionController::class, 'index']);             
        Route::get('/{id}', [TransaccionController::class, 'show']);         
        Route::post('/', [TransaccionController::class, 'guardar']);          
        Route::put('/', [TransaccionController::class, 'guardar']);       
        Route::delete('/{id}', [TransaccionController::class, 'destroy']);
        Route::post('/reembolsar', [TransaccionController::class, 'cambiarEstadoReembolsado']);
    });

    Route::prefix('reembolsos')->group(function () {
        Route::get('/', [ReembolsoController::class, 'index']);             
        Route::get('/{id}', [ReembolsoController::class, 'show']);            
        Route::post('/', [ReembolsoController::class, 'guardar']);            
        Route::put('/', [ReembolsoController::class, 'guardar']);        
        Route::delete('/{id}', [ReembolsoController::class, 'destroy']);     
    });

});