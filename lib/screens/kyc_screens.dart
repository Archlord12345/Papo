import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';
import '../widgets/screen_explorer.dart';

// Helper for generic file upload layout
Widget _buildUploadBox(BuildContext context, String title, String currentFile, VoidCallback onUpload) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return GestureDetector(
    onTap: onUpload,
    child: Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.uploadCloud, size: 48, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            currentFile.isNotEmpty ? "Fichier sélectionné : $currentFile" : "Sélectionner un fichier JPG/PNG ou PDF",
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

// ==========================================
// 1. UPLOAD CNI SCREEN
// ==========================================
class UploadCNIScreen extends StatefulWidget {
  const UploadCNIScreen({super.key});

  @override
  State<UploadCNIScreen> createState() => _UploadCNIScreenState();
}

class _UploadCNIScreenState extends State<UploadCNIScreen> {
  String _rectoFile = "";
  String _versoFile = "";

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(title: const Text("Télécharger la CNI")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Pièce d'Identité Nationale (CNI)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Veuillez importer des photos nettes de votre CNI (Recto et Verso).", style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 24),
              _buildUploadBox(context, "Recto de la CNI", _rectoFile, () {
                setState(() {
                  _rectoFile = "CNI_Recto_Mamadou.jpg";
                });
              }),
              const SizedBox(height: 20),
              _buildUploadBox(context, "Verso de la CNI", _versoFile, () {
                setState(() {
                  _versoFile = "CNI_Verso_Mamadou.jpg";
                });
              }),
              const SizedBox(height: 32),
              CustomButton(
                text: "Continuer vers la vérification",
                onPressed: () {
                  if (_rectoFile.isEmpty || _versoFile.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Veuillez sélectionner les photos")),
                    );
                    return;
                  }
                  appState.uploadKYCDocument("CNI", "CNI_Mamadou.pdf");
                  appState.setScreen("FaceVerification");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. UPLOAD PASSPORT SCREEN
// ==========================================
class UploadPassportScreen extends StatefulWidget {
  const UploadPassportScreen({super.key});

  @override
  State<UploadPassportScreen> createState() => _UploadPassportScreenState();
}

class _UploadPassportScreenState extends State<UploadPassportScreen> {
  String _passportFile = "";

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(title: const Text("Télécharger le Passeport")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Passeport International", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Importez la double-page de signature et d'informations de votre passeport.", style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 24),
              _buildUploadBox(context, "Page d'informations du Passeport", _passportFile, () {
                setState(() {
                  _passportFile = "Passport_Mamadou.jpg";
                });
              }),
              const SizedBox(height: 48),
              CustomButton(
                text: "Continuer vers la vérification",
                onPressed: () {
                  if (_passportFile.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Veuillez sélectionner votre photo")),
                    );
                    return;
                  }
                  appState.uploadKYCDocument("Passport", "Passport_Mamadou.pdf");
                  appState.setScreen("FaceVerification");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. FACE VERIFICATION SCREEN
// ==========================================
class FaceVerificationScreen extends StatefulWidget {
  const FaceVerificationScreen({super.key});

  @override
  State<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen> {
  int _step = 0; // 0: Start, 1: Blinking, 2: Smiling, 3: Success
  
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    Widget content;
    if (_step == 0) {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle),
            child: const Icon(LucideIcons.scanFace, size: 96, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          const Text("Vérification Vivacité (Selfie)", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text(
            "Nous allons valider votre identité en analysant la vivacité de votre visage. Placez-vous dans un endroit bien éclairé.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 48),
          CustomButton(
            text: "Démarrer le Scan Faciale",
            onPressed: () {
              setState(() {
                _step = 1;
              });
            },
          )
        ],
      );
    } else if (_step == 1 || _step == 2) {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular mock camera view
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 4),
            ),
            child: ClipOval(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.camera, size: 48, color: AppColors.primary.withOpacity(0.4)),
                    const SizedBox(height: 8),
                    const Text("Caméra Active", style: TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _step == 1 ? "Clignez des yeux..." : "Veuillez sourire...",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            "Suivez les instructions à l'écran.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 48),
          CustomButton(
            text: "Simuler la détection",
            onPressed: () {
              setState(() {
                if (_step == 1) {
                  _step = 2;
                } else {
                  appState.verifyFace();
                  _step = 3;
                }
              });
            },
          ),
        ],
      );
    } else {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
            child: const Icon(LucideIcons.check, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text("Scan réussi !", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text(
            "Votre selfie 3D a été enregistré avec succès et associé à vos documents.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 48),
          CustomButton(
            text: "Finaliser mon dossier",
            onPressed: () {
              appState.setScreen("KYCStatus");
            },
          ),
        ],
      );
    }

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(title: const Text("Vérification Faciale")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: content,
        ),
      ),
    );
  }
}

// ==========================================
// 4. KYC STATUS SCREEN
// ==========================================
class KYCStatusScreen extends StatelessWidget {
  const KYCStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget statusCard;
    if (appState.kycStatus == "none") {
      statusCard = GlassCard(
        child: Column(
          children: [
            const Icon(LucideIcons.alertTriangle, size: 48, color: AppColors.accent),
            const SizedBox(height: 16),
            const Text("Vérification requise", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              "Vous devez valider votre KYC pour débloquer les limites de transaction de votre portefeuille.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: "Vérifier avec CNI",
              onPressed: () => appState.setScreen("UploadCNI"),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: "Vérifier avec Passeport",
              isPrimary: false,
              onPressed: () => appState.setScreen("UploadPassport"),
            ),
          ],
        ),
      );
    } else if (appState.kycStatus == "pending") {
      statusCard = GlassCard(
        borderColor: AppColors.warning.withOpacity(0.3),
        child: Column(
          children: [
            const Icon(LucideIcons.clock, size: 48, color: AppColors.warning),
            const SizedBox(height: 16),
            const Text("Dossier en cours d'examen", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              "Nos agents analysent vos pièces justificatives. Cette opération prend généralement moins de 24h.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: "Simuler Validation (Admin)",
                    onPressed: () {
                      appState.approveKYC();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: "Simuler Rejet (Admin)",
                    isPrimary: false,
                    onPressed: () {
                      appState.rejectKYC();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (appState.kycStatus == "verified") {
      statusCard = GlassCard(
        borderColor: AppColors.success.withOpacity(0.3),
        child: Column(
          children: [
            const Icon(LucideIcons.checkCircle, size: 48, color: AppColors.success),
            const SizedBox(height: 16),
            const Text("Compte Vérifié", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.success)),
            const SizedBox(height: 8),
            const Text(
              "Félicitations, votre KYC est entièrement approuvé. Toutes les limites ont été levées.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: "Retourner à l'accueil",
              onPressed: () => appState.setScreen("Dashboard"),
            ),
          ],
        ),
      );
    } else {
      // Rejected
      statusCard = GlassCard(
        borderColor: AppColors.danger.withOpacity(0.3),
        child: Column(
          children: [
            const Icon(LucideIcons.xCircle, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            const Text("Dossier Rejeté", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.danger)),
            const SizedBox(height: 8),
            const Text(
              "Les documents soumis étaient flous ou ne correspondaient pas au selfie de vivacité.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: "Recommencer la vérification",
              onPressed: () {
                appState.resetKYC();
              },
            ),
          ],
        ),
      );
    }

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(title: const Text("Statut KYC")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            statusCard,
          ],
        ),
      ),
    );
  }
}
