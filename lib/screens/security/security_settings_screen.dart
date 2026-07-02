import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sécurité'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SecurityScore(appState: appState),
          const SizedBox(height: 30),
          _SectionHeader(title: 'Authentification'),
          _SecurityTile(
            icon: LucideIcons.fingerprint,
            title: 'Biométrie',
            subtitle: 'Empreinte digitale ou visage',
            trailing: Switch(
              value: appState.biometricsEnabled,
              activeColor: AppColors.primary,
              onChanged: (v) => appState.toggleBiometrics(),
            ),
          ),
          _SecurityTile(
            icon: LucideIcons.shieldCheck,
            title: 'Double authentification (2FA)',
            subtitle: 'Code de sécurité par SMS/Email',
            trailing: Switch(
              value: appState.twoFactorEnabled,
              activeColor: AppColors.primary,
              onChanged: (v) => appState.toggle2FA(),
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: 'Accès'),
          _SecurityTile(
            icon: LucideIcons.keyRound,
            title: 'Changer le code PIN',
            subtitle: 'Modifier votre code secret à 4 chiffres',
            onTap: () => _showChangePinDialog(context, appState),
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: 'Appareils connectés'),
          ...appState.devices.map((d) => _DeviceTile(
                device: d,
                onRemove: () => appState.removeDevice(d['id'], d['label']),
              )),
          const SizedBox(height: 40),
          CustomButton(
            text: 'Réinitialiser les paramètres de sécurité',
            onPressed: () {},
            isOutlined: true,
            color: AppColors.danger,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Changer le code PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(labelText: 'Code PIN actuel'),
              ),
              TextField(
                controller: newCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(labelText: 'Nouveau code PIN'),
              ),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(labelText: 'Confirmer le code'),
              ),
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
                if (ctx.mounted) {
                  setState(() => loading = false);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'PIN modifié avec succès' : 'Code PIN actuel incorrect'),
                      backgroundColor: ok ? AppColors.success : AppColors.danger,
                    ),
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

  @override
  Widget build(BuildContext context) {
    int score = 30;
    if (appState.biometricsEnabled) score += 20;
    if (appState.twoFactorEnabled) score += 30;
    if (appState.kycStatus == 'verified') score += 20;

    Color color = AppColors.danger;
    if (score > 50) color = AppColors.warning;
    if (score > 80) color = AppColors.success;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Niveau de sécurité', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('$score%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
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
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title.toUpperCase(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
    );
  }
}

class _SecurityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SecurityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      trailing: trailing ?? const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final Map<String, dynamic> device;
  final VoidCallback onRemove;

  const _DeviceTile({required this.device, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(LucideIcons.smartphone, color: Colors.grey),
      title: Text(device['label'] ?? 'Appareil inconnu', style: const TextStyle(fontSize: 14)),
      subtitle: Text('Dernière connexion: ${device['last_seen'] ?? '—'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: IconButton(
        icon: const Icon(LucideIcons.logOut, size: 18, color: AppColors.danger),
        onPressed: onRemove,
      ),
    );
  }
}
