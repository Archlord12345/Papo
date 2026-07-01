import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final menuItems = [
      _MenuItem(LucideIcons.layoutDashboard, 'Accueil', 'Dashboard', AppColors.primary),
      _MenuItem(LucideIcons.wallet, 'Portefeuille', 'Wallet', AppColors.secondary),
      _MenuItem(LucideIcons.link, 'Blockchain', 'Blockchain', AppColors.accent),
      _MenuItem(LucideIcons.contact, 'KYC', 'KYCStatus', Colors.purple),
      _MenuItem(LucideIcons.user, 'Profil', 'Profile', Colors.teal),
      _MenuItem(LucideIcons.shield, 'Cercle', 'Circle', AppColors.secondary),
      _MenuItem(LucideIcons.phone, 'Aide', 'Aide', Colors.orange),
      _MenuItem(LucideIcons.terminal, 'Développeur', 'Developer', Colors.blueGrey),
      _MenuItem(LucideIcons.store, 'Marchand', 'MerchantDashboard', AppColors.accent),
      _MenuItem(LucideIcons.lock, 'Sécurité', 'SecuritySettings', AppColors.danger),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Language picker
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButton<String>(
              value: appState.language,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'fr', child: Text('🇫🇷 FR')),
                DropdownMenuItem(value: 'en', child: Text('🇬🇧 EN')),
              ],
              onChanged: (v) { if (v != null) appState.changeLanguage(v); },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile mini header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: Text(appState.avatarInitials, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appState.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(appState.userPhone, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 4),
                        _KycBadge(status: appState.kycStatus),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.chevronRight),
                    onPressed: () => appState.setScreen('Profile'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Accès Rapide', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: menuItems.length,
              itemBuilder: (ctx, i) {
                final item = menuItems[i];
                return GestureDetector(
                  onTap: () => appState.setScreen(item.screen),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: item.color.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: Icon(item.icon, color: item.color, size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(item.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String screen;
  final Color color;
  const _MenuItem(this.icon, this.label, this.screen, this.color);
}

class _KycBadge extends StatelessWidget {
  final String status;
  const _KycBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    Color c;
    String t;
    IconData ic;
    switch (status) {
      case 'verified':
        c = AppColors.success; t = 'Vérifié'; ic = LucideIcons.checkCircle;
        break;
      case 'pending':
        c = AppColors.warning; t = 'En attente'; ic = LucideIcons.clock;
        break;
      default:
        c = AppColors.danger; t = 'Non vérifié'; ic = LucideIcons.alertTriangle;
    }
    return Row(children: [
      Icon(ic, size: 12, color: c),
      const SizedBox(width: 4),
      Text(t, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
    ]);
  }
}
