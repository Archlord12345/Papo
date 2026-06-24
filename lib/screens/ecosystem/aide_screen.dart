import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_colors.dart';

class AideScreen extends StatefulWidget {
  const AideScreen({super.key});
  @override
  State<AideScreen> createState() => _AideScreenState();
}

class _AideScreenState extends State<AideScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMsg> _messages = [
    _ChatMsg(agent: true, text: 'Bonjour ! Je suis Awa 👋, votre assistante PAYPOINT. Comment puis-je vous aider ?'),
  ];

  static const _faq = [
    _Faq('Quelles sont mes limites de transaction ?',
        'Sans KYC : 50 000 XOF/jour. Avec KYC vérifié : 2 000 000 XOF/jour.'),
    _Faq('Le paiement hors ligne est-il sécurisé ?',
        'Oui. Chaque transaction est signée cryptographiquement localement puis ancrée sur la blockchain lors de la synchronisation.'),
    _Faq('Comment recharger mon compte ?',
        'Allez dans Portefeuille > Déposer des fonds. Plusieurs méthodes : Mobile Money, Virement bancaire, PAPO Tokens.'),
    _Faq('Comment contacter le support ?',
        'Via ce chat ou par WhatsApp au +225 07 00 00 00 00 (lun-ven 8h-18h).'),
  ];

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMsg(agent: false, text: text));
      _ctrl.clear();
    });

    // Auto reply after delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMsg(
          agent: true,
          text: 'Merci pour votre question. Un agent va vous répondre dans quelques instants. En attendant, consultez notre FAQ ci-dessous.',
        ));
      });
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Support & Aide'), backgroundColor: Colors.transparent, elevation: 0),
      body: Column(
        children: [
          // Quick action bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? AppColors.darkSurface : Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () {},
                    icon: const Icon(LucideIcons.phoneCall, size: 15),
                    label: const Text('WhatsApp', style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () => _showFaq(context),
                    icon: const Icon(LucideIcons.helpCircle, size: 15),
                    label: const Text('FAQ', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),

          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) => _ChatBubble(msg: _messages[i]),
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Saisissez votre message...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: IconButton(icon: const Icon(LucideIcons.send, color: Colors.white, size: 18), onPressed: _send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFaq(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (_, ctrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Foire Aux Questions', style: Theme.of(context).textTheme.titleLarge),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _faq.map((f) => ExpansionTile(
                  title: Text(f.question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  children: [Padding(padding: const EdgeInsets.all(12), child: Text(f.answer, style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.5)))],
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMsg {
  final bool agent;
  final String text;
  const _ChatMsg({required this.agent, required this.text});
}

class _Faq {
  final String question;
  final String answer;
  const _Faq(this.question, this.answer);
}

class _ChatBubble extends StatelessWidget {
  final _ChatMsg msg;
  const _ChatBubble({required this.msg});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: msg.agent ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: msg.agent ? (isDark ? AppColors.darkSurface : Colors.grey.shade100) : AppColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: msg.agent ? Radius.zero : const Radius.circular(16),
            bottomRight: msg.agent ? const Radius.circular(16) : Radius.zero,
          ),
          border: msg.agent ? Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade300) : null,
        ),
        child: Text(msg.text, style: TextStyle(color: msg.agent ? null : Colors.white, fontSize: 13, height: 1.4)),
      ),
    );
  }
}
