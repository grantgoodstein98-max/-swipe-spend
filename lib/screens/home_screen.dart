import 'package:flutter/material.dart';
import 'swipe_screen.dart';
import 'charts_screen.dart';
import 'budget_screen.dart';
import 'ai_assistant_screen.dart';
import 'settings_screen.dart';

/// Main home screen with bottom navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

  /// Find the nearest HomeScreen and switch to a specific tab
  static void switchTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_HomeScreenState>();
    state?.setState(() {
      state._currentIndex = index;
    });
  }
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // List of screens for each tab (Settings removed - accessed via AppBar icon)
  final List<Widget> _screens = const [
    SwipeScreen(),
    ChartsScreen(),
    BudgetScreen(),
    AiAssistantScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 4,
      initialIndex: _currentIndex,
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark
                    ? const Color(0xFF38383A).withOpacity(0.5)
                    : const Color(0xFFD1D1D6).withOpacity(0.3),
                width: 0.5,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.swipe_outlined),
                activeIcon: Icon(Icons.swipe_rounded),
                label: 'Swipe',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.pie_chart_outline_rounded),
                activeIcon: Icon(Icons.pie_chart_rounded),
                label: 'Charts',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Budget',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.psychology_outlined),
                activeIcon: Icon(Icons.psychology_rounded),
                label: 'AI',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
