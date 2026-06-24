import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../utils/formatters.dart';

/// Bluetooth-specific transfer screen with device scan animation
class SendBluetoothScreen extends StatefulWidget {
  const SendBluetoothScreen({super.key});
  @override
  State<SendBluetoothScreen> createState() => _SendBluetoothScreenState();
}

class _SendBluetoothScreenState extends State<SendBluetoothScreen>
    with TickerProviderStateMixin {
  // mode: 'form' | 'scanning' | 'select' | 'confirm' | 'success' | 'fail'
  String _mode = 'form';
  String _selectedPeer = '';
  final _amountCtrl = TextEditingController();
  String _asset = 'XOF';
  bool _loading = false;

  late final AnimationController _radarCtrl;

  // Simulated nearby devices
  final _nearbyDevices = [
    {'name': 'Awa Diop', 'device': 'Samsung Galaxy A54', 'signal': 'Fort'},
    {'name': 'Kofi Mensah', 'device': 'Tecno Camon 20', 'signal': 'Moyen'},
    {'name': 'Pierre Aka', 'device': 'iPhone 14', 'signal': 'Faible'},
  ];

  @override
  void initState() {
    super.initState();
    _radarCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _radarCtrl.dispose();
    super.dispose();
  }

  void _startScan() {
    setState(() => _mode = 'scanning');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _mode = 'select');
    });
  }

  Future<void> _execute(AppState appState) async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    final ok = await appState.sendMoney(
      recipient: _selectedPeer,
      amount: double.tryParse(_amountCtrl.text) ?? 0,
      asset: _asset,
      method: 'bluetooth',
    );
    if (mounted) setState(() { _loading = false; _mode = ok ? 'success' : 'fail'; });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement Bluetooth'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (_mode == 'form') appState.popScreen();
            else setState(() => _mode = 'form');
          },
        ),
      ),
      body: _buildBody(appState),
    );
  }

  Widget _buildBody(AppState appState) {
    switch (_mode) {
      case 'form': return _FormView(
        amountCtrl: _amountCtrl, asset: _asset,
        balances: appState.balances,
        onAssetChange: (a) => setState(() => _asset = a),
        onScan: _startScan,
      );
      case 'scanning': return _RadarView(ctrl: _radarCtrl);
      case 'select': return _DeviceListView(
        devices: _nearbyDevices,
        onSelect: (d) => setState(() { _selectedPeer = '${d['name']} (${d['device']})'; _mode = 'confirm'; }),
      );
      case 'confirm': return _ConfirmView(
        recipient: _selectedPeer,
        amount: double.tryParse(_amountCtrl.text) ?? 0,
        asset: _asset,
        loading: _loading,
        onConfirm: () => _execute(appState),
        onCancel: () => setState(() => _mode = 'select'),
      );
      case 'success': return _ResultView(success: true, amount: double.tryParse(_amountCtrl.text) ?? 0, asset: _asset, recipient: _selectedPeer, onDone: () => appState.replaceScreen('Dashboard'));
      case 'fail': return _ResultView(success: false, amount: double.tryParse(_amountCtrl.text) ?? 0, asset: _asset, recipient: _selectedPeer, onDone: () => setState(() => _mode = 'form'));
      default: return const SizedBox.shrink();
    }
  }
}

class _FormView extends StatelessWidget {
  final TextEditingController amountCtrl;
  final String asset;
  final Map<String, double> balances;
  final void Function(String) onAssetChange;
  final VoidCallback onScan;
  const _FormView({required this.amountCtrl, required this.asset, required this.balances, required this.onAssetChange, required this.onScan});

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
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: const Row(children: [
              Icon(LucideIcons.bluetooth, color: Colors.blue, size: 28),
              SizedBox(width: 12),
              Expanded(child: Text(
                'Assurez-vous que le Bluetooth est activé sur les deux appareils. Seuls les appareils à proximité apparaîtront.',
                style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
              )),
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
                    color: sel ? Colors.blue : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? Colors.blue : AppColors.darkBorder),
                  ),
                  child: Text(a, style: TextStyle(fontWeight: FontWeight.bold, color: sel ? Colors.white : null)),
                ),
              );
            }).toList()),
          ),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Montant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text('Solde: ${formatAmountAbs(balance, asset)}', style: const TextStyle(color: Colors.blue, fontSize: 12)),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(hintText: '0'),
          ),
          const SizedBox(height: 36),
          CustomButton(
            text: 'Rechercher des appareils',
            gradient: const LinearGradient(colors: [Colors.blue, Colors.blueAccent]),
            icon: const Icon(LucideIcons.bluetooth, color: Colors.white, size: 20),
            onPressed: onScan,
          ),
        ],
      ),
    );
  }
}

class _RadarView extends StatelessWidget {
  final AnimationController ctrl;
  const _RadarView({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200, height: 200,
            child: AnimatedBuilder(
              animation: ctrl,
              builder: (_, __) => CustomPaint(
                painter: _RadarPainter(ctrl.value),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text('Recherche d\'appareils...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Détection des appareils Bluetooth à proximité', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double progress;
  _RadarPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5;

    // Static rings
    for (int i = 1; i <= 4; i++) {
      paint.color = Colors.blue.withValues(alpha: 0.15);
      canvas.drawCircle(center, maxRadius * i / 4, paint);
    }

    // Animated sweep
    paint
      ..color = Colors.blue.withValues(alpha: 0.6 * (1 - progress))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius * progress, paint);

    // Center dot
    paint
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, paint);
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.progress != progress;
}

class _DeviceListView extends StatelessWidget {
  final List<Map<String, String>> devices;
  final void Function(Map<String, String>) onSelect;
  const _DeviceListView({required this.devices, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('${devices.length} appareil(s) trouvé(s)',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: devices.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (ctx, i) {
              final d = devices[i];
              final signalColor = d['signal'] == 'Fort' ? AppColors.success : d['signal'] == 'Moyen' ? AppColors.warning : AppColors.danger;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.smartphone, color: Colors.white, size: 20),
                  ),
                  title: Text(d['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(d['device']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.signal, color: signalColor, size: 16),
                      Text(d['signal']!, style: TextStyle(fontSize: 10, color: signalColor)),
                    ],
                  ),
                  onTap: () => onSelect(d),
                ),
              );
            },
          ),
        ),
      ],
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
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.blue, Colors.blueAccent]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(children: [
                const Icon(LucideIcons.bluetooth, color: Colors.white, size: 32),
                const SizedBox(height: 12),
                const Text('CONFIRMER — BLUETOOTH', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Text(formatAmountAbs(amount, asset), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('→ $recipient', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 32),
            if (loading)
              const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.blue))
            else ...[
              CustomButton(
                text: 'Envoyer via Bluetooth',
                gradient: const LinearGradient(colors: [Colors.blue, Colors.blueAccent]),
                onPressed: onConfirm,
              ),
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
            Text(widget.success ? 'Transfert Bluetooth réussi !' : 'Transfert échoué', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.success
              ? '${formatAmountAbs(widget.amount, widget.asset)} → ${widget.recipient}'
              : 'Solde insuffisant ou appareil non trouvé.',
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, height: 1.5)),
            const SizedBox(height: 48),
            CustomButton(text: widget.success ? 'Retour à l\'accueil' : 'Réessayer', onPressed: widget.onDone),
          ],
        ),
      ),
    );
  }
}
