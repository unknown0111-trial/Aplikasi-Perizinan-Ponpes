import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/utils/validators.dart';
import '../auth/auth_provider.dart';

/// Mengembalikan true jika password berhasil diubah.
class UbahPasswordDialog extends StatefulWidget {
  const UbahPasswordDialog({super.key});

  @override
  State<UbahPasswordDialog> createState() => _UbahPasswordDialogState();
}

class _UbahPasswordDialogState extends State<UbahPasswordDialog> {
  final _form = GlobalKey<FormState>();
  final _lama = TextEditingController();
  final _baru = TextEditingController();
  final _konfirmasi = TextEditingController();
  bool _sembunyi = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _lama.dispose();
    _baru.dispose();
    _konfirmasi.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final err = await context.read<AuthProvider>().gantiPassword(
      _lama.text,
      _baru.text,
    );
    if (!mounted) return;
    if (err == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      scrollable: true,
      title: const Text('Ubah password'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _lama,
              obscureText: _sembunyi,
              decoration: InputDecoration(
                labelText: 'Password lama',
                suffixIcon: IconButton(
                  tooltip: _sembunyi ? 'Tampilkan' : 'Sembunyikan',
                  icon: Icon(
                    _sembunyi
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _sembunyi = !_sembunyi),
                ),
              ),
              validator: Validators.password,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _baru,
              obscureText: _sembunyi,
              decoration: const InputDecoration(
                labelText: 'Password baru',
                helperText: 'Minimal 8 karakter',
              ),
              validator: (v) {
                if (v == null || v.length < 8) return 'Minimal 8 karakter';
                if (v == _lama.text) return 'Harus berbeda dari password lama';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _konfirmasi,
              obscureText: _sembunyi,
              decoration: const InputDecoration(
                labelText: 'Ulangi password baru',
              ),
              validator: (v) => v != _baru.text ? 'Password tidak sama' : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: _saving ? null : _simpan,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}

/// Mengembalikan true jika nomor berhasil disimpan.
class UbahNoHpDialog extends StatefulWidget {
  const UbahNoHpDialog({super.key, this.awal});
  final String? awal;

  @override
  State<UbahNoHpDialog> createState() => _UbahNoHpDialogState();
}

class _UbahNoHpDialogState extends State<UbahNoHpDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.awal ?? '',
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final err = await context.read<AuthProvider>().ubahNoHpWali(_ctrl.text);
    if (!mounted) return;
    if (err == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      scrollable: true,
      title: const Text('Nomor HP wali'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _ctrl,
              keyboardType: TextInputType.phone,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nomor HP',
                hintText: '08xxxxxxxxxx',
                helperText: 'Kosongkan untuk menghapus',
              ),
              validator: Validators.noHp,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: _saving ? null : _simpan,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
