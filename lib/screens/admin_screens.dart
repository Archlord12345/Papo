import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/screen_explorer.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(
        title: const Text("Administration & Audit"),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.home),
            onPressed: () => appState.setScreen("Dashboard"),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // System Health Metrics
              const Text("Métriques Globales Système", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildMetricCard(context, "Utilisateurs Actifs", "245 680", LucideIcons.users, AppColors.primary),
                  _buildMetricCard(context, "Volume Tx (24h)", "12.4M XOF", LucideIcons.circleDollarSign, AppColors.secondary),
                  _buildMetricCard(context, "Nœuds Blockchain", "12 Actifs", LucideIcons.link, AppColors.accent),
                  _buildMetricCard(context, "Alerte Anti-Fraude", "0 Suspecte", LucideIcons.shieldCheck, AppColors.success),
                ],
              ),
              const SizedBox(height: 28),
              
              // KYC Queue
              const Text("Vérifications KYC en attente", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              appState.kycStatus == "pending" 
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(appState.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                  child: Text(
                                    appState.uploadedDocType ?? "Document",
                                    style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text("Fichier : ${appState.uploadedDocName ?? 'cni.pdf'}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            Text("Vérification faciale : ${appState.isFaceVerified ? 'Réussie (Liveness OK)' : 'Non effectuée'}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: CustomButton(
                                    text: "Approuver",
                                    onPressed: () {
                                      appState.approveKYC();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CustomButton(
                                    text: "Rejeter",
                                    isPrimary: false,
                                    onPressed: () {
                                      appState.rejectKYC();
                                    },
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    )
                  : const Card(
                      child: ListTile(
                        leading: Icon(LucideIcons.checkSquare, color: AppColors.success),
                        title: Text("File d'attente KYC vide", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text("Tous les profils d'utilisateurs ont été examinés."),
                      ),
                    ),
              
              const SizedBox(height: 28),
              
              // Anti-Fraud Risk Score
              const Text("Analyse de Risque Anti-Fraude", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.success,
                    child: Text("12%", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  title: Text(appState.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Risque de double dépense : Très faible"),
                  trailing: const Icon(LucideIcons.shieldCheck, color: AppColors.success),
                ),
              ),

              const SizedBox(height: 28),

              // Security Audit Logs
              const Text("Journaux d'Audit & Blockchain", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildAuditLog(context, "KYC", "Utilisateur M. Diallo : Statut mis à jour (${appState.kycStatus})", "À l'instant"),
              _buildAuditLog(context, "Blockchain", "Ancrage cryptographique du bloc #349102 réussi", "Il y a 10 min"),
              _buildAuditLog(context, "Sécurité", "Alerte IP résolue sur le compte de F. Sy", "Il y a 2h"),
              _buildAuditLog(context, "Transactions", "Frais système de 2% appliqués au transfert TX-101", "Il y a 3h"),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String val, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                Icon(icon, color: color, size: 16),
              ],
            ),
            const SizedBox(height: 6),
            Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditLog(BuildContext context, String category, String text, String time) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              category,
              style: const TextStyle(fontSize: 8, color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 2),
                Text(time, style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
