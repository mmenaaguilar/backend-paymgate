<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Refund extends Model
{
    protected $table = 'reembolsos';

    protected $fillable = [
        'transaccion_id',
        'id_solicitud_reembolso',
        'estado_id',
        'codigo_respuesta',
        'motivo',
        'activo',
        'creado_por',
        'actualizado_por',
        'fecha_eliminacion'
    ];

    protected function casts(): array
    {
        return [
            'fecha_eliminacion' => 'datetime',
            'transaccion_id' => 'integer',
            'estado_id' => 'integer',
            'activo' => 'integer'
        ];
    }
}