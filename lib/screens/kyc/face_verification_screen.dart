import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Étapes de vivacité
// ─────────────────────────────────────────────────────────────────────────────
enum _LivenessStep { intro, blink, smile, capture, uploading, done, error }

class _StepMeta {
  final IconData icon;
  final String title;
  final String hint;
  const _StepMeta(this.icon, this.title, this.hint);
}

const _stepMetas = [
  _StepMeta(LucideIcons.eye, 'Clignez des yeux', 'Clignez lentement 2 à 3 fois'),
  _StepMeta(LucideIcons.smile, 'Souriez naturellement', 'Gardez le sourire quelques secondes'),
];

// ─────────────────────────────────────────────────────────────────────────────
class FaceVerificationScreen extends StatefulWidget {
  const FaceVerificationScreen({super.key});
  @override
  State<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen>
    with TickerProviderStateMixin {
  _LivenessStep _step = _LivenessStep.intro;
  int _livenessIndex = 0; // 0=blink 1=smile
  bool _busy = false;
  String? _errorMsg;
  XFile? _capturedPhoto;

  CameraController? _cam;
  bool _camReady = false;
  bool _camUnavailable = false;

  late final AnimationController _pulse;
  late final AnimationController _borderAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.96,
      upperBound: 1.04,
    )..repeat(reverse: true);
    _borderAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _cam?.dispose();
    _pulse.dispose();
    _borderAnim.dispose();
    super.dispose();
  }

  // ── Caméra ──────────────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() => _camUnavailable = true);
      return;
    }
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _camUnavailable = true);
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cam = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _cam!.initialize();
      if (mounted) setState(() => _camReady = true);
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) setState(() => _camUnavailable = true);
    }
  }

  // ── Flux de vivacité ────────────────────────────────────────────────────────

  Future<void> _startScan() async {
    setState(() => _step = _LivenessStep.blink);
    _livenessIndex = 0;
    _pulse.repeat(reverse: true);
    await _initCamera();
  }

  Future<void> _confirmStep() async {
    if (_busy) return;
    setState(() => _busy = true);
    _pulse.stop();

    // Simule la détection locale (dans un vrai projet : ML Kit ou google_mlkit_face_detection)
    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;

    if (_livenessIndex < 1) {
      // Passer à l'étape suivante
      _livenessIndex++;
      final nextStep = _livenessIndex == 0 ? _LivenessStep.blink : _LivenessStep.smile;
      setState(() {
        _step = nextStep;
        _busy = false;
      });
      _pulse.repeat(reverse: true);
    } else {
      // Toutes les étapes de vivacité passées → capturer le selfie
      setState(() {
        _step = _LivenessStep.capture;
        _busy = false;
      });
      await _captureSelfie();
    }
  }

  Future<void> _captureSelfie() async {
    setState(() => _busy = true);
    try {
      XFile? photo;
      if (_camReady && _cam != null) {
        photo = await _cam!.takePicture();
      }
      _capturedPhoto = photo;
      setState(() {
        _step = _LivenessStep.uploading;
        _busy = false;
      });
      await _uploadSelfie();
    } catch (e) {
      if (mounted) {
        setState(() {
          _step = _LivenessStep.error;
          _errorMsg = 'Capture impossible : $e';
          _busy = false;
        });
      }
    }
  }

  Future<void> _uploadSelfie() async {
    final appState = context.read<AppState>();
    try {
      if (_capturedPhoto != null) {
        // Upload le selfie en tant que document KYC face
        await appState.uploadKYCDocument(
          'SELFIE',
          _capturedPhoto!.path,
        );
      }
      await appState.verifyFace();
      if (mounted) setState(() => _step = _LivenessStep.done);
    } catch (e) {
      if (mounted) {
        setState(() {
          _step = _LivenessStep.error;
          _errorMsg = 'Échec de l\'envoi : $e';
        });
      }
    }
  }

  void _retry() {
    _cam?.dispose();
    _cam = null;
    _camReady = false;
    _camUnavailable = false;
    setState(() {
      _step = _LivenessStep.intro;
      _livenessIndex = 0;
      _busy = false;
      _errorMsg = null;
      _capturedPhoto = null;
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Vérification Faciale'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _step == _LivenessStep.intro || _step == _LivenessStep.done
            ? null
            : IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: _retry,
                tooltip: 'Annuler',
              ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case _LivenessStep.intro:
        return _IntroView(
          key: const ValueKey('intro'),
          onStart: _startScan,
        );

      case _LivenessStep.blink:
      case _LivenessStep.smile:
        final meta = _stepMetas[_livenessIndex];
        return _ScanView(
          key: ValueKey('scan_$_livenessIndex'),
          meta: meta,
          stepIndex: _livenessIndex,
          totalSteps: _stepMetas.length,
          controller: _camReady ? _cam : null,
          unavailable: _camUnavailable,
          busy: _busy,
          pulse: _pulse,
          borderAnim: _borderAnim,
          onConfirm: _busy ? null : _confirmStep,
        );

      case _LivenessStep.capture:
      case _LivenessStep.uploading:
        return _CapturingView(
          key: const ValueKey('capturing'),
          controller: _camReady ? _cam : null,
          isUploading: _step == _LivenessStep.uploading,
        );

      case _LivenessStep.done:
        return _SuccessView(
          key: const ValueKey('done'),
          photoPath: _capturedPhoto?.path,
          onNext: () => context.read<AppState>().setScreen('KYCStatus'),
        );

      case _LivenessStep.error:
        return _ErrorView(
          key: const ValueKey('error'),
          message: _errorMsg ?? 'Une erreur est survenue.',
          onRetry: _retry,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Intro
// ─────────────────────────────────────────────────────────────────────────────
class _IntroView extends StatelessWidget {
  final VoidCallback onStart;
  const _IntroView({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.scanFace, size: 96, color: AppColors.primary),
        ),
        const SizedBox(height: 32),
        const Text('Scan Facial de Vivacité',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text(
          'Nous allons confirmer que c\'est bien vous en temps réel.\n\nAssurez-vous d\'être dans un endroit bien éclairé.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, height: 1.6, fontSize: 14),
        ),
        const SizedBox(height: 24),
        _InfoTile(icon: LucideIcons.sun, text: 'Bonne luminosité, pas de contre-jour'),
        const SizedBox(height: 8),
        _InfoTile(icon: LucideIcons.glasses, text: 'Retirez lunettes ou chapeau si possible'),
        const SizedBox(height: 8),
        _InfoTile(icon: LucideIcons.shield, text: 'Vos données sont chiffrées et protégées'),
        const SizedBox(height: 48),
        CustomButton(
          text: 'Démarrer le Scan',
          icon: const Icon(LucideIcons.play, color: Colors.white, size: 18),
          onPressed: onStart,
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoTile({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.primary),
      const SizedBox(width: 10),
      Expanded(
        child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Scan (vivacité)
// ─────────────────────────────────────────────────────────────────────────────
class _ScanView extends StatelessWidget {
  final _StepMeta meta;
  final int stepIndex;
  final int totalSteps;
  final CameraController? controller;
  final bool unavailable;
  final bool busy;
  final AnimationController pulse;
  final AnimationController borderAnim;
  final VoidCallback? onConfirm;

  const _ScanView({
    super.key,
    required this.meta,
    required this.stepIndex,
    required this.totalSteps,
    required this.controller,
    required this.unavailable,
    required this.busy,
    required this.pulse,
    required this.borderAnim,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Indicateur d'étape
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSteps, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == stepIndex ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i <= stepIndex ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          )),
        ),
        const SizedBox(height: 24),

        // Cercle caméra / fallback
        ScaleTransition(
          scale: busy ? const AlwaysStoppedAnimation(1.0) : pulse,
          child: _FaceOval(
            controller: controller,
            unavailable: unavailable,
            busy: busy,
            icon: meta.icon,
            borderAnim: borderAnim,
          ),
        ),
        const SizedBox(height: 32),

        Text(
          meta.title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          meta.hint,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Étape ${stepIndex + 1} sur $totalSteps',
          style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 40),

        busy
            ? const _LoadingIndicator(label: 'Analyse en cours...')
            : unavailable
                ? _UnavailableHint(onConfirm: onConfirm ?? () {})
                : CustomButton(
                    text: stepIndex == 0 ? 'J\'ai cligné des yeux ✓' : 'Je souris ✓',
                    onPressed: onConfirm ?? () {},
                  ),
      ],
    );
  }
}

/// Ovale avec preview caméra ou icône fallback
class _FaceOval extends StatelessWidget {
  final CameraController? controller;
  final bool unavailable;
  final bool busy;
  final IconData icon;
  final AnimationController borderAnim;

  const _FaceOval({
    required this.controller,
    required this.unavailable,
    required this.busy,
    required this.icon,
    required this.borderAnim,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cercle animé (border tournant)
          AnimatedBuilder(
            animation: borderAnim,
            builder: (_, __) => CustomPaint(
              size: const Size(260, 320),
              painter: _OvalBorderPainter(
                progress: borderAnim.value,
                color: busy ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
          // Contenu caméra ou fallback
          ClipOval(
            child: SizedBox(
              width: 244,
              height: 304,
              child: controller != null
                  ? CameraPreview(controller!)
                  : Container(
                      color: Colors.black12,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 64,
                            color: unavailable
                                ? Colors.orange
                                : AppColors.primary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            unavailable
                                ? 'Caméra non disponible'
                                : 'Initialisation...',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          // Overlay "Placez votre visage ici"
          if (controller != null)
            Positioned(
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Centrez votre visage',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OvalBorderPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _OvalBorderPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // Arc tournant
    canvas.drawArc(rect, -1.5708 + progress * 6.2832, 4.7, false, paint);

    // Arc de fond (gris léger)
    paint
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 2;
    canvas.drawOval(rect, paint);
  }

  @override
  bool shouldRepaint(_OvalBorderPainter old) =>
      old.progress != progress || old.color != color;
}

class _LoadingIndicator extends StatelessWidget {
  final String label;
  const _LoadingIndicator({required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
      const SizedBox(height: 12),
      Text(label,
          style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13)),
    ]);
  }
}

/// Affiché quand la caméra est indisponible — l'utilisateur peut quand même valider manuellement
class _UnavailableHint extends StatelessWidget {
  final VoidCallback onConfirm;
  const _UnavailableHint({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: const Row(children: [
          Icon(LucideIcons.alertTriangle, color: Colors.orange, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Caméra non disponible sur cet appareil.\nValidation manuelle autorisée.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      CustomButton(
        text: 'Valider manuellement',
        onPressed: onConfirm,
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Capture en cours
// ─────────────────────────────────────────────────────────────────────────────
class _CapturingView extends StatelessWidget {
  final CameraController? controller;
  final bool isUploading;
  const _CapturingView({super.key, required this.controller, required this.isUploading});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 240,
          height: 300,
          child: ClipOval(
            child: controller != null
                ? CameraPreview(controller!)
                : Container(
                    color: Colors.black12,
                    child: const Icon(LucideIcons.camera,
                        size: 64, color: AppColors.primary),
                  ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          isUploading ? 'Envoi en cours...' : 'Prise du selfie...',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const _LoadingIndicator(label: 'Veuillez patienter'),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Succès
// ─────────────────────────────────────────────────────────────────────────────
class _SuccessView extends StatelessWidget {
  final String? photoPath;
  final VoidCallback onNext;
  const _SuccessView({super.key, required this.photoPath, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Aperçu du selfie si disponible
        if (photoPath != null && File(photoPath!).existsSync())
          ClipOval(
            child: Image.file(
              File(photoPath!),
              width: 160,
              height: 160,
              fit: BoxFit.cover,
            ),
          )
        else
          Container(
            width: 160,
            height: 160,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 72),
          ),
        const SizedBox(height: 12),
        if (photoPath != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(LucideIcons.checkCircle, size: 14, color: AppColors.success),
              SizedBox(width: 6),
              Text('Selfie capturé',
                  style: TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        const SizedBox(height: 24),
        const Text('Vérification Réussie !',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text(
          'Votre selfie a été transmis et associé à vos documents.\nNos agents traiteront votre dossier sous 24h.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, height: 1.5, fontSize: 14),
        ),
        const SizedBox(height: 48),
        CustomButton(
          text: 'Voir le statut de mon dossier',
          onPressed: onNext,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Erreur
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.xCircle,
              size: 72, color: AppColors.danger),
        ),
        const SizedBox(height: 24),
        const Text('Échec du scan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 40),
        CustomButton(
          text: 'Réessayer',
          icon: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 16),
          onPressed: onRetry,
        ),
      ],
    );
  }
}
