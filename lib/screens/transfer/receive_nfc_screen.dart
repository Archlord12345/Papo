import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../utils/formatters.dart';

// ─────────────────────────────────────────────────────────────────────────────
// États possibles : waiting | received | programming | error
// ─────────────────────────────────────────────────────────────────────────────

class ReceiveNfcScreen extends StatefulWidget {
  const ReceiveNfcScreen({super.key});
  @override
  State<ReceiveNfcScreen> createState() => _ReceiveNfcScreenState();
}

class _ReceiveNfcScreenState extends State<ReceiveNfcScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  // État mutable (corrigé — plus final)
  String _mode = 'waiting'; // waiting | received | error
  double _receivedAmount = 0;
  String _senderLabel = '';
  String _asset = 'XOF';
  String? _errorMsg;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      setState(() => _asset = appState.activeSlot?.asset ?? 'XOF');
      _startListening(appState);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _stopListening();
    super.dispose();
  }

  // ── Écoute NFC ──────────────────────────────────────────────────────────────

  Future<void> _startListening(AppState appState) async {
    if (_listening) return;
    final availability = await FlutterNfcKit.nfcAvailability;
    if (availability != NFCAvailability.available) {
      if (mounted) {
        setState(() {
          _mode = 'error';
          _errorMsg = 'NFC non disponible sur cet appareil ou désactivé.';
        });
      }
      return;
    }

    setState(() => _listening = true);

    try {
      // On attend un tag indéfiniment (timeout = 0)
      while (_listening && mounted) {
        try {
          final tag = await FlutterNfcKit.poll(
            timeout: const Duration(seconds: 30),
            iosAlertMessage: 'Approchez l\'appareil de l\'envoyeur',
            androidCheckNDEF: true,
          );

          if (tag.ndefAvailable == true) {
            final records = await FlutterNfcKit.readNDEFRecords();
            for (final record in records) {
              final raw = record.toString();

              // Format paiement standard : papo:pay/WALLET_ID
              if (raw.contains('papo:pay/') || raw.contains('papo:offline/')) {
                await _processIncoming(raw, appState);
                break;
              }
            }
          }

          await FlutterNfcKit.finish();
        } on Exception catch (_) {
          // Timeout normal — on relance
        }
      }
    } catch (e) {
      if (mounted && _mode == 'waiting') {
        setState(() {
          _mode = 'error';
          _errorMsg = e.toString();
        });
      }
    }
  }

  Future<void> _processIncoming(String data, AppState appState) async {
    double amount = 0;
    String sender = 'NFC';

    // Format offline : papo:offline/RECIPIENT/AMOUNT/ASSET
    if (data.contains('papo:offline/')) {
      final parts = data.split('papo:offline/').last.split('/');
      if (parts.length >= 2) {
        sender = parts[0];
        amount = double.tryParse(parts[1]) ?? 0;
        if (parts.length >= 3) _asset = parts[2];
      }
    }
    // Format paiement : papo:pay/WALLET_ID?amount=X&asset=Y
    else if (data.contains('papo:pay/')) {
      try {
        final withScheme = data.replaceFirst('papo:pay/', 'https://pay/');
        final uri = Uri.tryParse(withScheme);
        if (uri != null) {
          sender = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'Inconnu';
          amount = double.tryParse(uri.queryParameters['amount'] ?? '0') ?? 0;
          _asset = uri.queryParameters['asset'] ?? _asset;
        }
      } catch (_) {}
    }

    if (amount > 0 && mounted) {
      await appState.receiveMoney(amount, _asset, senderLabel: 'Reçu de $sender via NFC');
      setState(() {
        _receivedAmount = amount;
        _senderLabel = sender;
        _mode = 'received';
        _listening = false;
      });
    }
  }

  Future<void> _stopListening() async {
    _listening = false;
    try {
      await FlutterNfcKit.finish();
    } catch (_) {}
  }

  // ── Programme un tag NFC avec l'adresse du wallet ───────────────────────────

  Future<void> _writeToTag(String walletId) async {
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) throw 'NFC non disponible';

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Approchez un tag NFC vierge pour le programmer…')),
      );

      await FlutterNfcKit.poll();
      await FlutterNfcKit.writeNDEFRecords([
        ndef.TextRecord(text: 'papo:pay/$walletId'),
      ]);
      await FlutterNfcKit.finish();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tag NFC programmé ! Tout paiement sur ce tag ira sur votre wallet.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recevoir par NFC'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () async {
            await _stopListening();
            if (mounted) appState.popScreen();
          },
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: switch (_mode) {
          'received' => _SuccessView(
              key: const ValueKey('success'),
              amount: _receivedAmount,
              sender: _senderLabel,
              asset: _asset,
              onDone: () => appState.replaceScreen('Dashboard'),
            ),
          'error' => _ErrorView(
              key: const ValueKey('error'),
              message: _errorMsg ?? 'Erreur NFC',
              onRetry: () {
                setState(() { _mode = 'waiting'; _errorMsg = null; });
                _startListening(appState);
              },
            ),
          _ => _WaitingView(
              key: const ValueKey('waiting'),
              pulseCtrl: _pulseCtrl,
              name: appState.userName,
              walletId: appState.activeWalletId,
              onWrite: () => _writeToTag(appState.activeWalletId),
            ),
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Vue d'attente
// ─────────────────────────────────────────────────────────────────────────────
class _WaitingView extends StatelessWidget {
  final AnimationController pulseCtrl;
  final String name;
  final String walletId;
  final VoidCallback onWrite;
  const _WaitingView({
    super.key,
    required this.pulseCtrl,
    required this.name,
    required this.walletId,
    required this.onWrite,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Prêt pour contact NFC',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              'Maintenez votre téléphone\ncontre celui de l\'envoyeur.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 48),
            AnimatedBuilder(
              animation: pulseCtrl,
              builder: (_, __) => Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 160 + pulseCtrl.value * 40,
                    height: 160 + pulseCtrl.value * 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondary.withValues(
                          alpha: 0.08 * (1 - pulseCtrl.value)),
                    ),
                  ),
                  Container(
                    width: 140,
                    height: 140,
                    decoration: const BoxDecoration(
                        color: AppColors.secondary, shape: BoxShape.circle),
                    child: const Center(
                      child: Icon(LucideIcons.nfc, size: 64, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Text(name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              walletId,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 11, fontFamily: 'monospace'),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 32),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.secondary),
              ),
              const SizedBox(width: 12),
              const Text('En attente du contact…',
                  style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Programmer un tag NFC',
              isPrimary: false,
              icon: const Icon(LucideIcons.save, color: AppColors.primary, size: 18),
              onPressed: onWrite,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Vue succès
// ─────────────────────────────────────────────────────────────────────────────
class _SuccessView extends StatelessWidget {
  final double amount;
  final String sender;
  final String asset;
  final VoidCallback onDone;
  const _SuccessView({
    super.key,
    required this.amount,
    required this.sender,
    required this.asset,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                  color: AppColors.success, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 64),
            ),
            const SizedBox(height: 24),
            const Text('Fonds reçus !',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              '+${formatAmountAbs(amount, asset)} reçus de $sender via NFC',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, height: 1.5, fontSize: 15),
            ),
            const SizedBox(height: 48),
            CustomButton(text: 'Retour à l\'accueil', onPressed: onDone),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Vue erreur
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.alertTriangle,
                  size: 56, color: Colors.orange),
            ),
            const SizedBox(height: 24),
            const Text('NFC non disponible',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 8),
            const Text(
              'Assurez-vous que le NFC est activé dans les paramètres.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: 'Réessayer',
              icon: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 16),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
