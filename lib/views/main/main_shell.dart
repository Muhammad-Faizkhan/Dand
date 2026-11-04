import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/check_in_banner.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/side_menu.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'marketplace_screen.dart';
import 'profile_screen.dart';

/// Tab shell hosting Home / Market / Map / Profile plus the slide-in menu.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NavController>(
      builder: (context, nav, _) {
        return Builder(
          builder: (context) {
            void openMenu() => Scaffold.of(context).openDrawer();
            // The tabs carry their own content widths: the three scrolling
            // tabs are centred on a tablet, the map keeps the whole viewport.
            final tabs = IndexedStack(
              index: nav.index,
              children: [
                SafeArea(
                  bottom: false,
                  child: ResponsiveCanvas(
                    child: HomeScreen(onMenu: openMenu, onTab: nav.setIndex),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: ResponsiveCanvas(
                    width: ContentWidth.wide,
                    child: MarketplaceScreen(onMenu: openMenu, onTab: nav.setIndex),
                  ),
                ),
                const MapScreen(showBack: false),
                const SafeArea(
                  bottom: false,
                  child: ResponsiveCanvas(width: ContentWidth.wide, child: ProfileScreen()),
                ),
              ],
            );
            return Stack(
              children: [
                tabs,
                const Positioned(left: 0, right: 0, top: 0, child: CheckInBanner()),
              ],
            );
          },
        );
      },
    );
  }
}

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavController>();
    return AppScaffold(
      // Each tab decides its own measure inside MainShell — the map wants the
      // whole viewport, the rest want a centred column.
      contentWidth: ContentWidth.full,
      drawer: const SideMenu(),
      safeAreaTop: false,
      bottomNavigationBar: AppBottomNav(
        currentIndex: nav.index,
        onTap: nav.setIndex,
        onAdd: () => Navigator.pushNamed(context, AppRoutes.addItem),
      ),
      body: const MainShell(),
    );
  }
}
