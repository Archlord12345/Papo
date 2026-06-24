import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _newPinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Nouveau Code PIN',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Définissez votre nouveau code PIN de sécurité.',
              style: TextStyle(color: AppColors.textDarkSecondary),
            ),
            const SizedBox(height: 40),
            CustomInput(
              label: 'Nouveau Code PIN',
              hint: 'Minimum 4 chiffres',
              prefixIcon: LucideIcons.lock,
              isPassword: true,
              keyboardType: TextInputType.number,
              controller: _newPinCtrl,
            ),
            const SizedBox(height: 20),
            CustomInput(
              label: 'Confirmer le Code PIN',
              hint: 'Répétez le nouveau code PIN',
              prefixIcon: LucideIcons.lock,
              isPassword: true,
              keyboardType: TextInputType.number,
              controller: _confirmCtrl,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Enregistrer',
              isLoading: _loading,
              onPressed: () async {
                if (_newPinCtrl.text != _confirmCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Les codes PIN ne correspondent pas'),
                        backgroundColor: AppColors.danger),
                  );
                  return;
                }
                if (_newPinCtrl.text.length < 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Minimum 4 chiffres'),
                        backgroundColor: AppColors.danger),
                  );
                  return;
                }
                setState(() => _loading = true);
                await Future.delayed(const Duration(milliseconds: 500));
                if (mounted) {
                  setState(() => _loading = false);
                  appState.addNotification(
                      'PIN modifié', 'Votre code PIN a été réinitialisé.', 'security');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Code PIN mis à jour avec succès'),
                        backgroundColor: AppColors.success),
                  );
                  appState.setScreen('Login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
