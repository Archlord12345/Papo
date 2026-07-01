import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:local_auth/local_auth.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';

class BiometricLoginScreen extends StatefulWidget {
  const BiometricLoginScreen({super.key});
  @override
  State<BiometricLoginScreen> createState() => _BiometricLoginScreenState();
}

class _BiometricLoginScreenState extends State<BiometricLoginScreen>
    with SingleTickerProviderStateMixin {
  bool _scanning = false;
  late final AnimationController _pulse;
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
        lowerBound: 0.9,
        upperBound: 1.1)
      ..repeat(reverse: true);

    // Auto-start auth
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biométrie non disponible sur cet appareil')),
          );
        }
        return;
      }

      setState(() => _scanning = true);

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Veuillez vous authentifier pour accéder à Papo',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (didAuthenticate && mounted) {
        context.read<AppState>().unlockWithBiometrics();
      } else {
        if (mounted) setState(() => _scanning = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _scanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'authentification: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scanning ? _pulse : const AlwaysStoppedAnimation(1.0),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: _scanning
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                  ),
                  child: Icon(
                    LucideIcons.fingerprint,
                    size: 96,
                    color: _scanning ? AppColors.primary : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _scanning ? 'Lecture en cours...' : 'Authentification Biométrique',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Posez votre empreinte ou scannez votre visage pour accéder à votre portefeuille.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textDarkSecondary),
              ),
              const SizedBox(height: 56),
              if (!_scanning) ...[
                CustomButton(
                  text: 'S\'authentifier',
                  onPressed: _authenticate,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Utiliser mon Code PIN',
                  isPrimary: false,
                  onPressed: () =>
                      context.read<AppState>().setScreen('Login'),
                ),
              ] else
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
