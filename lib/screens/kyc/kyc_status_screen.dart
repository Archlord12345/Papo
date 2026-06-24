import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_button.dart';

class KYCStatusScreen extends StatelessWidget {
  const KYCStatusScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Statut KYC'), backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildCard(context, appState),
            const SizedBox(height: 24),
            if (appState.kycStatus != 'none')
              _StepsTimeline(status: appState.kycStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, AppState appState) {
    switch (appState.kycStatus) {
      case 'pending':
        return GlassCard(
          borderColor: AppColors.warning.withOpacity(0.3),
          child: _StatusContent(
            icon: LucideIcons.clock,
            color: AppColors.warning,
            title: 'Dossier en cours d\'examen',
            desc: 'Nos agents analysent vos pièces. Délai habituel : moins de 24h.',
            children: [
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: CustomButton(text: 'Approuver (Admin)', onPressed: () => appState.approveKYC())),
                const SizedBox(width: 10),
                Expanded(child: CustomButton(text: 'Rejeter (Admin)', isPrimary: false, onPressed: () => appState.rejectKYC())),
              ]),
            ],
          ),
        );
      case 'verified':
        return GlassCard(
          borderColor: AppColors.success.withOpacity(0.3),
          child: _StatusContent(
            icon: LucideIcons.checkCircle,
            color: AppColors.success,
            title: 'Compte Vérifié ✓',
            desc: 'Félicitations ! Votre identité a été approuvée. Toutes vos limites sont débloquées.',
            children: [
              const SizedBox(height: 16),
              CustomButton(text: 'Retour à l\'accueil', onPressed: () => appState.setScreen('Dashboard')),
            ],
          ),
        );
      case 'rejected':
        return GlassCard(
          borderColor: AppColors.danger.withOpacity(0.3),
          child: _StatusContent(
            icon: LucideIcons.xCircle,
            color: AppColors.danger,
            title: 'Dossier Rejeté',
            desc: 'Vos documents ne satisfaisaient pas nos critères. Soumettez une pièce valide.',
            children: [
              const SizedBox(height: 16),
              CustomButton(text: 'Recommencer', onPressed: () => appState.resetKYC()),
            ],
          ),
        );
      default: // none
        return GlassCard(
          child: _StatusContent(
            icon: LucideIcons.alertTriangle,
            color: AppColors.accent,
            title: 'Vérification requise',
            desc: 'Vérifiez votre identité pour débloquer les limites de transaction.',
            children: [
              const SizedBox(height: 16),
              CustomButton(text: 'Vérifier avec CNI', onPressed: () => appState.setScreen('UploadCNI')),
              const SizedBox(height: 10),
              CustomButton(text: 'Vérifier avec Passeport', isPrimary: false, onPressed: () => appState.setScreen('UploadPassport')),
            ],
          ),
        );
    }
  }
}

class _StatusContent extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  final List<Widget> children;
  const _StatusContent({required this.icon, required this.color, required this.title, required this.desc, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 56, color: color),
        const SizedBox(height: 16),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5)),
        ...children,
      ],
    );
  }
}

class _StepsTimeline extends StatelessWidget {
  final String status;
  const _StepsTimeline({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _Step('Documents soumis', status != 'none'),
      _Step('Vérification en cours', status == 'pending' || status == 'verified' || status == 'rejected'),
      _Step('Identité validée', status == 'verified'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Étapes KYC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...steps.map((s) => _StepRow(step: s, isLast: steps.last == s)),
      ],
    );
  }
}

class _Step { final String label; final bool done; const _Step(this.label, this.done); }

class _StepRow extends StatelessWidget {
  final _Step step;
  final bool isLast;
  const _StepRow({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: step.done ? AppColors.success : Colors.grey.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(step.done ? LucideIcons.check : LucideIcons.circle, size: 12, color: Colors.white),
            ),
            if (!isLast) Container(width: 2, height: 32, color: step.done ? AppColors.success.withOpacity(0.3) : Colors.grey.withOpacity(0.2)),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(step.label, style: TextStyle(fontWeight: step.done ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
        ),
      ],
    );
  }
}
