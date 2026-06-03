<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasFactory, Notifiable, HasApiTokens;

    protected $table = 'usuarios';

    protected $fillable = [
        'usuario',
        'correo',
        'contrasena_hash',
        'nombre',
        'apellido',
        'telefono',
        'activo',
        'creado_por',
        'actualizado_por',
        'fecha_eliminacion'
    ];

    protected $hidden = [
        'contrasena_hash',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'ultimo_acceso' => 'datetime',
            'fecha_eliminacion' => 'datetime',
            'activo' => 'integer'
        ];
    }

    public function getAuthPassword()
    {
        return $this->contrasena_hash;
    }
}