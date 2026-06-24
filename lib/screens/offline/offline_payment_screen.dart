import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';
import '../../utils/formatters.dart';

class OfflinePaymentScreen extends StatefulWidget {
  const OfflinePaymentScreen({super.key});
  @override
  State<OfflinePaymentScreen> createState() => _OfflinePaymentScreenState();
}

class _OfflinePaymentScreenState extends State<OfflinePaymentScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _recipientCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _broadcasting = false;
  bool _loading = false;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _recipientCtrl.dispose();
    _amountCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;
    final appState = context.read<AppState>();
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    final balance = appState.balances['XOF'] ?? 0;

    if (amount > balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Solde insuffisant'), backgroundColor: AppColors.danger),
      );
      return;
    }
    setState(() => _broadcasting = true);
  }

  Future<void> _finalize() async {
    final appState = context.read<AppState>();
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    final recipient = _recipientCtrl.text.trim();
    setState(() => _loading = true);

    await appState.sendMoney(
      recipient: recipient,
      amount: amount,
      asset: 'XOF',
      isOffline: true,
    );

    if (mounted) {
      setState(() {
        _loading = false;
        _broadcasting = false;
        _amountCtrl.clear();
        _recipientCtrl.clear();
      });
      appState.setScreen('Sync');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final balance = appState.balances['XOF'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement Hors Ligne'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (appState.offlineQueue.isNotEmpty)
            TextButton.icon(
              onPressed: () => appState.setScreen('Sync'),
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text('${appState.offlineQueue.length} en attente'),
            )
        ],
      ),
      body: _broadcasting ? _BroadcastView(
        onSuccess: _finalize,
        onCancel: () => setState(() => _broadcasting = false),
        loading: _loading,
        pulseCtrl: _pulseCtrl,
      ) : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.wifiOff,
                        color: AppColors.warning, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Mode Hors Ligne',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.warning)),
                          Text(
                            'Transaction signée localement puis diffusée par NFC/Bluetooth.',
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textDarkSecondary
                                    : AppColors.textLightSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Solde disponible
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Solde XOF disponible',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                    Text(
                      formatAmountAbs(balance, 'XOF'),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              CustomInput(
                label: 'Téléphone / Adresse du destinataire',
                hint: '+225 07 00 00 00 00',
                prefixIcon: LucideIcons.user,
                controller: _recipientCtrl,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 20),
              CustomInput(
                label: 'Montant (XOF)',
                hint: '0',
                prefixIcon: LucideIcons.circleDollarSign,
                keyboardType: TextInputType.number,
                controller: _amountCtrl,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Champ obligatoire';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Montant invalide';
                  if (n > balance) return 'Solde insuffisant';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Signer & Diffuser localement',
                gradient: AppColors.accentGradient,
                icon: const Icon(LucideIcons.radio, color: Colors.white, size: 18),
                onPressed: _confirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BroadcastView extends StatelessWidget {
  final VoidCallback onSuccess;
  final VoidCallback onCancel;
  final bool loading;
  final AnimationController pulseCtrl;
  const _BroadcastView({
    required this.onSuccess,
    required this.onCancel,
    required this.loading,
    required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ripple animation
            AnimatedBuilder(
              animation: pulseCtrl,
              builder: (ctx, _) => Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 160 * (1 + pulseCtrl.value * 0.1),
                    height: 160 * (1 + pulseCtrl.value * 0.1),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.07),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                        color: AppColors.warning, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.radio,
                        color: Colors.white, size: 32),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Diffusion en cours...',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Approchez les deux téléphones (NFC/Bluetooth)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 48),
            if (loading)
              const CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primary))
            else ...[
              CustomButton(
                  text: 'Simuler la transmission réussie',
                  onPressed: onSuccess),
              const SizedBox(height: 12),
              CustomButton(
                  text: 'Annuler',
                  isPrimary: false,
                  onPressed: onCancel),
            ],
          ],
        ),
      ),
    );
  }
}
