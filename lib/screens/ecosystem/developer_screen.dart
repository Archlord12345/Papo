import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';

class DeveloperScreen extends StatefulWidget {
  const DeveloperScreen({super.key});
  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen> {
  bool _sandbox = true;
  String _apiKey = '';
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _apiKey = 'pk_sandbox_${const Uuid().v4().substring(0, 16)}';
  }

  void _regen() {
    setState(() {
      final prefix = _sandbox ? 'pk_sandbox_' : 'pk_live_';
      _apiKey = '$prefix${const Uuid().v4().substring(0, 16)}';
    });
  }

  void _runTest() {
    setState(() {
      _logs.insert(0, '[${DateTime.now().toIso8601String().substring(11, 19)}] POST /v1/payments — 200 OK — {"status":"success","id":"tx_demo"}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Portail Développeur'), backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sandbox toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _sandbox ? AppColors.warning.withOpacity(0.3) : AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_sandbox ? 'Mode Sandbox (Test)' : 'Mode Production (Live)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: _sandbox ? AppColors.warning : AppColors.success)),
                      Text(_sandbox ? 'Données de test, aucun paiement réel.' : 'Paiements réels activés.',
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Switch(value: !_sandbox, onChanged: (v) => setState(() => _sandbox = !v), activeColor: AppColors.success),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // API Key
            _SectionTitle('Clé API'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: isDark ? AppColors.darkBg : Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_apiKey, style: const TextStyle(fontFamily: 'monospace', fontSize: 12), overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(LucideIcons.copy, size: 16, color: AppColors.primary), onPressed: () {
                    Clipboard.setData(ClipboardData(text: _apiKey));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clé API copiée'), duration: Duration(seconds: 1)));
                  }),
                  IconButton(icon: const Icon(LucideIcons.refreshCw, size: 16, color: Colors.grey), onPressed: _regen),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick endpoint reference
            _SectionTitle('Endpoints REST'),
            _EndpointCard('POST', '/v1/payments/initiate', 'Initier un paiement'),
            _EndpointCard('GET', '/v1/payments/{id}', 'Statut d\'une transaction'),
            _EndpointCard('POST', '/v1/webhooks/register', 'Enregistrer un webhook'),
            _EndpointCard('GET', '/v1/wallets/balance', 'Consulter les soldes'),
            const SizedBox(height: 20),

            // Debug console
            _SectionTitle('Console de Débogage'),
            GestureDetector(
              onTap: _runTest,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: isDark ? Colors.black : Colors.grey.shade900, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('> Terminal', style: TextStyle(color: AppColors.primary, fontFamily: 'monospace', fontSize: 12)),
                        GestureDetector(
                          onTap: () => setState(() => _logs.clear()),
                          child: const Text('Effacer', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._logs.take(5).map((l) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(l, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 10)),
                    )),
                    if (_logs.isEmpty)
                      const Text('// Appuyez ici pour tester une requête', style: TextStyle(color: Colors.grey, fontFamily: 'monospace', fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.primary)),
    );
  }
}

class _EndpointCard extends StatelessWidget {
  final String method;
  final String path;
  final String desc;
  const _EndpointCard(this.method, this.path, this.desc);
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color methodColor;
    switch (method) {
      case 'POST': methodColor = Colors.orange; break;
      case 'DELETE': methodColor = AppColors.danger; break;
      default: methodColor = AppColors.success;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: methodColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
            child: Text(method, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: methodColor)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(path, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ])),
        ],
      ),
    );
  }
}
