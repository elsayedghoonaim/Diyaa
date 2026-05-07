import 'package:flutter/material.dart';
import '../widgets/shared/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'achievements_screen.dart';
import 'rewards_shop_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static final GlobalKey<MainScreenState> mainKey = GlobalKey<MainScreenState>();

  @override
  State<MainScreen> createState() => MainScreenState();

  /// Switch to a specific tab from anywhere that has access to the key
  static void switchToTab(NavTab tab) {
    mainKey.currentState?._switchTab(tab);
  }
}

class MainScreenState extends State<MainScreen> {
  NavTab _activeTab = NavTab.home;

  void _switchTab(NavTab tab) {
    setState(() => _activeTab = tab);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: DiyaaBottomNav(
        active: _activeTab,
        onTap: _switchTab,
      ),
    );
  }

  Widget _buildBody() {
    switch (_activeTab) {
      case NavTab.home:
        return const HomeScreen();
      case NavTab.library:
        return const LibraryScreen();
      case NavTab.achievements:
        return const AchievementsScreen();
      case NavTab.rewards:
        return const RewardsShopScreen();
      case NavTab.settings:
        return const SettingsScreen();
    }
  }
}
