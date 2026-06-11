class Allowance {
  final String jenis;
  final double jumlah;

  Allowance({required this.jenis, required this.jumlah});

  Map<String, dynamic> toJson() => {'jenis': jenis, 'jumlah': jumlah};

  factory Allowance.fromJson(Map<String, dynamic> json) {
    double jumlah = 0.0;
    if (json['jumlah'] is double) jumlah = json['jumlah'];
    else if (json['jumlah'] is int) jumlah = (json['jumlah'] as int).toDouble();
    else if (json['jumlah'] is String) jumlah = double.tryParse(json['jumlah']) ?? 0.0;
    
    return Allowance(
      jenis: json['jenis'] ?? '',
      jumlah: jumlah,
    );
  }
}