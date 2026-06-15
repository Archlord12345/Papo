import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/screen_explorer.dart';

Widget _buildUploadBox(
  BuildContext context,
  String title,
  String currentFile,
  VoidCallback onUpload,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return GestureDetector(
    onTap: onUpload,
    child: Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.uploadCloud, size: 48, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            currentFile.isNotEmpty
                ? 'Fichier sélectionné : $currentFile'
                : 'Sélectionner un fichier JPG, PNG ou PDF',
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

class UploadCNIScreen extends StatefulWidget {
  const UploadCNIScreen({super.key});

  @override
  State<UploadCNIScreen> createState() => _UploadCNIScreenState();
}

class _UploadCNIScreenState extends State<UploadCNIScreen> {
  PlatformFile? _documentFile;

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _documentFile = result.files.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(title: const Text('Télécharger la CNI')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Pièce d'Identité Nationale",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Importez un document lisible contenant votre CNI recto/verso.",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              _buildUploadBox(
                context,
                'Document CNI',
                _documentFile?.name ?? '',
                _pickDocument,
              ),
              if (appState.lastError != null) ...[
                const SizedBox(height: 12),
                Text(
                  appState.lastError!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: 32),
              CustomButton(
                text: 'Téléverser et continuer',
                isLoading: appState.isBusy,
                onPressed: () async {
                  if (_documentFile == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez sélectionner un document.')),
                    );
                    return;
                  }
                  final success = await appState.uploadKYCDocument(
                    type: 'CNI',
                    documentFile: _documentFile,
                  );
                  if (!mounted) return;
                  if (success) {
                    appState.setScreen('FaceVerification');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UploadPassportScreen extends StatefulWidget {
  const UploadPassportScreen({super.key});

  @override
  State<UploadPassportScreen> createState() => _UploadPassportScreenState();
}

class _UploadPassportScreenState extends State<UploadPassportScreen> {
  PlatformFile? _documentFile;

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _documentFile = result.files.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(title: const Text('Télécharger le Passeport')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Passeport International',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Importez la page d'identité ou un PDF lisible du passeport.",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              _buildUploadBox(
                context,
                "Document Passeport",
                _documentFile?.name ?? '',
                _pickDocument,
              ),
              if (appState.lastError != null) ...[
                const SizedBox(height: 12),
                Text(
                  appState.lastError!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: 32),
              CustomButton(
                text: 'Téléverser et continuer',
                isLoading: appState.isBusy,
                onPressed: () async {
                  if (_documentFile == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez sélectionner un document.')),
                    );
                    return;
                  }
                  final success = await appState.uploadKYCDocument(
                    type: 'Passport',
                    documentFile: _documentFile,
                  );
                  if (!mounted) return;
                  if (success) {
                    appState.setScreen('FaceVerification');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FaceVerificationScreen extends StatefulWidget {
  const FaceVerificationScreen({super.key});

  @override
  State<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen> {
  PlatformFile? _selfieFile;

  Future<void> _pickSelfie() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _selfieFile = result.files.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(title: const Text('Vérification Faciale')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                  LucideIcons.scanFace,
                  size: 96,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Vérification de vivacité',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Sélectionnez un selfie récent pour l'associer à votre dossier KYC PocketBase.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              _buildUploadBox(
                context,
                'Selfie de vérification',
                _selfieFile?.name ?? '',
                _pickSelfie,
              ),
              if (appState.lastError != null) ...[
                const SizedBox(height: 12),
                Text(
                  appState.lastError!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: 32),
              CustomButton(
                text: 'Finaliser mon dossier',
                isLoading: appState.isBusy,
                onPressed: () async {
                  if (_selfieFile == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez sélectionner un selfie.')),
                    );
                    return;
                  }
                  final success = await appState.uploadKYCDocument(
                    type: appState.uploadedDocType ?? 'KYC',
                    selfieFile: _selfieFile,
                  );
                  if (!mounted) return;
                  if (success) {
                    appState.setScreen('KYCStatus');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class KYCStatusScreen extends StatelessWidget {
  const KYCStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Widget statusCard;
    if (appState.kycStatus == 'verified') {
      statusCard = GlassCard(
        child: Column(
          children: [
            const Icon(LucideIcons.badgeCheck, size: 52, color: AppColors.success),
            const SizedBox(height: 16),
            const Text(
              'KYC vérifié',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Votre identité a été validée.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else if (appState.kycStatus == 'pending') {
      statusCard = GlassCard(
        child: Column(
          children: [
            const Icon(LucideIcons.hourglass, size: 52, color: AppColors.warning),
            const SizedBox(height: 16),
            const Text(
              'KYC en attente',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre document ${appState.uploadedDocName ?? ''} et votre selfie sont stockés sur PocketBase et attendent validation.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else if (appState.kycStatus == 'rejected') {
      statusCard = GlassCard(
        child: Column(
          children: [
            const Icon(LucideIcons.shieldAlert, size: 52, color: AppColors.danger),
            const SizedBox(height: 16),
            const Text(
              'KYC rejeté',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Le dossier a besoin d’une nouvelle soumission.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      statusCard = GlassCard(
        child: Column(
          children: [
            const Icon(LucideIcons.alertTriangle, size: 52, color: AppColors.accent),
            const SizedBox(height: 16),
            const Text(
              'Vérification requise',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Soumettez votre document pour activer le KYC.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(title: const Text('Statut KYC')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              statusCard,
              const SizedBox(height: 24),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dossier actuel',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text('Type : ${appState.uploadedDocType ?? "Aucun"}'),
                    const SizedBox(height: 8),
                    Text('Fichier : ${appState.uploadedDocName ?? "Aucun"}'),
                    const SizedBox(height: 8),
                    Text(
                      'Selfie : ${appState.isFaceVerified ? "Téléversé" : "En attente"}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (appState.kycStatus == 'none' || appState.kycStatus == 'rejected')
                CustomButton(
                  text: 'Soumettre une CNI',
                  onPressed: () => appState.setScreen('UploadCNI'),
                ),
              if (appState.kycStatus == 'none' || appState.kycStatus == 'rejected') ...[
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Soumettre un passeport',
                  isPrimary: false,
                  onPressed: () => appState.setScreen('UploadPassport'),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Validation réelle : aucune action admin simulée n’est exposée dans l’application.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textLightSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
