class Routes {
  static const splash = '/splash';
  static const login = '/login';

  static const santriHome = '/santri';
  static const santriAjukan = '/santri/ajukan';
  static const santriRiwayat = '/santri/riwayat';
  static const santriProfil = '/santri/profil';

  static const pengurusHome = '/pengurus';
  static String santriForm(String jenis) => '$santriAjukan/$jenis';
  static String santriDetail(int id) => '$santriRiwayat/$id';
  static String santriUbah(int id) => '$santriRiwayat/$id/ubah';

  static const pengurusPengajuan = '/pengurus/pengajuan';
  static const pengurusRiwayat = '/pengurus/riwayat';
  static const pengurusProfil = '/pengurus/profil';
  static String pengurusDetailPengajuan(int id) => '$pengurusPengajuan/$id';
  static String pengurusDetailRiwayat(int id) => '$pengurusRiwayat/$id';

  static const santriNotifikasi = '/santri/notifikasi';
  static const pengurusNotifikasi = '/pengurus/notifikasi';
  static const pengurusIzinSaya = '/pengurus/izin-saya';
}

/// Kumpulan rute untuk mengelola izin milik sendiri.
class IzinRoutes {
  const IzinRoutes({required this.daftar, required this.ajukan});

  final String daftar; // daftar izin milik sendiri
  final String ajukan; // pemilih jenis izin

  String form(String jenis) => '$ajukan/$jenis';
  String detail(int id) => '$daftar/$id';
  String ubah(int id) => '$daftar/$id/ubah';

  static const santri = IzinRoutes(
    daftar: Routes.santriRiwayat,
    ajukan: Routes.santriAjukan,
  );
  static const pengurus = IzinRoutes(
    daftar: Routes.pengurusIzinSaya,
    ajukan: '${Routes.pengurusIzinSaya}/ajukan',
  );
}
