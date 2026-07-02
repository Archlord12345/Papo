import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav.dart';

class SendMoneyScreen extends StatelessWidget {
  const SendMoneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: appState.popScreen,
        ),
        title: const Text(
          'Envoyer',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MethodBigCard(
              icon: 'qr_code',
              title: 'QR Code',
              subtitle: 'Scannez le QR du destinataire',
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1A0A3E),
                  Color(0xFF2A1A4A),
                ],
              ),
              onTap: () => appState.setScreen('SendQR'),
            ),
            const SizedBox(height: 16),
            _MethodBigCard(
              icon: 'nfc',
              title: 'NFC',
              subtitle: 'Approchez les deux téléphones',
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0A162D),
                  Color(0xFF1A2030),
                ],
              ),
              onTap: () => appState.setScreen('SendNFC'),
            ),
            const SizedBox(height: 16),
            _MethodBigCard(
              icon: 'bluetooth',
              title: 'Bluetooth',
              subtitle: 'Appairez avec biométrie',
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0A1020),
                  Color(0xFF1A1A2A),
                ],
              ),
              onTap: () => appState.setScreen('SendBluetooth'),
            ),
            const SizedBox(height: 16),
            _MethodBigCard(
              icon: 'hashtag',
              title: 'Code-T',
              subtitle: 'Code valide 24h - max 10/jour',
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1A1010),
                  Color(0xFF2A2020),
                ],
              ),
              onTap: () => appState.setScreen('SendMoney'),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.lock,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tous les transferts sont chiffrés AES-256 et protégés par authentification à deux facteurs.',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodBigCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _MethodBigCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getIconData(icon),
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              color: Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String icon) {
    switch (icon) {
      case 'qr_code': return LucideIcons.qrCode;
      case 'nfc': return LucideIcons.wifi;
      case 'bluetooth': return LucideIcons.bluetooth;
      case 'hashtag': return LucideIcons.hashtag;
      default: return LucideIcons.helpCircle;
    }
  }
}