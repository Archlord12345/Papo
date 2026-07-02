import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_button.dart';
import '../../utils/formatters.dart';
import '../../models/transaction_model.dart';

// ─── Format QR marchand standardisé ──────────────────────────────────────────
// papo:merchant?walletId=PAPO-XXX-0&name=Boutique%20Kone&phone=%2B2250700000000
// Le scanner dans send_qr_screen lit ce format et pré-remplit le destinataire.
String buildMerchantQrData({
  required String walletId,
  required String name,
  required String phone,
}) {
  final encoded = Uri(
    scheme: 'papo',
    host: 'merchant',
    queryParameters: {
      'walletId': walletId,
      'name': name,
      'phone': phone,
    },
  ).toString();
  return encoded;
}

// ─────────────────────────────────────────────────────────────────────────────

class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});
  @override
  State<MerchantDashboardScreen> createState() => _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> {
  bool _withdrawing = false;
  final GlobalKey _qrKey = GlobalKey();

  // ── Stats depuis les vraies transactions ─────────────────────────────────

  List<double> _last7Days(List<TransactionModel> txs) {
    final now = DateTime.now();
    final result = List<double>.filled(7, 0);
    for (final tx in txs) {
      if (tx.amount <= 0) continue;
      final date = DateTime.tryParse(tx.createdAt);
      if (date == null) continue;
      final diff = now.difference(date).inDays;
      if (diff >= 0 && diff < 7) result[6 - diff] += tx.amount;
    }
    return result;
  }

  double _totalRevenue(List<TransactionModel> txs) =>
      txs.where((t) => t.amount > 0).fold(0, (s, t) => s + t.amount);

  double _weekRevenue(List<TransactionModel> txs) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return txs
        .where((t) => t.amount > 0 && DateTime.tryParse(t.createdAt)?.isAfter(cutoff) == true)
        .fold(0, (s, t) => s + t.amount);
  }

  // ── Partage du QR ─────────────────────────────────────────────────────────

  Future<void> _shareQr(AppState appState) async {
    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/qr_marchand_${appState.userName.replaceAll(' ', '_')}.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Mon QR de paiement PAYPOINT',
        text: 'Scannez ce code pour me payer directement via PAYPOINT.\n${buildMerchantQrData(walletId: appState.activeWalletId, name: appState.userName, phone: appState.userPhone)}',
      );
    } catch (e) {
      debugPrint('Share QR error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de partage : $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final txs = appState.transactions;
    final slot = appState.activeSlot;
    final balance = slot?.balance ?? 0;
    final revenueData = _last7Days(txs);
    final maxRevenue = revenueData.fold<double>(1, (m, v) => v > m ? v : m);
    final now = DateTime.now();
    final dayLabels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return ['D', 'L', 'M', 'M', 'J', 'V', 'S'][d.weekday % 7];
    });

    final qrData = buildMerchantQrData(
      walletId: appState.activeWalletId,
      name: appState.userName,
      phone: appState.userPhone,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Marchand'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () => appState.refreshFromBackend(),
          ),
          IconButton(
            icon: const Icon(LucideIcons.home),
            onPressed: () => appState.setScreen('Dashboard'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => appState.refreshFromBackend(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Solde ───────────────────────────────────────────────────
              GlassCard(
                borderColor: AppColors.secondary.withValues(alpha: 0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SOLDE MARCHAND (WALLET ACTIF)',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary, letterSpacing: 1.5)),
                    const SizedBox(height: 6),
                    Text(formatAmountAbs(balance, 'XOF'),
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                    if (slot != null) ...[
                      const SizedBox(height: 4),
                      Text(slot.name, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                    const SizedBox(height: 16),
                    Row(children: [
                      _StatPill(label: '7j', value: formatAmountAbs(_weekRevenue(txs), 'XOF'), color: AppColors.secondary),
                      const SizedBox(width: 8),
                      _StatPill(label: 'Tx', value: '${txs.length}', color: AppColors.primary),
                      const SizedBox(width: 8),
                      _StatPill(label: 'Total', value: formatAmountAbs(_totalRevenue(txs), 'XOF'), color: AppColors.success),
                    ]),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Retirer vers mon compte principal',
                      gradient: AppColors.electricGradient,
                      isLoading: _withdrawing,
                      onPressed: balance < 1000 ? null : () => _showWithdrawDialog(context, appState, balance),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Graphique ───────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Volume (7 derniers jours)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  if (revenueData.every((v) => v == 0))
                    const Text('Aucune activité', style: TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 12),
              revenueData.every((v) => v == 0)
                  ? _EmptyChart()
                  : SizedBox(
                      height: 140,
                      child: LineChart(LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= dayLabels.length) return const SizedBox();
                              return Text(dayLabels[i], style: const TextStyle(fontSize: 10, color: Colors.grey));
                            },
                          )),
                        ),
                        borderData: FlBorderData(show: false),
                        minY: 0,
                        maxY: maxRevenue * 1.2,
                        lineBarsData: [
                          LineChartBarData(
                            spots: revenueData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                            isCurved: true,
                            color: AppColors.secondary,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: true, color: AppColors.secondary.withValues(alpha: 0.1)),
                          ),
                        ],
                      )),
                    ),
              const SizedBox(height: 24),

              // ── Transactions récentes ────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Transactions récentes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () => appState.setScreen('History'), child: const Text('Voir tout')),
                ],
              ),
              const SizedBox(height: 8),
              txs.isEmpty
                  ? _EmptyTransactions()
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: txs.length.clamp(0, 5),
                      itemBuilder: (ctx, i) => _MerchantTxTile(tx: txs[i]),
                    ),
              const SizedBox(height: 24),

              // ── QR Code Marchand ─────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('QR Code Encaissement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    icon: const Icon(LucideIcons.share2, size: 16),
                    label: const Text('Partager'),
                    onPressed: () => _shareQr(appState),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    // RepaintBoundary pour la capture du QR
                    RepaintBoundary(
                      key: _qrKey,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 200,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Color(0xFF0F172A),
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Color(0xFF0F172A),
                              ),
                              embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(32, 32)),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              appState.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              appState.userPhone,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F4FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                appState.activeWalletId,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 9,
                                  color: Color(0xFF3B5BDB),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Affichez ce QR sur votre comptoir.\nLes clients scannent depuis leur app PAYPOINT.',
                      style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(LucideIcons.share2, size: 16),
                          label: const Text('Partager le QR'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _shareQr(appState),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, AppState appState, double balance) {
    final ctrl = TextEditingController();
    bool loading = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Retirer des fonds'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Solde : ${formatAmountAbs(balance, 'XOF')}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Montant à retirer (XOF)',
                  hintText: '0',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: loading
                  ? null
                  : () async {
                      final amt = double.tryParse(ctrl.text) ?? 0;
                      if (amt <= 0 || amt > balance) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Montant invalide')));
                        return;
                      }
                      setState(() => loading = true);
                      await appState.receiveMoney(amt, 'XOF', senderLabel: 'Retrait espace marchand');
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Retrait effectué'), backgroundColor: AppColors.success));
                      }
                    },
              child: const Text('Confirmer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sous-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: const Center(
        child: Text('Aucune transaction cette semaine', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'Aucune transaction pour le moment.\nRecevez votre premier paiement via le QR.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, height: 1.5),
        ),
      ),
    );
  }
}

class _MerchantTxTile extends StatelessWidget {
  final TransactionModel tx;
  const _MerchantTxTile({required this.tx});
  @override
  Widget build(BuildContext context) {
    final isIn = tx.amount > 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isIn ? AppColors.success : AppColors.danger).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isIn ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
            color: isIn ? AppColors.success : AppColors.danger,
            size: 16,
          ),
        ),
        title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(timeAgo(tx.createdAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: Text(
          formatAmount(tx.amount, tx.asset),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isIn ? AppColors.success : AppColors.danger),
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
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}
