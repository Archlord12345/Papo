import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/bottom_nav.dart';
import '../../utils/formatters.dart';

class ReceiveMoneyScreen extends StatefulWidget {
  const ReceiveMoneyScreen({super.key});
  @override
  State<ReceiveMoneyScreen> createState() => _ReceiveMoneyScreenState();
}

class _ReceiveMoneyScreenState extends State<ReceiveMoneyScreen> {
  final _amountCtrl = TextEditingController();
  late String _asset;

  @override
  void initState() {
    super.initState();
    _asset = context.read<AppState>().activeSlot?.asset ?? 'XOF';
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  String _qrData(AppState appState) {
    final amount = _amountCtrl.text.trim();
    if (amount.isEmpty) {
      return 'papo:pay/${appState.walletAddress}?asset=$_asset';
    }
    return 'papo:pay/${appState.walletAddress}?asset=$_asset&amount=$amount';
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
          title: const Text('Recevoir des fonds'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: appState.popScreen,
          )),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Mon QR de paiement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Affichez ce code pour recevoir un transfert instantané',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 32),

            // QR Code with "Active Listening" feel
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  QrImageView(
                    data: _qrData(appState),
                    version: QrVersions.auto,
                    size: 240,
                    eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square, color: Color(0xFF0F172A)),
                    dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Active status indicator
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
              const SizedBox(width: 10),
              const Text('En attente du paiement...',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
            const SizedBox(height: 32),

            // Name + address
            Text(
              appState.userName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: appState.walletAddress));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Adresse copiée'), behavior: SnackBarBehavior.floating),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${appState.walletAddress.substring(0, 8)}...${appState.walletAddress.substring(appState.walletAddress.length - 8)}',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 10),
                    const Icon(LucideIcons.copy, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Optional: request a specific amount
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Demander un montant précis',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_asset, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Share button
            CustomButton(
              text: 'Partager le lien de paiement',
              icon: const Icon(LucideIcons.share2, color: Colors.white, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _qrData(appState)));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lien copié'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
            const SizedBox(height: 32),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Options de partage à proximité',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SmallMethodCard(
                    icon: LucideIcons.nfc,
                    label: 'Payer via NFC',
                    color: AppColors.secondary,
                    onTap: () => appState.setScreen('ReceiveNFC'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SmallMethodCard(
                    icon: LucideIcons.bluetooth,
                    label: 'Payer via Bluetooth',
                    color: Colors.blue,
                    onTap: () => appState.setScreen('ReceiveBluetooth'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'En mode NFC/Bluetooth, l\'envoyeur pourra scanner votre identité directement depuis son application Papo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.4),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SmallMethodCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SmallMethodCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
