import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    void go(String screen) => appState.setScreen(screen);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: LucideIcons.home,
                  label: 'Accueil',
                  selected: currentIndex == 0,
                  onTap: () => go('Dashboard'),
                ),
                _NavItem(
                  icon: LucideIcons.arrowUpRight,
                  label: 'Envoyer',
                  selected: currentIndex == 1,
                  onTap: () => go('SendMoney'),
                  isPrimary: true,
                ),
                _NavItem(
                  icon: LucideIcons.arrowDownLeft,
                  label: 'Recevoir',
                  selected: currentIndex == 2,
                  onTap: () => go('ReceiveMoney'),
                ),
                _NavItem(
                  icon: LucideIcons.clock,
                  label: 'Historique',
                  selected: currentIndex == 3,
                  onTap: () => go('History'),
                ),
                _NavItem(
                  icon: LucideIcons.refreshCw,
                  label: 'Convertir',
                  selected: currentIndex == 4,
                  onTap: () => go('Converter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool isPrimary;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : Colors.grey;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: selected && isPrimary 
              ? AppColors.secondary.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SizedBox(
          width: selected ? 80 : 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? (isPrimary ? AppColors.primary : AppColors.primary) : Colors.grey, size: selected ? 26 : 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? (isPrimary ? AppColors.primary : AppColors.primary) : Colors.grey,
                  fontSize: 10,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
