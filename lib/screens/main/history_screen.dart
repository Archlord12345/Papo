import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav.dart';
import '../../utils/formatters.dart';
import 'dashboard_screen.dart' show _NewTxListItem;

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = appState.transactions.where((tx) {
      if (_filter == 'all') return true;
      if (_filter == 'send') return tx.amount < 0;
      if (_filter == 'receive') return tx.amount > 0;
      return true;
    }).toList();

    // Compute totals for header
    final sent = appState.transactions
        .where((t) => t.amount < 0 && t.asset == 'XOF')
        .fold<double>(0, (s, t) => s + t.amount.abs());
    final received = appState.transactions
        .where((t) => t.amount > 0 && t.asset == 'XOF')
        .fold<double>(0, (s, t) => s + t.amount);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Historique',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search),
            onPressed: () => _showSearch(context, appState),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      body: Column(
        children: [
          // Summary cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Total reçu',
                    amount: received,
                    asset: 'XOF',
                    color: AppColors.success,
                    icon: LucideIcons.arrowDownLeft,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: 'Total envoyé',
                    amount: sent,
                    asset: 'XOF',
                    color: AppColors.danger,
                    icon: LucideIcons.arrowUpRight,
                  ),
                ),
              ],
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _Chip(
                    label: 'Tout',
                    value: 'all',
                    current: _filter,
                    onTap: (v) => setState(() => _filter = v)),
                _Chip(
                    label: 'Reçus',
                    value: 'receive',
                    current: _filter,
                    onTap: (v) => setState(() => _filter = v)),
                _Chip(
                    label: 'Envoyés',
                    value: 'send',
                    current: _filter,
                    onTap: (v) => setState(() => _filter = v)),
              ],
            ),
          ),

          // Transaction list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'Aucune transaction',
                      style: TextStyle(
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textLightSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _NewTxListItem(tx: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  void _showSearch(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _SearchSheet(transactions: appState.transactions),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final String asset;
  final Color color;
  final IconData icon;
  const _SummaryCard(
      {required this.label,
      required this.amount,
      required this.asset,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            '+${formatAmountAbs(amount, asset)}',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final void Function(String) onTap;
  const _Chip(
      {required this.label,
      required this.value,
      required this.current,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.secondary
              : (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkSurface
                  : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: selected ? AppColors.primary : null),
        ),
      ),
    );
  }
}

class _SearchSheet extends StatefulWidget {
  final List transactions;
  const _SearchSheet({required this.transactions});
  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = widget.transactions.where((tx) {
      final q = _query.toLowerCase();
      return tx.title.toLowerCase().contains(q) ||
          tx.recipient.toLowerCase().contains(q) ||
          tx.description.toLowerCase().contains(q);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Rechercher une transaction...',
                prefixIcon: Icon(LucideIcons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: results.length,
              itemBuilder: (ctx, i) => _NewTxListItem(tx: results[i]),
            ),
          ),
        ],
      ),
    );
  }
}
