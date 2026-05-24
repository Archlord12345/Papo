import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/screen_explorer.dart';

class NotificationsListScreen extends StatelessWidget {
  const NotificationsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(
        title: const Text("Centre de Notifications"),
        actions: [
          TextButton(
            onPressed: () {
              appState.markAllNotificationsAsRead();
            },
            child: const Text("Tout lire", style: TextStyle(color: AppColors.primary)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: appState.notifications.isEmpty
                  ? const Center(child: Text("Aucune notification"))
                  : ListView.builder(
                      itemCount: appState.notifications.length,
                      itemBuilder: (context, index) {
                        final notif = appState.notifications[index];
                        
                        IconData icon;
                        Color color;
                        switch (notif.type) {
                          case 'security':
                            icon = LucideIcons.shieldAlert;
                            color = AppColors.danger;
                            break;
                          case 'success':
                            icon = LucideIcons.checkCircle;
                            color = AppColors.success;
                            break;
                          default:
                            icon = LucideIcons.info;
                            color = AppColors.secondary;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: notif.isRead ? 0 : 2,
                          color: notif.isRead 
                              ? (isDark ? AppColors.darkSurface.withOpacity(0.5) : Colors.white.withOpacity(0.6))
                              : (isDark ? AppColors.darkSurface : Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: notif.isRead
                                  ? Colors.transparent
                                  : AppColors.primary.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.1),
                              child: Icon(icon, color: color, size: 20),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notif.title,
                                    style: TextStyle(
                                      fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (!notif.isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(notif.content, style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 6),
                                Text(
                                  notif.timestamp.toString().substring(11, 16),
                                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                                ),
                              ],
                            ),
                            onTap: () {
                              appState.markNotificationRead(notif.id);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
