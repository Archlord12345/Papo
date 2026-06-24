import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../models/wallet_slot_model.dart';
import '../../widgets/custom_button.dart';
import '../../utils/formatters.dart';

class WalletSlotScreen extends StatelessWidget {
  const WalletSlotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Wallets'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: appState.popScreen,
        ),
        actions: [
          if (appState.walletSlots.length < 10)
            IconButton(
              icon: const Icon(LucideIcons.plusCircle, color: AppColors.primary),
              onPressed: () => appState.setScreen('CreateWallet'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.wallet, color: Colors.white, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Slots de Wallet', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(
                          '${appState.walletSlots.length}/10 wallets',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text('Adresse: ${appState.blockchainAddr}',
                            style: const TextStyle(color: Colors.white60, fontSize: 10, fontFamily: 'monospace'),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Slots list
          Expanded(
            child: appState.walletSlots.isEmpty
                ? const Center(child: Text('Aucun wallet'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: appState.walletSlots.length,
                    itemBuilder: (ctx, i) {
                      final slot = appState.walletSlots[i];
                      return _SlotCard(
                        slot: slot,
                        onActivate: () async {
                          await appState.setActiveWalletSlot(slot.id!);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('${slot.name} activé'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                        onRename: () => _showRenameDialog(ctx, appState, slot),
                        onDelete: () => _confirmDelete(ctx, appState, slot),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, AppState appState, WalletSlotModel slot) {
    final ctrl = TextEditingController(text: slot.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Renommer le wallet'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nom du wallet'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                await appState.renameWalletSlot(slot.id!, name);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Renommer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppState appState, WalletSlotModel slot) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce wallet ?'),
        content: Text('${slot.name} (${slot.walletId}) sera définitivement supprimé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              final err = await appState.deleteWalletSlot(slot.id!);
              if (context.mounted) {
                Navigator.pop(context);
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.danger));
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  final WalletSlotModel slot;
  final VoidCallback onActivate;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  const _SlotCard({required this.slot, required this.onActivate, required this.onRename, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: slot.isActive
            ? AppColors.primary.withValues(alpha: 0.08)
            : (isDark ? AppColors.darkSurface : Colors.white),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: slot.isActive ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: slot.isActive ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('SLOT ${slot.slot}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(slot.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                if (slot.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: const Text('ACTIF', style: TextStyle(fontSize: 9, color: AppColors.success, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(slot.walletId,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(LucideIcons.smartphone, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(slot.deviceName, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
            const SizedBox(height: 12),
            // Balances
            Row(children: slot.balances.entries.take(4).map((e) =>
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${e.value.toStringAsFixed(e.key == 'BTC' ? 4 : 0)} ${e.key}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              )
            ).toList()),
            const SizedBox(height: 12),
            // Actions
            Row(children: [
              if (!slot.isActive)
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: onActivate,
                    child: const Text('Activer', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
              if (!slot.isActive) const SizedBox(width: 8),
              IconButton(
                icon: const Icon(LucideIcons.pencil, size: 18),
                onPressed: onRename,
                tooltip: 'Renommer',
              ),
              if (!slot.isActive)
                IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.danger),
                  onPressed: onDelete,
                  tooltip: 'Supprimer',
                ),
            ]),
          ],
        ),
      ),
    );
  }
}
