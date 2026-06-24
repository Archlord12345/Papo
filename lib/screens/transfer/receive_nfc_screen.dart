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

class ReceiveNfcScreen extends StatefulWidget {
  const ReceiveNfcScreen({super.key});

  @override
  State<ReceiveNfcScreen> createState() => _ReceiveNfcScreenState();
}

class _ReceiveNfcScreenState extends State<ReceiveNfcScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  bool _received = false;
  double _amount = 0;
  String _sender = '';
  String _asset = 'XOF';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Initialisation de l'actif
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      setState(() => _asset = appState.activeSlot?.asset ?? 'XOF');
    });
  }

  Future<void> _writeToTag(String walletId) async {
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) {
        throw 'NFC non disponible';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Approchez un tag NFC pour le programmer')),
      );

      await FlutterNfcKit.poll();
      await FlutterNfcKit.writeNDEFRecords([
        ndef.TextRecord(text: "papo:pay/$walletId")
      ]);
      await FlutterNfcKit.finish();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tag Papo programmé avec succès !'), backgroundColor: AppColors.success),
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

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

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
          onPressed: () => appState.popScreen(),
        ),
      ),
      body: _received ? _SuccessView(
        amount: _amount,
        sender: _sender,
        asset: _asset,
        onDone: () => appState.replaceScreen('Dashboard'),
      ) : _WaitingView(
        pulseCtrl: _pulseCtrl,
        name: appState.userName,
        walletId: appState.activeWalletId,
        onWrite: () => _writeToTag(appState.activeWalletId),
      ),
    );
  }
}

class _WaitingView extends StatelessWidget {
  final AnimationController pulseCtrl;
  final String name;
  final String walletId;
  final VoidCallback onWrite;

  const _WaitingView({
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
            const SizedBox(height: 12),
            const Text('Maintenez votre téléphone contre celui de l\'envoyeur.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.5)),
            const SizedBox(height: 64),
            AnimatedBuilder(
              animation: pulseCtrl,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 140 + (pulseCtrl.value * 40),
                      height: 140 + (pulseCtrl.value * 40),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondary.withValues(alpha: 0.1 * (1 - pulseCtrl.value)),
                      ),
                    ),
                    Container(
                      width: 140,
                      height: 140,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondary,
                      ),
                      child: const Center(
                        child: Icon(LucideIcons.nfc, size: 64, color: Colors.white),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 64),
            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(walletId, style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'monospace')),
            const SizedBox(height: 80),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary),
                ),
                const SizedBox(width: 12),
                const Text('En attente du contact...', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Programmer un tag NFC',
              icon: const Icon(LucideIcons.save, color: Colors.white, size: 18),
              onPressed: onWrite,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final double amount;
  final String sender;
  final String asset;
  final VoidCallback onDone;

  const _SuccessView({
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
              decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 64),
            ),
            const SizedBox(height: 32),
            const Text('Fonds reçus !', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'Vous avez reçu ${formatAmountAbs(amount, asset)} de $sender via NFC.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, height: 1.5, fontSize: 16),
            ),
            const SizedBox(height: 48),
            CustomButton(text: 'Terminer', onPressed: onDone),
          ],
        ),
      ),
    );
  }
}
