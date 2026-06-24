import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';
import '../../models/circle_model.dart';
import '../../utils/formatters.dart';

class CircleScreen extends StatelessWidget {
  const CircleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cercles de Confiance'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: appState.popScreen),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plusCircle, color: AppColors.primary),
            onPressed: () => _showCreateCircleDialog(context, appState),
          ),
        ],
      ),
      body: appState.circles.isEmpty
          ? _EmptyState(onCreate: () => _showCreateCircleDialog(context, appState))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appState.circles.length,
              itemBuilder: (ctx, i) => _CircleCard(
                circle: appState.circles[i],
                appState: appState,
              ),
            ),
    );
  }

  static void _showCreateCircleDialog(BuildContext context, AppState appState) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final targetCtrl = TextEditingController(text: '500000');
    final contribCtrl = TextEditingController(text: '100000');
    String freq = 'monthly';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Créer un cercle'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CustomInput(label: 'Nom du cercle', hint: 'ex: Tontine Familiale', controller: nameCtrl),
              const SizedBox(height: 12),
              CustomInput(label: 'Description', hint: 'Optionnel', controller: descCtrl),
              const SizedBox(height: 12),
              CustomInput(label: 'Objectif (XOF)', hint: '500000', controller: targetCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              CustomInput(label: 'Cotisation par membre (XOF)', hint: '100000', controller: contribCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: freq,
                decoration: const InputDecoration(labelText: 'Fréquence'),
                items: const [
                  DropdownMenuItem(value: 'weekly', child: Text('Hebdomadaire')),
                  DropdownMenuItem(value: 'monthly', child: Text('Mensuelle')),
                  DropdownMenuItem(value: 'quarterly', child: Text('Trimestrielle')),
                ],
                onChanged: (v) => setState(() => freq = v!),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                final err = await appState.createCircle(
                  name: nameCtrl.text,
                  description: descCtrl.text,
                  target: double.tryParse(targetCtrl.text) ?? 500000,
                  contribution: double.tryParse(contribCtrl.text) ?? 100000,
                  frequency: freq,
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (err != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.danger));
                }
              },
              child: const Text('Créer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(LucideIcons.shield, size: 80, color: Colors.grey),
      const SizedBox(height: 16),
      const Text('Aucun cercle de confiance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 8),
      const Text('Créez votre première tontine pour commencer.', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      CustomButton(text: 'Créer un cercle', icon: const Icon(LucideIcons.plus, color: Colors.white, size: 18), onPressed: onCreate),
    ]));
  }
}

class _CircleCard extends StatelessWidget {
  final CircleModel circle;
  final AppState appState;
  const _CircleCard({required this.circle, required this.appState});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(circle.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _showEditDialog(context, appState, circle);
                    if (v == 'delete') _confirmDelete(context, appState, circle);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Modifier')),
                    PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: AppColors.danger))),
                  ],
                ),
              ]),
              if (circle.description.isNotEmpty)
                Text(circle.description, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${formatAmountAbs(circle.collected, 'XOF')} / ${formatAmountAbs(circle.target, 'XOF')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('${(circle.progress * 100).toInt()}%', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: circle.progress, minHeight: 8,
                  backgroundColor: isDark ? AppColors.darkBorder : Colors.grey.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${circle.paidCount}/${circle.members.length} membres', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text('Cotisation: ${formatAmountAbs(circle.contribution, 'XOF')}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
            ]),
          ),
          // Members
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Membres', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              TextButton.icon(
                icon: const Icon(LucideIcons.qrCode, size: 14),
                label: const Text('Scanner QR', style: TextStyle(fontSize: 12)),
                onPressed: () => _showScanMemberQr(context, appState, circle),
              ),
            ]),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: circle.members.length,
            itemBuilder: (ctx, i) => _MemberTile(
              member: circle.members[i],
              circle: circle,
              appState: appState,
              isCurrentUser: i == 0,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: CustomButton(
              text: 'Ajouter un membre manuellement',
              isPrimary: false,
              icon: const Icon(LucideIcons.userPlus, color: AppColors.primary, size: 16),
              onPressed: () => _showAddMemberDialog(context, appState, circle),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, AppState appState, CircleModel circle) {
    final nameCtrl = TextEditingController(text: circle.name);
    final descCtrl = TextEditingController(text: circle.description);
    final targetCtrl = TextEditingController(text: circle.target.toStringAsFixed(0));
    final contribCtrl = TextEditingController(text: circle.contribution.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Modifier le cercle'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          CustomInput(label: 'Nom', hint: '', controller: nameCtrl),
          const SizedBox(height: 12),
          CustomInput(label: 'Description', hint: '', controller: descCtrl),
          const SizedBox(height: 12),
          CustomInput(label: 'Objectif (XOF)', hint: '', controller: targetCtrl, keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          CustomInput(label: 'Cotisation (XOF)', hint: '', controller: contribCtrl, keyboardType: TextInputType.number),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              circle.name = nameCtrl.text.trim();
              circle.description = descCtrl.text.trim();
              circle.target = double.tryParse(targetCtrl.text) ?? circle.target;
              circle.contribution = double.tryParse(contribCtrl.text) ?? circle.contribution;
              await appState.updateCircle(circle);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppState appState, CircleModel circle) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce cercle ?'),
        content: Text('${circle.name} et tous ses membres seront supprimés définitivement.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              await appState.deleteCircle(circle.id!);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, AppState appState, CircleModel circle) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ajouter un membre'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          CustomInput(label: 'Nom complet', hint: 'ex: Awa Diop', controller: nameCtrl),
          const SizedBox(height: 12),
          CustomInput(label: 'Téléphone', hint: '+225 07 00 00 00', controller: phoneCtrl, keyboardType: TextInputType.phone),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              final err = await appState.addCircleMember(circleId: circle.id!, name: nameCtrl.text, phone: phoneCtrl.text);
              if (context.mounted) {
                Navigator.pop(context);
                if (err != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.danger));
              }
            },
            child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showScanMemberQr(BuildContext context, AppState appState, CircleModel circle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _QrScanMemberSheet(circle: circle, appState: appState),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final CircleMember member;
  final CircleModel circle;
  final AppState appState;
  final bool isCurrentUser;
  const _MemberTile({required this.member, required this.circle, required this.appState, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: member.paid ? AppColors.success.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
          child: Icon(LucideIcons.user, color: member.paid ? AppColors.success : Colors.grey, size: 16),
        ),
        title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(
          member.paid ? 'Payé le ${member.paidDate ?? ''}' : (member.phone.isNotEmpty ? member.phone : 'En attente'),
          style: TextStyle(color: member.paid ? AppColors.success : Colors.grey, fontSize: 11),
        ),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (!member.paid && isCurrentUser)
            GestureDetector(
              onTap: () => _contribute(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('Payer', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ),
          if (!isCurrentUser)
            GestureDetector(
              onTap: () => _confirmRemove(context),
              child: const Icon(LucideIcons.trash2, size: 14, color: AppColors.danger),
            ),
        ]),
      ),
    );
  }

  Future<void> _contribute(BuildContext context) async {
    final balance = appState.activeSlot?.balances['XOF'] ?? 0;
    final contribution = circle.contribution;

    // Confirmation dialog
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmer le versement'),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(gradient: AppColors.electricGradient, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            const Text('COTISATION TONTINE', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.2)),
            const SizedBox(height: 6),
            Text(formatAmountAbs(contribution, 'XOF'), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            Text('vers ${circle.name}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok != true) return;
    if (balance < contribution) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solde insuffisant'), backgroundColor: AppColors.danger));
      return;
    }
    final success = await appState.contributeToCircle(circle.id!, member.id!, contribution, 'XOF');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Cotisation versée !' : 'Erreur'), backgroundColor: success ? AppColors.success : AppColors.danger),
      );
    }
  }

  void _confirmRemove(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Retirer ce membre ?'),
        content: Text('${member.name} sera retiré du cercle.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              await appState.removeCircleMember(member.id!);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Retirer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _QrScanMemberSheet extends StatefulWidget {
  final CircleModel circle;
  final AppState appState;
  const _QrScanMemberSheet({required this.circle, required this.appState});
  @override
  State<_QrScanMemberSheet> createState() => _QrScanMemberSheetState();
}

class _QrScanMemberSheetState extends State<_QrScanMemberSheet> with SingleTickerProviderStateMixin {
  late final AnimationController _scan;
  bool _scanned = false;
  String _scannedName = '';
  String _scannedPhone = '';
  String _scannedWalletId = '';

  @override
  void initState() {
    super.initState();
    _scan = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }
  @override
  void dispose() { _scan.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      expand: false,
      builder: (_, ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.all(24),
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          const Text('Scanner le QR du nouveau membre', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Demandez au nouveau membre d\'afficher son QR depuis son profil PAYPOINT.', style: TextStyle(color: Colors.grey, height: 1.5)),
          const SizedBox(height: 24),
          if (!_scanned) ...[
            Center(child: Stack(alignment: Alignment.center, children: [
              Container(width: 220, height: 220, decoration: BoxDecoration(border: Border.all(color: AppColors.primary, width: 3), borderRadius: BorderRadius.circular(14))),
              AnimatedBuilder(animation: _scan, builder: (_, __) => Positioned(
                top: 10 + _scan.value * 190,
                child: Container(width: 214, height: 2, color: AppColors.primary.withValues(alpha: 0.7)),
              )),
              const Icon(LucideIcons.qrCode, size: 80, color: Colors.grey),
            ])),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Simuler le scan',
              onPressed: () => setState(() {
                _scannedName = 'Nouveau Membre';
                _scannedPhone = '+225 07 99 88 77';
                _scannedWalletId = 'PAPO-${widget.appState.blockchainAddr}-0';
                _scanned = true;
              }),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))),
              child: Column(children: [
                const Icon(LucideIcons.checkCircle, color: AppColors.success, size: 40),
                const SizedBox(height: 12),
                Text(_scannedName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(_scannedPhone, style: const TextStyle(color: Colors.grey)),
                Text(_scannedWalletId, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
              ]),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Ajouter au cercle',
              onPressed: () async {
                await widget.appState.addCircleMember(circleId: widget.circle.id!, name: _scannedName, phone: _scannedPhone, walletId: _scannedWalletId);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membre ajouté !'), backgroundColor: AppColors.success));
                }
              },
            ),
            const SizedBox(height: 10),
            CustomButton(text: 'Scanner un autre QR', isPrimary: false, onPressed: () => setState(() => _scanned = false)),
          ],
        ],
      ),
    );
  }
}
