import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';
import '../widgets/screen_explorer.dart';
import '../services/nfc_service.dart';

// Helper to format currency
String formatCurrency(double amount, String asset) {
  if (asset == "BTC") return "${amount.toStringAsFixed(4)} $asset";
  final prefix = amount >= 0 ? "+" : "";
  return "$prefix${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} $asset";
}

// Common Bottom Navigation Builder for Main Screens
Widget buildBottomNavBar(BuildContext context, int currentIndex) {
  final appState = Provider.of<AppState>(context, listen: false);
  return BottomNavigationBar(
    currentIndex: currentIndex,
    type: BottomNavigationBarType.fixed,
    onTap: (index) {
      switch (index) {
        case 0:
          appState.setScreen("Dashboard");
          break;
        case 1:
          appState.setScreen("Wallet");
          break;
        case 2:
          appState.setScreen("SendMoney");
          break;
        case 3:
          appState.setScreen("History");
          break;
        case 4:
          appState.setScreen("Menu");
          break;
      }
    },
    items: const [
      BottomNavigationBarItem(icon: Icon(LucideIcons.layoutDashboard), label: "Accueil"),
      BottomNavigationBarItem(icon: Icon(LucideIcons.wallet), label: "Wallet"),
      BottomNavigationBarItem(icon: Icon(LucideIcons.send), label: "Envoyer"),
      BottomNavigationBarItem(icon: Icon(LucideIcons.history), label: "Historique"),
      BottomNavigationBarItem(icon: Icon(LucideIcons.grid), label: "Plus"),
    ],
  );
}

// ==========================================
// 1. DASHBOARD SCREEN
// ==========================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _hideBalance = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalBalance = appState.balances.values.fold<double>(
      0,
      (sum, value) => sum + value.abs(),
    );
    final unreadCount = appState.notifications.where((n) => !n.isRead).length;

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(LucideIcons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: Text(
                appState.avatarInitials,
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Salut,", style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  appState.userName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Notification Bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.bell),
                onPressed: () {
                  appState.setScreen("NotificationsList");
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                    child: Text(
                      "$unreadCount",
                      style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          // Theme Switcher
          IconButton(
            icon: Icon(appState.themeMode == ThemeMode.dark ? LucideIcons.sun : LucideIcons.moon),
            onPressed: () {
              appState.toggleTheme();
            },
          ),
        ],
      ),
      bottomNavigationBar: buildBottomNavBar(context, 0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Glassmorphic Wallet Balance Card
              GlassCard(
                padding: const EdgeInsets.all(20),
                borderColor: AppColors.primary.withOpacity(0.2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("SOLDE DISPONIBLE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppColors.primary)),
                        IconButton(
                          icon: Icon(_hideBalance ? LucideIcons.eyeOff : LucideIcons.eye, size: 20),
                          onPressed: () {
                            setState(() {
                              _hideBalance = !_hideBalance;
                            });
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _hideBalance ? "•••••• F CFA" : formatCurrency(appState.balances['XOF']!, 'XOF'),
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            appState.walletAddress,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'monospace'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.copy, size: 16, color: Colors.grey),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: appState.walletAddress));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Adresse copiée dans le presse-papiers")),
                            );
                          },
                        )
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Quick Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickAction(context, LucideIcons.send, "Envoyer", "SendMoney"),
                  _buildQuickAction(context, LucideIcons.download, "Recevoir", "ReceiveMoney"),
                  _buildQuickAction(context, LucideIcons.wifiOff, "Offline", "OfflinePayment"),
                  _buildQuickAction(context, LucideIcons.qrCode, "Scanner", "SendMoney"),
                ],
              ),
              const SizedBox(height: 32),

              // ── Services PAPO ──────────────────────────────────
              const Text("Services PAPO", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.6,
                children: [
                  _buildServiceCard(context, LucideIcons.shield, "Cercle (Tontine)", "Circle", AppColors.secondary),
                  _buildServiceCard(context, LucideIcons.link, "Blockchain", "Blockchain", AppColors.primary),
                  _buildServiceCard(context, LucideIcons.globe, "Écosystème", "Ecosystem", AppColors.accent),
                  _buildServiceCard(context, LucideIcons.terminal, "Développeur", "Developer", Colors.blueGrey),
                ],
              ),
              const SizedBox(height: 28),
              
              // Pending Offline Sync Banner
              if (appState.offlineQueue.isNotEmpty) ...[
                GestureDetector(
                  onTap: () => appState.setScreen("Sync"),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.wifiOff, color: AppColors.warning),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "${appState.offlineQueue.length} transaction(s) en attente de synchro",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const Icon(LucideIcons.arrowRight, size: 16, color: AppColors.warning),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Recent Transactions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Transactions récentes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      appState.setScreen("History");
                    },
                    child: const Text("Voir tout"),
                  )
                ],
              ),
              const SizedBox(height: 8),
              // Recent Transactions List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: appState.transactions.length > 5 ? 5 : appState.transactions.length,
                itemBuilder: (context, index) {
                  final tx = appState.transactions[index];
                  return _buildTransactionItem(context, tx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, IconData icon, String label, String screen, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => Provider.of<AppState>(context, listen: false).setScreen(screen),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: isDark ? Colors.white : Colors.black87)),
              ),
              Icon(LucideIcons.chevronRight, size: 14, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, String screenName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Provider.of<AppState>(context, listen: false).setScreen(screenName);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ]
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// Transaction List Item Helper
Widget _buildTransactionItem(BuildContext context, Transaction tx) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  IconData icon;
  Color iconColor;
  switch (tx.type) {
    case 'send':
      icon = LucideIcons.arrowUpRight;
      iconColor = AppColors.danger;
      break;
    case 'receive':
      icon = LucideIcons.arrowDownLeft;
      iconColor = AppColors.success;
      break;
    case 'offline':
      icon = LucideIcons.wifiOff;
      iconColor = AppColors.warning;
      break;
    default:
      icon = LucideIcons.store;
      iconColor = AppColors.secondary;
  }

  return Card(
    margin: const EdgeInsets.symmetric(vertical: 6),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.1),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Row(
        children: [
          Text(
            "${tx.timestamp.hour}:${tx.timestamp.minute.toString().padLeft(2, '0')}",
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(width: 8),
          if (tx.status == "pending")
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
              child: const Text("OFFLINE", style: TextStyle(fontSize: 8, color: Colors.orange, fontWeight: FontWeight.bold)),
            )
          else if (tx.status == "failed")
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
              child: const Text("ÉCHOUÉ", style: TextStyle(fontSize: 8, color: Colors.red, fontWeight: FontWeight.bold)),
            )
        ],
      ),
      trailing: Text(
        formatCurrency(tx.amount, tx.asset),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: tx.amount > 0 ? AppColors.success : (isDark ? Colors.white : AppColors.textLightPrimary),
          fontSize: 14,
        ),
      ),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Détails du paiement"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow("ID Transaction", tx.id),
                _detailRow("Description", tx.description),
                _detailRow("Montant", formatCurrency(tx.amount, tx.asset)),
                _detailRow("Statut", tx.status.toUpperCase()),
                _detailRow("Date", tx.timestamp.toString().substring(0, 19)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Fermer"),
              ),
            ],
          ),
        );
      },
    ),
  );
}

Widget _detailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14)),
        const Divider(),
      ],
    ),
  );
}

// ==========================================
// 2. WALLET SCREEN
// ==========================================
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(
        title: const Text("Mes Portefeuilles"),
      ),
      bottomNavigationBar: buildBottomNavBar(context, 1),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balances vertical list
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: appState.balances.keys.length,
                itemBuilder: (context, index) {
                  final asset = appState.balances.keys.elementAt(index);
                  final bal = appState.balances[asset]!;
                  
                  Gradient grad;
                  if (asset == "XOF") {
                    grad = AppColors.primaryGradient;
                  } else if (asset == "PAPO") {
                    grad = AppColors.accentGradient;
                  } else if (asset == "USD") {
                    grad = AppColors.electricGradient;
                  } else {
                    grad = const LinearGradient(colors: [Colors.purple, Colors.deepPurple]);
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: grad,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(asset, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                      subtitle: const Text("Actif numérique", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      trailing: Text(
                        formatCurrency(bal, asset),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Analytics Section
              const Text("Répartition du Portefeuille", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              SizedBox(
                height: 160,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 40,
                    sections: totalBalance == 0
                        ? [
                            PieChartSectionData(
                              value: 1,
                              color: AppColors.darkBorder,
                              title: "0",
                              radius: 42,
                              titleStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ]
                        : appState.balances.entries.map((entry) {
                            final color = entry.key == "XOF"
                                ? AppColors.primary
                                : entry.key == "USD"
                                    ? AppColors.secondary
                                    : entry.key == "PAPO"
                                        ? AppColors.accent
                                        : Colors.purple;
                            return PieChartSectionData(
                              value: entry.value.abs(),
                              color: color,
                              title: entry.key,
                              radius: 44,
                              titleStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Add Contract Token Simulator Button
              CustomButton(
                text: "+ Importer un token personnalisé",
                isPrimary: false,
                onPressed: () {
                  // Simulate adding token
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Importer un Token"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CustomInput(label: "Adresse du Smart Contract", hint: "0x..."),
                          const SizedBox(height: 12),
                          const CustomInput(label: "Symbole du Token", hint: "ex: WOF"),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
                        TextButton(
                          onPressed: () {
                            appState.balances['PAPO_TEST'] = 100;
                            appState.addNotification("Token importé", "Le token customisé PAPO_TEST a été importé.", "success");
                            Navigator.pop(context);
                          },
                          child: const Text("Importer"),
                        )
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. SEND MONEY SCREEN
// ==========================================
class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _nfcService = NfcService();
  final _scannerController = MobileScannerController();
  String _selectedAsset = "XOF";
  bool _scanningQR = false;

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _applyQrPayload(String rawValue) {
    if (!rawValue.startsWith('papo:')) {
      _recipientController.text = rawValue;
      return;
    }

    final payload = rawValue.substring(5);
    final uri = Uri.tryParse(payload);
    if (uri == null) {
      _recipientController.text = rawValue;
      return;
    }

    _recipientController.text = uri.path.isEmpty ? rawValue : uri.path;
    final qrAsset = uri.queryParameters['asset'];
    final qrAmount = uri.queryParameters['amount'];

    if (qrAsset != null && qrAsset.isNotEmpty) {
      _selectedAsset = qrAsset;
    }
    if (qrAmount != null && qrAmount.isNotEmpty) {
      _amountController.text = qrAmount;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_scanningQR) {
      return Scaffold(
        drawer: const ScreenExplorer(),
        appBar: AppBar(title: const Text("Scan QR Code")),
        body: Stack(
          children: [
            MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                final barcode =
                    capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
                final rawValue = barcode?.rawValue;
                if (rawValue == null || !_scanningQR) {
                  return;
                }
                setState(() {
                  _applyQrPayload(rawValue);
                  _scanningQR = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("QR détecté avec succès.")),
                );
              },
            ),
            Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const Positioned(
              top: 32,
              left: 24,
              right: 24,
              child: Text(
                "Cadrez un QR PAYPOINT/PAPO pour remplir automatiquement le destinataire.",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: CustomButton(
                text: "Annuler",
                isPrimary: false,
                onPressed: () {
                  setState(() {
                    _scanningQR = false;
                  });
                },
              ),
            )
          ],
        ),
      );
    }

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(title: const Text("Envoyer des fonds")),
      bottomNavigationBar: buildBottomNavBar(context, 2),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // QR / NFC shortcuts
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: "Scanner QR",
                      icon: const Icon(LucideIcons.scan, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _scanningQR = true;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: "Contact NFC",
                      isPrimary: false,
                      icon: const Icon(LucideIcons.contact, color: AppColors.primary),
                      onPressed: () {
                        // Simulate NFC
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => Container(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.contact, size: 64, color: AppColors.primary),
                                const SizedBox(height: 16),
                                const Text("Approchez votre téléphone d'un appareil", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 24),
                                CustomButton(
                                  text: "Appairer via NFC",
                                  onPressed: () async {
                                    try {
                                      final peerId = await _nfcService.pairAndGetPeerId();
                                      if (!mounted) return;
                                      setState(() {
                                        _recipientController.text = peerId;
                                      });
                                      await appState.addPairedDevice(peerId: peerId, alias: 'Contact NFC ${peerId.substring(0, peerId.length > 6 ? 6 : peerId.length)}');
                                      if (!context.mounted) return;
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Appareil appairé: $peerId')),
                                      );
                                    } catch (_) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('NFC indisponible, saisissez le destinataire manuellement.')),
                                      );
                                      setState(() {
                                        _recipientController.text = "";
                                      });
                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
              
              // Recipient Form
              CustomInput(
                label: "Destinataire",
                hint: "Saisissez un numéro de téléphone ou une adresse",
                controller: _recipientController,
                prefixIcon: LucideIcons.search,
              ),
              const SizedBox(height: 20),
              
              // Asset Picker
              const Text("Devise à envoyer", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAsset,
                    isExpanded: true,
                    onChanged: (val) {
                      setState(() {
                        _selectedAsset = val!;
                      });
                    },
                    items: appState.balances.keys.map((String key) {
                      return DropdownMenuItem<String>(
                        value: key,
                        child: Text("$key (Solde: ${appState.balances[key]})"),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Amount Form
              CustomInput(
                label: "Montant",
                hint: "0",
                controller: _amountController,
                keyboardType: TextInputType.number,
                prefixIcon: LucideIcons.circleDollarSign,
              ),
              const SizedBox(height: 32),
              
              CustomButton(
                text: "Confirmer le transfert",
                onPressed: () {
                  final amount = double.tryParse(_amountController.text) ?? 0;
                  final recipient = _recipientController.text.trim();
                  if (amount <= 0 || recipient.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Veuillez remplir correctement les champs")),
                    );
                    return;
                  }

                  final success = appState.sendMoney(recipient, amount, _selectedAsset);
                  if (success) {
                    _amountController.clear();
                    _recipientController.clear();
                    appState.setScreen("Dashboard");
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Solde insuffisant")),
                    );
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

// ==========================================
// 4. RECEIVE MONEY SCREEN
// ==========================================
class ReceiveMoneyScreen extends StatefulWidget {
  const ReceiveMoneyScreen({super.key});

  @override
  State<ReceiveMoneyScreen> createState() => _ReceiveMoneyScreenState();
}

class _ReceiveMoneyScreenState extends State<ReceiveMoneyScreen> {
  final _amountController = TextEditingController();
  final _nfcService = NfcService();
  String _selectedAsset = "XOF";

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Generate dynamic QR Code content containing details
    final amountText = _amountController.text.trim();
    final qrData = "papo:${appState.walletAddress}?asset=$_selectedAsset" + 
        (amountText.isNotEmpty ? "&amount=$amountText" : "");

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(title: const Text("Recevoir des fonds")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Card containing QR Code
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      "Votre Code QR de Réception",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    
                    // QR Render
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 200.0,
                        gapless: false,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      appState.walletAddress,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: "Copier mon adresse",
                      isPrimary: false,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: appState.walletAddress));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Adresse copiée")),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Inputs to customize QR code amount
              CustomInput(
                label: "Personnaliser le montant",
                hint: "Entrez le montant désiré",
                controller: _amountController,
                keyboardType: TextInputType.number,
                prefixIcon: LucideIcons.circleDollarSign,
                onChanged: (_) {
                  setState(() {}); // refresh QR
                },
              ),
              const SizedBox(height: 20),
              
              CustomButton(
                text: "Partager ma demande de paiement",
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Demande partagée")),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // Simulate NFC receive
              CustomButton(
                text: "Recevoir via NFC",
                isPrimary: false,
                icon: const Icon(LucideIcons.contact, color: AppColors.primary),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.contact, size: 64, color: AppColors.primary),
                          const SizedBox(height: 16),
                          const Text("Prêt à recevoir", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          const Text("Approchez l'autre téléphone avec NFC actif"),
                          const SizedBox(height: 24),
                          CustomButton(
                            text: "Recevoir maintenant",
                            onPressed: () async {
                              try {
                                await _nfcService.readIncomingPaymentRequest();
                              } catch (_) {}
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Canal NFC prêt. Attendez l'envoi réel du payeur."),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 5. TRANSACTION HISTORY SCREEN
// ==========================================
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _activeFilter = "all"; // 'all', 'send', 'receive', 'offline'
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filtered transaction list
    final filteredTxs = appState.transactions.where((tx) {
      final searchVal = _searchController.text.toLowerCase();
      final matchesSearch = tx.title.toLowerCase().contains(searchVal) || 
                            tx.description.toLowerCase().contains(searchVal) ||
                            tx.id.toLowerCase().contains(searchVal);
      
      if (!matchesSearch) return false;
      if (_activeFilter == "all") return true;
      return tx.type == _activeFilter;
    }).toList();

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(title: const Text("Historique")),
      bottomNavigationBar: buildBottomNavBar(context, 3),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Input
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Rechercher une transaction...",
                prefixIcon: Icon(LucideIcons.search),
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
            
            // Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterTab("all", "Tout"),
                  _filterTab("send", "Envoyé"),
                  _filterTab("receive", "Reçu"),
                  _filterTab("offline", "Offline"),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Transactions list
            Expanded(
              child: filteredTxs.isEmpty
                  ? const Center(child: Text("Aucune transaction trouvée"))
                  : ListView.builder(
                      itemCount: filteredTxs.length,
                      itemBuilder: (context, index) {
                        final tx = filteredTxs[index];
                        return _buildTransactionItem(context, tx);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterTab(String type, String label) {
    final isSelected = _activeFilter == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _activeFilter = type;
            });
          }
        },
        selectedColor: AppColors.primary.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
