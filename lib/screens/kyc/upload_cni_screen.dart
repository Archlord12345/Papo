import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';

class UploadCNIScreen extends StatefulWidget {
  const UploadCNIScreen({super.key});
  @override
  State<UploadCNIScreen> createState() => _UploadCNIScreenState();
}

class _UploadCNIScreenState extends State<UploadCNIScreen> {
  String _recto = '';
  String _verso = '';

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(
          title: const Text('Télécharger la CNI'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Carte Nationale d\'Identité',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Importez des photos nettes de votre CNI (Recto et Verso). Formats acceptés : JPG, PNG, PDF.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            UploadBox(
              title: 'Recto de la CNI',
              selected: _recto,
              onTap: () => setState(() => _recto = 'CNI_Recto.jpg'),
            ),
            const SizedBox(height: 16),
            UploadBox(
              title: 'Verso de la CNI',
              selected: _verso,
              onTap: () => setState(() => _verso = 'CNI_Verso.jpg'),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Continuer vers la vérification faciale',
              onPressed: () {
                if (_recto.isEmpty || _verso.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Veuillez sélectionner les deux photos'),
                        backgroundColor: AppColors.danger),
                  );
                  return;
                }
                appState.uploadKYCDocument('CNI', 'CNI_Document.pdf');
                appState.setScreen('FaceVerification');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class UploadBox extends StatelessWidget {
  final String title;
  final String selected;
  final VoidCallback onTap;
  const UploadBox({super.key, required this.title, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected.isNotEmpty
                ? AppColors.success
                : AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected.isNotEmpty ? LucideIcons.checkCircle : LucideIcons.uploadCloud,
              size: 40,
              color: selected.isNotEmpty ? AppColors.success : AppColors.primary,
            ),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              selected.isNotEmpty ? selected : 'Appuyez pour sélectionner',
              style: TextStyle(
                  color: selected.isNotEmpty ? AppColors.success : Colors.grey,
                  fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
