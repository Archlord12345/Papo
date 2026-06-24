import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_button.dart';
import '../../utils/formatters.dart';

class MerchantDashboardScreen extends StatelessWidget {
  const MerchantDashboardScreen({super.key});

  static const _revenueData = [150000.0, 240000, 190000, 310000, 280000, 420000, 380000];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    const double merchantBalance = 2450000.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Marchand'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(LucideIcons.home), onPressed: () => appState.setScreen('Dashboard')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance card
            GlassCard(
              borderColor: AppColors.secondary.withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SOLDE MARCHAND', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary, letterSpacing: 1.5)),
                  const SizedBox(height: 6),
                  Text(formatAmountAbs(merchantBalance, 'XOF'), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StatPill(label: '7j', value: formatAmountAbs(_revenueData.reduce((a, b) => a + b).toDouble(), 'XOF'), color: AppColors.secondary),
                      const SizedBox(width: 10),
                      _StatPill(label: 'Tx ce mois', value: '${appState.transactions.length}', color: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Retirer vers mon compte principal',
                    gradient: AppColors.electricGradient,
                    onPressed: () async {
                      if (merchantBalance < 1000) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solde insuffisant')));
                        return;
                      }
                      await appState.receiveMoney(100000.0, 'XOF', senderLabel: 'Retrait espace marchand');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Retrait effectué'), backgroundColor: AppColors.success));
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Revenue chart
            const Text('Volume des ventes (7 derniers jours)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: LineChart(LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                        return Text(days[v.toInt()], style: const TextStyle(fontSize: 10, color: Colors.grey));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _revenueData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
                    isCurved: true,
                    color: AppColors.secondary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: AppColors.secondary.withOpacity(0.1)),
                  ),
                ],
              )),
            ),
            const SizedBox(height: 24),

            // Checkout QR
            const Text('QR Code Encaissement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: QrImageView(
                      data: 'papo:merchant/${appState.activeWalletId}?name=${Uri.encodeComponent(appState.userName)}',
                      version: QrVersions.auto,
                      size: 160,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Boutique de ${appState.userName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Text('Affichez ce QR sur votre comptoir pour recevoir les paiements.', style: TextStyle(color: Colors.grey, fontSize: 11), textAlign: TextAlign.center),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatPill({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }
}
