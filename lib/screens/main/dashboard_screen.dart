import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/bottom_nav.dart';
import '../../utils/formatters.dart';
import '../../models/transaction_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _hideBalance = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().refreshFromBackend();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slot = appState.activeSlot;
    final xofBalance = slot?.balance ?? 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: Text(
                appState.avatarInitials,
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Salut,',
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textLightSecondary)),
                Text(
                  appState.userName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Notification badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.bell),
                onPressed: () => appState.setScreen('NotificationsList'),
              ),
              if (appState.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: AppColors.danger, shape: BoxShape.circle),
                    child: Text(
                      '${appState.unreadCount}',
                      style: const TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(appState.themeMode == ThemeMode.dark
                ? LucideIcons.sun
                : LucideIcons.moon),
            onPressed: appState.toggleTheme,
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: RefreshIndicator(
        onRefresh: () => context.read<AppState>().refreshFromBackend(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Balance card ──────────────────────────────────────────────
              GlassCard(
                padding: const EdgeInsets.all(22),
                borderColor: AppColors.primary.withValues(alpha: 0.25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SOLDE DISPONIBLE',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: AppColors.primary),
                        ),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _hideBalance = !_hideBalance),
                          child: Icon(
                            _hideBalance
                                ? LucideIcons.eyeOff
                                : LucideIcons.eye,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _hideBalance
                          ? '•••••• XOF'
                          : formatAmountAbs(xofBalance, 'XOF'),
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1),
                    ),
                    const SizedBox(height: 4),
                    if (slot != null) ...[
                      Text(slot.name,
                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      slot != null
                          ? '${slot.walletId.substring(0, 18)}...'
                          : appState.activeWalletId,
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 16),
                    // Mini asset row
                    Row(
                      children: [
                        _AssetPill(asset: 'USD', value: slot?.balances['USD'] ?? 0),
                        const SizedBox(width: 8),
                        _AssetPill(asset: 'PAPO', value: slot?.balances['PAPO'] ?? 0),
                        const SizedBox(width: 8),
                        _AssetPill(asset: 'BTC', value: slot?.balances['BTC'] ?? 0),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: appState.activeWalletId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Adresse copiée'), duration: Duration(seconds: 1)),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(LucideIcons.copy, size: 14, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Quick Actions ─────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _QuickAction(
                      icon: LucideIcons.send,
                      label: 'Envoyer',
                      screen: 'SendMoney'),
                  _QuickAction(
                      icon: LucideIcons.download,
                      label: 'Recevoir',
                      screen: 'ReceiveMoney'),
                  _QuickAction(
                      icon: LucideIcons.wifiOff,
                      label: 'Offline',
                      screen: 'OfflinePayment'),
                  _QuickAction(
                      icon: LucideIcons.globe,
                      label: 'Services',
                      screen: 'Ecosystem'),
                ],
              ),

              const SizedBox(height: 28),

              // ── Services Grid ─────────────────────────────────────────────
              const Text('Services PAPO',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: const [
                  _ServiceCard(
                      icon: LucideIcons.shield,
                      label: 'Cercle (Tontine)',
                      screen: 'Circle',
                      color: AppColors.secondary),
                  _ServiceCard(
                      icon: LucideIcons.link,
                      label: 'Blockchain',
                      screen: 'Blockchain',
                      color: AppColors.primary),
                  _ServiceCard(
                      icon: LucideIcons.globe,
                      label: 'Écosystème',
                      screen: 'Ecosystem',
                      color: AppColors.accent),
                  _ServiceCard(
                      icon: LucideIcons.terminal,
                      label: 'Développeur',
                      screen: 'Developer',
                      color: Colors.blueGrey),
                ],
              ),

              const SizedBox(height: 24),

              // ── KYC Banner ────────────────────────────────────────────────
              if (appState.kycStatus == 'none')
                _KycBanner(onTap: () => appState.setScreen('KYCStatus')),

              // ── Offline sync banner ───────────────────────────────────────
              if (appState.offlineQueue.isNotEmpty)
                GestureDetector(
                  onTap: () => appState.setScreen('Sync'),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.wifiOff,
                            color: AppColors.warning),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${appState.offlineQueue.length} transaction(s) en attente de synchronisation',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const Icon(LucideIcons.chevronRight,
                            size: 16, color: AppColors.warning),
                      ],
                    ),
                  ),
                ),

              // ── Recent Transactions ───────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Transactions récentes',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => appState.setScreen('History'),
                    child: const Text('Voir tout'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (appState.transactions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Aucune transaction',
                      style: TextStyle(
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textLightSecondary),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: appState.transactions.length.clamp(0, 5),
                  itemBuilder: (context, i) =>
                      TxListItem(tx: appState.transactions[i]),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _AssetPill extends StatelessWidget {
  final String asset;
  final double value;
  const _AssetPill({required this.asset, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${value.toStringAsFixed(asset == 'BTC' ? 4 : 0)} $asset',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String screen;
  const _QuickAction(
      {required this.icon, required this.label, required this.screen});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => context.read<AppState>().setScreen(screen),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String screen;
  final Color color;
  const _ServiceCard(
      {required this.icon,
      required this.label,
      required this.screen,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => context.read<AppState>().setScreen(screen),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12)),
              ),
              Icon(LucideIcons.chevronRight, size: 14, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _KycBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _KycBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.alertTriangle, color: AppColors.accent),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Vérifiez votre identité (KYC) pour débloquer toutes les limites.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const Icon(LucideIcons.chevronRight,
                size: 16, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}

// Shared transaction list item (used by Dashboard + History)
class TxListItem extends StatelessWidget {
  final TransactionModel tx;
  const TxListItem({super.key, required this.tx});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPositive = tx.amount > 0;

    IconData icon;
    Color iconColor;
    switch (tx.type) {
      case 'receive':
      case 'deposit':
        icon = LucideIcons.arrowDownLeft;
        iconColor = AppColors.success;
        break;
      case 'offline':
        icon = LucideIcons.wifiOff;
        iconColor = AppColors.warning;
        break;
      case 'bill':
        icon = LucideIcons.receipt;
        iconColor = AppColors.secondary;
        break;
      default:
        icon = LucideIcons.arrowUpRight;
        iconColor = AppColors.danger;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        title: Text(tx.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Row(
          children: [
            Text(timeAgo(tx.createdAt),
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            if (tx.status == 'pending')
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('EN ATTENTE',
                    style: TextStyle(
                        fontSize: 8,
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        trailing: Text(
          formatAmount(tx.amount, tx.asset),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isPositive ? AppColors.success : (isDark ? Colors.white : AppColors.textLightPrimary),
          ),
        ),
        onTap: () => _showDetail(context, tx),
      ),
    );
  }

  void _showDetail(BuildContext context, TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _TxDetailSheet(tx: tx),
    );
  }
}

class _TxDetailSheet extends StatelessWidget {
  final TransactionModel tx;
  const _TxDetailSheet({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPositive = tx.amount > 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.all(24),
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              formatAmountAbs(tx.amount, tx.asset),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: isPositive ? AppColors.success : AppColors.danger,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: _statusColor(tx.status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                tx.status.toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    color: _statusColor(tx.status),
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 28),
          _Row('Titre', tx.title),
          _Row('Type', tx.type.toUpperCase()),
          _Row('Destinataire',
              tx.recipient.isEmpty ? '—' : tx.recipient),
          _Row('Date', formatDate(tx.createdAt)),
          _Row('ID Transaction', tx.id, mono: true),
          if (tx.description.isNotEmpty)
            _Row('Description', tx.description),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed': return AppColors.success;
      case 'pending': return AppColors.warning;
      default: return AppColors.danger;
    }
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  const _Row(this.label, this.value, {this.mono = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: mono ? 'monospace' : null),
            ),
          ),
        ],
      ),
    );
  }
}
