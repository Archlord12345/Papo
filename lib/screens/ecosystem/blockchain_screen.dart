import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';

class BlockchainScreen extends StatelessWidget {
  const BlockchainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Blocs depuis les vraies transactions
    final txs = appState.transactions;
    final baseBlock = 349000;
    final totalBlocks = baseBlock + txs.length;
    final confirmedCount = txs.where((t) => t.status == 'completed').length;
    final pendingCount = txs.where((t) => t.status == 'pending').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorateur de Blocs'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () => appState.refreshFromBackend(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => appState.refreshFromBackend(),
        color: AppColors.primary,
        child: Column(
          children: [
            // ── Stats de la chaîne ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              color: isDark ? AppColors.darkSurface : Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat('Dernier bloc', '#$totalBlocks'),
                  _Stat('Tx confirmées', '$confirmedCount'),
                  _Stat('En attente', '$pendingCount'),
                  _Stat('Tx totales', '${txs.length}'),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Liste des blocs ───────────────────────────────────────────
            Expanded(
              child: txs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.blocks, size: 64, color: Colors.grey.withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          const Text('Aucune transaction enregistrée',
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          const Text('Effectuez votre première transaction pour voir la chaîne.',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: txs.length,
                      itemBuilder: (ctx, i) {
                        final tx = txs[i];
                        final blockNum = totalBlocks - i;
                        return _BlockCard(
                          blockNum: blockNum,
                          tx: tx,
                          isDark: isDark,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
}

class _BlockCard extends StatelessWidget {
  final int blockNum;
  final dynamic tx;
  final bool isDark;
  const _BlockCard({
    required this.blockNum,
    required this.tx,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Hash simulé depuis l'ID de la transaction
    final rawId = tx.id.toString().replaceAll('-', '');
    final hashPreview = '0x${rawId.substring(0, rawId.length >= 16 ? 16 : rawId.length)}…';
    final isPositive = (tx.amount as num) > 0;
    final statusColor = tx.status == 'completed'
        ? AppColors.success
        : tx.status == 'pending'
            ? AppColors.warning
            : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Bloc #$blockNum',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 12)),
              ),
              Text(timeAgo(tx.createdAt.toString()),
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),

          // Hash
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: tx.id.toString()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Hash copié'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Row(children: [
              const Icon(LucideIcons.link, size: 13, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hashPreview,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppColors.secondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(LucideIcons.copy, size: 12, color: Colors.grey),
            ]),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '${tx.type.toString().toUpperCase()} — ${tx.asset ?? 'XOF'}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formatAmountAbs(
                    (tx.amount as num).toDouble(), tx.asset?.toString() ?? 'XOF'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isPositive ? AppColors.success : AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Row(children: [
            Icon(
              tx.status == 'completed'
                  ? LucideIcons.checkCircle
                  : tx.status == 'pending'
                      ? LucideIcons.clock
                      : LucideIcons.xCircle,
              size: 13,
              color: statusColor,
            ),
            const SizedBox(width: 4),
            Text(
              tx.status.toString().toUpperCase(),
              style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
            ),
            if (tx.recipient?.toString().isNotEmpty == true) ...[
              const SizedBox(width: 8),
              const Icon(LucideIcons.arrowRight, size: 11, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  tx.recipient.toString(),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ]),
        ],
      ),
    );
  }
}
