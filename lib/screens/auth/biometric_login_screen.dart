import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:local_auth/local_auth.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
class BiometricLoginScreen extends StatefulWidget {
  const BiometricLoginScreen({super.key});
  @override
  State<BiometricLoginScreen> createState() => _BiometricLoginScreenState();
}

class _BiometricLoginScreenState extends State<BiometricLoginScreen>
    with SingleTickerProviderStateMixin {
  final LocalAuthentication _auth = LocalAuthentication();
  late final AnimationController _pulse;

  // État
  bool _scanning = false;
  bool _checking = true;        // détection des capacités en cours
  bool _noBiometry = false;     // appareil sans biométrie du tout
  bool _failed = false;
  String? _failMessage;

  // Capacités détectées
  List<BiometricType> _availableTypes = [];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.88,
      upperBound: 1.12,
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndAuth());
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  // ── Détection des capacités ─────────────────────────────────────────────────

  Future<void> _checkAndAuth() async {
    setState(() => _checking = true);
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();

      if (!canCheck && !supported) {
        // Pas de biométrie du tout → fallback PIN automatique
        if (mounted) {
          setState(() {
            _checking = false;
            _noBiometry = true;
          });
          // Redirige vers PIN après un court délai pour que l'utilisateur voit le message
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            context.read<AppState>().setScreen('Login');
          }
        }
        return;
      }

      _availableTypes = await _auth.getAvailableBiometrics();
      if (mounted) {
        setState(() => _checking = false);
        await _authenticate();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checking = false;
          _noBiometry = true;
          _failMessage = e.toString();
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) context.read<AppState>().setScreen('Login');
      }
    }
  }

  Future<void> _authenticate() async {
    if (_scanning) return;
    setState(() {
      _scanning = true;
      _failed = false;
      _failMessage = null;
    });
    _pulse.repeat(reverse: true);
    try {
      final success = await _auth.authenticate(
        localizedReason: 'Accédez à votre portefeuille PAYPOINT',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // autorise aussi le PIN système en fallback
          useErrorDialogs: true,
        ),
      );
      if (!mounted) return;
      if (success) {
        _pulse.stop();
        context.read<AppState>().unlockWithBiometrics();
      } else {
        setState(() {
          _scanning = false;
          _failed = true;
          _failMessage = 'Authentification échouée ou annulée.';
        });
        _pulse.stop();
      }
    } catch (e) {
      if (!mounted) return;
      _pulse.stop();
      setState(() {
        _scanning = false;
        _failed = true;
        _failMessage = _friendlyError(e.toString());
      });
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('NotAvailable') || raw.contains('not available')) {
      return 'Biométrie non disponible. Utilisez votre code PIN.';
    }
    if (raw.contains('LockedOut') || raw.contains('locked')) {
      return 'Trop de tentatives échouées. Réessayez dans quelques minutes.';
    }
    if (raw.contains('NotEnrolled') || raw.contains('not enrolled')) {
      return 'Aucune empreinte enregistrée. Configurez la biométrie dans les paramètres.';
    }
    if (raw.contains('cancel') || raw.contains('UserCancel')) {
      return 'Authentification annulée.';
    }
    return 'Erreur d\'authentification.';
  }

  // ── Icône adaptative ────────────────────────────────────────────────────────

  /// Retourne l'icône la plus pertinente selon les capacités de l'appareil.
  IconData get _biometricIcon {
    if (_availableTypes.contains(BiometricType.face)) return LucideIcons.scanFace;
    if (_availableTypes.contains(BiometricType.iris)) return LucideIcons.eye;
    if (_availableTypes.contains(BiometricType.fingerprint)) return LucideIcons.fingerprint;
    if (_availableTypes.contains(BiometricType.strong)) return LucideIcons.fingerprint;
    if (_availableTypes.contains(BiometricType.weak)) return LucideIcons.fingerprint;
    return LucideIcons.fingerprint; // défaut
  }

  String get _biometricLabel {
    if (_availableTypes.contains(BiometricType.face)) return 'Reconnaissance faciale';
    if (_availableTypes.contains(BiometricType.iris)) return 'Reconnaissance iris';
    if (_availableTypes.contains(BiometricType.fingerprint)) return 'Empreinte digitale';
    return 'Authentification biométrique';
  }

  String get _biometricHint {
    if (_availableTypes.contains(BiometricType.face)) {
      return 'Regardez votre téléphone pour accéder à votre portefeuille.';
    }
    if (_availableTypes.contains(BiometricType.fingerprint) ||
        _availableTypes.contains(BiometricType.strong)) {
      return 'Posez votre doigt sur le capteur pour vous connecter.';
    }
    return 'Utilisez votre biométrie pour accéder à votre portefeuille.';
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Chargement initial
    if (_checking) return _buildChecking();

    // Pas de biométrie — feedback avant redirection
    if (_noBiometry) return _buildNoBiometry();

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône principale animée
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
                        color: _failed
                            ? AppColors.danger.withValues(alpha: 0.4)
                            : AppColors.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _biometricIcon,
                      size: 88,
                      color: _failed
                          ? AppColors.danger
                          : _scanning
                              ? AppColors.primary
                              : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  _scanning ? 'Scan en cours...' : _biometricLabel,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _failed
                      ? _FailureBanner(message: _failMessage)
                      : Text(
                          _biometricHint,
                          key: const ValueKey('hint'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.textDarkSecondary, fontSize: 14, height: 1.5),
                        ),
                ),

                const SizedBox(height: 56),

                if (_scanning)
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                else ...[
                  CustomButton(
                    text: _failed ? 'Réessayer' : 'S\'authentifier',
                    icon: Icon(
                      _biometricIcon,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: _authenticate,
                  ),
                  const SizedBox(height: 14),
                  CustomButton(
                    text: 'Utiliser mon Code PIN',
                    isPrimary: false,
                    onPressed: () => context.read<AppState>().setScreen('Login'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecking() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Détection des capacités biométriques...',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoBiometry() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.alertTriangle,
                    size: 64, color: Colors.orange),
              ),
              const SizedBox(height: 24),
              const Text(
                'Biométrie non disponible',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Cet appareil ne dispose pas de capteur biométrique ou aucune empreinte n\'est enregistrée.\n\nRedirection vers le code PIN...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.6),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _FailureBanner extends StatelessWidget {
  final String? message;
  const _FailureBanner({this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('fail'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.alertCircle,
              color: AppColors.danger, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message ?? 'Authentification échouée.',
              style: const TextStyle(
                  color: AppColors.danger, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
