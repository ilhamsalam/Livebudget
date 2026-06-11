import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import '../utils/formatter.dart';
import '../widgets/category_pill.dart';
import '../services/api_service.dart';
import 'form_screen.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;
  final Map<String, dynamic> inputData;
  const ResultScreen({required this.result, required this.inputData});

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _getCategoryDesc(String cat) {
    switch (cat) {
      case 'Siaga/Rentan': return 'Tabungan kurang dari 10% dari pendapatan bersih. Segera kurangi pengeluaran.';
      case 'Standar/Cukup': return 'Tabungan 10-19%. Cukup baik, masih ada ruang perbaikan.';
      case 'Ideal/Sehat': return 'Tabungan tepat 20%. Sangat sehat secara finansial.';
      case 'Agresif/Kuat': return 'Tabungan 20-40%. Disiplin tinggi, target finansial cepat tercapai.';
      case 'Ekstrem/Frugal': return 'Tabungan >40%. Gaya hidup sangat hemat, tapi jangan sampai kehilangan kesenangan hidup.';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = result['data'];

    final gajiPokok = _toDouble(data['gaji_pokok']);
    final penghasilanBruto = _toDouble(data['penghasilan_bruto_per_bulan']);
    final penghasilanNeto = _toDouble(data['penghasilan_neto_per_bulan']);
    final ptkp = _toDouble(data['ptkp']);
    final pkp = _toDouble(data['penghasilan_kena_pajak']);
    final pphSetahun = _toDouble(data['pph_terutang_setahun']);
    final pphSebulan = _toDouble(data['pph_terutang_sebulan']);
    final gajiBersihSetelahPajak = _toDouble(data['gaji_bersih_setelah_pajak']);
    final totalSavings = _toDouble(data['total_savings']);
    final savingsCategory = data['savings_category'] ?? 'Standar/Cukup';

    final totalGajiTunjangan = _toDouble(inputData['gaji_pokok']) +
        (inputData['tunjangan'] as List).fold(0.0, (s, t) => s + _toDouble(t['jumlah']));

    final gajiBersih = totalGajiTunjangan - pphSebulan;
    final totalBiaya = (inputData['biaya_hidup'] as List).fold(0.0, (s, b) => s + _toDouble(b['jumlah']));
    final savings = gajiBersih - totalBiaya;
    final pct = (gajiBersih > 0 ? (savings / gajiBersih) * 100 : 0).toDouble(); // Explicit conversion to double
    final category = savingsCategory;

    final breakdown = {
      ...Map.fromIterable(inputData['biaya_hidup'], key: (e) => e['jenis'], value: (e) => _toDouble(e['jumlah'])),
      if (savings > 0) 'Tabungan': savings,
    };

    return Scaffold(
      appBar: AppBar(title: Text('Hasil Perhitungan'), backgroundColor: Color(0xFF1A2D45)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(color: Color(0xFF1A2D45), child: Padding(padding: EdgeInsets.all(16), child: Column(children: [
              Text('Gaji Bersih Setelah Pajak', style: TextStyle(color: Colors.tealAccent)),
              Text(formatRupiah(gajiBersih), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            ]))),
            Row(children: [
              Expanded(child: Card(child: Padding(padding: EdgeInsets.all(12), child: Column(children: [Text('PPh 21 / Bulan'), Text(formatRupiah(pphSebulan), style: TextStyle(color: Colors.red))])))),
              Expanded(child: Card(child: Padding(padding: EdgeInsets.all(12), child: Column(children: [Text('Tabungan'), Text(formatRupiah(savings), style: TextStyle(color: Colors.orange))])))),
              Expanded(child: Card(child: Padding(padding: EdgeInsets.all(12), child: Column(children: [Text('Persentase'), Text(formatPercent(pct), style: TextStyle(color: Colors.teal))])))),
            ]),
            SizedBox(height: 16),
            Text('Alokasi Biaya & Tabungan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            PieChart(dataMap: breakdown.map((k, v) => MapEntry(k, v.toDouble())), chartRadius: MediaQuery.of(context).size.width / 2.2, legendOptions: LegendOptions(showLegends: true)),
            SizedBox(height: 16),
            Card(child: Padding(padding: EdgeInsets.all(12), child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Kategori'), CategoryPill(category)]),
              SizedBox(height: 8),
              Text(_getCategoryDesc(category), style: TextStyle(color: Colors.grey)),
            ]))),
            SizedBox(height: 16),
            Text('Rincian Perhitungan', style: TextStyle(fontWeight: FontWeight.bold)),
            Table(columnWidths: {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)}, children: [
              _buildRow('Gaji Pokok', formatRupiah(gajiPokok)),
              _buildRow('Penghasilan Bruto', formatRupiah(penghasilanBruto)),
              _buildRow('Penghasilan Neto', formatRupiah(penghasilanNeto)),
              _buildRow('PTKP', formatRupiah(ptkp)),
              _buildRow('PKP', formatRupiah(pkp)),
              _buildRow('PPh Terutang Setahun', formatRupiah(pphSetahun)),
              _buildRow('PPh Terutang Sebulan', formatRupiah(pphSebulan), isBold: true),
            ]),
            SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              ElevatedButton(onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => FormScreen()));
              }, child: Text('Coba Lagi')),
              ElevatedButton(onPressed: () {
                showDialog(context: context, builder: (_) => AlertDialog(
                  title: Text('Publikasi Hasil'),
                  content: Text('Apakah hasil ini ingin dilihat orang lain?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: Text('Tidak')),
                    TextButton(onPressed: () async {
                      final api = ApiService();
                      await api.updateCalculation(data['id'], {'is_public': true});
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data dipublikasikan')));
                    }, child: Text('Ya')),
                  ],
                ));
              }, child: Text('Coba Baru'), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent)),
            ]),
          ],
        ),
      ),
    );
  }

  TableRow _buildRow(String label, String value, {bool isBold = false}) {
    return TableRow(children: [
      Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text(label, style: TextStyle(fontWeight: FontWeight.w500))),
      Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? Colors.tealAccent : null))),
    ]);
  }
}