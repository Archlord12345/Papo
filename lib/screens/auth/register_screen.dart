import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pinCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Les codes PIN ne correspondent pas'),
            backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _loading = true);
    final appState = context.read<AppState>();
    final error = await appState.register(
        _nameCtrl.text, _phoneCtrl.text, _pinCtrl.text);

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
    } else {
      appState.setScreen('OTP');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Créer un Compte',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rejoignez PAYPOINT pour des paiements instantanés et sécurisés.',
                  style: TextStyle(
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textLightSecondary),
                ),
                const SizedBox(height: 32),
                CustomInput(
                  label: 'Nom complet',
                  hint: 'Mamadou Diallo',
                  prefixIcon: LucideIcons.user,
                  controller: _nameCtrl,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 20),
                CustomInput(
                  label: 'Numéro de téléphone',
                  hint: '+225 07 00 00 00 00',
                  prefixIcon: LucideIcons.phone,
                  keyboardType: TextInputType.phone,
                  controller: _phoneCtrl,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 20),
                CustomInput(
                  label: 'Code PIN',
                  hint: 'Minimum 4 chiffres',
                  prefixIcon: LucideIcons.lock,
                  isPassword: true,
                  keyboardType: TextInputType.number,
                  controller: _pinCtrl,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ obligatoire';
                    if (v.length < 4) return 'Minimum 4 chiffres';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomInput(
                  label: 'Confirmer le code PIN',
                  hint: 'Répétez votre code PIN',
                  prefixIcon: LucideIcons.lock,
                  isPassword: true,
                  keyboardType: TextInputType.number,
                  controller: _confirmCtrl,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 32),
                // PIN strength indicator
                _PinStrengthIndicator(pin: _pinCtrl.text),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'S\'inscrire',
                  isLoading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Déjà un compte ? ',
                      style: TextStyle(
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textLightSecondary),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.read<AppState>().setScreen('Login'),
                      child: const Text('Se connecter',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinStrengthIndicator extends StatelessWidget {
  final String pin;
  const _PinStrengthIndicator({required this.pin});

  @override
  Widget build(BuildContext context) {
    if (pin.isEmpty) return const SizedBox.shrink();
    Color color;
    String label;
    double value;
    if (pin.length < 4) {
      color = AppColors.danger;
      label = 'Trop court';
      value = 0.2;
    } else if (pin.length < 6) {
      color = AppColors.warning;
      label = 'Moyen';
      value = 0.6;
    } else {
      color = AppColors.success;
      label = 'Fort';
      value = 1.0;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Force du PIN', style: TextStyle(fontSize: 12)),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.grey.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}
