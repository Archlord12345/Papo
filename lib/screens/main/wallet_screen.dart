import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/bottom_nav.dart';
import '../../utils/formatters.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  static const _assetColors = {
    'XOF': AppColors.primary,
    'USD': AppColors.secondary,
    'PAPO': AppColors.accent,
    'BTC': Colors.purple,
  };

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slot = appState.activeSlot;
    final balances = slot?.balances ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portefeuille'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: appState.popScreen),
        actions: [
          TextButton.icon(
            icon: const Icon(LucideIcons.layers, size: 16, color: AppColors.primary),
            label: Text(
              '${appState.walletSlots.length} wallet(s)',
              style: const TextStyle(color: AppColors.primary, fontSize: 12),
            ),
            onPressed: () => appState.setScreen('WalletSlots'),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active wallet header
            if (slot != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('WALLET ACTIF', style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 1.5)),
                          Text(slot.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        ]),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                          child: Text('SLOT ${slot.slot}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(slot.walletId,
                        style: const TextStyle(color: Colors.white60, fontFamily: 'monospace', fontSize: 11),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(LucideIcons.smartphone, color: Colors.white60, size: 12),
                      const SizedBox(width: 4),
                      Text(slot.deviceName, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    ]),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: isDark ? AppColors.darkSurface : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                child: Row(children: [
                  const Icon(LucideIcons.alertTriangle, color: AppColors.warning),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Aucun wallet actif', style: TextStyle(fontWeight: FontWeight.bold))),
                  TextButton(onPressed: () => appState.setScreen('WalletSlots'), child: const Text('Gérer')),
                ]),
              ),

            const SizedBox(height: 24),

            // Asset balances
            const Text('Soldes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...balances.entries.map((e) => _AssetCard(
              asset: e.key,
              balance: e.value,
              isDark: isDark,
              onSend: () => appState.setScreen('SendMoney'),
              onReceive: () => appState.setScreen('ReceiveMoney'),
            )),

            const SizedBox(height: 24),

            // Top up
            CustomButton(
              text: 'Déposer des fonds',
              icon: const Icon(LucideIcons.plusCircle, color: Colors.white, size: 18),
              onPressed: () => _showTopUpDialog(context, appState),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Gérer mes wallets (${appState.walletSlots.length}/10)',
              isPrimary: false,
              icon: const Icon(LucideIcons.layers, color: AppColors.primary, size: 18),
              onPressed: () => appState.setScreen('WalletSlots'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTopUpDialog(BuildContext context, AppState appState) {
    final ctrl = TextEditingController();
    String asset = 'XOF';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Déposer des fonds'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: asset,
                isExpanded: true,
                items: (appState.activeSlot?.balances.keys ?? ['XOF'])
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => asset = v!),
              ),
              const SizedBox(height: 12),
              CustomInput(label: 'Montant', hint: '0', controller: ctrl, keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                final amt = double.tryParse(ctrl.text) ?? 0;
                if (amt > 0) {
                  await appState.topUp(amt, asset);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Déposer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  final String asset;
  final double balance;
  final bool isDark;
  final VoidCallback onSend;
  final VoidCallback onReceive;
  const _AssetCard({required this.asset, required this.balance, required this.isDark, required this.onSend, required this.onReceive});

  static const _gradients = {
    'XOF': AppColors.primaryGradient,
    'USD': AppColors.electricGradient,
    'PAPO': AppColors.accentGradient,
  };

  @override
  Widget build(BuildContext context) {
    final gradient = _gradients[asset] ?? const LinearGradient(colors: [Colors.purple, Colors.deepPurple]);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: (gradient.colors.first).withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(asset, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 4),
              Text(formatAmountAbs(balance, asset), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            ])),
            Row(children: [
              _Btn(label: 'Envoyer', icon: LucideIcons.send, onTap: onSend),
              const SizedBox(width: 8),
              _Btn(label: 'Recevoir', icon: LucideIcons.download, onTap: onReceive),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _Btn({required this.label, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Icon(icon, color: Colors.white, size: 13),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
      ]),
    ),
  );
}
