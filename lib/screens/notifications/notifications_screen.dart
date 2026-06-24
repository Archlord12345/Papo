import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (appState.notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: appState.markAllNotificationsAsRead,
              child: const Text('Tout lire', style: TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
      body: appState.notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.bellOff, size: 72, color: Colors.grey.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  const Text('Aucune notification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Vos alertes et confirmations apparaîtront ici.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appState.notifications.length,
              itemBuilder: (ctx, i) {
                final n = appState.notifications[i];

                IconData icon;
                Color color;
                switch (n.type) {
                  case 'security':
                    icon = LucideIcons.shieldAlert;
                    color = AppColors.danger;
                    break;
                  case 'success':
                    icon = LucideIcons.checkCircle;
                    color = AppColors.success;
                    break;
                  case 'warning':
                    icon = LucideIcons.alertTriangle;
                    color = AppColors.warning;
                    break;
                  default:
                    icon = LucideIcons.info;
                    color = AppColors.secondary;
                }

                return GestureDetector(
                  onTap: () => appState.markNotificationRead(n.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: n.isRead
                          ? (isDark ? AppColors.darkSurface.withOpacity(0.5) : Colors.white.withOpacity(0.6))
                          : (isDark ? AppColors.darkSurface : Colors.white),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: n.isRead ? Colors.transparent : AppColors.primary.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: n.isRead
                          ? []
                          : [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                          child: Icon(icon, color: color, size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                  if (!n.isRead)
                                    Container(
                                      width: 8, height: 8,
                                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(n.content, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4)),
                              const SizedBox(height: 6),
                              Text(timeAgo(n.createdAt), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
