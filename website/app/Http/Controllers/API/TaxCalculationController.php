<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\TaxCalculation;
use App\Models\Allowance;
use App\Models\LivingCost;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TaxCalculationController extends Controller
{
    /**
     * POST /api/calculate
     * Menyimpan perhitungan baru beserta total tabungan dan kategori
     */
    public function calculate(Request $request)
    {
        // Validasi input
        $validated = $request->validate([
            'gaji_pokok' => 'required|numeric',
            'tunjangan' => 'array',
            'tunjangan.*.jenis' => 'string',
            'tunjangan.*.jumlah' => 'numeric',
            'risiko_kerja' => 'required|in:Sangat Rendah,Rendah,Sedang,Tinggi,Sangat Tinggi',
            'status_perkawinan' => 'required|in:Tidak Kawin,Kawin',
            'jumlah_tanggungan' => 'required|in:0,1,2,3',
            'gabung_istri' => 'boolean',
            'biaya_hidup' => 'required|array|min:1',
            'biaya_hidup.*.jenis' => 'string',
            'biaya_hidup.*.jumlah' => 'numeric',
            'user_id' => 'required|exists:users,id',
            'is_public' => 'boolean' // opsional, default false
        ]);

        // Hitung total tunjangan
        $tunjanganArray = $request->tunjangan ?? [];
        $totalTunjangan = collect($tunjanganArray)->sum('jumlah');

        // --- Hitung Penghasilan Bruto per bulan ---
        $penghasilanBruto = $request->gaji_pokok + $totalTunjangan;

        // Jaminan yang dibayar perusahaan
        $jk = 0.04;                           // Jaminan Kesehatan 4%
        $jkk = $this->getJKKRate($request->risiko_kerja);
        $jkm = 0.003;                         // Jaminan Kematian 0.3%
        $jht_perusahaan = 0.037;              // JHT 3.7%
        $jp_perusahaan = 0.02;                // JP 2%
        $persenJaminanPerusahaan = $jk + $jkk + $jkm + $jht_perusahaan + $jp_perusahaan;
        $penghasilanBruto += $persenJaminanPerusahaan * $penghasilanBruto;

        // --- Pengurang ---
        $biayaJabatan = min(0.05 * $penghasilanBruto, 500000);
        $jk_bayar = 0.01;   // 1%
        $jht_bayar = 0.02;  // 2%
        $jp_bayar = 0.01;   // 1%
        $persenPengurang = $jk_bayar + $jht_bayar + $jp_bayar;
        $totalPengurang = $biayaJabatan + ($persenPengurang * $penghasilanBruto);

        $penghasilanNetoPerBulan = $penghasilanBruto - $totalPengurang;
        $penghasilanNetoPerTahun = $penghasilanNetoPerBulan * 12;

        // PTKP dan PKP
        $ptkp = $this->calculatePTKP(
            $request->status_perkawinan,
            $request->jumlah_tanggungan,
            $request->gabung_istri ?? false
        );
        $pkp = max($penghasilanNetoPerTahun - $ptkp, 0);
        $pphSetahun = $this->calculatePPh($pkp);
        $pphSebulan = $pphSetahun / 12;
        $gajiBersih = ($request->gaji_pokok + $totalTunjangan) - $pphSebulan;

        // --- Hitung total biaya hidup dan tabungan ---
        $biayaHidupArray = $request->biaya_hidup;
        $totalBiayaHidup = collect($biayaHidupArray)->sum('jumlah');
        $pendapatanSetelahPajak = $request->gaji_pokok + $totalTunjangan - $pphSebulan;
        $totalSavings = max($pendapatanSetelahPajak - $totalBiayaHidup, 0);
        $persentaseTabungan = ($pendapatanSetelahPajak > 0) ? ($totalSavings / $pendapatanSetelahPajak) * 100 : 0;
        $savingsCategory = $this->getSavingsCategory($persentaseTabungan);

        // Simpan ke database tax_calculations
        $taxCalc = TaxCalculation::create([
            'user_id' => $request->user_id,
            'gaji_pokok' => $request->gaji_pokok,
            'risiko_kerja' => $request->risiko_kerja,
            'status_perkawinan' => $request->status_perkawinan,
            'jumlah_tanggungan' => $request->jumlah_tanggungan,
            'gabung_istri' => $request->gabung_istri ?? false,
            'penghasilan_bruto_per_bulan' => $penghasilanBruto,
            'penghasilan_neto_per_bulan' => $penghasilanNetoPerBulan,
            'penghasilan_neto_per_tahun' => $penghasilanNetoPerTahun,
            'ptkp' => $ptkp,
            'penghasilan_kena_pajak' => $pkp,
            'pph_terutang_setahun' => $pphSetahun,
            'pph_terutang_sebulan' => $pphSebulan,
            'gaji_bersih_setelah_pajak' => $gajiBersih,
            // Kolom baru
            'is_public' => $request->is_public ?? false,
            'total_savings' => $totalSavings,
            'savings_category' => $savingsCategory,
        ]);

        // Simpan tunjangan
        foreach ($tunjanganArray as $tunj) {
            Allowance::create([
                'tax_calculation_id' => $taxCalc->id,
                'jenis' => $tunj['jenis'],
                'jumlah' => $tunj['jumlah']
            ]);
        }

        // Simpan biaya hidup
        foreach ($biayaHidupArray as $bh) {
            LivingCost::create([
                'tax_calculation_id' => $taxCalc->id,
                'jenis' => $bh['jenis'],
                'jumlah' => $bh['jumlah']
            ]);
        }

        return response()->json([
            'message' => 'Perhitungan berhasil',
            'data' => $taxCalc,
            'pph_sebulan' => $pphSebulan,
            'gaji_bersih' => $gajiBersih,
            'total_savings' => $totalSavings,
            'savings_category' => $savingsCategory,
            'persentase_tabungan' => round($persentaseTabungan, 2)
        ]);
    }

    /**
     * GET /api/history/{user_id}
     * Riwayat milik sendiri (privat)
     */
    public function history($userId)
    {
        $history = TaxCalculation::with('user')
                    ->where('user_id', $userId)
                    ->orderBy('created_at', 'desc')
                    ->get();
        return response()->json($history);
    }

    /**
     * GET /api/public-history
     * Riwayat publik semua user, dengan sorting dan pagination
     */
    public function publicHistory(Request $request)
    {
        $perPage = $request->get('per_page', 15);
        $sortBy = $request->get('sort_by', 'created_at');
        $sortDirection = $request->get('sort_direction', 'desc');

        // Mapping kolom yang boleh di-sort
        $allowedSorts = [
            'no' => 'created_at',
            'nama' => 'name',
            'gaji' => 'gaji_pokok',
            'PPh Terutang sebulan' => 'pph_terutang_sebulan',
            'total tabungan' => 'total_savings',
            'kategori tabungan' => 'savings_category'
        ];

        $orderColumn = $allowedSorts[$sortBy] ?? 'created_at';

        $query = TaxCalculation::with('user')
                    ->where('is_public', true);

        // Sorting khusus untuk nama (berdasarkan relasi user)
        if ($orderColumn == 'name') {
            $query->join('users', 'tax_calculations.user_id', '=', 'users.id')
                  ->orderBy('users.name', $sortDirection)
                  ->select('tax_calculations.*');
        } else {
            $query->orderBy($orderColumn, $sortDirection);
        }

        $history = $query->paginate($perPage);
        return response()->json($history);
    }

    /**
     * PUT /api/update/{id}
     * Mengupdate data perhitungan (hanya is_public dan data utama)
     * Catatan: sesuai permintaan, update hanya mengubah is_public dan data terkait.
     * Untuk menyederhanakan, kita izinkan update semua field (kecuali id dan user_id)
     */
    public function update(Request $request, $id)
    {
        $taxCalc = TaxCalculation::findOrFail($id);

        // Validasi input (bisa lebih longgar karena update)
        $validated = $request->validate([
            'gaji_pokok' => 'sometimes|numeric',
            'risiko_kerja' => 'sometimes|in:Sangat Rendah,Rendah,Sedang,Tinggi,Sangat Tinggi',
            'status_perkawinan' => 'sometimes|in:Tidak Kawin,Kawin',
            'jumlah_tanggungan' => 'sometimes|in:0,1,2,3',
            'gabung_istri' => 'boolean',
            'is_public' => 'boolean',
            'tunjangan' => 'array',
            'biaya_hidup' => 'array|min:1',
        ]);

        DB::transaction(function () use ($request, $taxCalc) {
            // Update field utama jika ada
            $taxCalc->fill($request->only([
                'gaji_pokok', 'risiko_kerja', 'status_perkawinan',
                'jumlah_tanggungan', 'gabung_istri', 'is_public'
            ]));

            // Jika ada perubahan data yang mempengaruhi perhitungan, ulang hitung
            // Untuk memudahkan, kita hitung ulang seperti method calculate
            if ($request->has('gaji_pokok') || $request->has('tunjangan') || 
                $request->has('risiko_kerja') || $request->has('biaya_hidup') ||
                $request->has('status_perkawinan') || $request->has('jumlah_tanggungan') ||
                $request->has('gabung_istri')) {

                // Ambil data terbaru
                $gajiPokok = $request->gaji_pokok ?? $taxCalc->gaji_pokok;
                $tunjanganArray = $request->tunjangan ?? [];
                $totalTunjangan = collect($tunjanganArray)->sum('jumlah');
                $risiko = $request->risiko_kerja ?? $taxCalc->risiko_kerja;
                $statusKawin = $request->status_perkawinan ?? $taxCalc->status_perkawinan;
                $jumlahTanggungan = $request->jumlah_tanggungan ?? $taxCalc->jumlah_tanggungan;
                $gabungIstri = $request->gabung_istri ?? $taxCalc->gabung_istri;
                $biayaHidupArray = $request->biaya_hidup ?? [];

                // Hitung ulang
                $penghasilanBruto = $gajiPokok + $totalTunjangan;
                $jk = 0.04; $jkk = $this->getJKKRate($risiko); $jkm = 0.003;
                $jht_perusahaan = 0.037; $jp_perusahaan = 0.02;
                $penghasilanBruto += ($jk + $jkk + $jkm + $jht_perusahaan + $jp_perusahaan) * $penghasilanBruto;

                $biayaJabatan = min(0.05 * $penghasilanBruto, 500000);
                $jk_bayar = 0.01; $jht_bayar = 0.02; $jp_bayar = 0.01;
                $totalPengurang = $biayaJabatan + ($jk_bayar + $jht_bayar + $jp_bayar) * $penghasilanBruto;
                $penghasilanNetoPerBulan = $penghasilanBruto - $totalPengurang;
                $penghasilanNetoPerTahun = $penghasilanNetoPerBulan * 12;
                $ptkp = $this->calculatePTKP($statusKawin, $jumlahTanggungan, $gabungIstri);
                $pkp = max($penghasilanNetoPerTahun - $ptkp, 0);
                $pphSetahun = $this->calculatePPh($pkp);
                $pphSebulan = $pphSetahun / 12;
                $gajiBersih = ($gajiPokok + $totalTunjangan) - $pphSebulan;

                // Tabungan dan kategori
                $totalBiayaHidup = collect($biayaHidupArray)->sum('jumlah');
                $pendapatanSetelahPajak = $gajiPokok + $totalTunjangan - $pphSebulan;
                $totalSavings = max($pendapatanSetelahPajak - $totalBiayaHidup, 0);
                $persenTabungan = ($pendapatanSetelahPajak > 0) ? ($totalSavings / $pendapatanSetelahPajak) * 100 : 0;
                $savingsCategory = $this->getSavingsCategory($persenTabungan);

                // Assign hasil hitung ulang
                $taxCalc->fill([
                    'gaji_pokok' => $gajiPokok,
                    'risiko_kerja' => $risiko,
                    'status_perkawinan' => $statusKawin,
                    'jumlah_tanggungan' => $jumlahTanggungan,
                    'gabung_istri' => $gabungIstri,
                    'penghasilan_bruto_per_bulan' => $penghasilanBruto,
                    'penghasilan_neto_per_bulan' => $penghasilanNetoPerBulan,
                    'penghasilan_neto_per_tahun' => $penghasilanNetoPerTahun,
                    'ptkp' => $ptkp,
                    'penghasilan_kena_pajak' => $pkp,
                    'pph_terutang_setahun' => $pphSetahun,
                    'pph_terutang_sebulan' => $pphSebulan,
                    'gaji_bersih_setelah_pajak' => $gajiBersih,
                    'total_savings' => $totalSavings,
                    'savings_category' => $savingsCategory,
                ]);

                // Update child tabel allowances
                if ($request->has('tunjangan')) {
                    Allowance::where('tax_calculation_id', $taxCalc->id)->delete();
                    foreach ($tunjanganArray as $tunj) {
                        Allowance::create([
                            'tax_calculation_id' => $taxCalc->id,
                            'jenis' => $tunj['jenis'],
                            'jumlah' => $tunj['jumlah']
                        ]);
                    }
                }

                // Update child tabel living_costs
                if ($request->has('biaya_hidup')) {
                    LivingCost::where('tax_calculation_id', $taxCalc->id)->delete();
                    foreach ($biayaHidupArray as $bh) {
                        LivingCost::create([
                            'tax_calculation_id' => $taxCalc->id,
                            'jenis' => $bh['jenis'],
                            'jumlah' => $bh['jumlah']
                        ]);
                    }
                }
            }

            $taxCalc->save();
        });

        return response()->json([
            'message' => 'Data berhasil diupdate',
            'data' => $taxCalc->fresh()
        ]);
    }

    /**
     * DELETE /api/delete/{id}
     * Menghapus data perhitungan beserta relasi
     */
    public function destroy($id)
    {
        $taxCalc = TaxCalculation::findOrFail($id);
        DB::transaction(function () use ($taxCalc) {
            Allowance::where('tax_calculation_id', $taxCalc->id)->delete();
            LivingCost::where('tax_calculation_id', $taxCalc->id)->delete();
            $taxCalc->delete();
        });
        return response()->json(['message' => 'Data berhasil dihapus']);
    }

    // ------------------------------------------------------------------
    // Helper functions
    // ------------------------------------------------------------------
    private function getJKKRate($risiko) {
        $rates = [
            'Sangat Rendah' => 0.0024,
            'Rendah' => 0.0054,
            'Sedang' => 0.0089,
            'Tinggi' => 0.0127,
            'Sangat Tinggi' => 0.0174
        ];
        return $rates[$risiko];
    }

    private function calculatePTKP($status, $tanggungan, $gabungIstri) {
        $tk = [0=>54000000, 1=>58500000, 2=>63000000, 3=>67500000];
        $k  = [0=>58500000, 1=>63000000, 2=>67500000, 3=>72000000];
        $ki = [0=>112500000, 1=>117000000, 2=>121500000, 3=>126000000];
        if ($status == 'Tidak Kawin') return $tk[$tanggungan];
        if ($status == 'Kawin' && !$gabungIstri) return $k[$tanggungan];
        if ($status == 'Kawin' && $gabungIstri) return $ki[$tanggungan];
        return $tk[0]; // fallback
    }

    private function calculatePPh($pkp) {
        $tax = 0;
        if ($pkp <= 60000000) {
            $tax = $pkp * 0.05;
        } elseif ($pkp <= 250000000) {
            $tax = 60000000 * 0.05 + ($pkp - 60000000) * 0.15;
        } elseif ($pkp <= 500000000) {
            $tax = 60000000 * 0.05 + 190000000 * 0.15 + ($pkp - 250000000) * 0.25;
        } elseif ($pkp <= 5000000000) {
            $tax = 60000000 * 0.05 + 190000000 * 0.15 + 250000000 * 0.25 + ($pkp - 500000000) * 0.3;
        } else {
            $tax = 60000000 * 0.05 + 190000000 * 0.15 + 250000000 * 0.25 + 4500000000 * 0.3 + ($pkp - 5000000000) * 0.35;
        }
        return $tax;
    }

    private function getSavingsCategory(float $percentage): string
    {
        if ($percentage < 10) return 'Siaga/Rentan';
        if ($percentage <= 19) return 'Standar/Cukup';
        if ($percentage == 20) return 'Ideal/Sehat';
        if ($percentage <= 40) return 'Agresif/Kuat';
        return 'Ekstrem/Frugal';
    }
}