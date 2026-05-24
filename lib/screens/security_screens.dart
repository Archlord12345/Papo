import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/screen_explorer.dart';
import 'main_screens.dart';

class SecuritySettingsScreen extends StatelessWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(title: const Text("Sécurité")),
      bottomNavigationBar: buildBottomNavBar(context, 4),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Security summary header
              const Text("Paramètres de sécurité", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Biometrics Toggle
              SwitchListTile(
                title: const Text("Authentification Biométrique"),
                subtitle: const Text("Se connecter via Empreinte / FaceID"),
                value: appState.biometricsEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: (val) {
                  appState.toggleBiometrics();
                },
              ),
              const Divider(),
              
              // 2FA Toggle
              SwitchListTile(
                title: const Text("Double authentification (2FA)"),
                subtitle: const Text("Valider les transactions par OTP SMS"),
                value: appState.twoFactorEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: (val) {
                  appState.toggle2FA();
                },
              ),
              const Divider(),
              
              // Change Password Button
              ListTile(
                leading: const Icon(LucideIcons.keyRound, color: AppColors.primary),
                title: const Text("Modifier le code PIN"),
                trailing: const Icon(LucideIcons.chevronRight),
                onTap: () {
                  appState.setScreen("ResetPassword");
                },
              ),
              const Divider(),

              const SizedBox(height: 24),
              
              // Active sessions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Appareils connectés", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      // Navigate to sessions list (or list in place)
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Sessions Actives"),
                          content: const Text("Toutes vos sessions sont surveillées par Device Binding."),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
                          ],
                        ),
                      );
                    },
                    child: const Text("Vérifier"),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Active devices list
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: appState.activeDevices.length,
                itemBuilder: (context, index) {
                  final dev = appState.activeDevices[index];
                  final isCurrent = dev.contains("(Actuel)");
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        dev.contains("MacBook") ? LucideIcons.laptop : LucideIcons.smartphone,
                        color: isCurrent ? AppColors.primary : Colors.grey,
                      ),
                      title: Text(dev, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                      subtitle: const Text("Dernière activité : Il y a quelques minutes"),
                      trailing: isCurrent
                          ? null
                          : IconButton(
                              icon: const Icon(LucideIcons.trash2, color: AppColors.danger, size: 18),
                              onPressed: () {
                                appState.removeDevice(dev);
                              },
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              
              CustomButton(
                text: "Déconnexion globale",
                isPrimary: false,
                onPressed: () {
                  appState.setScreen("Login");
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
