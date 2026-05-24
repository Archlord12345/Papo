import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/screen_explorer.dart';
import 'main_screens.dart';

class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  State<MerchantDashboardScreen> createState() => _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> {
  double _merchantBalance = 2450000; // Simulated merchant business balance

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(
        title: const Text("Espace Marchand"),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.home),
            onPressed: () => appState.setScreen("Dashboard"),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Merchant balance Card
              GlassCard(
                borderColor: AppColors.secondary.withOpacity(0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("SOLDE MARCHAND", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(_merchantBalance, 'XOF'),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: "Faire un retrait",
                            gradient: AppColors.electricGradient,
                            onPressed: () {
                              if (_merchantBalance < 50000) return;
                              setState(() {
                                _merchantBalance -= 100000;
                              });
                              appState.receiveMoney(100000, 'XOF'); // Add to personal balance
                              appState.addNotification(
                                "Retrait Marchand",
                                "Retrait de 100,000 XOF effectué vers votre solde principal.",
                                "success",
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Revenue Analytics Line Chart
              const Text("Volume des Ventes (7 derniers jours)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                height: 150,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 150000),
                          FlSpot(1, 240000),
                          FlSpot(2, 190000),
                          FlSpot(3, 310000),
                          FlSpot(4, 280000),
                          FlSpot(5, 420000),
                          FlSpot(6, 380000),
                        ],
                        isCurved: true,
                        color: AppColors.secondary,
                        barWidth: 3,
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.secondary.withOpacity(0.1),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Permanent Checkout QR
              const Text("QR Code Encaissement Boutique", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: QrImageView(
                        data: "papo:merchant/${appState.walletAddress}?name=Boutique%20Mamadou",
                        version: QrVersions.auto,
                        size: 150.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Nom de la boutique : Papo Store - ${appState.userName}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      "Affichez ce code sur votre comptoir pour recevoir les paiements",
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
