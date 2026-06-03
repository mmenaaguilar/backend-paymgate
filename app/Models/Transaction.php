<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    protected $table = 'transacciones';

    protected $fillable = [
        'id_solicitud',
        'id_transaccion_pasarela',
        'telefono',
        'nombre_cliente',
        'monto',
        'otp',
        'estado_id',
        'codigo_respuesta',
        'descripcion',
        'activo',
        'creado_por',
        'actualizado_por',
        'fecha_eliminacion'
    ];

    protected function casts(): array
    {
        return [
            'fecha_eliminacion' => 'datetime',
            'monto' => 'decimal:2',
            'activo' => 'integer',
            'estado_id' => 'integer'
        ];
    }
}