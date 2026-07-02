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
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Les mots de passe ne correspondent pas'),
            backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _loading = true);
    final appState = context.read<AppState>();
    // TODO: Implement real register logic
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;
    setState(() => _loading = false);

    appState.setScreen('OTP');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => context.read<AppState>().setScreen('Onboarding'),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      LucideIcons.arrowLeft,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Créer un compte',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complétez ces informations pour commencer',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textDarkSecondary,
                  ),
                ),
                const SizedBox(height: 40),
                CustomInput(
                  label: 'Nom complet',
                  hint: 'Jean Dupont',
                  prefixIcon: LucideIcons.user,
                  controller: _nameCtrl,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 20),
                CustomInput(
                  label: 'Adresse e-mail',
                  hint: 'vous@exemple.com',
                  prefixIcon: LucideIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailCtrl,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 20),
                CustomInput(
                  label: 'Numéro de téléphone',
                  hint: '+33 6 12 34 56 78',
                  prefixIcon: LucideIcons.phone,
                  keyboardType: TextInputType.phone,
                  controller: _phoneCtrl,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 20),
                CustomInput(
                  label: 'Mot de passe',
                  hint: 'Minimum 8 caractères',
                  prefixIcon: LucideIcons.lock,
                  isPassword: true,
                  keyboardType: TextInputType.visiblePassword,
                  controller: _passwordCtrl,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ obligatoire';
                    if (v.length < 8) return 'Minimum 8 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomInput(
                  label: 'Confirmer le mot de passe',
                  hint: 'Répétez votre mot de passe',
                  prefixIcon: LucideIcons.lock,
                  isPassword: true,
                  keyboardType: TextInputType.visiblePassword,
                  controller: _confirmCtrl,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 32),
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
                        color: AppColors.textDarkSecondary,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.read<AppState>().setScreen('Login'),
                      child: Text(
                        'Se connecter',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
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