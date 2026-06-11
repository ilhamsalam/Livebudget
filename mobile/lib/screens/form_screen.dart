import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

class FormScreen extends StatefulWidget {
  @override
  _FormScreenState createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _gajiCtrl = TextEditingController();
  String _risiko = 'Sedang';
  String _status = 'Tidak Kawin';
  int _tanggungan = 0;
  bool _gabungIstri = false;
  bool _isPublic = false;

  List<Map<String, dynamic>> _tunjangan = []; // each item: {'jenis': controller, 'jumlah': controller}
  List<Map<String, dynamic>> _biaya = [];

  final ApiService _api = ApiService();
  bool _loading = false;

  void _addTunjangan() {
    if (_tunjangan.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Maksimal 5 tunjangan')));
      return;
    }
    setState(() {
      _tunjangan.add({
        'jenis': TextEditingController(),
        'jumlah': TextEditingController(),
      });
    });
  }

  void _removeTunjangan(int index) {
    setState(() {
      _tunjangan.removeAt(index);
    });
  }

  void _addBiaya() {
    setState(() {
      _biaya.add({
        'jenis': TextEditingController(),
        'jumlah': TextEditingController(),
      });
    });
  }

  void _removeBiaya(int index) {
    setState(() {
      _biaya.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();
    // Tambahkan satu biaya default agar minimal 1
    _addBiaya();
  }

  @override
  void dispose() {
    _gajiCtrl.dispose();
    for (var t in _tunjangan) {
      t['jenis'].dispose();
      t['jumlah'].dispose();
    }
    for (var b in _biaya) {
      b['jenis'].dispose();
      b['jumlah'].dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final gaji = double.tryParse(_gajiCtrl.text);
    if (gaji == null || gaji <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Masukkan gaji pokok yang valid')));
      return;
    }
    if (_biaya.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Minimal satu biaya hidup')));
      return;
    }

    final tunjanganData = _tunjangan
        .map((t) => {
              'jenis': t['jenis'].text,
              'jumlah': double.tryParse(t['jumlah'].text) ?? 0,
            })
        .where((e) => e['jenis'].isNotEmpty && e['jumlah'] > 0)
        .toList();

    final biayaData = _biaya
        .map((b) => {
              'jenis': b['jenis'].text,
              'jumlah': double.tryParse(b['jumlah'].text) ?? 0,
            })
        .where((e) => e['jenis'].isNotEmpty && e['jumlah'] > 0)
        .toList();

    if (biayaData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Minimal satu biaya hidup dengan nominal > 0')));
      return;
    }

    final data = {
      'gaji_pokok': gaji,
      'tunjangan': tunjanganData,
      'risiko_kerja': _risiko,
      'status_perkawinan': _status,
      'jumlah_tanggungan': _tanggungan,
      'gabung_istri': _gabungIstri,
      'biaya_hidup': biayaData,
      'user_id': context.read<AuthProvider>().user!.id,
      'is_public': _isPublic,
    };

    setState(() => _loading = true);
    try {
      final result = await _api.calculate(data);
      Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen(result: result, inputData: data)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(controller: _gajiCtrl, decoration: InputDecoration(labelText: 'Gaji Pokok (Rp)'), keyboardType: TextInputType.number),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _risiko,
            items: ['Sangat Rendah','Rendah','Sedang','Tinggi','Sangat Tinggi'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _risiko = v!),
            decoration: InputDecoration(labelText: 'Risiko Kerja'),
          ),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _status,
            items: ['Tidak Kawin','Kawin'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _status = v!),
            decoration: InputDecoration(labelText: 'Status Perkawinan'),
          ),
          if (_status == 'Kawin')
            Row(children: [
              Checkbox(value: _gabungIstri, onChanged: (v) => setState(() => _gabungIstri = v!)),
              Text('Gabung dengan istri'),
            ]),
          SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _tanggungan,
            items: [0,1,2,3].map((e) => DropdownMenuItem(value: e, child: Text('$e orang'))).toList(),
            onChanged: (v) => setState(() => _tanggungan = v!),
            decoration: InputDecoration(labelText: 'Jumlah Tanggungan'),
          ),
          Divider(),
          Text('Tunjangan (Opsional, max 5)', style: TextStyle(fontWeight: FontWeight.bold)),
          ..._tunjangan.asMap().entries.map((entry) {
            int idx = entry.key;
            var t = entry.value;
            return Row(
              children: [
                Expanded(child: TextField(controller: t['jenis'], decoration: InputDecoration(hintText: 'Jenis tunjangan'))),
                SizedBox(width: 8),
                Expanded(child: TextField(controller: t['jumlah'], decoration: InputDecoration(hintText: 'Jumlah (Rp)'), keyboardType: TextInputType.number)),
                IconButton(icon: Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _removeTunjangan(idx)),
              ],
            );
          }).toList(),
          if (_tunjangan.length < 5)
            ElevatedButton(onPressed: _addTunjangan, child: Text('+ Tambah Tunjangan'), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800])),
          Divider(),
          Text('Biaya Hidup (Minimal 1)', style: TextStyle(fontWeight: FontWeight.bold)),
          ..._biaya.asMap().entries.map((entry) {
            int idx = entry.key;
            var b = entry.value;
            return Row(
              children: [
                Expanded(child: TextField(controller: b['jenis'], decoration: InputDecoration(hintText: 'Jenis biaya'))),
                SizedBox(width: 8),
                Expanded(child: TextField(controller: b['jumlah'], decoration: InputDecoration(hintText: 'Jumlah (Rp)'), keyboardType: TextInputType.number)),
                IconButton(icon: Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _removeBiaya(idx)),
              ],
            );
          }).toList(),
          ElevatedButton(onPressed: _addBiaya, child: Text('+ Tambah Biaya'), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800])),
          Divider(),
          Row(children: [
            Checkbox(value: _isPublic, onChanged: (v) => setState(() => _isPublic = v!)),
            Text('Publikasikan hasil ini'),
          ]),
          SizedBox(height: 20),
          Center(
            child: _loading
                ? CircularProgressIndicator()
                : ElevatedButton(onPressed: _submit, child: Text('Hitung Sekarang'), style: ElevatedButton.styleFrom(minimumSize: Size(200, 48))),
          ),
        ],
      ),
    );
  }
}