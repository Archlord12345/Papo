import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
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
  CameraController? _controller;
  bool _cameraInitialized = false;

  final _steps = [
    _StepData(icon: LucideIcons.eye, instruction: 'Clignez des yeux 3 fois'),
    _StepData(icon: LucideIcons.smile, instruction: 'Souriez naturellement'),
  ];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission caméra requise pour le KYC')),
        );
      }
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // Look for front camera
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(front, ResolutionPreset.medium, enableAudio: false);
      await _controller!.initialize();
      if (mounted) setState(() => _cameraInitialized = true);
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _nextStep() async {
    setState(() => _processing = true);

    // Simuler une capture réelle avec la caméra (ou capture réelle si initialisée)
    try {
      if (_cameraInitialized && _controller != null) {
        await _controller!.takePicture();
      }
    } catch (e) {
      debugPrint('Capture error: $e');
    }

    await Future.delayed(const Duration(milliseconds: 1500));
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
                      controller: _controller,
                      initialized: _cameraInitialized,
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
              color: AppColors.primary.withValues(alpha: 0.08),
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
  final CameraController? controller;
  final bool initialized;

  const _ScanView({
    required this.data,
    required this.processing,
    required this.onDetect,
    this.controller,
    required this.initialized,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: processing ? AppColors.primary : Colors.grey.withValues(alpha: 0.3), width: 4),
          ),
          child: ClipOval(
            child: initialized && controller != null
                ? AspectRatio(
                    aspectRatio: 1,
                    child: CameraPreview(controller!),
                  )
                : Container(
                    color: Colors.black12,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(data.icon,
                            size: 52,
                            color: processing
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.4)),
                        const SizedBox(height: 8),
                        const Text('Initialisation caméra...',
                            style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          data.instruction,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text('Maintenez votre visage dans le cercle',
            style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 48),
        processing
            ? const CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primary))
            : const Text('Détection en cours...', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
