import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';

class FaceVerificationScreen extends StatefulWidget {
  const FaceVerificationScreen({super.key});
  @override
  State<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen> {
  int _step = 0; // 0=start 1=blink 2=smile 3=done
  bool _processing = false;

  final _steps = [
    _StepData(icon: LucideIcons.eye, instruction: 'Clignez des yeux 3 fois'),
    _StepData(icon: LucideIcons.smile, instruction: 'Souriez naturellement'),
  ];

  void _nextStep() async {
    setState(() => _processing = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _processing = false;
      _step++;
    });

    if (_step == 3) {
      context.read<AppState>().verifyFace();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Vérification Faciale'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _step == 0
              ? _StartView(onStart: () => setState(() => _step = 1))
              : _step == 3
                  ? _SuccessView(
                      onNext: () => context.read<AppState>().setScreen('KYCStatus'))
                  : _ScanView(
                      data: _steps[_step - 1],
                      processing: _processing,
                      onDetect: _nextStep,
                    ),
        ),
      ),
    );
  }
}

class _StepData {
  final IconData icon;
  final String instruction;
  const _StepData({required this.icon, required this.instruction});
}

class _StartView extends StatelessWidget {
  final VoidCallback onStart;
  const _StartView({required this.onStart});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle),
          child: const Icon(LucideIcons.scanFace,
              size: 96, color: AppColors.primary),
        ),
        const SizedBox(height: 32),
        const Text('Vérification Vivacité',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text(
          'Nous allons valider votre identité via un selfie IA. Placez-vous dans un endroit bien éclairé.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, height: 1.5),
        ),
        const SizedBox(height: 48),
        CustomButton(
            text: 'Démarrer le Scan',
            icon: const Icon(LucideIcons.play, color: Colors.white, size: 18),
            onPressed: onStart),
      ],
    );
  }
}

class _ScanView extends StatelessWidget {
  final _StepData data;
  final bool processing;
  final VoidCallback onDetect;
  const _ScanView(
      {required this.data, required this.processing, required this.onDetect});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: processing ? AppColors.primary : Colors.grey, width: 3),
          ),
          child: ClipOval(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(data.icon,
                    size: 52,
                    color: processing
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.4)),
                const SizedBox(height: 8),
                const Text('Caméra active',
                    style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          data.instruction,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        processing
            ? const CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primary))
            : CustomButton(
                text: 'Simuler la détection',
                onPressed: onDetect),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  final VoidCallback onNext;
  const _SuccessView({required this.onNext});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
              color: AppColors.success, shape: BoxShape.circle),
          child: const Icon(Icons.check, color: Colors.white, size: 56),
        ),
        const SizedBox(height: 24),
        const Text('Scan Réussi !',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text(
          'Votre selfie a été enregistré et associé à vos documents.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, height: 1.5),
        ),
        const SizedBox(height: 48),
        CustomButton(
            text: 'Voir le statut de mon dossier',
            onPressed: onNext),
      ],
    );
  }
}
