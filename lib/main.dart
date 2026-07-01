import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'state/app_state.dart';
import 'theme/app_theme.dart';

// ── Auth ──────────────────────────────────────────────────────────────────────
import 'screens/auth/splash_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/biometric_login_screen.dart';

// ── Main ──────────────────────────────────────────────────────────────────────
import 'screens/main/dashboard_screen.dart';
import 'screens/main/wallet_screen.dart';
import 'screens/main/send_money_screen.dart';
import 'screens/main/receive_money_screen.dart';
import 'screens/main/history_screen.dart';

// ── Offline ───────────────────────────────────────────────────────────────────
import 'screens/offline/offline_payment_screen.dart';
import 'screens/offline/sync_screen.dart';

// ── KYC ───────────────────────────────────────────────────────────────────────
import 'screens/kyc/upload_cni_screen.dart';
import 'screens/kyc/upload_passport_screen.dart';
import 'screens/kyc/face_verification_screen.dart';
import 'screens/kyc/kyc_status_screen.dart';

// ── Security ──────────────────────────────────────────────────────────────────
import 'screens/security/security_settings_screen.dart';
import 'screens/security/active_sessions_screen.dart';

// ── Notifications ─────────────────────────────────────────────────────────────
import 'screens/notifications/notifications_screen.dart';

// ── Merchant ──────────────────────────────────────────────────────────────────
import 'screens/merchant/merchant_dashboard_screen.dart';

// ── Admin ─────────────────────────────────────────────────────────────────────
import 'screens/admin/admin_dashboard_screen.dart';

// ── Ecosystem ─────────────────────────────────────────────────────────────────
import 'screens/ecosystem/menu_screen.dart';
import 'screens/ecosystem/circle_screen.dart';
import 'screens/ecosystem/aide_screen.dart';
import 'screens/ecosystem/developer_screen.dart';
import 'screens/ecosystem/ecosystem_screen.dart';
import 'screens/ecosystem/blockchain_screen.dart';

// ── Profile ───────────────────────────────────────────────────────────────────
import 'screens/profile/profile_screen.dart';

// ── Transfer methods ──────────────────────────────────────────────────────────
import 'screens/transfer/send_qr_screen.dart';
import 'screens/transfer/send_nfc_screen.dart';
import 'screens/transfer/send_bluetooth_screen.dart';
import 'screens/transfer/receive_nfc_screen.dart';
import 'screens/transfer/receive_bluetooth_screen.dart';

// ── Wallet management ─────────────────────────────────────────────────────────
import 'screens/wallet/wallet_slot_screen.dart';
import 'screens/wallet/create_wallet_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final appState = AppState();
  await appState.init();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const PaypointApp(),
    ),
  );
}

class PaypointApp extends StatelessWidget {
  const PaypointApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (_, appState, _) => MaterialApp(
        title: 'PAYPOINT (PAPO)',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: appState.themeMode,
        home: const AppShell(),
      ),
    );
  }
}

/// Root shell that handles Android back button via PopScope
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const _noBackScreens = {
    'Splash', 'Onboarding', 'Login', 'Dashboard',
  };

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final screen = appState.currentScreen;
    final canPop = appState.canGoBack && !_noBackScreens.contains(screen);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (canPop) {
          appState.popScreen();
        } else if (!_noBackScreens.contains(screen)) {
          // Confirm exit from main screens
          final exit = await _showExitDialog(context);
          if (exit == true) SystemNavigator.pop();
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, animation) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: KeyedSubtree(
          key: ValueKey(screen),
          child: _resolve(screen),
        ),
      ),
    );
  }

  Future<bool?> _showExitDialog(BuildContext context) => showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Quitter PAYPOINT ?'),
      content: const Text('Voulez-vous vraiment fermer l\'application ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Quitter', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  Widget _resolve(String screen) {
    switch (screen) {
      case 'Splash':           return const SplashScreen();
      case 'Onboarding':       return const OnboardingScreen();
      case 'Login':            return const LoginScreen();
      case 'Register':         return const RegisterScreen();
      case 'OTP':              return const OtpScreen();
      case 'ForgotPassword':   return const ForgotPasswordScreen();
      case 'ResetPassword':    return const ResetPasswordScreen();
      case 'BiometricLogin':   return const BiometricLoginScreen();
      case 'Dashboard':        return const DashboardScreen();
      case 'Wallet':           return const WalletScreen();
      case 'WalletSlots':      return const WalletSlotScreen();
      case 'CreateWallet':     return const CreateWalletScreen();
      case 'SendMoney':        return const SendMoneyScreen();
      case 'SendQR':           return const SendQrScreen();
      case 'SendNFC':          return const SendNfcScreen();
      case 'SendBluetooth':    return const SendBluetoothScreen();
      case 'ReceiveNFC':       return const ReceiveNfcScreen();
      case 'ReceiveBluetooth': return const ReceiveBluetoothScreen();
      case 'ReceiveMoney':     return const ReceiveMoneyScreen();
      case 'History':          return const HistoryScreen();
      case 'OfflinePayment':   return const OfflinePaymentScreen();
      case 'Sync':             return const SyncScreen();
      case 'UploadCNI':        return const UploadCNIScreen();
      case 'UploadPassport':   return const UploadPassportScreen();
      case 'FaceVerification': return const FaceVerificationScreen();
      case 'KYCStatus':        return const KYCStatusScreen();
      case 'SecuritySettings': return const SecuritySettingsScreen();
      case 'ActiveSessions':   return const ActiveSessionsScreen();
      case 'NotificationsList':return const NotificationsScreen();
      case 'MerchantDashboard':return const MerchantDashboardScreen();
      case 'AdminDashboard':   return const AdminDashboardScreen();
      case 'Menu':             return const MenuScreen();
      case 'Circle':           return const CircleScreen();
      case 'Aide':             return const AideScreen();
      case 'Developer':        return const DeveloperScreen();
      case 'Ecosystem':        return const EcosystemScreen();
      case 'Blockchain':       return const BlockchainScreen();
      case 'Profile':          return const ProfileScreen();
      default:                 return const SplashScreen();
    }
  }
}
