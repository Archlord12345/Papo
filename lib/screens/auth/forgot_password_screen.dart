import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneCtrl = TextEditingController();
  bool _sent = false;
  bool _loading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Mot de Passe Oublié',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Entrez votre numéro de téléphone pour recevoir un code de réinitialisation.',
              style: TextStyle(color: AppColors.textDarkSecondary),
            ),
            const SizedBox(height: 40),
            if (!_sent) ...[
              CustomInput(
                label: 'Numéro de téléphone',
                hint: '+225 07 00 00 00 00',
                prefixIcon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
                controller: _phoneCtrl,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Envoyer le code',
                isLoading: _loading,
                onPressed: () async {
                  if (_phoneCtrl.text.trim().isEmpty) return;
                  setState(() => _loading = true);
                  await Future.delayed(const Duration(seconds: 1));
                  setState(() {
                    _loading = false;
                    _sent = true;
                  });
                },
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(LucideIcons.mailCheck,
                        size: 48, color: AppColors.success),
                    const SizedBox(height: 16),
                    Text(
                      'Code envoyé au\n${_phoneCtrl.text}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Vérifiez vos SMS et saisissez le code reçu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Continuer',
                onPressed: () =>
                    context.read<AppState>().setScreen('ResetPassword'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
