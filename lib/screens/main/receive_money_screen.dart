import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/bottom_nav.dart';
import '../../utils/formatters.dart';

class ReceiveMoneyScreen extends StatefulWidget {
  const ReceiveMoneyScreen({super.key});
  @override
  State<ReceiveMoneyScreen> createState() => _ReceiveMoneyScreenState();
}

class _ReceiveMoneyScreenState extends State<ReceiveMoneyScreen> {
  final _amountCtrl = TextEditingController();
  String _asset = 'XOF';
  bool _loading = false;

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
          elevation: 0),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // QR Code
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: QrImageView(
                data: _qrData(appState),
                version: QrVersions.auto,
                size: 220,
                eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square, color: Color(0xFF0F172A)),
                dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF0F172A)),
              ),
            ),
            const SizedBox(height: 24),

            // Name + address
            Text(
              appState.userName,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () {
                Clipboard.setData(
                    ClipboardData(text: appState.walletAddress));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Adresse copiée')),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${appState.walletAddress.substring(0, 12)}...${appState.walletAddress.substring(appState.walletAddress.length - 8)}',
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    const Icon(LucideIcons.copy,
                        size: 14, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Optional: request a specific amount
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Demander un montant précis (optionnel)',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '0',
                      suffixText: _asset,
                      suffixStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _asset,
                  underline: const SizedBox(),
                  items: ['XOF', 'USD', 'PAPO', 'BTC']
                      .map((a) => DropdownMenuItem(
                          value: a, child: Text(a)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _asset = v);
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Share button
            CustomButton(
              text: 'Partager mon QR Code',
              icon: const Icon(LucideIcons.share2, color: Colors.white, size: 18),
              onPressed: () {
                Clipboard.setData(
                    ClipboardData(text: _qrData(appState)));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Lien de paiement copié dans le presse-papiers')),
                );
              },
            ),
            const SizedBox(height: 12),

            // Simulate receive (demo)
            CustomButton(
              text: 'Simuler réception de fonds',
              isPrimary: false,
              onPressed: () async {
                final amount =
                    double.tryParse(_amountCtrl.text) ?? 5000;
                setState(() => _loading = true);
                await appState.receiveMoney(amount, _asset,
                    senderLabel: 'Fonds reçus via QR Code');
                if (mounted) {
                  setState(() => _loading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            '${formatAmountAbs(amount, _asset)} reçus !'),
                        backgroundColor: AppColors.success),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
