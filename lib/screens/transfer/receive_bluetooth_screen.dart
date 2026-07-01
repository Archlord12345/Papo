import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../utils/formatters.dart';

class ReceiveBluetoothScreen extends StatefulWidget {
  const ReceiveBluetoothScreen({super.key});

  @override
  State<ReceiveBluetoothScreen> createState() => _ReceiveBluetoothScreenState();
}

class _ReceiveBluetoothScreenState extends State<ReceiveBluetoothScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  final bool _received = false;
  final double _amount = 0;
  final String _sender = '';
  String _asset = 'XOF';
  String _deviceName = 'Chargement...';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _getDeviceName();

    // Initialisation de l'actif
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      setState(() => _asset = appState.activeSlot?.asset ?? 'XOF');
    });
  }

  Future<void> _getDeviceName() async {
    try {
      final name = await FlutterBluePlus.adapterName;
      if (mounted) setState(() => _deviceName = name);
    } catch (e) {
      if (mounted) setState(() => _deviceName = "Bluetooth Actif");
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
        title: const Text('Recevoir par Bluetooth'),
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
        deviceName: _deviceName,
      ),
    );
  }
}

class _WaitingView extends StatelessWidget {
  final AnimationController pulseCtrl;
  final String name;
  final String walletId;
  final String deviceName;

  const _WaitingView({
    required this.pulseCtrl,
    required this.name,
    required this.walletId,
    required this.deviceName,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Prêt à recevoir',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Votre appareil est maintenant visible par les autres utilisateurs de Papo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.5)),
            const SizedBox(height: 48),
            AnimatedBuilder(
              animation: pulseCtrl,
              builder: (context, child) {
                return Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withValues(alpha: 0.1 + (pulseCtrl.value * 0.1)),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3 + (pulseCtrl.value * 0.4)),
                      width: 2 + (pulseCtrl.value * 2),
                    ),
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.bluetooth, size: 64, color: Colors.blue),
                  ),
                );
              },
            ),
            const SizedBox(height: 48),
            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Visibilité : $deviceName', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            Text(walletId, style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace')),
            const SizedBox(height: 64),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                ),
                SizedBox(width: 12),
                Text('En attente d\'un transfert...', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
              ],
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
              'Vous avez reçu ${formatAmountAbs(amount, asset)} de $sender via Bluetooth.',
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
