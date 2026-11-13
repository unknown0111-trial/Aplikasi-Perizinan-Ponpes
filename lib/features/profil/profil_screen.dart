import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import 'profil_dialogs.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  void _info(BuildContext context, String pesan) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(pesan), behavior: SnackBarBehavior.floating),
        );

  Future<void> _konfirmasiKeluar(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Anda perlu masuk kembali untuk memakai aplikasi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ya == true) await auth.logout();
  }

  Future<void> _ubahPassword(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const UbahPasswordDialog(),
    );
    if (ok == true && context.mounted) {
      _info(context, 'Password berhasil diubah');
    }
  }

  Future<void> _ubahNoHp(BuildContext context, String? awal) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => UbahNoHpDialog(awal: awal),
    );
    if (ok == true && context.mounted) {
      _info(context, 'Nomor HP wali diperbarui');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final baris = <(IconData, String, String, VoidCallback?)>[
      (
        Icons.badge_outlined,
        user.isPengurus ? 'Username' : 'Nomor kartu santri',
        user.noIdentitas,
        null,
      ),
      (Icons.workspace_premium_outlined, 'Jabatan', user.jabatan, null),
      if (user.kelas != null)
        (Icons.class_outlined, 'Kelas', user.kelas!, null),
      if (!user.isPengurus)
        (
          Icons.phone_outlined,
          'No. HP wali',
          user.noHpWali ?? 'Belum diisi',
          () => _ubahNoHp(context, user.noHpWali),
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  user.nama.trim().isEmpty
                      ? '?'
                      : user.nama.trim()[0].toUpperCase(),
                  style: text.headlineMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                user.nama,
                textAlign: TextAlign.center,
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                user.jabatan,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < baris.length; i++) ...[
                  ListTile(
                    leading: Icon(baris[i].$1),
                    title: Text(
                      baris[i].$2,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    subtitle: Text(baris[i].$3, style: text.bodyLarge),
                    trailing: baris[i].$4 == null
                        ? null
                        : IconButton(
                            tooltip: 'Ubah',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: baris[i].$4,
                          ),
                  ),
                  if (i != baris.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (user.isPengurus) ...[
            OutlinedButton.icon(
              onPressed: () => _ubahPassword(context),
              icon: const Icon(Icons.lock_reset),
              label: const Text('Ubah password'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: () => _konfirmasiKeluar(context),
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: scheme.error,
            ),
          ),
        ],
      ),
    );
  }
}
