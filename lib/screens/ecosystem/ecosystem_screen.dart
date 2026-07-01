import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/bottom_nav.dart';
import '../../utils/formatters.dart';

class EcosystemScreen extends StatelessWidget {
  const EcosystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Écosystème & Services'), backgroundColor: Colors.transparent, elevation: 0),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bills section
            const _SectionTitle('Paiement de Factures'),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: const [
                _BillCard(name: 'CIE', label: 'Électricité', icon: LucideIcons.zap, color: AppColors.accent),
                _BillCard(name: 'SODECI', label: 'Eau', icon: LucideIcons.droplets, color: AppColors.secondary),
                _BillCard(name: 'Canal+', label: 'TV/Satellite', icon: LucideIcons.tv, color: Colors.purple),
                _BillCard(name: 'Orange CI', label: 'Mobile Money', icon: LucideIcons.smartphone, color: Colors.orange),
              ],
            ),
            const SizedBox(height: 24),

            // Web3 / DeFi section
            const _SectionTitle('Web3 & DeFi'),
            _Web3Card(
              icon: LucideIcons.trendingUp,
              title: 'Staking PAPO',
              desc: 'Déposez vos PAPO et gagnez 12% APY.',
              color: AppColors.primary,
              onTap: () => _showStakingDialog(context),
            ),
            const SizedBox(height: 10),
            _Web3Card(
              icon: LucideIcons.gift,
              title: 'Airdrops',
              desc: 'Participez aux distributions de tokens PAPO.',
              color: AppColors.accent,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucun airdrop actif pour l\'instant.'))),
            ),
          ],
        ),
      ),
    );
  }

  static void _showStakingDialog(BuildContext context) {
    final appState = context.read<AppState>();
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Staking PAPO'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Solde PAPO disponible', style: TextStyle(fontSize: 13)),
                  Text(formatAmountAbs(appState.balances['PAPO'] ?? 0, 'PAPO'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CustomInput(label: 'Montant à staker', hint: '0', controller: ctrl, keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            const Text('APY estimé : 12% par an', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              final amt = double.tryParse(ctrl.text) ?? 0;
              if (amt > 0 && amt <= (appState.balances['PAPO'] ?? 0)) {
                appState.addNotification('Staking activé', 'Vous avez mis ${ amt.toStringAsFixed(0)} PAPO en staking à 12% APY.', 'success');
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staking activé avec succès !'), backgroundColor: AppColors.success));
              }
            },
            child: const Text('Staker', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}

class _BillCard extends StatelessWidget {
  final String name;
  final String label;
  final IconData icon;
  final Color color;
  const _BillCard({required this.name, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _showBillSheet(context),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
            const SizedBox(height: 8),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  void _showBillSheet(BuildContext context) {
    final appState = context.read<AppState>();
    final refCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Text('Payer $name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ]),
            const SizedBox(height: 20),
            CustomInput(label: 'Référence / Numéro de compte', hint: 'Ex: CI2024-XXXXX', controller: refCtrl),
            const SizedBox(height: 14),
            CustomInput(label: 'Montant (XOF)', hint: '0', controller: amtCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () async {
                  final amt = double.tryParse(amtCtrl.text) ?? 0;
                  final ref = refCtrl.text.trim();
                  if (amt <= 0 || ref.isEmpty) return;
                  Navigator.pop(ctx);
                  final ok = await appState.payBill(provider: name, reference: ref, amount: amt);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ok ? 'Facture $name payée avec succès !' : 'Solde insuffisant'), backgroundColor: ok ? AppColors.success : AppColors.danger),
                    );
                  }
                },
                child: const Text('Payer maintenant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Web3Card extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  final VoidCallback onTap;
  const _Web3Card({required this.icon, required this.title, required this.desc, required this.color, required this.onTap});
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
        ),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ])),
            Icon(LucideIcons.chevronRight, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
