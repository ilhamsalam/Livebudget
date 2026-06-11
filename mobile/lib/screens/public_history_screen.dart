import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/calculation.dart';
import '../widgets/category_pill.dart';
import '../utils/formatter.dart';

class PublicHistoryScreen extends StatefulWidget {
  @override
  _PublicHistoryScreenState createState() => _PublicHistoryScreenState();
}

class _PublicHistoryScreenState extends State<PublicHistoryScreen> {
  List<Calculation> _list = [];
  bool _loading = true;
  String _sortBy = 'created_at';
  String _sortDir = 'desc';
  int _page = 1;
  int _lastPage = 1;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.getPublicHistory(page: _page, sortBy: _sortBy, sortDirection: _sortDir);
      setState(() {
        _list = (res['data'] as List).map((e) => Calculation.fromJson(e)).toList();
        _lastPage = res['last_page'] ?? 1;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat'), backgroundColor: Colors.red));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _changeSort(String sort) {
    if (_sortBy == sort) {
      _sortDir = _sortDir == 'asc' ? 'desc' : 'asc';
    } else {
      _sortBy = sort;
      _sortDir = 'asc';
    }
    _page = 1;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(padding: EdgeInsets.all(8), child: Row(children: [
          DropdownButton<String>(
            value: _sortBy,
            items: ['created_at', 'gaji_pokok', 'total_savings', 'user.name'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) { _changeSort(v!); },
          ),
          IconButton(icon: Icon(_sortDir == 'asc' ? Icons.arrow_upward : Icons.arrow_downward), onPressed: () { _sortDir = _sortDir == 'asc' ? 'desc' : 'asc'; _load(); }),
        ])),
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator())
              : (_list.isEmpty
                  ? Center(child: Text('Belum ada data publik'))
                  : ListView.builder(
                      itemCount: _list.length,
                      itemBuilder: (ctx, i) {
                        final c = _list[i];
                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: ListTile(
                            leading: Text('${c.id}'),
                            title: Text(c.userName ?? 'User ${c.userId}'),
                            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Gaji: ${formatRupiah(c.gajiPokok)} | PPh: ${formatRupiah(c.pphTerutangSebulan)}'),
                              Text('Tabungan: ${formatRupiah(c.totalSavings)}'),
                              CategoryPill(c.savingsCategory),
                            ]),
                            isThreeLine: true,
                          ),
                        );
                      },
                    )),
        ),
        if (_lastPage > 1)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(icon: Icon(Icons.chevron_left), onPressed: _page > 1 ? () { setState(() { _page--; }); _load(); } : null),
            Text('$_page / $_lastPage'),
            IconButton(icon: Icon(Icons.chevron_right), onPressed: _page < _lastPage ? () { setState(() { _page++; }); _load(); } : null),
          ]),
      ],
    );
  }
}