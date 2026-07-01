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

    return Scaffold(
      appBar: AppBar(title: const Text('Appareils connectés'), backgroundColor: Colors.transparent, elevation: 0),
      body: ListView.builder(
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
                  color: isCurrent ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.smartphone, color: isCurrent ? AppColors.primary : Colors.grey, size: 20),
              ),
              title: Row(
                children: [
                  Expanded(child: Text(dev['label'] as String? ?? 'Appareil', style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, fontSize: 14))),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                      child: const Text('ACTUEL', style: TextStyle(fontSize: 9, color: AppColors.success, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              subtitle: Text('Dernière activité : ${timeAgo(dev['last_seen'] as String? ?? '')}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              trailing: isCurrent
                  ? null
                  : IconButton(
                      icon: const Icon(LucideIcons.trash2, color: AppColors.danger, size: 18),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: ctx,
                          builder: (_) => AlertDialog(
                            title: const Text('Révoquer l\'appareil ?'),
                            content: Text('La session sur "${dev['label']}" sera clôturée.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Révoquer', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && ctx.mounted) {
                          await appState.removeDevice(dev['id'] as int, dev['label'] as String);
                        }
                      },
                    ),
            ),
          );
        },
      ),
    );
  }
}
