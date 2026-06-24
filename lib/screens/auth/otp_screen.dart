import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _otp = '';
  // Demo OTP always shown as 1234
  static const _demoOtp = '1234';
  bool _verified = false;
  int _resendSeconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _resendSeconds = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds <= 0) {
        t.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _verify() {
    if (_otp == _demoOtp) {
      setState(() => _verified = true);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) context.read<AppState>().setScreen('Dashboard');
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Code OTP incorrect. Utilisez 1234 en démo.'),
            backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Vérification OTP',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Code envoyé au ${appState.userPhone}\n(En démo, saisissez 1234)',
              style: TextStyle(
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textLightSecondary,
                  height: 1.5),
            ),
            const SizedBox(height: 48),
            if (_verified)
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                          color: AppColors.success, shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 16),
                    const Text('Numéro vérifié !',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            else ...[
              PinCodeTextField(
                appContext: context,
                length: 4,
                animationType: AnimationType.fade,
                keyboardType: TextInputType.number,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 64,
                  fieldWidth: 64,
                  activeFillColor:
                      isDark ? AppColors.darkSurface : Colors.white,
                  inactiveFillColor:
                      isDark ? AppColors.darkBg : AppColors.lightBg,
                  selectedFillColor:
                      AppColors.primary.withOpacity(0.1),
                  activeColor: AppColors.primary,
                  inactiveColor:
                      isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  selectedColor: AppColors.primary,
                ),
                enableActiveFill: true,
                onChanged: (v) => setState(() => _otp = v),
                onCompleted: (_) => _verify(),
              ),
              const SizedBox(height: 40),
              CustomButton(
                text: 'Vérifier',
                onPressed: _verify,
              ),
              const SizedBox(height: 24),
              Center(
                child: _resendSeconds > 0
                    ? Text(
                        'Renvoyer dans $_resendSeconds s',
                        style: const TextStyle(color: Colors.grey),
                      )
                    : TextButton(
                        onPressed: () {
                          _startTimer();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Code renvoyé (démo: 1234)')),
                          );
                        },
                        child: const Text('Renvoyer le code OTP'),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
