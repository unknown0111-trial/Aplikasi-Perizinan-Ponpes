import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

class SantriShell extends StatelessWidget {
  const SantriShell({
    super.key,
    required this.navigationShell,
    this.sembunyikanNav = false,
  });
  final StatefulNavigationShell navigationShell;
  final bool sembunyikanNav;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: sembunyikanNav
          ? null
          : NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (i) => navigationShell.goBranch(
                i,
                initialLocation: i == navigationShell.currentIndex,
              ),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Beranda',
                ),
                NavigationDestination(
                  icon: Icon(Icons.add_circle_outline),
                  selectedIcon: Icon(Icons.add_circle),
                  label: 'Ajukan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history),
                  selectedIcon: Icon(Icons.history_toggle_off),
                  label: 'Riwayat',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profil',
                ),
              ],
            ),
    );
  }
}
