<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TaxCalculation extends Model
{
    protected $fillable = [
        'user_id', 'gaji_pokok', 'risiko_kerja', 'status_perkawinan',
        'jumlah_tanggungan', 'gabung_istri', 'penghasilan_bruto_per_bulan',
        'penghasilan_neto_per_bulan', 'penghasilan_neto_per_tahun', 'ptkp',
        'penghasilan_kena_pajak', 'pph_terutang_setahun', 'pph_terutang_sebulan',
        'gaji_bersih_setelah_pajak',
        // Kolom baru untuk fitur publik dan tabungan
        'is_public', 'total_savings', 'savings_category'
    ];

    // Relasi ke allowances (opsional)
    public function allowances()
    {
        return $this->hasMany(Allowance::class);
    }

    // Relasi ke living_costs (opsional)
    public function livingCosts()
    {
        return $this->hasMany(LivingCost::class);
    }

    // Relasi ke user (opsional)
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}