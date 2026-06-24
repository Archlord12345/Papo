import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/bottom_nav.dart';

class SecuritySettingsScreen extends StatelessWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Sécurité'), backgroundColor: Colors.transparent, elevation: 0),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Security score
          _SecurityScore(appState: appState),
          const SizedBox(height: 24),

          const _SectionHeader(title: 'Authentification'),
          _ToggleTile(
            icon: LucideIcons.fingerprint,
            title: 'Authentification Biométrique',
            subtitle: 'Empreinte digitale ou Face ID',
            value: appState.biometricsEnabled,
            onChanged: (_) => appState.toggleBiometrics(),
          ),
          _ToggleTile(
            icon: LucideIcons.shieldCheck,
            title: 'Double Authentification (2FA)',
            subtitle: 'Code SMS à chaque connexion',
            value: appState.twoFactorEnabled,
            onChanged: (_) => appState.toggle2FA(),
          ),
          const SizedBox(height: 16),

          const _SectionHeader(title: 'Code PIN'),
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: const Icon(LucideIcons.keyRound, color: AppColors.primary, size: 18),
              ),
              title: const Text('Modifier le code PIN', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Changer votre code de sécurité', style: TextStyle(fontSize: 12)),
              trailing: const Icon(LucideIcons.chevronRight, size: 18),
              onTap: () => _showChangePinDialog(context, appState),
            ),
          ),
          const SizedBox(height: 16),

          const _SectionHeader(title: 'Appareils'),
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: const Icon(LucideIcons.smartphone, color: AppColors.secondary, size: 18),
              ),
              title: const Text('Appareils connectés', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${appState.devices.length} appareil(s) actif(s)', style: const TextStyle(fontSize: 12)),
              trailing: const Icon(LucideIcons.chevronRight, size: 18),
              onTap: () => appState.setScreen('ActiveSessions'),
            ),
          ),
          const SizedBox(height: 32),

          CustomButton(
            text: 'Se déconnecter',
            isPrimary: false,
            icon: const Icon(LucideIcons.logOut, color: AppColors.danger),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Se déconnecter ?'),
                  content: const Text('Vous serez redirigé vers l\'écran de connexion.'),
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
              if (confirm == true && context.mounted) {
                await appState.logout();
              }
            },
          ),
        ],
      ),
    );
  }

  void _showChangePinDialog(BuildContext context, AppState appState) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Modifier le code PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomInput(label: 'Code PIN actuel', hint: '••••', isPassword: true, keyboardType: TextInputType.number, controller: currentCtrl),
              const SizedBox(height: 12),
              CustomInput(label: 'Nouveau code PIN', hint: '••••', isPassword: true, keyboardType: TextInputType.number, controller: newCtrl),
              const SizedBox(height: 12),
              CustomInput(label: 'Confirmer', hint: '••••', isPassword: true, keyboardType: TextInputType.number, controller: confirmCtrl),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: loading ? null : () async {
                if (newCtrl.text != confirmCtrl.text) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Les codes ne correspondent pas')));
                  return;
                }
                setState(() => loading = true);
                final ok = await appState.changePin(currentCtrl.text, newCtrl.text);
                setState(() => loading = false);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ok ? 'PIN modifié avec succès' : 'Code PIN actuel incorrect'), backgroundColor: ok ? AppColors.success : AppColors.danger),
                  );
                }
              },
              child: const Text('Modifier', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityScore extends StatelessWidget {
  final AppState appState;
  const _SecurityScore({required this.appState});

  int get _score {
    int s = 0;
    if (appState.biometricsEnabled) s += 33;
    if (appState.twoFactorEnabled) s += 33;
    if (appState.kycStatus == 'verified') s += 34;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final score = _score;
    final color = score >= 66 ? AppColors.success : score >= 33 ? AppColors.warning : AppColors.danger;
    final label = score >= 66 ? 'Sécurité élevée' : score >= 33 ? 'Sécurité moyenne' : 'Sécurité faible';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 6,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text('$score%', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  score < 100 ? 'Activez plus d\'options pour sécuriser votre compte.' : 'Votre compte est entièrement sécurisé.',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(title.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.primary)),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;
  const _ToggleTile({required this.icon, required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        activeColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }
}
