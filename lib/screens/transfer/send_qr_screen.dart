import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';
import '../../utils/formatters.dart';

/// QR transfer: sender scans recipient's QR, then enters amount.
/// Recipient just shows their QR and waits.
class SendQrScreen extends StatefulWidget {
  const SendQrScreen({super.key});
  @override
  State<SendQrScreen> createState() => _SendQrScreenState();
}

class _SendQrScreenState extends State<SendQrScreen>
    with SingleTickerProviderStateMixin {
  // mode: 'choose' | 'scan' | 'amount' | 'confirm' | 'success' | 'fail'
  String _mode = 'choose';
  String _scannedRecipient = '';
  final _amountCtrl = TextEditingController();
  String _asset = 'XOF';
  bool _loading = false;

  late final AnimationController _scanAnim;

  @override
  void initState() {
    super.initState();
    _scanAnim = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _scanAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfert par QR Code'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (_mode == 'choose') {
              appState.popScreen();
            } else {
              setState(() => _mode = 'choose');
            }
          },
        ),
      ),
      body: _buildBody(appState),
    );
  }

  Widget _buildBody(AppState appState) {
    switch (_mode) {
      case 'choose': return _ChooseView(
        onSend: () => setState(() => _mode = 'scan'),
        onReceive: () => setState(() => _mode = 'receive'),
      );
      case 'scan': return _ScanView(
        animCtrl: _scanAnim,
        onSimulate: (addr) => setState(() {
          _scannedRecipient = addr;
          _mode = 'amount';
        }),
      );
      case 'receive': return _ReceiveQrView(walletId: appState.activeWalletId, name: appState.userName);
      case 'amount': return _AmountView(
        recipient: _scannedRecipient,
        amountCtrl: _amountCtrl,
        asset: _asset,
        balances: appState.balances,
        onAssetChange: (a) => setState(() => _asset = a),
        onConfirm: () => setState(() => _mode = 'confirm'),
      );
      case 'confirm': return _ConfirmView(
        recipient: _scannedRecipient,
        amount: double.tryParse(_amountCtrl.text) ?? 0,
        asset: _asset,
        loading: _loading,
        onConfirm: () => _execute(appState),
        onCancel: () => setState(() => _mode = 'amount'),
      );
      case 'success': return _ResultView(
        success: true,
        amount: double.tryParse(_amountCtrl.text) ?? 0,
        asset: _asset,
        recipient: _scannedRecipient,
        onDone: () => appState.replaceScreen('Dashboard'),
      );
      case 'fail': return _ResultView(
        success: false,
        amount: double.tryParse(_amountCtrl.text) ?? 0,
        asset: _asset,
        recipient: _scannedRecipient,
        onDone: () => setState(() => _mode = 'amount'),
      );
      default: return const SizedBox.shrink();
    }
  }

  Future<void> _execute(AppState appState) async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    final ok = await appState.sendMoney(
      recipient: _scannedRecipient,
      amount: double.tryParse(_amountCtrl.text) ?? 0,
      asset: _asset,
      method: 'qr',
    );
    if (mounted) setState(() { _loading = false; _mode = ok ? 'success' : 'fail'; });
  }
}

class _ChooseView extends StatelessWidget {
  final VoidCallback onSend;
  final VoidCallback onReceive;
  const _ChooseView({required this.onSend, required this.onReceive});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.qrCode, size: 80, color: AppColors.primary),
          const SizedBox(height: 24),
          const Text('Que souhaitez-vous faire ?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 48),
          _BigButton(icon: LucideIcons.scanLine, label: 'Scanner le QR d\'un contact\n(pour envoyer)', color: AppColors.primary, onTap: onSend),
          const SizedBox(height: 16),
          _BigButton(icon: LucideIcons.qrCode, label: 'Afficher mon QR\n(pour recevoir)', color: AppColors.secondary, onTap: onReceive),
        ],
      ),
    );
  }
}

class _ScanView extends StatelessWidget {
  final AnimationController animCtrl;
  final void Function(String) onSimulate;
  const _ScanView({required this.animCtrl, required this.onSimulate});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              // Scanner line animation
              AnimatedBuilder(
                animation: animCtrl,
                builder: (_, __) => Positioned(
                  top: 10 + animCtrl.value * 220,
                  child: Container(
                    width: 254,
                    height: 2,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const Icon(LucideIcons.qrCode, size: 80, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Pointez vers le QR du destinataire',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Le nom du destinataire s\'affichera automatiquement.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 40),
          CustomButton(
            text: 'Simuler la lecture (démo)',
            onPressed: () => onSimulate('+225 07 12 34 56 78'),
          ),
        ],
      ),
    );
  }
}

class _ReceiveQrView extends StatelessWidget {
  final String walletId;
  final String name;
  const _ReceiveQrView({required this.walletId, required this.name});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Mon QR de paiement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Wallet : $walletId',
              style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace')),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 32, offset: const Offset(0, 8))],
            ),
            child: QrImageView(
              data: 'papo:pay/$walletId',
              version: QrVersions.auto,
              size: 220,
            ),
          ),
          const SizedBox(height: 20),
          Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('En attente du paiement...',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
            const SizedBox(width: 8),
            const Text('Écoute active', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ],
      ),
    );
  }
}

class _AmountView extends StatelessWidget {
  final String recipient;
  final TextEditingController amountCtrl;
  final String asset;
  final Map<String, double> balances;
  final void Function(String) onAssetChange;
  final VoidCallback onConfirm;
  const _AmountView({required this.recipient, required this.amountCtrl, required this.asset, required this.balances, required this.onAssetChange, required this.onConfirm});
  @override
  Widget build(BuildContext context) {
    final balance = balances[asset] ?? 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(LucideIcons.circleCheck, color: AppColors.success),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Destinataire identifié', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(recipient, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ])),
            ]),
          ),
          const SizedBox(height: 28),
          const Text('Actif', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: balances.keys.map((a) {
                final sel = a == asset;
                return GestureDetector(
                  onTap: () => onAssetChange(a),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: sel ? AppColors.primaryGradient : null,
                      color: sel ? null : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sel ? AppColors.primary : AppColors.darkBorder),
                    ),
                    child: Text(a, style: TextStyle(fontWeight: FontWeight.bold, color: sel ? Colors.white : null)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Montant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text('Solde: ${formatAmountAbs(balance, asset)}', style: const TextStyle(color: AppColors.primary, fontSize: 12)),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '0',
              suffixText: asset,
              suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [1000, 5000, 10000, 25000].map((v) =>
            GestureDetector(
              onTap: () => amountCtrl.text = v.toString(),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                child: Text('+${v ~/ 1000}k', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
            )
          ).toList()),
          const SizedBox(height: 36),
          CustomButton(text: 'Continuer', onPressed: onConfirm),
        ],
      ),
    );
  }
}

class _ConfirmView extends StatelessWidget {
  final String recipient;
  final double amount;
  final String asset;
  final bool loading;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  const _ConfirmView({required this.recipient, required this.amount, required this.asset, required this.loading, required this.onConfirm, required this.onCancel});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(24)),
              child: Column(children: [
                const Icon(LucideIcons.qrCode, color: Colors.white, size: 32),
                const SizedBox(height: 12),
                const Text('CONFIRMER LE TRANSFERT QR', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Text(formatAmountAbs(amount, asset), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('vers $recipient', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Frais : 0 XOF', style: TextStyle(color: Colors.white, fontSize: 12))),
              ]),
            ),
            const SizedBox(height: 32),
            if (loading)
              const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary))
            else ...[
              CustomButton(text: 'Confirmer & Envoyer', onPressed: onConfirm),
              const SizedBox(height: 12),
              CustomButton(text: 'Annuler', isPrimary: false, onPressed: onCancel),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultView extends StatefulWidget {
  final bool success;
  final double amount;
  final String asset;
  final String recipient;
  final VoidCallback onDone;
  const _ResultView({required this.success, required this.amount, required this.asset, required this.recipient, required this.onDone});
  @override
  State<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<_ResultView> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = widget.success ? AppColors.success : AppColors.danger;
    final icon = widget.success ? Icons.check_rounded : Icons.close_rounded;
    final title = widget.success ? 'Transfert réussi !' : 'Transfert échoué';
    final msg = widget.success
        ? '${formatAmountAbs(widget.amount, widget.asset)} envoyés à ${widget.recipient}'
        : 'Solde insuffisant ou erreur réseau.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scale,
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 56),
              ),
            ),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5)),
            const SizedBox(height: 48),
            CustomButton(text: widget.success ? 'Retour à l\'accueil' : 'Réessayer', onPressed: widget.onDone),
          ],
        ),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _BigButton({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 24)),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color, height: 1.4))),
          Icon(LucideIcons.chevronRight, color: color),
        ]),
      ),
    );
  }
}
