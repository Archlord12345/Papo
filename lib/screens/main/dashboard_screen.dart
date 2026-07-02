import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav.dart';
import '../utils/formatters.dart';
import '../models/transaction_model.dart';

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
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1A0A3E),
                      Color(0xFF0A0516),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    appState.avatarInitials,
                    style: const TextStyle(
                        color: AppColors.primary, 
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bonjour,',
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
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(LucideIcons.bell),
                  onPressed: () => appState.setScreen('NotificationsList'),
                ),
              ),
              if (appState.unreadCount > 0)
                Positioned(
                  right: 0,
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
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: RefreshIndicator(
        onRefresh: () => context.read<AppState>().refreshFromBackend(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Balance card ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1A0A3E),
                      Color(0xFF2A1A4A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.creditCard,
                              color: AppColors.primary.withValues(alpha: 0.7),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              slot?.name ?? 'Portefeuille',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _hideBalance = !_hideBalance),
                          child: Icon(
                            _hideBalance
                                ? LucideIcons.eyeOff
                                : LucideIcons.eye,
                            size: 20,
                            color: Colors.grey[300],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _hideBalance
                          ? '•••••• XOF'
                          : formatAmountAbs(xofBalance, 'XOF'),
                      style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1),
                    ),
                    const SizedBox(height: 12),
                    if (slot != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              slot.walletId.length > 18 
                                  ? '•••• ${slot.walletId.substring(slot.walletId.length - 8)}'
                                  : slot.walletId,
                              style: TextStyle(
                                fontSize: 12, 
                                color: Colors.grey[300], 
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.darkSurface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+ Add Card',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Quick Actions ─────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _QuickAction(
                      icon: LucideIcons.arrowUpRight,
                      label: 'Send',
                      screen: 'SendMoney'),
                  _QuickAction(
                      icon: LucideIcons.arrowDownLeft,
                      label: 'Request',
                      screen: 'ReceiveMoney'),
                  _QuickAction(
                      icon: LucideIcons.refreshCw,
                      label: 'TopUp',
                      screen: 'Dashboard'),
                  _QuickAction(
                      icon: LucideIcons.moreHorizontal,
                      label: 'USSD',
                      screen: 'Ecosystem'),
                ],
              ),

              const SizedBox(height: 32),

              // ── Send Methods ─────────────────────────────────────────────
              const Text('MÉTHODES D\'ENVOI',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  )),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MethodCard(
                      icon: 'qr_code',
                      label: 'QR Code',
                      color: const Color(0xFF1A0A3E),
                      onTap: () => appState.setScreen('SendQR'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MethodCard(
                      icon: 'nfc',
                      label: 'NFC',
                      color: const Color(0xFF0A162D),
                      onTap: () => appState.setScreen('SendNFC'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MethodCard(
                      icon: 'bluetooth',
                      label: 'Bluetooth',
                      color: const Color(0xFF0A1020),
                      onTap: () => appState.setScreen('SendBluetooth'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MethodCard(
                      icon: 'hashtag',
                      label: 'Code-T',
                      color: const Color(0xFF1A1010),
                      onTap: () => appState.setScreen('SendMoney'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Recent Transactions ───────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Manage Expenses',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => appState.setScreen('History'),
                    child: Text(
                      'View All',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                  itemCount: appState.transactions.length.clamp(0, 4),
                  itemBuilder: (context, i) =>
                      _NewTxListItem(tx: appState.transactions[i]),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

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
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              )),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(_getIconData(icon), color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label, 
              style: const TextStyle(
                fontSize: 11, 
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String icon) {
    switch (icon) {
      case 'qr_code': return LucideIcons.qrCode;
      case 'nfc': return LucideIcons.wifi;
      case 'bluetooth': return LucideIcons.bluetooth;
      case 'hashtag': return LucideIcons.hashtag;
      default: return LucideIcons.helpCircle;
    }
  }
}

class _NewTxListItem extends StatelessWidget {
  final TransactionModel tx;
  const _NewTxListItem({super.key, required this.tx});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPositive = tx.amount > 0;
    final initials = tx.title.isNotEmpty 
        ? tx.title.substring(0, 2).toUpperCase() 
        : 'NA';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isPositive 
                  ? AppColors.success.withValues(alpha: 0.2) 
                  : AppColors.danger.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: isPositive 
                      ? AppColors.success 
                      : AppColors.danger,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600, 
                      fontSize: 14,
                    )),
                const SizedBox(height: 4),
                Text(timeAgo(tx.createdAt),
                    style: const TextStyle(
                      fontSize: 11, 
                      color: Colors.grey,
                    )),
              ],
            ),
          ),
          Text(
            formatAmount(tx.amount, tx.asset),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isPositive ? AppColors.success : (isDark ? Colors.white : AppColors.textLightPrimary),
            ),
          ),
        ],
      ),
    );
  }
}