import 'enums.dart';

class AppUser {
  final int? id;
  final String nama;
  final String noIdentitas; // nomor kartu santri / username pengurus
  final String? passwordHash;
  final String? salt;
  final UserRole role;
  final int levelPengurus; // 0 = santri, 1 = pengurus, 2 = pengurus senior
  final String? kelas;
  final String? noHpWali;

  const AppUser({
    this.id,
    required this.nama,
    required this.noIdentitas,
    this.passwordHash,
    this.salt,
    required this.role,
    this.levelPengurus = 0,
    this.kelas,
    this.noHpWali,
  });

  bool get isPengurus => role == UserRole.pengurus;

  String get jabatan => switch (levelPengurus) {
    2 => 'Pengurus Senior',
    1 => 'Pengurus',
    _ => 'Santri',
  };

  factory AppUser.fromMap(Map<String, Object?> m) => AppUser(
    id: m['id'] as int?,
    nama: m['nama'] as String,
    noIdentitas: m['no_identitas'] as String,
    passwordHash: m['password_hash'] as String?,
    salt: m['salt'] as String?,
    role: UserRole.values.byName(m['role'] as String),
    levelPengurus: (m['level_pengurus'] as int?) ?? 0,
    kelas: m['kelas'] as String?,
    noHpWali: m['no_hp_wali'] as String?,
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'nama': nama,
    'no_identitas': noIdentitas,
    'password_hash': passwordHash,
    'salt': salt,
    'role': role.name,
    'level_pengurus': levelPengurus,
    'kelas': kelas,
    'no_hp_wali': noHpWali,
  };
}
