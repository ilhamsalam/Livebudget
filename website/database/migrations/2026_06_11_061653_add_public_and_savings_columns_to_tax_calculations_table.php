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
        Schema::table('tax_calculations', function (Blueprint $table) {
            // Menambahkan kolom is_public (default false) setelah kolom gaji_bersih_setelah_pajak
            $table->boolean('is_public')->default(false)->after('gaji_bersih_setelah_pajak');
            // Menambahkan kolom total_savings (nullable)
            $table->decimal('total_savings', 15, 2)->nullable()->after('is_public');
            // Menambahkan kolom savings_category dengan enum kategori
            $table->enum('savings_category', [
                'Siaga/Rentan',
                'Standar/Cukup',
                'Ideal/Sehat',
                'Agresif/Kuat',
                'Ekstrem/Frugal'
            ])->nullable()->after('total_savings');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('tax_calculations', function (Blueprint $table) {
            // Menghapus ketiga kolom jika rollback
            $table->dropColumn(['is_public', 'total_savings', 'savings_category']);
        });
    }
};