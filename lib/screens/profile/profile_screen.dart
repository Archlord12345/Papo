import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';
import '../../utils/formatters.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon Profil'), backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(appState.avatarInitials, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                  const SizedBox(height: 12),
                  Text(appState.userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(appState.userPhone, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 8),
                  _KycBadge(status: appState.kycStatus),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Wallet address
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ADRESSE WALLET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  Text(appState.walletAddress, style: const TextStyle(fontFamily: 'monospace', fontSize: 12), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Limits based on KYC
            _LimitsCard(kycStatus: appState.kycStatus),
            const SizedBox(height: 20),

            // Account stats
            Row(
              children: [
                Expanded(child: _StatCard('Transactions', appState.transactions.length.toString(), LucideIcons.list)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard('Membre depuis', formatDateShort(appState.user?.createdAt ?? DateTime.now().toIso8601String()), LucideIcons.calendar)),
              ],
            ),
            const SizedBox(height: 20),

            // Actions
            _ActionTile(icon: LucideIcons.scanFace, title: 'Vérification KYC', subtitle: 'Statut : ${appState.kycStatus}', onTap: () => appState.setScreen('KYCStatus')),
            _ActionTile(icon: LucideIcons.lock, title: 'Sécurité', subtitle: 'PIN, biométrie, 2FA', onTap: () => appState.setScreen('SecuritySettings')),
            _ActionTile(icon: LucideIcons.store, title: 'Espace Marchand', subtitle: 'Gérez votre boutique', onTap: () => appState.setScreen('MerchantDashboard')),
            _ActionTile(icon: LucideIcons.shieldCheck, title: 'Administration', subtitle: 'Panneau admin & audit', onTap: () => appState.setScreen('AdminDashboard')),
            const SizedBox(height: 24),

            CustomButton(
              text: 'Se déconnecter',
              isPrimary: false,
              icon: const Icon(LucideIcons.logOut, color: AppColors.danger),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Se déconnecter ?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Déconnecter', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) appState.logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _KycBadge extends StatelessWidget {
  final String status;
  const _KycBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    Color c; String t; IconData ic;
    switch (status) {
      case 'verified': c = AppColors.success; t = 'Identité Vérifiée'; ic = LucideIcons.checkCircle; break;
      case 'pending': c = AppColors.warning; t = 'Vérification en cours'; ic = LucideIcons.clock; break;
      default: c = AppColors.danger; t = 'Non vérifié'; ic = LucideIcons.alertTriangle;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: c.withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ic, size: 14, color: c),
        const SizedBox(width: 6),
        Text(t, style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _LimitsCard extends StatelessWidget {
  final String kycStatus;
  const _LimitsCard({required this.kycStatus});
  @override
  Widget build(BuildContext context) {
    final isVerified = kycStatus == 'verified';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LIMITES DU COMPTE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.primary)),
          const SizedBox(height: 12),
          _LimitRow('Envoi quotidien', isVerified ? '2 000 000 XOF' : '50 000 XOF', isVerified),
          _LimitRow('Envoi mensuel', isVerified ? '20 000 000 XOF' : '500 000 XOF', isVerified),
          _LimitRow('Dépôt quotidien', isVerified ? 'Illimité' : '200 000 XOF', isVerified),
          if (!isVerified) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.read<AppState>().setScreen('KYCStatus'),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Row(
                  children: [
                    Icon(LucideIcons.arrowUpCircle, color: AppColors.accent, size: 16),
                    SizedBox(width: 8),
                    Text('Vérifiez votre identité pour débloquer toutes les limites', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LimitRow extends StatelessWidget {
  final String label;
  final String value;
  final bool unlocked;
  const _LimitRow(this.label, this.value, this.unlocked);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Row(children: [
            Icon(unlocked ? LucideIcons.unlockKeyhole : LucideIcons.lock, size: 13, color: unlocked ? AppColors.success : AppColors.danger),
            const SizedBox(width: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: unlocked ? AppColors.success : AppColors.danger)),
          ]),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard(this.label, this.value, this.icon);
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ]),
      ]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle), child: Icon(icon, color: AppColors.primary, size: 18)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ])),
          const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
        ]),
      ),
    );
  }
}
