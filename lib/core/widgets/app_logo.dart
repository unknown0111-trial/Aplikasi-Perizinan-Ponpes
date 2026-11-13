import 'package:material_ui/material_ui.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 88});
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        Icons.mosque_rounded,
        size: size * 0.55,
        color: scheme.onPrimaryContainer,
      ),
    );
  }
}
