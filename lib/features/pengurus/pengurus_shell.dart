import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'pengurus_provider.dart';

class PengurusShell extends StatelessWidget {
  const PengurusShell({
    super.key,
    required this.navigationShell,
    this.sembunyikanNav = false,
  });

  final StatefulNavigationShell navigationShell;
  final bool sembunyikanNav;

  @override
  Widget build(BuildContext context) {
    final antrean = context.select<PengurusProvider, int>(
      (p) => p.jumlahAntrean,
    );

    Widget lencana(IconData ikon) => Badge(
      label: Text('$antrean'),
      isLabelVisible: antrean > 0,
      child: Icon(ikon),
    );

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
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: lencana(Icons.inbox_outlined),
                  selectedIcon: lencana(Icons.inbox),
                  label: 'Pengajuan',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.history),
                  selectedIcon: Icon(Icons.history_toggle_off),
                  label: 'Riwayat',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profil',
                ),
              ],
            ),
    );
  }
}
