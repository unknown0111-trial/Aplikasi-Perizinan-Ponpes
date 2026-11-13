import 'package:flutter/foundation.dart';

import '../../data/models/enums.dart';
import '../../data/models/perizinan_model.dart';
import '../../data/repositories/perizinan_repository.dart';

class PerizinanProvider extends ChangeNotifier {
  PerizinanProvider(this._repo, this.userId, {this.onBerubah});

  final PerizinanRepository _repo;
  final int userId;

  /// Dipanggil setelah data milik pengguna berubah (buat/ubah/batal/hapus).
  final VoidCallback? onBerubah;

  List<Perizinan> _items = [];
  bool _loading = false;
  bool _loaded = false;
  bool _reloadQueued = false;
  bool _disposed = false;
  String? _error;

  List<Perizinan> get items => _items;
  bool get isLoading => _loading;
  bool get hasLoaded => _loaded;
  String? get error => _error;

  int hitung(StatusIzin s) => _items.where((e) => e.status == s).length;

  List<Perizinan> get terbaru => _items.take(5).toList();

  /// Izin disetujui yang rentang tanggalnya mencakup hari ini.
  Perizinan? get izinAktif {
    final n = DateTime.now();
    final hariIni = DateTime(n.year, n.month, n.day);
    for (final i in _items) {
      if (i.status == StatusIzin.disetujui &&
          !i.tanggalMulai.isAfter(hariIni) &&
          !i.tanggalSelesai.isBefore(hariIni)) {
        return i;
      }
    }
    return null;
  }
  Perizinan? cari(int id) {
    for (final izin in _items) {
      if (izin.id == id) return izin;
    }
    return null;
  }

  Future<void> load() async {
    if (_loading) {
      _reloadQueued = true;
      return;
    }
    _loading = true;
    _error = null;
    _safeNotify();
    try {
      _items = await _repo.getByUser(userId);
    } catch (_) {
      _error = 'Gagal memuat data perizinan.';
    } finally {
      _loading = false;
      _loaded = true;
      _safeNotify();
    }
    if (_reloadQueued && !_disposed) {
      _reloadQueued = false;
      await load();
    }
  }

  /// Menyimpan pengajuan baru. Melempar [PerizinanException] jika tidak valid
  /// atau bentrok tanggal; pemanggil yang menampilkan pesannya.
  Future<void> ajukan(Perizinan izin) async {
    await _repo.create(izin);
    await load();
    onBerubah?.call();
  }

  Future<void> perbarui(Perizinan izin) async {
    await _repo.update(izin);
    await load();
    onBerubah?.call();
  }

  Future<void> batalkan(int id) async {
    await _repo.batalkan(izinId: id, userId: userId);
    await load();
    onBerubah?.call();
  }

  Future<void> hapus(int id) async {
    await _repo.hapus(izinId: id, userId: userId);
    await load();
    onBerubah?.call();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
