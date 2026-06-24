import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
        lowerBound: 0.9,
        upperBound: 1.1)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _simulate() {
    setState(() => _scanning = true);
    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) context.read<AppState>().setScreen('Dashboard');
    });
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
                        ? AppColors.primary.withOpacity(0.15)
                        : AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.3), width: 2),
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
                  text: 'Simuler la lecture',
                  onPressed: _simulate,
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
