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
  String? _selectedDevice;
  String _selectedAsset = 'XOF';
  bool _loading = false;

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
        title: const Text('Créer un Wallet'),
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
                  const Text('SLOT', style: TextStyle(color: Colors.white60, fontSize: 11, letterSpacing: 1.5)),
                  Text('#$nextSlot', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32)),
                  const SizedBox(height: 8),
                  const Text('ID Wallet (aperçu)', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  Text(previewId,
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Wallet name
            CustomInput(
              label: 'Nom du wallet',
              hint: 'ex: Wallet Famille, Épargne BTC...',
              prefixIcon: LucideIcons.tag,
              controller: _nameCtrl,
            ),
            const SizedBox(height: 24),

            // Asset selection
            const Text('Devise du solde', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            Row(
              children: ['XOF', 'USD', 'PAPO', 'BTC'].map((asset) {
                final isSelected = _selectedAsset == asset;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedAsset = asset),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : (isDark ? AppColors.darkSurface : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                      ),
                      child: Center(
                        child: Text(
                          asset,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Device selection
            const Text('Appareil associé', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            const Text('Choisissez l\'appareil physique de ce wallet.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),

            if (appState.deviceCatalog.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: appState.deviceCatalog.length,
                itemBuilder: (ctx, i) {
                  final device = appState.deviceCatalog[i];
                  final name = device['name'] as String;
                  final isSelected = _selectedDevice == name;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDevice = name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : (isDark ? AppColors.darkSurface : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.smartphone,
                            color: isSelected ? AppColors.primary : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppColors.primary : null,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(LucideIcons.circleCheck, color: AppColors.primary, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 32),
            CustomButton(
              text: 'Créer le Wallet',
              isLoading: _loading,
              icon: const Icon(LucideIcons.plusCircle, color: Colors.white, size: 18),
              onPressed: () async {
                if (_nameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez saisir un nom'), backgroundColor: AppColors.danger),
                  );
                  return;
                }
                if (_selectedDevice == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez sélectionner un appareil'), backgroundColor: AppColors.danger),
                  );
                  return;
                }
                setState(() => _loading = true);
                final error = await appState.createWalletSlot(
                  name: _nameCtrl.text.trim(),
                  deviceName: _selectedDevice!,
                  asset: _selectedAsset,
                );
                if (mounted) {
                  setState(() => _loading = false);
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppColors.danger));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Wallet créé avec succès !'), backgroundColor: AppColors.success),
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
