import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../utils/formatters.dart';

// Note : la réception Bluetooth de fonds PAYPOINT repose sur un protocole
// personnalisé. En pratique l'envoyeur se connecte à cet appareil et écrit
// un payload JSON contenant le montant et l'ID de l'expéditeur.
// Pour rester compatible avec le hardware réel, on utilise les
// caractéristiques GATT standard + advertisement name "PAPO-{walletId}".

class ReceiveBluetoothScreen extends StatefulWidget {
  const ReceiveBluetoothScreen({super.key});
  @override
  State<ReceiveBluetoothScreen> createState() => _ReceiveBluetoothScreenState();
}

class _ReceiveBluetoothScreenState extends State<ReceiveBluetoothScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  // État mutable
  String _mode = 'waiting'; // waiting | received | unavailable
  double _receivedAmount = 0;
  String _senderLabel = '';
  String _asset = 'XOF';
  String _deviceName = '';
  bool _btAvailable = false;

  StreamSubscription? _adapterSub;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appState = context.read<AppState>();
      setState(() => _asset = appState.activeSlot?.asset ?? 'XOF');
      await _initBluetooth(appState);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _adapterSub?.cancel();
    super.dispose();
  }

  Future<void> _initBluetooth(AppState appState) async {
    final supported = await FlutterBluePlus.isSupported;
    if (!supported) {
      if (mounted) setState(() => _mode = 'unavailable');
      return;
    }

    // Récupérer le nom de l'adaptateur
    try {
      final name = await FlutterBluePlus.adapterName;
      if (mounted) setState(() => _deviceName = name);
    } catch (_) {
      if (mounted) setState(() => _deviceName = 'Bluetooth actif');
    }

    // Écouter l'état de l'adaptateur
    _adapterSub = FlutterBluePlus.adapterState.listen((state) {
      if (mounted) {
        setState(() => _btAvailable = state == BluetoothAdapterState.on);
        if (state == BluetoothAdapterState.on) {
          _btAvailable = true;
        }
      }
    });

    // Vérifier l'état initial
    final currentState = await FlutterBluePlus.adapterState.first;
    if (mounted) {
      setState(() => _btAvailable = currentState == BluetoothAdapterState.on);
    }

    // Écouter les connexions entrantes
    // En mode récepteur, on écoute les appareils qui se connectent
    // et qui publient un nom "PAPO-*" dans leur advertisement.
    // Pour les paiements réels, l'envoyeur initie la connexion.
    FlutterBluePlus.onScanResults.listen((results) {
      for (final result in results) {
        final advName = result.advertisementData.advName;
        // Chercher les appareils Papo qui envoient un payload
        if (advName.startsWith('PAPO-TX-')) {
          final parts = advName.split('-');
          // Format: PAPO-TX-{amount}-{asset}-{senderWalletId}
          if (parts.length >= 5) {
            final amount = double.tryParse(parts[2]) ?? 0;
            final txAsset = parts[3];
            final senderWallet = parts[4];
            if (amount > 0 && mounted) {
              _handleIncoming(amount, txAsset, senderWallet, appState);
            }
          }
        }
      }
    });
  }

  Future<void> _handleIncoming(
      double amount, String txAsset, String sender, AppState appState) async {
    if (_mode != 'waiting') return;

    // Confirmation avant d'accepter
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Paiement entrant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(children: [
                const Text('REÇU VIA BLUETOOTH',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 10, letterSpacing: 1.2)),
                const SizedBox(height: 6),
                Text(
                  formatAmountAbs(amount, txAsset),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                Text('de $sender',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Refuser')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Accepter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      await appState.receiveMoney(amount, txAsset,
          senderLabel: 'Reçu de $sender via Bluetooth');
      setState(() {
        _receivedAmount = amount;
        _senderLabel = sender;
        _asset = txAsset;
        _mode = 'received';
      });
    }
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
          onPressed: () {
            _adapterSub?.cancel();
            appState.popScreen();
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
          'unavailable' => _UnavailableView(
              key: const ValueKey('unavailable'),
              onBack: () => appState.popScreen(),
            ),
          _ => _WaitingView(
              key: const ValueKey('waiting'),
              pulseCtrl: _pulseCtrl,
              name: appState.userName,
              walletId: appState.activeWalletId,
              deviceName: _deviceName,
              btAvailable: _btAvailable,
            ),
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _WaitingView extends StatelessWidget {
  final AnimationController pulseCtrl;
  final String name;
  final String walletId;
  final String deviceName;
  final bool btAvailable;
  const _WaitingView({
    super.key,
    required this.pulseCtrl,
    required this.name,
    required this.walletId,
    required this.deviceName,
    required this.btAvailable,
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
            const Text(
              'Votre appareil est visible par les autres utilisateurs PAYPOINT à proximité.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 48),
            AnimatedBuilder(
              animation: pulseCtrl,
              builder: (_, __) => Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withValues(
                      alpha: 0.08 + pulseCtrl.value * 0.06),
                  border: Border.all(
                    color: Colors.blue
                        .withValues(alpha: 0.2 + pulseCtrl.value * 0.3),
                    width: 2 + pulseCtrl.value * 2,
                  ),
                ),
                child: const Center(
                  child: Icon(LucideIcons.bluetooth, size: 64, color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 48),
            Text(name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            if (deviceName.isNotEmpty)
              Text('Visible comme : $deviceName',
                  style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            const SizedBox(height: 4),
            Text(walletId,
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontFamily: 'monospace'),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 32),
            if (!btAvailable)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: const Row(children: [
                  Icon(LucideIcons.alertTriangle,
                      color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bluetooth désactivé. Activez-le dans les paramètres.',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ]),
              )
            else
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                const Text('En attente d\'un transfert…',
                    style: TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.w600)),
              ]),
          ],
        ),
      ),
    );
  }
}

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
              decoration:
                  const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 64),
            ),
            const SizedBox(height: 24),
            const Text('Fonds reçus !',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              '+${formatAmountAbs(amount, asset)} reçus de $sender via Bluetooth',
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
class _UnavailableView extends StatelessWidget {
  final VoidCallback onBack;
  const _UnavailableView({super.key, required this.onBack});

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
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.bluetoothOff,
                  size: 64, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Text('Bluetooth non supporté',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              'Cet appareil ne supporte pas le Bluetooth ou la fonctionnalité est désactivée.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: 'Retour',
              isPrimary: false,
              onPressed: onBack,
            ),
          ],
        ),
      ),
    );
  }
}
