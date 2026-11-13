class AppNotifikasi {
  final int id;
  final int userId;
  final int? perizinanId;
  final String judul;
  final String isi;
  final bool dibaca;
  final DateTime createdAt;

  const AppNotifikasi({
    required this.id,
    required this.userId,
    this.perizinanId,
    required this.judul,
    required this.isi,
    required this.dibaca,
    required this.createdAt,
  });

  factory AppNotifikasi.fromMap(Map<String, Object?> m) => AppNotifikasi(
    id: m['id'] as int,
    userId: m['user_id'] as int,
    perizinanId: m['perizinan_id'] as int?,
    judul: m['judul'] as String,
    isi: m['isi'] as String,
    dibaca: (m['dibaca'] as int) == 1,
    createdAt: DateTime.parse(m['created_at'] as String),
  );
}
