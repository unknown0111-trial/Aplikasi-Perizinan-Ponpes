import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/utils/validators.dart';
import '../../core/widgets/app_logo.dart';
import 'auth_provider.dart';

enum _LoginRole { santri, pengurus }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _santriKey = GlobalKey<FormState>();
  final _pengurusKey = GlobalKey<FormState>();

  final _nama = TextEditingController();
  final _noId = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();

  _LoginRole _role = _LoginRole.santri;
  bool _hidePassword = true;

  @override
  void dispose() {
    _nama.dispose();
    _noId.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final formKey = _role == _LoginRole.santri ? _santriKey : _pengurusKey;
    if (!formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final ok = _role == _LoginRole.santri
        ? await auth.loginSantri(_nama.text, _noId.text)
        : await auth.loginPengurus(_username.text, _password.text);

    // Jika berhasil, router otomatis berpindah halaman.
    if (!ok && mounted && auth.error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(auth.error!),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final loading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(child: AppLogo()),
                  const SizedBox(height: 24),
                  Text(
                    'Selamat datang',
                    textAlign: TextAlign.center,
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Masuk untuk mengelola perizinan',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SegmentedButton<_LoginRole>(
                    segments: const [
                      ButtonSegment(
                        value: _LoginRole.santri,
                        label: Text('Santri'),
                        icon: Icon(Icons.school_outlined),
                      ),
                      ButtonSegment(
                        value: _LoginRole.pengurus,
                        label: Text('Pengurus'),
                        icon: Icon(Icons.admin_panel_settings_outlined),
                      ),
                    ],
                    selected: {_role},
                    onSelectionChanged: loading
                        ? null
                        : (s) {
                            context.read<AuthProvider>().clearError();
                            setState(() => _role = s.first);
                          },
                  ),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _role == _LoginRole.santri
                        ? _formSantri()
                        : _formPengurus(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: loading ? null : _submit,
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text('Masuk'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formSantri() => Form(
    key: _santriKey,
    child: Column(
      key: const ValueKey('santri'),
      children: [
        TextFormField(
          controller: _nama,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nama lengkap',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: Validators.nama,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _noId,
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.number,
          onFieldSubmitted: (_) => _submit(),
          decoration: const InputDecoration(
            labelText: 'Nomor kartu santri',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          validator: Validators.noIdentitas,
        ),
      ],
    ),
  );

  Widget _formPengurus() => Form(
    key: _pengurusKey,
    child: Column(
      key: const ValueKey('pengurus'),
      children: [
        TextFormField(
          controller: _username,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Username',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (v) => Validators.wajib(v, 'Username'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _password,
          obscureText: _hidePassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: _hidePassword ? 'Tampilkan' : 'Sembunyikan',
              icon: Icon(
                _hidePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
            ),
          ),
          validator: Validators.password,
        ),
      ],
    ),
  );
}
