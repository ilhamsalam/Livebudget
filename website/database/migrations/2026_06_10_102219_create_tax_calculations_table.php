<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('tax_calculations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->decimal('gaji_pokok', 15, 2);
            $table->enum('risiko_kerja', ['Sangat Rendah', 'Rendah', 'Sedang', 'Tinggi', 'Sangat Tinggi']);
            $table->enum('status_perkawinan', ['Tidak Kawin', 'Kawin']);
            $table->integer('jumlah_tanggungan');
            $table->boolean('gabung_istri')->default(false);
            // hasil perhitungan (nullable)
            $table->decimal('penghasilan_bruto_per_bulan', 15, 2)->nullable();
            $table->decimal('penghasilan_neto_per_bulan', 15, 2)->nullable();
            $table->decimal('penghasilan_neto_per_tahun', 15, 2)->nullable();
            $table->decimal('ptkp', 15, 2)->nullable();
            $table->decimal('penghasilan_kena_pajak', 15, 2)->nullable();
            $table->decimal('pph_terutang_setahun', 15, 2)->nullable();
            $table->decimal('pph_terutang_sebulan', 15, 2)->nullable();
            $table->decimal('gaji_bersih_setelah_pajak', 15, 2)->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tax_calculations');
    }
};