import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/calculation.dart';
import '../widgets/category_pill.dart';
import '../utils/formatter.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Calculation> _list = [];
  bool _loading = true;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final userId = context.read<AuthProvider>().user!.id;
      final data = await _api.getHistory(userId);
      setState(() => _list = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text('Hapus Data'),
      content: Text('Yakin ingin menghapus perhitungan ini?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Batal')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Ya'), style: TextButton.styleFrom(foregroundColor: Colors.red)),
      ],
    ));
    if (confirm == true) {
      try {
        await _api.deleteCalculation(id);
        _load();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data dihapus')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal hapus'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _togglePublic(Calculation calc) async {
    final newVal = !calc.isPublic;
    try {
      await _api.updateCalculation(calc.id, {'is_public': newVal});
      _load();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newVal ? 'Data dipublikasikan' : 'Data disembunyikan')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal update publikasi'), backgroundColor: Colors.red));
    }
  }

  void _edit(Calculation calc) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen(result: {'data': calc.toJson()}, inputData: {})));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Center(child: CircularProgressIndicator());
    if (_list.isEmpty) return Center(child: Text('Belum ada data perhitungan', style: TextStyle(color: Colors.grey)));
    return ListView.builder(
      itemCount: _list.length,
      itemBuilder: (ctx, i) {
        final c = _list[i];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: CircleAvatar(child: Text('${c.id}'), backgroundColor: Colors.teal),
            title: Text(formatRupiah(c.gajiPokok), style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('PPh: ${formatRupiah(c.pphTerutangSebulan)} | Tabungan: ${formatRupiah(c.totalSavings)}'),
              CategoryPill(c.savingsCategory),
            ]),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: Icon(c.isPublic ? Icons.public : Icons.lock_outline, color: c.isPublic ? Colors.teal : Colors.grey), onPressed: () => _togglePublic(c)),
              IconButton(icon: Icon(Icons.edit, color: Colors.blue), onPressed: () => _edit(c)),
              IconButton(icon: Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _delete(c.id)),
            ]),
          ),
        );
      },
    );
  }
}