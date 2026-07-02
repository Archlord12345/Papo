import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import 'upload_cni_screen.dart';

class UploadPassportScreen extends StatefulWidget {
  const UploadPassportScreen({super.key});
  @override
  State<UploadPassportScreen> createState() => _UploadPassportScreenState();
}

class _UploadPassportScreenState extends State<UploadPassportScreen> {
  String _file = '';
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        setState(() {
          _file = image.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(
          title: const Text('Télécharger le Passeport'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Passeport International',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Importez la page d\'informations biographiques de votre passeport.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            UploadBox(
              title: 'Page d\'informations du Passeport',
              selected: _file,
              onTap: _pickImage,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Continuer vers la vérification faciale',
              onPressed: () {
                if (_file.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Veuillez sélectionner votre photo'),
                        backgroundColor: AppColors.danger),
                  );
                  return;
                }
                appState.uploadKYCDocument('Passeport', _file);
                appState.setScreen('FaceVerification');
              },
            ),
          ],
        ),
      ),
    );
  }
}
