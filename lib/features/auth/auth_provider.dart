import 'package:flutter/foundation.dart';

import '../../data/models/enums.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { unknown, loggedOut, loggedIn }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repo);
  final AuthRepository _repo;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  bool _loading = false;
  String? _error;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get isLoading => _loading;
  String? get error => _error;
  UserRole? get role => _user?.role;

  /// Dipanggil sekali saat aplikasi dibuka.
  /// Dipanggil sekali saat aplikasi dibuka.
  Future<void> init() async {
    final hasil = await Future.wait([
      _repo.restoreSession(),
      Future<void>.delayed(const Duration(seconds: 3)),
    ]);

    _user = hasil[0] as AppUser?;
    _status = _user == null ? AuthStatus.loggedOut : AuthStatus.loggedIn;

    notifyListeners();
  }

  Future<bool> loginSantri(String nama, String noIdentitas) =>
      _run(() => _repo.loginSantri(nama: nama, noIdentitas: noIdentitas));

  Future<bool> loginPengurus(String username, String password) =>
      _run(() => _repo.loginPengurus(username: username, password: password));

  Future<bool> _run(Future<AppUser> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await action();
      _status = AuthStatus.loggedIn;
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Terjadi kesalahan. Silakan coba lagi.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await _repo.logout();
    _user = null;
    _status = AuthStatus.loggedOut;
    notifyListeners();
  }

  /// Mengembalikan pesan error, atau null jika berhasil.
  Future<String?> gantiPassword(String lama, String baru) async {
    try {
      await _repo.gantiPassword(userId: _user!.id!, lama: lama, baru: baru);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }

  Future<String?> ubahNoHpWali(String noHp) async {
    try {
      _user = await _repo.ubahNoHpWali(userId: _user!.id!, noHp: noHp);
      notifyListeners();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }
}
