import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';
import '../widgets/screen_explorer.dart';
import 'main_screens.dart';

// ==========================================
// 1. MENU SCREEN (MATCHING SCREENSHOT 5)
// ==========================================
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Grid items for "Plus" section
    final List<Map<String, dynamic>> menuItems = [
      {'title': 'Accueil', 'icon': LucideIcons.home, 'screen': 'Dashboard'},
      {'title': 'Portefeuille', 'icon': LucideIcons.wallet, 'screen': 'Wallet'},
      {'title': 'Blockchain', 'icon': LucideIcons.link, 'screen': 'Blockchain'},
      {'title': 'KYC', 'icon': LucideIcons.contact, 'screen': 'KYCStatus'},
      {'title': 'Profil', 'icon': LucideIcons.user, 'screen': 'Profile'},
      {'title': 'Cercle', 'icon': LucideIcons.shield, 'screen': 'Circle'},
      {'title': 'Aide', 'icon': LucideIcons.phone, 'screen': 'Aide'},
      {'title': 'Développeur', 'icon': LucideIcons.terminal, 'screen': 'Developer'},
    ];

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.menu, color: AppColors.secondary),
            SizedBox(width: 8),
            Text("Menu", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.chevronDown),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Language selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.globe, color: Colors.blueGrey),
                      const SizedBox(width: 12),
                      Text(
                        appState.language == 'fr' ? "Langue" : "Language",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  DropdownButton<String>(
                    value: appState.language,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: 'fr',
                        child: Text("Français 🇫🇷", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      DropdownMenuItem(
                        value: 'en',
                        child: Text("English 🇬🇧", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                    onChanged: (lang) {
                      if (lang != null) appState.changeLanguage(lang);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Recently Visited Section
              Text(
                appState.language == 'fr' ? "Récemment visité" : "Recently visited",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: appState.recentlyVisited.isEmpty
                    ? Center(
                        child: Text(
                          appState.language == 'fr' ? "Aucun historique de visite" : "No visit history",
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: appState.recentlyVisited.length,
                        itemBuilder: (context, index) {
                          final visited = appState.recentlyVisited[index];
                          // Match visited to icon
                          IconData visitedIcon = LucideIcons.globe;
                          String label = visited;
                          String screenToGo = "Dashboard";

                          if (visited == 'Dashboard') {
                            visitedIcon = LucideIcons.home;
                            label = appState.language == 'fr' ? 'Accueil' : 'Home';
                            screenToGo = 'Dashboard';
                          } else if (visited == 'Wallet') {
                            visitedIcon = LucideIcons.wallet;
                            label = appState.language == 'fr' ? 'Portefeuille' : 'Wallet';
                            screenToGo = 'Wallet';
                          } else if (visited == 'Circle') {
                            visitedIcon = LucideIcons.shield;
                            label = appState.language == 'fr' ? 'Cercle' : 'Circle';
                            screenToGo = 'Circle';
                          } else if (visited == 'Developer') {
                            visitedIcon = LucideIcons.terminal;
                            label = appState.language == 'fr' ? 'Développeur' : 'Developer';
                            screenToGo = 'Developer';
                          }

                          return GestureDetector(
                            onTap: () => appState.setScreen(screenToGo),
                            child: Container(
                              width: 90,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(visitedIcon, color: AppColors.secondary, size: 28),
                                  const SizedBox(height: 8),
                                  Text(
                                    label,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 28),

              // 3. Plus Grid Section
              Text(
                appState.language == 'fr' ? "Plus" : "More",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.95,
                ),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return GestureDetector(
                    onTap: () => appState.setScreen(item['screen']),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(item['icon'], color: AppColors.secondary, size: 26),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['title'],
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextButton.icon(
              onPressed: () => appState.setScreen("Dashboard"),
              icon: const Icon(LucideIcons.home, color: AppColors.primary),
              label: Text(
                appState.language == 'fr' ? "Accueil" : "Home",
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            VerticalDivider(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              indent: 16,
              endIndent: 16,
            ),
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      appState.language == 'fr'
                          ? "Lien de parrainage copié !"
                          : "Referral link copied!",
                    ),
                  ),
                );
              },
              icon: const Icon(LucideIcons.share2, color: Colors.blueGrey),
              label: Text(
                appState.language == 'fr' ? "Partager" : "Share",
                style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. CERCLE DE CONFIANCE (TONTINE) SCREEN
// ==========================================
class CircleScreen extends StatefulWidget {
  const CircleScreen({super.key});

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> {
  double _cercleCollected = 300000;
  final double _cercleTarget = 500000;
  bool _hasContributed = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(
        title: const Text("Cercle de Confiance (Tontine)"),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.helpCircle),
            onPressed: () => appState.setScreen("Aide"),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Info Card
              GlassCard(
                borderColor: AppColors.secondary.withOpacity(0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "TONTINE FAMILIALE DIALLO",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondary, letterSpacing: 1.2),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "Votre tour : Ce mois",
                            style: TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Collecté ce cycle", style: TextStyle(color: Colors.grey, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(
                              formatCurrency(_cercleCollected, 'XOF'),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("Objectif mensuel", style: TextStyle(color: Colors.grey, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(
                              formatCurrency(_cercleTarget, 'XOF'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _cercleCollected / _cercleTarget,
                        minHeight: 8,
                        backgroundColor: isDark ? AppColors.darkBorder : Colors.grey.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${((_cercleCollected / _cercleTarget) * 100).toInt()}% complété",
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        const Text("3/5 membres ont versé", style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action button to contribute
              if (!_hasContributed)
                CustomButton(
                  text: "Verser ma contribution (100 000 XOF)",
                  gradient: AppColors.electricGradient,
                  onPressed: () {
                    if (appState.balances['XOF']! >= 100000) {
                      appState.balances['XOF'] = appState.balances['XOF']! - 100000;
                      appState.transactions.insert(
                        0,
                        Transaction(
                          id: "TON-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}",
                          title: "Contribution Tontine Diallo",
                          amount: -100000,
                          asset: "XOF",
                          type: "send",
                          timestamp: DateTime.now(),
                          status: "completed",
                          description: "Versement mensuel du cercle de confiance",
                        ),
                      );
                      appState.addNotification(
                        "Tontine versée",
                        "Votre versement de 100,000 XOF a été partagé avec succès dans le cercle.",
                        "success",
                      );
                      setState(() {
                        _cercleCollected += 100000;
                        _hasContributed = true;
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Solde insuffisant pour cotiser.")),
                      );
                    }
                  },
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.checkCircle, color: AppColors.success),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Vous avez versé votre cotisation pour ce cycle. Merci !",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 28),
              const Text("Membres du Cercle", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildMemberRow("${appState.userName} (Vous)", "Payé le 22/05", true, isDark),
                  _buildMemberRow("Fatou Sy", "Payé le 20/05", true, isDark),
                  _buildMemberRow("Kouassi Yao", "Payé le 19/05", true, isDark),
                  _buildMemberRow("Awa Diop", "En attente", false, isDark),
                  _buildMemberRow("Ousmane Koné", "En attente", false, isDark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberRow(String name, String status, bool paid, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: paid ? AppColors.success.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          child: Icon(LucideIcons.user, color: paid ? AppColors.success : Colors.grey, size: 20),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(status, style: TextStyle(color: paid ? AppColors.success : Colors.grey, fontSize: 11)),
        trailing: Icon(
          paid ? LucideIcons.check : LucideIcons.clock,
          color: paid ? AppColors.success : Colors.orange,
          size: 18,
        ),
      ),
    );
  }
}

// ==========================================
// 3. SUPPORT & AIDE SCREEN
// ==========================================
class AideScreen extends StatefulWidget {
  const AideScreen({super.key});

  @override
  State<AideScreen> createState() => _AideScreenState();
}

class _AideScreenState extends State<AideScreen> {
  final TextEditingController _msgController = TextEditingController();
  final List<Map<String, dynamic>> _chatLogs = [
    {
      'sender': 'agent',
      'text': 'Bonjour ! Je suis Awa, votre assistante virtuelle PAYPOINT. Comment puis-je vous aider ?',
      'time': '12:00'
    }
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(title: const Text("Support & Aide")),
      body: Column(
        children: [
          // Quick Support Buttons
          Container(
            padding: const EdgeInsets.all(12),
            color: isDark ? AppColors.darkSurface : Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {},
                    icon: const Icon(LucideIcons.phoneCall, size: 16),
                    label: const Text("WhatsApp Support", style: TextStyle(fontSize: 10)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      _showFaqDialog(context);
                    },
                    icon: const Icon(LucideIcons.helpCircle, size: 16),
                    label: const Text("Foire Aux Questions", style: TextStyle(fontSize: 10)),
                  ),
                ),
              ],
            ),
          ),

          // Message log
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _chatLogs.length,
              itemBuilder: (context, index) {
                final chat = _chatLogs[index];
                final isAgent = chat['sender'] == 'agent';
                return Align(
                  alignment: isAgent ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isAgent
                          ? (isDark ? AppColors.darkSurface : Colors.grey.shade100)
                          : AppColors.primary,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isAgent ? Radius.zero : const Radius.circular(16),
                        bottomRight: isAgent ? const Radius.circular(16) : Radius.zero,
                      ),
                      border: isAgent
                          ? Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade300)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chat['text'],
                          style: TextStyle(
                            color: isAgent ? (isDark ? Colors.white : Colors.black87) : Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            chat['time'],
                            style: TextStyle(
                              fontSize: 9,
                              color: isAgent ? Colors.grey : Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Saisie message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(
                top: BorderSide(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: "Saisissez votre question...",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      fillColor: isDark ? AppColors.darkBg : Colors.grey.shade50,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  color: AppColors.primary,
                  icon: const Icon(LucideIcons.send),
                  onPressed: () {
                    final text = _msgController.text.trim();
                    if (text.isEmpty) return;
                    setState(() {
                      _chatLogs.add({'sender': 'user', 'text': text, 'time': 'A l\'instant'});
                      _msgController.clear();
                    });

                    // Auto-reply
                    Future.delayed(const Duration(seconds: 1), () {
                      setState(() {
                        _chatLogs.add({
                          'sender': 'agent',
                          'text':
                              "J'ai bien reçu votre demande concernant : '$text'. Un agent de support va vous répondre dans un instant.",
                          'time': 'A l\'instant'
                        });
                      });
                    });
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showFaqDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Foire Aux Questions"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: const [
                ExpansionTile(
                  title: Text("Quelles sont les limites de mon compte ?", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Sans KYC, votre limite quotidienne est de 50 000 XOF. Une fois vérifié, la limite passe à 2 000 000 XOF/jour.",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                ExpansionTile(
                  title: Text("Le paiement hors ligne est-il sûr ?", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Oui, il utilise une signature cryptographique locale ancrée dans le matériel. La transaction est validée dès que l'un des téléphones retrouve du réseau.",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                ExpansionTile(
                  title: Text("Quels sont les frais de transfert ?", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Les transferts nationaux et intracommunautaires sont à 1% de frais. Les airdrops et retraits marchands sont gratuits.",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fermer"),
            )
          ],
        );
      },
    );
  }
}

// ==========================================
// 4. PORTAIL DEVELOPPEUR SCREEN
// ==========================================
class DeveloperScreen extends StatefulWidget {
  const DeveloperScreen({super.key});

  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen> {
  bool _isSandbox = true;
  bool _showKeys = false;
  String _webhookUrl = "https://api.merchant.ci/v1/callback";
  List<String> _logs = ["Initialisation du Sandbox API..."];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(title: const Text("Portail Développeur")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Intégrations API & Webhooks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      const Text("Sandbox", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Switch(
                        value: _isSandbox,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            _isSandbox = val;
                            _logs.add("Environnement changé en : ${_isSandbox ? 'Sandbox' : 'Production'}");
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // API Keys Card
              GlassCard(
                borderColor: AppColors.primary.withOpacity(0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("CLÉS D'ACCÈS API", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(height: 12),
                    Text(
                      "Clé Publique",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    _buildApiKeyRow(_isSandbox ? "pk_sandbox_papo_71829asdjh21" : "pk_live_papo_90123haskjdha8", false),
                    const SizedBox(height: 12),
                    Text(
                      "Clé Secrète",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    _buildApiKeyRow(
                      _isSandbox ? "sk_sandbox_papo_2819028uioqjdw" : "sk_live_papo_401928091802qwe",
                      true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Webhook Configuration
              const Text("Configuration Webhooks", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                "Définissez l'URL qui recevra les notifications de paiement en temps réel.",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 12),
              CustomInput(
                hint: "https://votre-site.com/webhook",
                prefixIcon: LucideIcons.globe,
                initialValue: _webhookUrl,
                onChanged: (val) => setState(() => _webhookUrl = val),
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: "Tester le Webhook (Ping)",
                isPrimary: false,
                onPressed: () {
                  setState(() {
                    _logs.add("POST ping payload vers : $_webhookUrl");
                    _logs.add("Ping response: 200 OK - {'status': 'active'}");
                  });
                },
              ),
              const SizedBox(height: 24),

              // Console logs
              const Text("Console de débogage", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Text(
                      "> ${_logs[index]}",
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.greenAccent,
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApiKeyRow(String key, bool hideable) {
    final displayKey = (hideable && !_showKeys) ? "•••••••••••••••••••••••••••••" : key;
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              displayKey,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (hideable)
          IconButton(
            icon: Icon(_showKeys ? LucideIcons.eyeOff : LucideIcons.eye, size: 18),
            onPressed: () => setState(() => _showKeys = !_showKeys),
          ),
        IconButton(
          icon: const Icon(LucideIcons.copy, size: 18),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Clé API copiée !")),
            );
          },
        ),
      ],
    );
  }
}

// ==========================================
// 5. EXPLORATEUR DE L'ÉCOSYSTÈME SCREEN
// ==========================================
class EcosystemScreen extends StatelessWidget {
  const EcosystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, dynamic>> utilities = [
      {'name': 'CIE Électricité', 'category': 'Factures', 'icon': LucideIcons.zap},
      {'name': 'SODECI Eaux', 'category': 'Factures', 'icon': LucideIcons.droplet},
      {'name': 'Canal+ Côte d\'Ivoire', 'category': 'TV / Internet', 'icon': LucideIcons.tv},
      {'name': 'Orange CI Internet', 'category': 'TV / Internet', 'icon': LucideIcons.wifi},
    ];

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(title: const Text("Écosystème & Services")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search input
              CustomInput(
                hint: "Rechercher un marchand ou service...",
                prefixIcon: LucideIcons.search,
              ),
              const SizedBox(height: 24),

              // Categories Header
              const Text("Factures & Services Publics", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: utilities.length,
                itemBuilder: (context, index) {
                  final service = utilities[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Icon(service['icon'], color: AppColors.primary, size: 20),
                      ),
                      title: Text(service['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(service['category'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      trailing: const Icon(LucideIcons.chevronRight, size: 16),
                      onTap: () {
                        _showPaymentInvoiceSheet(context, appState, service['name']);
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Web3 DApps section
              const Text("Applications Décentralisées (Web3)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDappCard(
                      context,
                      "DeFi Staking",
                      "Épargnez vos crypto-monnaies à haut rendement.",
                      LucideIcons.trendingUp,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDappCard(
                      context,
                      "Airdrops PAPO",
                      "Réclamez vos récompenses de transactions.",
                      LucideIcons.gift,
                      AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDappCard(BuildContext context, String name, String desc, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  void _showPaymentInvoiceSheet(BuildContext context, AppState appState, String serviceName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        double invoiceAmount = 14500;
        String invoiceNum = "CIE-9988102";

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Paiement de facture : $serviceName",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text("Référence Facture", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(
                invoiceNum,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text("Montant Facture", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(
                formatCurrency(invoiceAmount, 'XOF'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: "Confirmer le paiement",
                onPressed: () {
                  if (appState.balances['XOF']! >= invoiceAmount) {
                    appState.balances['XOF'] = appState.balances['XOF']! - invoiceAmount;
                    appState.transactions.insert(
                      0,
                      Transaction(
                        id: "FAC-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}",
                        title: "Facture $serviceName",
                        amount: -invoiceAmount,
                        asset: "XOF",
                        type: "send",
                        timestamp: DateTime.now(),
                        status: "completed",
                        description: "Règlement de facture via écosystème PAPO",
                      ),
                    );
                    appState.addNotification(
                      "Paiement de Facture",
                      "Votre facture $serviceName de $invoiceAmount XOF a été réglée.",
                      "success",
                    );
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Solde insuffisant.")),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// 6. PROFIL UTILISATEUR SCREEN
// ==========================================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // KYC badge config
    final kycBadgeColor = appState.kycStatus == 'verified'
        ? AppColors.success
        : appState.kycStatus == 'pending'
            ? AppColors.warning
            : appState.kycStatus == 'rejected'
                ? AppColors.danger
                : Colors.grey;
    final kycLabel = appState.kycStatus == 'verified'
        ? 'Vérifié ✓'
        : appState.kycStatus == 'pending'
            ? 'En attente'
            : appState.kycStatus == 'rejected'
                ? 'Rejeté'
                : 'Non vérifié';

    final double maxLimit = appState.kycStatus == 'verified' ? 2000000 : 500000;
    final double used = appState.balances['XOF'] != null ? (maxLimit - appState.balances['XOF']!).clamp(0, maxLimit) : 0;
    final double limitProgress = used / maxLimit;

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(
        title: const Text("Mon Profil"),
        actions: [
          IconButton(
            icon: SvgPicture.asset('assets/svg/settings.svg', width: 24, height: 24, colorFilter: ColorFilter.mode(isDark ? Colors.white : Colors.black, BlendMode.srcIn)),
            onPressed: () => appState.setScreen("SecuritySettings"),
            tooltip: "Sécurité",
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header gradient banner ──────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              decoration: BoxDecoration(
                gradient: isDark ? AppColors.darkCardGradient : AppColors.primaryGradient,
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          appState.avatarInitials,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Modifier la photo (bientôt disponible)")),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(LucideIcons.camera, size: 14, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(appState.userName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(appState.userPhone, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 12),
                  // KYC badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: kycBadgeColor.withOpacity(0.15),
                      border: Border.all(color: kycBadgeColor.withOpacity(0.6)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.shieldCheck, size: 13, color: kycBadgeColor),
                        const SizedBox(width: 6),
                        Text(
                          "KYC : $kycLabel",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kycBadgeColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Account stats ──────────────────────────────
                  Row(
                    children: [
                      _statChip(context, "${appState.transactions.length}", "Transactions", LucideIcons.activity, AppColors.primary),
                      const SizedBox(width: 12),
                      _statChip(context, appState.kycStatus == 'verified' ? '2M XOF' : '500K XOF', "Limite / jour", LucideIcons.trendingUp, AppColors.secondary),
                      const SizedBox(width: 12),
                      _statChip(context, appState.activeDevices.length.toString(), "Appareils", LucideIcons.smartphone, Colors.blueGrey),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Wallet address ─────────────────────────────
                  const Text("Identifiant Wallet", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.link, size: 16, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            appState.walletAddress,
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.copy, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Adresse blockchain copiée !")),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Daily limit tracker ────────────────────────
                  const Text("Limite quotidienne utilisée", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${used.toStringAsFixed(0)} XOF utilisés",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              "Max : ${maxLimit.toStringAsFixed(0)} XOF",
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: limitProgress.clamp(0.0, 1.0),
                            minHeight: 7,
                            backgroundColor: isDark ? AppColors.darkBorder : Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              limitProgress > 0.8 ? AppColors.danger : AppColors.primary,
                            ),
                          ),
                        ),
                        if (appState.kycStatus != 'verified') ...[
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => appState.setScreen("KYCStatus"),
                            child: Row(
                              children: const [
                                Icon(LucideIcons.arrowUpCircle, size: 14, color: AppColors.secondary),
                                SizedBox(width: 6),
                                Text(
                                  "Vérifier mon identité pour augmenter la limite",
                                  style: TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Merchant mode toggle ───────────────────────
                  Card(
                    child: SwitchListTile(
                      secondary: const Icon(LucideIcons.store, color: AppColors.secondary),
                      title: const Text("Mode Marchand", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(
                        appState.isMerchant ? "Actif – Accès au tableau marchand" : "Inactif – Passer en mode commerçant",
                        style: const TextStyle(fontSize: 11),
                      ),
                      value: appState.isMerchant,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        appState.isMerchant = val;
                        appState.notifyListeners();
                        if (val) appState.setScreen("MerchantDashboard");
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Action list ────────────────────────────────
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(LucideIcons.user, color: AppColors.primary),
                          title: const Text("Modifier le profil", style: TextStyle(fontSize: 13)),
                          trailing: const Icon(LucideIcons.chevronRight, size: 16),
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Modification du profil bientôt disponible")),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(LucideIcons.shieldAlert, color: AppColors.primary),
                          title: const Text("Sécurité & PIN", style: TextStyle(fontSize: 13)),
                          trailing: const Icon(LucideIcons.chevronRight, size: 16),
                          onTap: () => appState.setScreen("SecuritySettings"),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(LucideIcons.fileText, color: AppColors.accent),
                          title: const Text("Vérification KYC", style: TextStyle(fontSize: 13)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: kycBadgeColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(kycLabel, style: TextStyle(fontSize: 10, color: kycBadgeColor, fontWeight: FontWeight.bold)),
                          ),
                          onTap: () => appState.setScreen("KYCStatus"),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(LucideIcons.bell, color: Colors.blueGrey),
                          title: const Text("Notifications", style: TextStyle(fontSize: 13)),
                          trailing: const Icon(LucideIcons.chevronRight, size: 16),
                          onTap: () => appState.setScreen("NotificationsList"),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(LucideIcons.logOut, color: AppColors.danger),
                          title: const Text("Déconnexion", style: TextStyle(fontSize: 13, color: AppColors.danger)),
                          onTap: () => appState.logout(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(BuildContext context, String value, String label, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}


// ==========================================
// 7. EXPLORATEUR BLOCKCHAIN SCREEN
// ==========================================
class BlockchainScreen extends StatelessWidget {
  const BlockchainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const ScreenExplorer(),
      appBar: AppBar(title: const Text("Explorateur Blockchain")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Blockchain Stats
              const Text("Statut du réseau PAPO Chain", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _buildStatTile(context, "Dernier Bloc Ancré", "#349,102", LucideIcons.cuboid, AppColors.primary),
                  _buildStatTile(context, "Vitesse de Bloc", "2.1 s", LucideIcons.timer, AppColors.secondary),
                  _buildStatTile(context, "Consensus", "Proof of Authority", LucideIcons.checkSquare, AppColors.success),
                  _buildStatTile(context, "Nodes Valideurs", "12 Actifs", LucideIcons.network, AppColors.accent),
                ],
              ),
              const SizedBox(height: 28),

              // Validating Nodes List
              const Text("Nœuds de validation régionaux", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      _buildNodeRow("Node-01 Abidjan", "Actif", true),
                      const Divider(),
                      _buildNodeRow("Node-02 Dakar", "Actif", true),
                      const Divider(),
                      _buildNodeRow("Node-03 Lomé", "Actif", true),
                      const Divider(),
                      _buildNodeRow("Node-04 Bamako", "En attente", false),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Recent blocks
              const Text("Derniers blocs minés", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildBlockTile("#349102", "0x8fa...21b0", "Il y a 2s", "3 txs", isDark),
              _buildBlockTile("#349101", "0x4fe...9902", "Il y a 4s", "5 txs", isDark),
              _buildBlockTile("#349100", "0x2ab...b12a", "Il y a 6s", "2 txs", isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(BuildContext context, String title, String val, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                Icon(icon, color: color, size: 14),
              ],
            ),
            const SizedBox(height: 4),
            Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeRow(String name, String status, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(LucideIcons.server, size: 16, color: active ? AppColors.success : Colors.grey),
              const SizedBox(width: 8),
              Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          Text(status, style: TextStyle(color: active ? AppColors.success : Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBlockTile(String height, String hash, String time, String txsCount, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Icon(LucideIcons.cuboid, color: Colors.white, size: 18),
        ),
        title: Text("Bloc $height", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        subtitle: Text("Hash: $hash • $time", style: const TextStyle(fontSize: 10, color: Colors.grey)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blueGrey.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            txsCount,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
