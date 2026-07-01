import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';
import '../../utils/formatters.dart';

/// NFC-specific transfer screen with detection animation
class SendNfcScreen extends StatefulWidget {
  const SendNfcScreen({super.key});
  @override
  State<SendNfcScreen> createState() => _SendNfcScreenState();
}

class _SendNfcScreenState extends State<SendNfcScreen>
    with TickerProviderStateMixin {
  // mode: 'form' | 'detecting' | 'detected' | 'confirm' | 'success' | 'fail'
  String _mode = 'form';
  String _detectedPeer = '';
  final _amountCtrl = TextEditingController();
  String _asset = 'XOF';
  bool _loading = false;

  late final AnimationController _pulseCtrl;
  late final AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();

    // Initialiser l'actif sur celui du wallet actuel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      if (appState.activeSlot != null) {
        setState(() => _asset = appState.activeSlot!.asset);
      }
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  void _startDetection() async {
    // 1. Check NFC Availability
    final availability = await FlutterNfcKit.nfcAvailability;
    if (availability == NFCAvailability.not_supported) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NFC non supporté sur cet appareil')),
        );
      }
      return;
    }

    if (availability == NFCAvailability.disabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez activer le NFC dans les paramètres de votre téléphone'),
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    setState(() => _mode = 'detecting');

    try {
      // Scan for a tag or another device
      final tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 15),
        iosAlertMessage: "Approchez l'autre appareil",
        androidCheckNDEF: true,
      );

      String peerData = '';

      // Try to read NDEF records if available
      if (tag.ndefAvailable == true) {
        final records = await FlutterNfcKit.readNDEFRecords();
        for (var record in records) {
          // Check for Papo URI format or raw text
          final recordStr = record.toString();
          if (recordStr.contains('papo:pay/')) {
            peerData = recordStr.split('papo:pay/').last;
            // Handle query params if any
            if (peerData.contains('?')) {
               peerData = peerData.split('?').first;
            }
            break;
          } else if (recordStr.contains('papo:offline/')) {
             // It's an offline payment being shared
             _handleOfflineNfc(recordStr);
             return;
          }
        }
      }

      if (peerData.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appareil Papo non identifié (NDEF requis)')),
          );
          setState(() => _mode = 'form');
        }
        return;
      }

      if (mounted) {
        setState(() {
          _detectedPeer = peerData;
          _mode = 'detected';
        });
      }

      await FlutterNfcKit.finish();
    } catch (e) {
      if (mounted) {
        setState(() => _mode = 'form');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('NFC error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _handleOfflineNfc(String data) async {
     // Format: papo:offline/recipient/amount/asset
     final parts = data.split('/');
     if (parts.length >= 4) {
        final recipient = parts[1];
        final amount = double.tryParse(parts[2]) ?? 0;
        final asset = parts[3];

        if (mounted) {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Transaction Offline Détectée'),
              content: Text('Voulez-vous accepter le transfert de ${formatAmountAbs(amount, asset)} vers $recipient ?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Refuser')),
                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Accepter')),
              ],
            ),
          );

          if (ok == true && mounted) {
             final appState = context.read<AppState>();
             await appState.receiveMoney(amount, asset, senderLabel: 'Reçu via Offline NFC');
             setState(() {
                _detectedPeer = recipient;
                _mode = 'success';
             });
          } else {
             if (mounted) setState(() => _mode = 'form');
          }
        }
     }
  }

  Future<void> _execute(AppState appState) async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    final ok = await appState.sendMoney(
      recipient: _detectedPeer,
      amount: double.tryParse(_amountCtrl.text) ?? 0,
      asset: _asset,
      method: 'nfc',
    );
    if (mounted) setState(() { _loading = false; _mode = ok ? 'success' : 'fail'; });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement NFC'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (_mode == 'form') {
              appState.popScreen();
            } else {
              setState(() => _mode = 'form');
            }
          },
        ),
      ),
      body: _buildBody(appState),
    );
  }

  Widget _buildBody(AppState appState) {
    switch (_mode) {
      case 'form': return _FormView(
        amountCtrl: _amountCtrl,
        asset: _asset,
        balances: appState.balances,
        onAssetChange: (a) => setState(() => _asset = a),
        onDetect: _startDetection,
      );
      case 'detecting': return _DetectingView(
        pulse: _pulseCtrl,
        wave: _waveCtrl,
        label: 'Approchez l\'autre téléphone\n(NFC activé)',
        onStop: () async {
          await FlutterNfcKit.finish();
          if (mounted) setState(() => _mode = 'form');
        },
      );
      case 'detected': return _DetectedView(
        peer: _detectedPeer,
        amount: double.tryParse(_amountCtrl.text) ?? 0,
        asset: _asset,
        onConfirm: () => setState(() => _mode = 'confirm'),
        onCancel: () => setState(() => _mode = 'form'),
      );
      case 'confirm': return _ConfirmView(
        recipient: _detectedPeer,
        amount: double.tryParse(_amountCtrl.text) ?? 0,
        asset: _asset,
        method: 'NFC',
        loading: _loading,
        onConfirm: () => _execute(appState),
        onCancel: () => setState(() => _mode = 'detected'),
      );
      case 'success': return _ResultView(success: true, amount: double.tryParse(_amountCtrl.text) ?? 0, asset: _asset, recipient: _detectedPeer, onDone: () => appState.replaceScreen('Dashboard'));
      case 'fail': return _ResultView(success: false, amount: double.tryParse(_amountCtrl.text) ?? 0, asset: _asset, recipient: _detectedPeer, onDone: () => setState(() => _mode = 'form'));
      default: return const SizedBox.shrink();
    }
  }
}

class _FormView extends StatelessWidget {
  final TextEditingController amountCtrl;
  final String asset;
  final Map<String, double> balances;
  final void Function(String) onAssetChange;
  final VoidCallback onDetect;
  const _FormView({required this.amountCtrl, required this.asset, required this.balances, required this.onAssetChange, required this.onDetect});

  @override
  Widget build(BuildContext context) {
    final balance = balances[asset] ?? 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NFC info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
            ),
            child: const Row(children: [
              Icon(LucideIcons.nfc, color: AppColors.secondary, size: 28),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Transfert NFC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Activez le NFC sur les deux appareils puis approchez-les.', style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4)),
              ])),
            ]),
          ),
          const SizedBox(height: 28),

          const Text('Actif', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: balances.keys.map((a) {
              final sel = a == asset;
              return GestureDetector(
                onTap: () => onAssetChange(a),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: sel ? AppColors.electricGradient : null,
                    color: sel ? null : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? AppColors.secondary : AppColors.darkBorder),
                  ),
                  child: Text(a, style: TextStyle(fontWeight: FontWeight.bold, color: sel ? Colors.white : null)),
                ),
              );
            }).toList()),
          ),
          const SizedBox(height: 24),

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Montant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text('Solde: ${formatAmountAbs(balance, asset)}', style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '0',
              suffixText: asset,
              suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 18),
            ),
          ),
          const SizedBox(height: 36),
          CustomButton(
            text: 'Détecter via NFC',
            gradient: AppColors.electricGradient,
            icon: const Icon(LucideIcons.nfc, color: Colors.white, size: 20),
            onPressed: onDetect,
          ),
        ],
      ),
    );
  }
}

class _DetectingView extends StatelessWidget {
  final AnimationController pulse;
  final AnimationController wave;
  final String label;
  final VoidCallback onStop;
  const _DetectingView({required this.pulse, required this.wave, required this.label, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: pulse,
              builder: (_, _) => Stack(
                alignment: Alignment.center,
                children: [
                  // Outer wave
                  AnimatedBuilder(
                    animation: wave,
                    builder: (_, _) => Container(
                      width: 180 + wave.value * 40,
                      height: 180 + wave.value * 40,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: (1 - wave.value) * 0.06),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Container(
                    width: 150 + pulse.value * 10,
                    height: 150 + pulse.value * 10,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.nfc, color: Colors.white, size: 48),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.5)),
            const SizedBox(height: 16),
            const SizedBox(width: 24, height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary)),
            const SizedBox(height: 48),
            CustomButton(
              text: 'Annuler la détection',
              isPrimary: false,
              onPressed: onStop,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetectedView extends StatelessWidget {
  final String peer;
  final double amount;
  final String asset;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  const _DetectedView({required this.peer, required this.amount, required this.asset, required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))),
            child: Column(children: [
              const Icon(LucideIcons.smartphoneNfc, color: AppColors.success, size: 48),
              const SizedBox(height: 12),
              const Text('Appareil détecté !', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(peer, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 32),
          Text('Envoyer ${formatAmountAbs(amount, asset)} à $peer ?', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.5)),
          const SizedBox(height: 32),
          CustomButton(text: 'Confirmer', onPressed: onConfirm),
          const SizedBox(height: 12),
          CustomButton(text: 'Annuler', isPrimary: false, onPressed: onCancel),
        ],
      ),
    );
  }
}

class _ConfirmView extends StatelessWidget {
  final String recipient;
  final double amount;
  final String asset;
  final String method;
  final bool loading;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  const _ConfirmView({required this.recipient, required this.amount, required this.asset, required this.method, required this.loading, required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: AppColors.electricGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(children: [
                Text(method.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                Text(formatAmountAbs(amount, asset), style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('→ $recipient', style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ]),
            ),
            const SizedBox(height: 32),
            if (loading)
              const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.secondary))
            else ...[
              CustomButton(text: 'Valider le transfert $method', gradient: AppColors.electricGradient, onPressed: onConfirm),
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
  late final AnimationController _c;
  late final Animation<double> _s;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _s = CurvedAnimation(parent: _c, curve: Curves.elasticOut);
    _c.forward();
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = widget.success ? AppColors.success : AppColors.danger;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _s,
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(widget.success ? Icons.check_rounded : Icons.close_rounded, color: Colors.white, size: 56),
              ),
            ),
            const SizedBox(height: 24),
            Text(widget.success ? 'Transfert NFC réussi !' : 'Transfert échoué', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.success
              ? '${formatAmountAbs(widget.amount, widget.asset)} envoyés à ${widget.recipient}'
              : 'Solde insuffisant ou NFC non disponible.',
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, height: 1.5)),
            const SizedBox(height: 48),
            CustomButton(text: widget.success ? 'Retour à l\'accueil' : 'Réessayer', onPressed: widget.onDone),
          ],
        ),
      ),
    );
  }
}
