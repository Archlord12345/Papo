import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final appState = context.read<AppState>();
    final error = await appState.login(_phoneCtrl.text.trim(), _pinCtrl.text);

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
    } else {
      appState.setScreen('Dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(LucideIcons.wallet,
                      color: AppColors.primary, size: 36),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Bon retour !',
                  style: TextStyle(
                      fontSize: 30, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connectez-vous à votre portefeuille PAYPOINT.',
                  style: TextStyle(
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textLightSecondary),
                ),
                const SizedBox(height: 40),
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
                  hint: '••••••',
                  prefixIcon: LucideIcons.lock,
                  isPassword: true,
                  keyboardType: TextInputType.number,
                  controller: _pinCtrl,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        context.read<AppState>().setScreen('ForgotPassword'),
                    child: const Text('Mot de passe oublié ?'),
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Se Connecter',
                  isLoading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Connexion Biométrique',
                  isPrimary: false,
                  icon: const Icon(LucideIcons.fingerprint,
                      color: AppColors.primary),
                  onPressed: () =>
                      context.read<AppState>().setScreen('BiometricLogin'),
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Nouveau sur PAPO ? ',
                      style: TextStyle(
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textLightSecondary),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.read<AppState>().setScreen('Register'),
                      child: const Text('Créer un compte',
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
