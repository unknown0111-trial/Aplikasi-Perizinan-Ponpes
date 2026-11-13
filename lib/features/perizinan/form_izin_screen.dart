import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/routes.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/picker_field.dart';
import '../../data/models/enums.dart';
import '../../data/models/perizinan_model.dart';
import '../../data/repositories/perizinan_repository.dart';
import '../auth/auth_provider.dart';
import 'perizinan_provider.dart';

class FormIzinScreen extends StatefulWidget {
  const FormIzinScreen({
    super.key,
    required this.jenis,
    this.awal,
    this.rute = IzinRoutes.santri,
  });

  final JenisIzin jenis;
  final Perizinan? awal;
  final IzinRoutes rute;

  @override
  State<FormIzinScreen> createState() => _FormIzinScreenState();
}

class _FormIzinScreenState extends State<FormIzinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tujuan = TextEditingController();
  final _penjemput = TextEditingController();
  final _keluhan = TextEditingController();
  final _alasan = TextEditingController();
  final _keterangan = TextEditingController();

  late DateTime _mulai;
  late DateTime _selesai;
  TimeOfDay? _jamKeluar;
  TimeOfDay? _jamKembali;
  bool _sakitDiAsrama = true;

  bool _submitted = false;
  bool _saving = false;
  String? _errorServer;

  bool get _modeUbah => widget.awal != null;
  DateTime get _hariIni {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  TimeOfDay? _parseJam(String? s) {
    if (s == null) return null;
    final p = s.split(':');
    if (p.length != 2) return null;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String? _cekMulai() {
    if (widget.jenis != JenisIzin.sakit && _mulai.isBefore(_hariIni)) {
      return 'Tanggal sudah lewat, pilih tanggal baru';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final a = widget.awal;
    if (a == null) {
      _mulai = _selesai = _hariIni;
      return;
    }
    _mulai = a.tanggalMulai;
    _selesai = a.tanggalSelesai;
    _jamKeluar = _parseJam(a.jamKeluar);
    _jamKembali = _parseJam(a.jamKembali);
    if (a.jenis == JenisIzin.sakit) {
      _sakitDiAsrama = a.tujuan != 'Berobat ke luar pesantren';
    } else {
      _tujuan.text = a.tujuan ?? '';
    }
    _penjemput.text = a.penjemput ?? '';
    _keluhan.text = a.keluhan ?? '';
    _alasan.text = a.alasan;
    _keterangan.text = a.keterangan ?? '';
  }

  @override
  void dispose() {
    _tujuan.dispose();
    _penjemput.dispose();
    _keluhan.dispose();
    _alasan.dispose();
    _keterangan.dispose();
    super.dispose();
  }

  // ---------- Helper ----------
  String _fmtJam(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  int _menit(TimeOfDay t) => t.hour * 60 + t.minute;

  /// Setelah percobaan kirim pertama, error ikut diperbarui saat nilai berubah.
  void _revalidate() {
    if (_submitted) _formKey.currentState?.validate();
  }

  String? _opt(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  // ---------- Picker ----------
  Future<void> _pilihTanggal({required bool mulai}) async {
    final h = _hariIni;
    // Izin sakit boleh diajukan mundur sampai 7 hari.
    final paling = widget.jenis == JenisIzin.sakit
        ? DateTime(h.year, h.month, h.day - 7)
        : h;
    final awal = mulai ? paling : _mulai;

    final dipilih = await showDatePicker(
      context: context,
      initialDate: (mulai ? _mulai : _selesai),
      firstDate: awal,
      lastDate: DateTime(h.year + 1, h.month, h.day),
      helpText: mulai
          ? (widget.jenis == JenisIzin.keluar
                ? 'Tanggal keluar'
                : 'Tanggal mulai')
          : 'Tanggal selesai',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (dipilih == null) return;
    setState(() {
      if (mulai) {
        _mulai = dipilih;
        if (_selesai.isBefore(dipilih)) _selesai = dipilih;
      } else {
        _selesai = dipilih;
      }
    });
    _revalidate();
  }

  Future<void> _pilihJam({required bool keluar}) async {
    final dipilih = await showTimePicker(
      context: context,
      initialTime: (keluar ? _jamKeluar : _jamKembali) ?? TimeOfDay.now(),
      helpText: keluar ? 'Jam keluar' : 'Jam kembali',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (dipilih == null) return;
    setState(() => keluar ? _jamKeluar = dipilih : _jamKembali = dipilih);
    _revalidate();
  }

  // ---------- Kirim ----------
  Future<void> _kirim() async {
    setState(() {
      _submitted = true;
      _errorServer = null;
    });
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final user = context.read<AuthProvider>().user!;
    final provider = context.read<PerizinanProvider>();
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final jenis = widget.jenis;
    final awal = widget.awal;

    final izin = Perizinan(
      id: awal?.id,
      userId: user.id!,
      jenis: jenis,
      tanggalPengajuan: awal?.tanggalPengajuan ?? DateTime.now(),
      tanggalMulai: _mulai,
      tanggalSelesai: jenis == JenisIzin.keluar ? _mulai : _selesai,
      jamKeluar: jenis == JenisIzin.keluar ? _fmtJam(_jamKeluar!) : null,
      jamKembali: jenis == JenisIzin.keluar ? _fmtJam(_jamKembali!) : null,
      tujuan: switch (jenis) {
        JenisIzin.keluar || JenisIzin.pulang => _opt(_tujuan.text),
        JenisIzin.sakit =>
          _sakitDiAsrama ? 'Istirahat di asrama' : 'Berobat ke luar pesantren',
      },
      penjemput: jenis == JenisIzin.pulang ? _opt(_penjemput.text) : null,
      keluhan: jenis == JenisIzin.sakit ? _opt(_keluhan.text) : null,
      alasan: _alasan.text.trim(),
      keterangan: _opt(_keterangan.text),
    );

    setState(() => _saving = true);
    try {
      if (awal == null) {
        await provider.ajukan(izin);
      } else {
        await provider.perbarui(izin);
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              awal == null
                  ? '${jenis.label} berhasil diajukan'
                  : 'Perubahan disimpan',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      router.pop();
      // Mode buat: lanjut ke Riwayat. Mode ubah: cukup kembali ke detail.
      if (awal == null) router.go(widget.rute.daftar);
    } on PerizinanException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorServer = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorServer = 'Gagal menyimpan pengajuan. Silakan coba lagi.';
        });
      }
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final jenis = widget.jenis;
    final lamaHari = _selesai.difference(_mulai).inDays + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(_modeUbah ? 'Ubah ${jenis.label}' : 'Form ${jenis.label}'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Data pemohon (otomatis) ---
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _InfoRow('Nama', user.nama),
                        _InfoRow('No. identitas', user.noIdentitas),
                        _InfoRow('Jenis izin', jenis.label),
                        _InfoRow(
                          'Tgl. pengajuan',
                          Fmt.tanggal(
                            widget.awal?.tanggalPengajuan ?? DateTime.now(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- Waktu ---
                _Judul('Waktu izin', text, scheme),
                if (jenis == JenisIzin.keluar) ...[
                  PickerField(
                    label: 'Tanggal keluar',
                    icon: Icons.event_outlined,
                    teks: Fmt.hariLengkap(_mulai),
                    onTap: () => _pilihTanggal(mulai: true),
                    cek: _cekMulai,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: PickerField(
                          label: 'Jam keluar',
                          icon: Icons.schedule,
                          teks: _jamKeluar == null
                              ? null
                              : _fmtJam(_jamKeluar!),
                          onTap: () => _pilihJam(keluar: true),
                          cek: () =>
                              _jamKeluar == null ? 'Pilih jam keluar' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PickerField(
                          label: 'Jam kembali',
                          icon: Icons.schedule,
                          teks: _jamKembali == null
                              ? null
                              : _fmtJam(_jamKembali!),
                          onTap: () => _pilihJam(keluar: false),
                          cek: () {
                            if (_jamKembali == null) return 'Pilih jam kembali';
                            if (_jamKeluar != null &&
                                _menit(_jamKembali!) <= _menit(_jamKeluar!)) {
                              return 'Harus setelah jam keluar';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  PickerField(
                    label: 'Tanggal mulai',
                    icon: Icons.event_outlined,
                    teks: Fmt.hariLengkap(_mulai),
                    onTap: () => _pilihTanggal(mulai: true),
                    cek: _cekMulai,
                  ),
                  const SizedBox(height: 16),
                  PickerField(
                    label: 'Tanggal selesai',
                    icon: Icons.event_available_outlined,
                    teks: Fmt.hariLengkap(_selesai),
                    onTap: () => _pilihTanggal(mulai: false),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      'Lama izin: $lamaHari hari',
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],

                // --- Detail sesuai jenis ---
                _Judul('Detail ${jenis.label.toLowerCase()}', text, scheme),
                ..._fieldKhusus(text, scheme),

                // --- Alasan ---
                _Judul('Alasan', text, scheme),
                TextFormField(
                  controller: _alasan,
                  minLines: 3,
                  maxLines: 4,
                  maxLength: 300,
                  textCapitalization: TextCapitalization.sentences,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Alasan izin',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => Validators.minimal(v, 'Alasan', 10),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _keterangan,
                  minLines: 2,
                  maxLines: 3,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Keterangan tambahan (opsional)',
                    alignLabelWithHint: true,
                  ),
                ),

                // --- Error dari aturan data (mis. tanggal bentrok) ---
                if (_errorServer != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: scheme.onErrorContainer,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorServer!,
                            style: text.bodyMedium?.copyWith(
                              color: scheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _kirim,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(
                          _modeUbah ? 'Simpan perubahan' : 'Kirim pengajuan',
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _fieldKhusus(TextTheme text, ColorScheme scheme) {
    switch (widget.jenis) {
      case JenisIzin.keluar:
        return [
          TextFormField(
            controller: _tujuan,
            textCapitalization: TextCapitalization.sentences,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: const InputDecoration(
              labelText: 'Tujuan',
              prefixIcon: Icon(Icons.place_outlined),
            ),
            validator: (v) => Validators.wajib(v, 'Tujuan'),
          ),
        ];
      case JenisIzin.pulang:
        return [
          TextFormField(
            controller: _tujuan,
            textCapitalization: TextCapitalization.sentences,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: const InputDecoration(
              labelText: 'Alamat / tujuan pulang',
              prefixIcon: Icon(Icons.home_outlined),
            ),
            validator: (v) => Validators.wajib(v, 'Tujuan'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _penjemput,
            textCapitalization: TextCapitalization.words,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: const InputDecoration(
              labelText: 'Nama penjemput',
              hintText: 'Contoh: Ayah, Kakak',
              prefixIcon: Icon(Icons.people_outline),
            ),
            validator: (v) => Validators.wajib(v, 'Penjemput'),
          ),
        ];
      case JenisIzin.sakit:
        return [
          Text(
            'Lokasi pemulihan',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Di asrama')),
              ButtonSegment(value: false, label: Text('Berobat keluar')),
            ],
            selected: {_sakitDiAsrama},
            onSelectionChanged: (s) => setState(() => _sakitDiAsrama = s.first),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _keluhan,
            minLines: 2,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: const InputDecoration(
              labelText: 'Keluhan / gejala',
              alignLabelWithHint: true,
            ),
            validator: (v) => Validators.wajib(v, 'Keluhan'),
          ),
        ];
    }
  }
}

class _Judul extends StatelessWidget {
  const _Judul(this.teks, this.text, this.scheme);
  final String teks;
  final TextTheme text;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(
      teks,
      style: text.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.primary,
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.nilai);
  final String label;
  final String nilai;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              nilai,
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
