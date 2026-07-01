import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav.dart';
import '../../utils/formatters.dart';

/// Hub screen for choosing the transfer method.
/// Each method has its own dedicated screen.
class SendMoneyScreen extends StatelessWidget {
  const SendMoneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slot = appState.activeSlot;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Envoyer des fonds'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: appState.popScreen,
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active wallet card
            if (slot != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.wallet, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(slot.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(formatAmountAbs(slot.xofBalance, 'XOF'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    )),
                    Text('SLOT ${slot.slot}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],

            const Text('Choisir la méthode de transfert',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez comment vous souhaitez envoyer vos fonds.',
              style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Method cards
            _MethodCard(
              icon: LucideIcons.qrCode,
              title: 'Scanner le QR Code',
              desc: 'Scannez le code QR du destinataire puis saisissez le montant.',
              color: AppColors.primary,
              onTap: () => appState.setScreen('SendQR'),
              badge: 'RECOMMANDÉ',
            ),
            const SizedBox(height: 12),
            _MethodCard(
              icon: LucideIcons.nfc,
              title: 'Transfert NFC',
              desc: 'Approchez deux téléphones pour transférer instantanément.',
              color: AppColors.secondary,
              onTap: () => appState.setScreen('SendNFC'),
            ),
            const SizedBox(height: 12),
            _MethodCard(
              icon: LucideIcons.bluetooth,
              title: 'Transfert Bluetooth',
              desc: 'Sélectionnez un appareil à proximité via Bluetooth.',
              color: Colors.blue,
              onTap: () => appState.setScreen('SendBluetooth'),
            ),
            const SizedBox(height: 12),
            _MethodCard(
              icon: LucideIcons.wifiOff,
              title: 'Paiement Hors Ligne',
              desc: 'Sans connexion internet. Synchronisé plus tard sur la blockchain.',
              color: AppColors.warning,
              onTap: () => appState.setScreen('OfflinePayment'),
              badge: 'OFFLINE',
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(badge!, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.4)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
