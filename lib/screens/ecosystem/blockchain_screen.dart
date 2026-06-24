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

    // Build block data from real transactions
    final blocks = appState.transactions.take(10).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Explorateur de Blocs'), backgroundColor: Colors.transparent, elevation: 0),
      body: Column(
        children: [
          // Chain stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? AppColors.darkSurface : Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat('Blocs', '#${(349000 + appState.transactions.length).toString()}'),
                _Stat('Nœuds', '12 actifs'),
                _Stat('Tx totales', appState.transactions.length.toString()),
                _Stat('TPS', '145'),
              ],
            ),
          ),

          Expanded(
            child: blocks.isEmpty
                ? const Center(child: Text('Aucune transaction enregistrée'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: blocks.length,
                    itemBuilder: (ctx, i) {
                      final tx = blocks[i];
                      final blockNum = 349000 + appState.transactions.length - i;
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
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
}

class _BlockCard extends StatelessWidget {
  final int blockNum;
  final tx;
  final bool isDark;
  const _BlockCard({required this.blockNum, required this.tx, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Simulate block hash from tx id
    final hash = '0x${tx.id.replaceAll('-', '').substring(0, 16)}...';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('Bloc #$blockNum', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12)),
              ),
              Text(timeAgo(tx.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(LucideIcons.link, size: 13, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: tx.id));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hash copié'), duration: Duration(seconds: 1)));
                  },
                  child: Text(hash, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.secondary), overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${tx.type.toUpperCase()} — ${tx.asset}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                formatAmountAbs(tx.amount, tx.asset),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: tx.amount > 0 ? AppColors.success : AppColors.danger),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(LucideIcons.checkCircle, size: 13, color: AppColors.success),
              const SizedBox(width: 4),
              Text('Confirmé — statut: ${tx.status}', style: const TextStyle(fontSize: 11, color: AppColors.success)),
            ],
          ),
        ],
      ),
    );
  }
}
