class Validators {
  static String? wajib(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null;

  static String? nama(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nama wajib diisi';
    if (v.trim().length < 3) return 'Nama minimal 3 karakter';
    return null;
  }

  static String? noIdentitas(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nomor identitas wajib diisi';
    if (v.trim().length < 4) return 'Nomor identitas tidak valid';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password wajib diisi';
    return null;
  }

  static String? minimal(String? v, String label, int min) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return '$label wajib diisi';
    if (t.length < min) return '$label minimal $min karakter';
    return null;
  }

  /// Opsional: kosong diperbolehkan.
  static String? noHp(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(t)) {
      return 'Nomor tidak valid (8 sampai 15 angka)';
    }
    return null;
  }
}
