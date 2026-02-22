import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import 'trip_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _itemScaleAnimations;

  static const _screens = [
    DashboardScreen(),
    TripHistoryScreen(),
    SettingsScreen(),
  ];

  static const _navItems = [
    _NavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
      color: Color(0xFF3B82F6),
    ),
    _NavItem(
      icon: Icons.route_outlined,
      activeIcon: Icons.route_rounded,
      label: 'Trips',
      color: Color(0xFF8B5CF6),
    ),
    _NavItem(
      icon: Icons.tune_outlined,
      activeIcon: Icons.tune_rounded,
      label: 'Settings',
      color: Color(0xFFF59E0B),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _itemControllers = List.generate(
      _navItems.length,
      (i) => AnimationController(
        duration: const Duration(milliseconds: 250),
        vsync: this,
        value: i == 0 ? 1.0 : 0.0,
      ),
    );
    _itemScaleAnimations = _itemControllers.map((c) {
      return Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeOutBack),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _itemControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    HapticFeedback.selectionClick();
    _itemControllers[_selectedIndex].reverse();
    setState(() => _selectedIndex = index);
    _itemControllers[index].forward();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF1F5F9),
      extendBody: true, // content flows behind nav bar
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: _screens[_selectedIndex],
        ),
      ),
      bottomNavigationBar: _FloatingNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: _navItems,
        scaleAnimations: _itemScaleAnimations,
        isDark: isDark,
      ),
    );
  }
}

// ─── Floating Nav Bar ──────────────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<_NavItem> items;
  final List<Animation<double>> scaleAnimations;
  final bool isDark;

  const _FloatingNavBar({
    required this.selectedIndex,
    required this.onTap,
    required this.items,
    required this.scaleAnimations,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // SafeArea handles the iPhone notch / Android gesture bar properly
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Container(
          // No fixed height — lets SafeArea + content determine size naturally
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.45 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: List.generate(items.length, (i) {
                return Expanded(
                  child: _NavBarItem(
                    item: items[i],
                    isSelected: selectedIndex == i,
                    scaleAnimation: scaleAnimations[i],
                    onTap: () => onTap(i),
                    isDark: isDark,
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final Animation<double> scaleAnimation;
  final VoidCallback onTap;
  final bool isDark;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.scaleAnimation,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      item.color.withOpacity(isDark ? 0.25 : 0.15),
                      item.color.withOpacity(isDark ? 0.1 : 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with glow
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? item.color.withOpacity(0.15)
                      : Colors.transparent,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: item.color.withOpacity(0.35),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected
                      ? item.color
                      : (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                  size: isSelected ? 24 : 22,
                ),
              ),
              const SizedBox(height: 3),
              // Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  color: isSelected
                      ? item.color
                      : (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                  fontSize: isSelected ? 11 : 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.4,
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Nav Item Model ────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}