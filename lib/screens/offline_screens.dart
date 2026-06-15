import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';
import '../widgets/screen_explorer.dart';
import 'main_screens.dart';

// ==========================================
// 1. OFFLINE PAYMENT SCREEN
// ==========================================
class OfflinePaymentScreen extends StatefulWidget {
  const OfflinePaymentScreen({super.key});

  @override
  State<OfflinePaymentScreen> createState() => _OfflinePaymentScreenState();
}

class _OfflinePaymentScreenState extends State<OfflinePaymentScreen> {
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isBroadcasting = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(
        title: const Text("Paiement Hors Ligne"),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () => appState.setScreen("Sync"),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Offline Alert Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.wifiOff, color: AppColors.warning, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Mode Secours Hors Ligne", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.warning)),
                          const SizedBox(height: 4),
                          Text(
                            "Créez une transaction signée localement. Elle sera transférée en Bluetooth/NFC à proximité.",
                            style: TextStyle(fontSize: 11, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              if (_isBroadcasting) ...[
                // Broadcasting NFC/Bluetooth Animation
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      // Rippling animation representation
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const CircleAvatar(
                            radius: 35,
                            backgroundColor: AppColors.warning,
                            child: Icon(LucideIcons.radio, size: 32, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        "Diffusion de la transaction...",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Approchez le téléphone du récepteur (NFC/Bluetooth)",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 48),
                      CustomButton(
                        text: "Enregistrer la transmission locale",
                        onPressed: () {
                          final amount = double.tryParse(_amountController.text) ?? 0;
                          final recipient = _recipientController.text.trim();
                          appState.addOfflineTransaction(amount, recipient);
                          
                          setState(() {
                            _isBroadcasting = false;
                            _amountController.clear();
                            _recipientController.clear();
                          });
                          
                          // Redirect to sync to view it
                          appState.setScreen("Sync");
                        },
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        text: "Annuler",
                        isPrimary: false,
                        onPressed: () {
                          setState(() {
                            _isBroadcasting = false;
                          });
                        },
                      )
                    ],
                  ),
                ),
              ] else ...[
                // Form input
                CustomInput(
                  label: "Téléphone / Adresse du Destinataire",
                  hint: "Numéro ou Wallet du destinataire",
                  controller: _recipientController,
                  prefixIcon: LucideIcons.user,
                ),
                const SizedBox(height: 20),
                CustomInput(
                  label: "Montant (XOF)",
                  hint: "Montant à transférer",
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  prefixIcon: LucideIcons.circleDollarSign,
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: "Signer & Diffuser localement",
                  gradient: AppColors.accentGradient, // Gold theme for offline
                  onPressed: () {
                    final amount = double.tryParse(_amountController.text) ?? 0;
                    final recipient = _recipientController.text.trim();
                    if (amount <= 0 || recipient.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Veuillez renseigner tous les champs")),
                      );
                      return;
                    }
                    if (amount > (appState.balances['XOF'] ?? 0)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Solde insuffisant")),
                      );
                      return;
                    }

                    setState(() {
                      _isBroadcasting = true;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. SYNC SCREEN
// ==========================================
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(title: const Text("Synchronisation")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Transactions Hors Ligne en attente",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Une fois le réseau rétabli, synchronisez vos paiements pour les pousser vers PocketBase.",
              style: TextStyle(fontSize: 13, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
            ),
            const SizedBox(height: 24),
            
            // Queue List
            Expanded(
              child: appState.offlineQueue.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.checkCircle, size: 64, color: AppColors.success),
                          const SizedBox(height: 16),
                          const Text("Aucune transaction en attente", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text("Toutes vos transactions sont synchronisées.", style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 24),
                          CustomButton(
                            text: "Retour à l'accueil",
                            isPrimary: false,
                            onPressed: () => appState.setScreen("Dashboard"),
                          )
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: appState.offlineQueue.length,
                      itemBuilder: (context, index) {
                        final tx = appState.offlineQueue[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.warning.withOpacity(0.1),
                              child: const Icon(LucideIcons.wifiOff, color: AppColors.warning),
                            ),
                            title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text("ID: ${tx.id}\nDate: ${tx.timestamp.toString().substring(11, 16)}"),
                            trailing: Text(
                              formatCurrency(tx.amount, tx.asset),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
            
            if (appState.offlineQueue.isNotEmpty) ...[
              if (_isSyncing) ...[
                Center(
                  child: Column(
                    children: const [
                      CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
                      SizedBox(height: 16),
                      Text("Traitement blockchain en cours...", style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                    ],
                  ),
                )
              ] else ...[
                CustomButton(
                  text: "Synchroniser avec le serveur (${appState.offlineQueue.length})",
                  onPressed: () {
                    setState(() {
                      _isSyncing = true;
                    });
                    
                    // Simulate Server & Blockchain Latency
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) {
                        appState.syncOfflineTransactions();
                        setState(() {
                          _isSyncing = false;
                        });
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
              ]
            ]
          ],
        ),
      ),
    );
  }
}
