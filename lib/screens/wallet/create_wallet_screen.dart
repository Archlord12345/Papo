import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';

class CreateWalletScreen extends StatefulWidget {
  const CreateWalletScreen({super.key});
  @override
  State<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  final _nameCtrl = TextEditingController();
  String _selectedAsset = 'PAPO';
  bool _loading = false;
  List<dynamic> _availableAssets = [];

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      final assets = await appState.getAvailableAssets();
      setState(() {
        _availableAssets = assets;
        if (_availableAssets.isNotEmpty) {
          _selectedAsset = _availableAssets.first['code'];
        }
      });
    } catch (e) {
      debugPrint('Error loading assets: $e');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nextSlot = appState.walletSlots.length;

    // Preview wallet ID
    final previewId = 'PAPO-${appState.blockchainAddr}-$nextSlot';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Portefeuille'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: appState.popScreen,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Slot preview card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SLOT DE STOCKAGE', style: TextStyle(color: Colors.white60, fontSize: 11, letterSpacing: 1.5)),
                  Text('#$nextSlot', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32)),
                  const SizedBox(height: 8),
                  const Text('ADRESSE BLOCKCHAIN', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  Text(previewId,
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Wallet name
            CustomInput(
              label: 'Libellé du portefeuille',
              hint: 'ex: Compte Courant, Épargne...',
              prefixIcon: LucideIcons.wallet,
              controller: _nameCtrl,
            ),
            const SizedBox(height: 32),

            // Asset selection
            const Text('Choisir la Monnaie (Asset)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              'Toutes les transactions seront converties via le pivot PAPO.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 16),

            if (_availableAssets.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _availableAssets.length,
                itemBuilder: (ctx, i) {
                  final asset = _availableAssets[i];
                  final code = asset['code'] as String;
                  final name = asset['name'] as String;
                  final isSelected = _selectedAsset == code;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedAsset = code),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : (isDark ? AppColors.darkSurface : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: isSelected ? Colors.white24 : AppColors.primary.withOpacity(0.1),
                            child: Text(
                              code[0],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  code,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isSelected ? Colors.white : null,
                                  ),
                                ),
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected ? Colors.white70 : Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 48),
            CustomButton(
              text: 'Confirmer la création',
              isLoading: _loading,
              icon: const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
              onPressed: () async {
                if (_nameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez donner un nom à ce portefeuille'), backgroundColor: AppColors.danger),
                  );
                  return;
                }

                setState(() => _loading = true);
                // deviceName is now passed as a placeholder or handled internally
                final error = await appState.createWalletSlot(
                  name: _nameCtrl.text.trim(),
                  deviceName: 'Mobile App', // Placeholder since it's no longer chosen
                  asset: _selectedAsset,
                );

                if (mounted) {
                  setState(() => _loading = false);
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppColors.danger));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Portefeuille créé avec succès !'), backgroundColor: AppColors.success),
                    );
                    appState.popScreen();
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
