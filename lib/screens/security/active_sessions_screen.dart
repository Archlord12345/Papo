import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';

class ActiveSessionsScreen extends StatelessWidget {
  const ActiveSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final others = appState.devices.where((d) => d['is_current'] != 1).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appareils connectés'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (others.isNotEmpty)
            TextButton.icon(
              icon: const Icon(LucideIcons.logOut, size: 14, color: AppColors.danger),
              label: const Text('Tout révoquer', style: TextStyle(color: AppColors.danger, fontSize: 12)),
              onPressed: () => _revokeAll(context, appState, others),
            ),
        ],
      ),
      body: appState.devices.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.smartphone, size: 64, color: Colors.grey.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  const Text('Aucun appareil connecté',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text(
                    'Vos sessions actives apparaîtront ici.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appState.devices.length,
              itemBuilder: (ctx, i) {
                final dev = appState.devices[i];
                final isCurrent = dev['is_current'] == 1;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.smartphone,
                          color: isCurrent ? AppColors.primary : Colors.grey, size: 20),
                    ),
                    title: Row(children: [
                      Expanded(
                        child: Text(
                          dev['label'] as String? ?? 'Appareil',
                          style: TextStyle(
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14),
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6)),
                          child: const Text('ACTUEL',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ]),
                    subtitle: Text(
                      'Dernière activité : ${timeAgo(dev['last_seen'] as String? ?? '')}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: isCurrent
                        ? null
                        : IconButton(
                            icon: const Icon(LucideIcons.trash2,
                                color: AppColors.danger, size: 18),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: ctx,
                                builder: (_) => AlertDialog(
                                  title: const Text('Révoquer l\'appareil ?'),
                                  content: Text(
                                      'La session sur "${dev['label']}" sera clôturée.'),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Annuler')),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.danger),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Révoquer',
                                          style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true && ctx.mounted) {
                                await appState.removeDevice(
                                    dev['id'] as int, dev['label'] as String? ?? '');
                              }
                            },
                          ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _revokeAll(
      BuildContext context, AppState appState, List<Map<String, dynamic>> others) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Révoquer tous les appareils ?'),
        content: Text(
            '${others.length} session(s) seront clôturées. Seul votre appareil actuel restera connecté.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tout révoquer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    for (final d in others) {
      await appState.removeDevice(d['id'] as int, d['label'] as String? ?? '');
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Tous les appareils ont été révoqués.'),
        backgroundColor: AppColors.success,
      ));
    }
  }
}
