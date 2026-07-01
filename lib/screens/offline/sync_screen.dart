import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../utils/formatters.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});
  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool _syncing = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Synchronisation Blockchain'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: appState.offlineQueue.isEmpty
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: appState.offlineQueue.isEmpty
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    appState.offlineQueue.isEmpty
                        ? LucideIcons.checkCircle
                        : LucideIcons.clock,
                    color: appState.offlineQueue.isEmpty
                        ? AppColors.success
                        : AppColors.warning,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.offlineQueue.isEmpty
                              ? 'Tout est synchronisé'
                              : '${appState.offlineQueue.length} transaction(s) en attente',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          appState.offlineQueue.isEmpty
                              ? 'Aucune action requise.'
                              : 'Connectez-vous au réseau et synchronisez.',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textDarkSecondary
                                  : AppColors.textLightSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Transactions en attente',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Expanded(
              child: appState.offlineQueue.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.checkCircle,
                              size: 72, color: AppColors.success),
                          const SizedBox(height: 16),
                          const Text('Aucune transaction en attente',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Toutes vos transactions sont confirmées.',
                              style: TextStyle(
                                  color: isDark
                                      ? AppColors.textDarkSecondary
                                      : AppColors.textLightSecondary)),
                          const SizedBox(height: 24),
                          CustomButton(
                            text: 'Retour à l\'accueil',
                            isPrimary: false,
                            onPressed: () =>
                                appState.setScreen('Dashboard'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: appState.offlineQueue.length,
                      itemBuilder: (ctx, i) {
                        final tx = appState.offlineQueue[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.wifiOff,
                                  color: AppColors.warning, size: 18),
                            ),
                            title: Text(tx.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('ID: ${tx.id.substring(0, 16)}...',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                        color: Colors.grey)),
                                Text(
                                    'Créé: ${timeAgo(tx.createdAt)}',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            trailing: Text(
                              formatAmount(tx.amount, tx.asset),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warning,
                                  fontSize: 14),
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),

            if (appState.offlineQueue.isNotEmpty) ...[
              if (_syncing)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary)),
                      SizedBox(height: 16),
                      Text('Ancrage blockchain en cours...',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              else
                CustomButton(
                  text: 'Synchroniser (${appState.offlineQueue.length} tx)',
                  icon: const Icon(LucideIcons.refreshCw,
                      color: Colors.white, size: 18),
                  onPressed: () async {
                    setState(() => _syncing = true);
                    await Future.delayed(const Duration(seconds: 2));
                    if (mounted) {
                      await appState.syncOfflineTransactions();
                      setState(() => _syncing = false);
                    }
                  },
                ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}
