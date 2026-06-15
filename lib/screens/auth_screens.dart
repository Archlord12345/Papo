import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';
import '../widgets/screen_explorer.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();

    Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.currentScreen == 'Splash') {
        appState.setScreen(appState.isAuthenticated ? 'Dashboard' : 'Onboarding');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const ScreenExplorer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  LucideIcons.wallet,
                  size: 72,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'PAYPOINT',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = const [
    {
      'title': 'Compte PocketBase Réel',
      'desc': 'Authentification, préférences et documents sont sauvegardés sur PocketBase.',
    },
    {
      'title': 'QR Fonctionnel',
      'desc': 'Le scanner caméra lit maintenant les QR PAYPOINT/PAPO.',
    },
    {
      'title': 'KYC Stocké',
      'desc': 'Les documents KYC sont téléversés dans PocketBase Storage.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const ScreenExplorer(),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () =>
                    Provider.of<AppState>(context, listen: false).setScreen('Login'),
                child: const Text('Passer'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (value) => setState(() => _currentPage = value),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.shieldCheck,
                            size: 96,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          _pages[index]['title']!,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _pages[index]['desc']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark
                                ? AppColors.textDarkSecondary
                                : AppColors.textLightSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  CustomButton(
                    text: _currentPage == _pages.length - 1 ? 'Commencer' : 'Suivant',
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Provider.of<AppState>(context, listen: false)
                            .setScreen('Login');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Bon retour !',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Connexion PocketBase directe avec votre numéro et votre PIN.',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textLightSecondary,
                ),
              ),
              const SizedBox(height: 32),
              CustomInput(
                label: 'Numéro de Téléphone',
                hint: 'ex: +225 07 08 09 10 11',
                prefixIcon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
                controller: _phoneController,
              ),
              const SizedBox(height: 20),
              CustomInput(
                label: 'Code PIN',
                hint: '6 chiffres',
                prefixIcon: LucideIcons.lock,
                isPassword: true,
                keyboardType: TextInputType.number,
                controller: _pinController,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => appState.setScreen('ForgotPassword'),
                  child: const Text('Mot de passe oublié ?'),
                ),
              ),
              if (appState.lastError != null)
                Text(
                  appState.lastError!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Se Connecter',
                isLoading: appState.isBusy,
                onPressed: () async {
                  final success = await appState.login(
                    phone: _phoneController.text.trim(),
                    pin: _pinController.text.trim(),
                  );
                  if (!mounted) return;
                  if (success) {
                    appState.setScreen('Dashboard');
                  }
                },
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Connexion session active',
                isPrimary: false,
                icon: const Icon(
                  LucideIcons.fingerprint,
                  color: AppColors.primary,
                ),
                onPressed: () => appState.setScreen('BiometricLogin'),
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
                          : AppColors.textLightSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => appState.setScreen('Register'),
                    child: const Text(
                      'Créer un compte',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Créer un Compte',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Votre compte et vos données seront créés directement dans PocketBase.',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textLightSecondary,
                ),
              ),
              const SizedBox(height: 32),
              CustomInput(
                label: 'Nom complet',
                hint: 'ex: Mamadou Diallo',
                prefixIcon: LucideIcons.user,
                controller: _nameController,
              ),
              const SizedBox(height: 20),
              CustomInput(
                label: 'Numéro de Téléphone',
                hint: 'ex: +225 07 08 09 10 11',
                prefixIcon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
                controller: _phoneController,
              ),
              const SizedBox(height: 20),
              CustomInput(
                label: 'Code PIN',
                hint: 'Code PIN à 6 chiffres',
                prefixIcon: LucideIcons.lock,
                isPassword: true,
                keyboardType: TextInputType.number,
                controller: _pinController,
              ),
              const SizedBox(height: 20),
              CustomInput(
                label: 'Confirmer le code PIN',
                hint: 'Saisissez à nouveau votre code PIN',
                prefixIcon: LucideIcons.lock,
                isPassword: true,
                keyboardType: TextInputType.number,
                controller: _confirmPinController,
              ),
              if (appState.lastError != null) ...[
                const SizedBox(height: 12),
                Text(
                  appState.lastError!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: 24),
              CustomButton(
                text: "S'inscrire",
                isLoading: appState.isBusy,
                onPressed: () async {
                  final pin = _pinController.text.trim();
                  if (pin != _confirmPinController.text.trim()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Les PIN ne correspondent pas.')),
                    );
                    return;
                  }
                  final success = await appState.register(
                    fullName: _nameController.text.trim(),
                    phone: _phoneController.text.trim(),
                    pin: pin,
                  );
                  if (!mounted) return;
                  if (success) {
                    appState.setScreen('Dashboard');
                  }
                },
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Vous avez déjà un compte ? ',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textLightSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => appState.setScreen('Login'),
                    child: const Text(
                      'Connexion',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vérification OTP',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Cette étape n'est plus utilisée dans le flux principal. L'application passe désormais par une session PocketBase directe.",
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Continuer',
              onPressed: () => appState.setScreen(
                appState.isAuthenticated ? 'Dashboard' : 'Login',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mot de Passe Oublié',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "La réinitialisation automatique n'est pas encore disponible sans configuration complémentaire PocketBase. Connectez-vous puis modifiez votre PIN depuis l'espace sécurité.",
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Aller à la connexion',
              onPressed: () => appState.setScreen('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nouveau Mot de Passe',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mettez à jour votre code PIN PocketBase depuis la session active.',
            ),
            const SizedBox(height: 32),
            CustomInput(
              label: 'Code PIN actuel',
              hint: 'Votre code PIN actuel',
              prefixIcon: LucideIcons.lock,
              isPassword: true,
              keyboardType: TextInputType.number,
              controller: _currentPinController,
            ),
            const SizedBox(height: 20),
            CustomInput(
              label: 'Nouveau Code PIN',
              hint: 'Code PIN à 6 chiffres',
              prefixIcon: LucideIcons.lock,
              isPassword: true,
              keyboardType: TextInputType.number,
              controller: _newPinController,
            ),
            const SizedBox(height: 20),
            CustomInput(
              label: 'Confirmer le Code PIN',
              hint: 'Saisissez à nouveau le code PIN',
              prefixIcon: LucideIcons.lock,
              isPassword: true,
              keyboardType: TextInputType.number,
              controller: _confirmPinController,
            ),
            if (appState.lastError != null) ...[
              const SizedBox(height: 12),
              Text(
                appState.lastError!,
                style: const TextStyle(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: 24),
            CustomButton(
              text: 'Enregistrer le mot de passe',
              isLoading: appState.isBusy,
              onPressed: () async {
                final newPin = _newPinController.text.trim();
                if (newPin != _confirmPinController.text.trim()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Les PIN ne correspondent pas.')),
                  );
                  return;
                }
                final success = await appState.changePin(
                  currentPin: _currentPinController.text.trim(),
                  newPin: newPin,
                );
                if (!mounted) return;
                if (success) {
                  appState.setScreen('SecuritySettings');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class BiometricLoginScreen extends StatefulWidget {
  const BiometricLoginScreen({super.key});

  @override
  State<BiometricLoginScreen> createState() => _BiometricLoginScreenState();
}

class _BiometricLoginScreenState extends State<BiometricLoginScreen> {
  bool _isAuthenticating = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.fingerprint,
                size: 96,
                color: AppColors.primary,
              ),
              const SizedBox(height: 32),
              const Text(
                'Authentification Biométrique',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "La biométrie matérielle n'est pas encore branchée. Cette entrée réutilise simplement la session PocketBase déjà ouverte.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (_isAuthenticating) ...[
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const SizedBox(height: 16),
                const Text('Vérification de la session...'),
              ] else ...[
                CustomButton(
                  text: 'Continuer avec la session',
                  onPressed: () {
                    setState(() => _isAuthenticating = true);
                    Timer(const Duration(seconds: 1), () {
                      if (!mounted) return;
                      appState.setScreen(
                        appState.isAuthenticated ? 'Dashboard' : 'Login',
                      );
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => appState.setScreen('Login'),
                  child: const Text('Utiliser mon Code PIN'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
