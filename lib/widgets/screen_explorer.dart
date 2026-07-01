import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';

class ScreenExplorer extends StatelessWidget {
  const ScreenExplorer({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Define the list of screens grouped by category
    final Map<String, List<Map<String, dynamic>>> categories = {
      "Authentification": [
        {"name": "Splash", "icon": LucideIcons.rocket, "desc": "Écran de démarrage"},
        {"name": "Onboarding", "icon": LucideIcons.compass, "desc": "Tutoriel d'accueil"},
        {"name": "Login", "icon": LucideIcons.logIn, "desc": "Connexion"},
        {"name": "Register", "icon": LucideIcons.userPlus, "desc": "Inscription"},
        {"name": "OTP", "icon": LucideIcons.shieldCheck, "desc": "Vérification OTP"},
        {"name": "ForgotPassword", "icon": LucideIcons.helpCircle, "desc": "Mot de passe oublié"},
        {"name": "ResetPassword", "icon": LucideIcons.keyRound, "desc": "Nouveau mot de passe"},
        {"name": "BiometricLogin", "icon": LucideIcons.fingerprint, "desc": "Authentification biométrique"},
      ],
      "Écrans Principaux": [
        {"name": "Dashboard", "icon": LucideIcons.layoutDashboard, "desc": "Accueil & Solde"},
        {"name": "Wallet", "icon": LucideIcons.wallet, "desc": "Multi-devises & Tokens"},
        {"name": "SendMoney", "icon": LucideIcons.send, "desc": "Envoi (QR, NFC, Tél)"},
        {"name": "ReceiveMoney", "icon": LucideIcons.download, "desc": "Réception (Code QR)"},
        {"name": "History", "icon": LucideIcons.history, "desc": "Historique complet"},
      ],
      "Paiements Hors Ligne": [
        {"name": "OfflinePayment", "icon": LucideIcons.wifiOff, "desc": "Création de transaction"},
        {"name": "Sync", "icon": LucideIcons.refreshCw, "desc": "Synchronisation blockchain"},
      ],
      "KYC (Identité)": [
        {"name": "UploadCNI", "icon": LucideIcons.fileText, "desc": "Télécharger CNI"},
        {"name": "UploadPassport", "icon": LucideIcons.globe, "desc": "Télécharger Passeport"},
        {"name": "FaceVerification", "icon": LucideIcons.scanFace, "desc": "Vérification faciale"},
        {"name": "KYCStatus", "icon": LucideIcons.shieldAlert, "desc": "Statut du dossier"},
      ],
      "Sécurité": [
        {"name": "SecuritySettings", "icon": LucideIcons.lock, "desc": "Paramètres de sécurité"},
        {"name": "ActiveSessions", "icon": LucideIcons.smartphone, "desc": "Appareils connectés"},
      ],
      "Notifications": [
        {"name": "NotificationsList", "icon": LucideIcons.bell, "desc": "Centre de notifications"},
      ],
      "Espaces Dédiés": [
        {"name": "MerchantDashboard", "icon": LucideIcons.store, "desc": "Espace Marchand"},
        {"name": "AdminDashboard", "icon": LucideIcons.shieldCheck, "desc": "Administration & Audit"},
      ],
      "Nouveaux Modules / Écosystème": [
        {"name": "Menu", "icon": LucideIcons.menu, "desc": "Menu principal & Langue"},
        {"name": "Circle", "icon": LucideIcons.shield, "desc": "Cercle de Confiance (Tontine)"},
        {"name": "Aide", "icon": LucideIcons.phone, "desc": "Support & Chat de secours"},
        {"name": "Developer", "icon": LucideIcons.terminal, "desc": "Portail Développeur"},
        {"name": "Ecosystem", "icon": LucideIcons.globe, "desc": "Services & Factures"},
        {"name": "Profile", "icon": LucideIcons.user, "desc": "Profil & Limites"},
        {"name": "Blockchain", "icon": LucideIcons.link, "desc": "Explorateur de Blocs"},
      ],
    };

    return Drawer(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                gradient: isDark ? AppColors.darkCardGradient : null,
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/papo_logo.png',
                    height: 32,
                    errorBuilder: (_, _, _) => Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.wallet, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "PAYPOINT (PAPO)",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          "Explorateur d'Écrans",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Drawer Content (Scrollable Categories)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: categories.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                        child: Text(
                          entry.key.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      ...entry.value.map((screen) {
                        final isSelected = appState.currentScreen == screen["name"];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            screen["icon"],
                            color: isSelected 
                                ? AppColors.primary 
                                : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                            size: 18,
                          ),
                          title: Text(
                            screen["name"],
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected 
                                  ? AppColors.primary 
                                  : (isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary),
                            ),
                          ),
                          subtitle: Text(
                            screen["desc"],
                            style: TextStyle(fontSize: 10, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                          ),
                          selected: isSelected,
                          selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
                          onTap: () {
                            appState.setScreen(screen["name"]);
                            Navigator.pop(context); // Close drawer
                          },
                        );
                      }),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
