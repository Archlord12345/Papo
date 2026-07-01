import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../utils/formatters.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final totalVolume = appState.transactions.fold<double>(0, (s, t) => s + t.amount.abs());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration & Audit'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(LucideIcons.home), onPressed: () => appState.setScreen('Dashboard')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // System metrics grid
            const _SectionHeader('Métriques Globales'),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _MetricCard('Utilisateurs actifs', '1', LucideIcons.users, AppColors.primary),
                _MetricCard('Volume (total)', formatAmountAbs(totalVolume, 'XOF'), LucideIcons.circleDollarSign, AppColors.secondary),
                _MetricCard('Nœuds Blockchain', '12 actifs', LucideIcons.link, AppColors.accent),
                _MetricCard('Alertes Fraude', '0 suspecte', LucideIcons.shieldCheck, AppColors.success),
              ],
            ),
            const SizedBox(height: 24),

            // KYC queue
            const _SectionHeader('File KYC'),
            if (appState.kycStatus == 'pending')
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(appState.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                            child: Text(appState.kycDocType, style: const TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Fichier : ${appState.kycDocName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('Vérification faciale : ${appState.isFaceVerified ? 'Réussie ✓' : 'Non effectuée'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: CustomButton(text: 'Approuver', onPressed: appState.approveKYC)),
                          const SizedBox(width: 10),
                          Expanded(child: CustomButton(text: 'Rejeter', isPrimary: false, onPressed: appState.rejectKYC)),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                child: ListTile(
                  leading: const Icon(LucideIcons.checkSquare, color: AppColors.success),
                  title: const Text('File KYC vide', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Tous les profils ont été examinés.'),
                ),
              ),
            const SizedBox(height: 24),

            // Anti-fraud
            const _SectionHeader('Analyse Anti-Fraude'),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.success,
                  child: Text('${_fraudScore(appState)}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
                title: Text(appState.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Risque de double dépense : Très faible'),
                trailing: const Icon(LucideIcons.shieldCheck, color: AppColors.success),
              ),
            ),
            const SizedBox(height: 24),

            // Audit logs
            const _SectionHeader('Journal d\'Audit'),
            _AuditLog('KYC', 'Statut mis à jour (${appState.kycStatus})', timeAgo(DateTime.now().toIso8601String())),
            _AuditLog('Blockchain', 'Bloc #${appState.transactions.length + 349000} ancré', 'Il y a 10 min'),
            _AuditLog('Sécurité', 'Aucune anomalie détectée', 'Il y a 1h'),
            _AuditLog('Transactions', '${appState.transactions.length} tx enregistrées', 'Ce jour'),
          ],
        ),
      ),
    );
  }

  int _fraudScore(AppState appState) {
    // Simple heuristic: fewer transactions = lower risk score
    return (appState.transactions.length * 2).clamp(0, 25);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.primary)),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _MetricCard(this.title, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))),
                Icon(icon, color: color, size: 16),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _AuditLog extends StatelessWidget {
  final String category;
  final String text;
  final String time;
  const _AuditLog(this.category, this.text, this.time);
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
            child: Text(category, style: const TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 2),
                Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
