import 'allowance.dart';

class Calculation {
  final int id;
  final int userId;
  final double gajiPokok;
  final String risikoKerja;
  final String statusPerkawinan;
  final int jumlahTanggungan;
  final bool gabungIstri;
  final double penghasilanBrutoPerBulan;
  final double penghasilanNetoPerBulan;
  final double penghasilanNetoPerTahun;
  final double ptkp;
  final double penghasilanKenaPajak;
  final double pphTerutangSetahun;
  final double pphTerutangSebulan;
  final double gajiBersihSetelahPajak;
  final bool isPublic;
  final double totalSavings;
  final String savingsCategory;
  final DateTime createdAt;
  final String? userName;
  final List<Allowance> allowances;
  final List<Allowance> livingCosts;

  Calculation({
    required this.id,
    required this.userId,
    required this.gajiPokok,
    required this.risikoKerja,
    required this.statusPerkawinan,
    required this.jumlahTanggungan,
    required this.gabungIstri,
    required this.penghasilanBrutoPerBulan,
    required this.penghasilanNetoPerBulan,
    required this.penghasilanNetoPerTahun,
    required this.ptkp,
    required this.penghasilanKenaPajak,
    required this.pphTerutangSetahun,
    required this.pphTerutangSebulan,
    required this.gajiBersihSetelahPajak,
    required this.isPublic,
    required this.totalSavings,
    required this.savingsCategory,
    required this.createdAt,
    this.userName,
    this.allowances = const [],
    this.livingCosts = const [],
  });

  // Helper to convert any numeric value (String or num) to double
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  factory Calculation.fromJson(Map<String, dynamic> json) {
    return Calculation(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id']),
      gajiPokok: _toDouble(json['gaji_pokok']),
      risikoKerja: json['risiko_kerja'] ?? '',
      statusPerkawinan: json['status_perkawinan'] ?? '',
      jumlahTanggungan: _toInt(json['jumlah_tanggungan']),
      gabungIstri: _toBool(json['gabung_istri']),
      penghasilanBrutoPerBulan: _toDouble(json['penghasilan_bruto_per_bulan']),
      penghasilanNetoPerBulan: _toDouble(json['penghasilan_neto_per_bulan']),
      penghasilanNetoPerTahun: _toDouble(json['penghasilan_neto_per_tahun']),
      ptkp: _toDouble(json['ptkp']),
      penghasilanKenaPajak: _toDouble(json['penghasilan_kena_pajak']),
      pphTerutangSetahun: _toDouble(json['pph_terutang_setahun']),
      pphTerutangSebulan: _toDouble(json['pph_terutang_sebulan']),
      gajiBersihSetelahPajak: _toDouble(json['gaji_bersih_setelah_pajak']),
      isPublic: _toBool(json['is_public']),
      totalSavings: _toDouble(json['total_savings']),
      savingsCategory: json['savings_category'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      userName: json['user'] != null ? json['user']['name'] : null,
      allowances: (json['allowances'] as List?)?.map((e) => Allowance.fromJson(e)).toList() ?? [],
      livingCosts: (json['living_costs'] as List?)?.map((e) => Allowance.fromJson(e)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'gaji_pokok': gajiPokok,
        'risiko_kerja': risikoKerja,
        'status_perkawinan': statusPerkawinan,
        'jumlah_tanggungan': jumlahTanggungan,
        'gabung_istri': gabungIstri ? 1 : 0,
        'is_public': isPublic ? 1 : 0,
      };
}