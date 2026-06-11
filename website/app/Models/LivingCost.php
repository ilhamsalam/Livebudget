<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LivingCost extends Model
{
    protected $fillable = ['tax_calculation_id', 'jenis', 'jumlah'];

    // Relasi ke tax_calculation (opsional)
    public function taxCalculation()
    {
        return $this->belongsTo(TaxCalculation::class);
    }
}