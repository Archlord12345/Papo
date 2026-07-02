import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../utils/formatters.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Tabs
// ─────────────────────────────────────────────────────────────────────────────
enum _Tab { stats, kyc, users, disputes }

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  _Tab _tab = _Tab.stats;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final app = context.read<AppState>();
    if (!app.isAdmin) return;
    await Future.wait([
      app.loadAdminStats(),
      app.loadKycQueue(),
      app.loadAdminUsers(),
      app.loadAdminDisputes(),
    ]);
    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (!appState.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Administration'), backgroundColor: Colors.transparent),
        body: const Center(
          child: Text('Accès réservé aux administrateurs.',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: appState.adminLoading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : const Icon(LucideIcons.refreshCw),
            onPressed: _load,
          ),
          IconButton(
            icon: const Icon(LucideIcons.home),
            onPressed: () => appState.setScreen('Dashboard'),
          ),
        ],
      ),
      body: Column(
        children: [
          _TabBar(current: _tab, onTap: (t) => setState(() => _tab = t)),
          Expanded(
            child: !_initialized && appState.adminLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _buildTab(appState),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(AppState appState) {
    switch (_tab) {
      case _Tab.stats:
        return _StatsTab(stats: appState.adminStats, appState: appState);
      case _Tab.kyc:
        return _KycTab(queue: appState.kycQueue, appState: appState, onRefresh: () => appState.loadKycQueue());
      case _Tab.users:
        return _UsersTab(users: appState.adminUsers, appState: appState, onRefresh: () => appState.loadAdminUsers());
      case _Tab.disputes:
        return _DisputesTab(disputes: appState.adminDisputes, appState: appState, onRefresh: () => appState.loadAdminDisputes());
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tab bar
// ─────────────────────────────────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final _Tab current;
  final void Function(_Tab) onTap;
  const _TabBar({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (_Tab.stats,    LucideIcons.barChart2,   'Stats'),
      (_Tab.kyc,      LucideIcons.contact,      'KYC'),
      (_Tab.users,    LucideIcons.users,        'Users'),
      (_Tab.disputes, LucideIcons.alertCircle,  'Litiges'),
    ];
    return Container(
      height: 52,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: tabs.map((t) {
          final selected = t.$1 == current;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(t.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t.$2, size: 16,
                        color: selected ? AppColors.primary : Colors.grey),
                    const SizedBox(height: 2),
                    Text(t.$3,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            color: selected ? AppColors.primary : Colors.grey)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Stats Tab
// ─────────────────────────────────────────────────────────────────────────────
class _StatsTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  final AppState appState;
  const _StatsTab({required this.stats, required this.appState});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return _EmptyState(
        icon: LucideIcons.barChart2,
        message: 'Chargement des statistiques...',
        onRetry: () => appState.loadAdminStats(),
      );
    }
    final ov = stats['overview'] as Map<String, dynamic>? ?? {};
    return RefreshIndicator(
      onRefresh: () => appState.loadAdminStats(),
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader('Métriques Globales'),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: [
              _MetricCard('Utilisateurs', '${ov['totalUsers'] ?? 0}', LucideIcons.users, AppColors.primary),
              _MetricCard('Transactions', '${ov['totalTransactions'] ?? 0}', LucideIcons.arrowLeftRight, AppColors.secondary),
              _MetricCard('Marchands', '${ov['totalMerchants'] ?? 0}', LucideIcons.store, AppColors.accent),
              _MetricCard('Agents', '${ov['totalAgents'] ?? 0}', LucideIcons.userCheck, Colors.teal),
              _MetricCard('Volume total',
                  formatAmountAbs((ov['totalVolume'] as num?)?.toDouble() ?? 0, 'XOF'),
                  LucideIcons.circleDollarSign, AppColors.success),
              _MetricCard('Revenus frais',
                  formatAmountAbs((ov['totalRevenue'] as num?)?.toDouble() ?? 0, 'XOF'),
                  LucideIcons.trendingUp, Colors.purple),
              _MetricCard('KYC en attente', '${ov['pendingKyc'] ?? 0}', LucideIcons.clock, AppColors.warning),
              _MetricCard('Litiges ouverts', '${ov['pendingDisputes'] ?? 0}', LucideIcons.alertTriangle, AppColors.danger),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionHeader('Transactions Récentes'),
          if ((stats['recentTransactions'] as List?)?.isEmpty ?? true)
            const _NoneYet(label: 'transaction')
          else
            ...(stats['recentTransactions'] as List).take(10).map((t) {
              final m = t as Map<String, dynamic>;
              final amt = (m['amount'] as num?)?.toDouble() ?? 0;
              final isPos = amt > 0;
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    isPos ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                    color: isPos ? AppColors.success : AppColors.danger,
                    size: 18,
                  ),
                  title: Text(m['title'] as String? ?? '', style: const TextStyle(fontSize: 13)),
                  subtitle: Text((m['user']?['name'] ?? m['user']?['phone'] ?? '') as String,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: Text(
                    formatAmount(amt, 'XOF'),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPos ? AppColors.success : AppColors.danger,
                        fontSize: 13),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  KYC Tab
// ─────────────────────────────────────────────────────────────────────────────
class _KycTab extends StatelessWidget {
  final List<Map<String, dynamic>> queue;
  final AppState appState;
  final VoidCallback onRefresh;
  const _KycTab({required this.queue, required this.appState, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (queue.isEmpty) {
      return _EmptyState(
        icon: LucideIcons.checkSquare,
        message: 'Aucun dossier KYC en attente.',
        onRetry: onRefresh,
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: queue.length,
        itemBuilder: (ctx, i) => _KycCard(review: queue[i], appState: appState),
      ),
    );
  }
}

class _KycCard extends StatefulWidget {
  final Map<String, dynamic> review;
  final AppState appState;
  const _KycCard({required this.review, required this.appState});
  @override
  State<_KycCard> createState() => _KycCardState();
}

class _KycCardState extends State<_KycCard> {
  bool _loading = false;

  Future<void> _approve() async {
    setState(() => _loading = true);
    final ok = await widget.appState.adminApproveKyc(widget.review['id'] as int);
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'KYC approuvé' : 'Erreur lors de l\'approbation'),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
      ));
    }
  }

  Future<void> _reject() async {
    final notesCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rejeter ce dossier KYC'),
        content: TextField(
          controller: notesCtrl,
          decoration: const InputDecoration(
            labelText: 'Motif du rejet (optionnel)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rejeter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _loading = true);
    final ok = await widget.appState.adminRejectKyc(
      widget.review['id'] as int,
      notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
    );
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'KYC rejeté' : 'Erreur'),
        backgroundColor: ok ? AppColors.warning : AppColors.danger,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.review;
    final user = r['user'] as Map<String, dynamic>? ?? {};
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(user['name'] as String? ?? '—',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            _StatusBadge(r['status'] as String? ?? 'PENDING'),
          ]),
          const SizedBox(height: 4),
          Text(user['phone'] as String? ?? '',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          _InfoRow('Type de document', r['docType'] as String? ?? '—'),
          if ((r['docNumber'] as String?)?.isNotEmpty == true)
            _InfoRow('Numéro', r['docNumber'] as String),
          _InfoRow('Soumis', timeAgo(r['createdAt'] as String? ?? '')),
          const SizedBox(height: 12),
          _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : Row(children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      icon: const Icon(LucideIcons.check, size: 16, color: Colors.white),
                      label: const Text('Approuver', style: TextStyle(color: Colors.white)),
                      onPressed: _approve,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      icon: const Icon(LucideIcons.x, size: 16),
                      label: const Text('Rejeter'),
                      onPressed: _reject,
                    ),
                  ),
                ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Users Tab
// ─────────────────────────────────────────────────────────────────────────────
class _UsersTab extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  final AppState appState;
  final VoidCallback onRefresh;
  const _UsersTab({required this.users, required this.appState, required this.onRefresh});
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  String _search = '';
  String? _roleFilter;

  List<Map<String, dynamic>> get _filtered {
    return widget.users.where((u) {
      final name = (u['name'] as String? ?? '').toLowerCase();
      final phone = (u['phone'] as String? ?? '').toLowerCase();
      final q = _search.toLowerCase();
      if (q.isNotEmpty && !name.contains(q) && !phone.contains(q)) return false;
      if (_roleFilter == 'ADMIN' && u['isAdmin'] != true) return false;
      if (_roleFilter == 'MERCHANT' && u['isMerchant'] != true) return false;
      if (_roleFilter == 'AGENT' && u['isAgent'] != true) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.users.isEmpty) {
      return _EmptyState(icon: LucideIcons.users, message: 'Aucun utilisateur trouvé.', onRetry: widget.onRefresh);
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  prefixIcon: const Icon(LucideIcons.search, size: 16),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String?>(
              value: _roleFilter,
              hint: const Text('Rôle', style: TextStyle(fontSize: 12)),
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: null, child: Text('Tous')),
                DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                DropdownMenuItem(value: 'MERCHANT', child: Text('Marchand')),
                DropdownMenuItem(value: 'AGENT', child: Text('Agent')),
              ],
              onChanged: (v) => setState(() => _roleFilter = v),
            ),
          ]),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => widget.onRefresh(),
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) => _UserCard(user: _filtered[i], appState: widget.appState),
            ),
          ),
        ),
      ],
    );
  }
}

class _UserCard extends StatefulWidget {
  final Map<String, dynamic> user;
  final AppState appState;
  const _UserCard({required this.user, required this.appState});
  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  bool _loading = false;

  Future<void> _toggle(String field, bool current) async {
    setState(() => _loading = true);
    final uid = widget.user['id'] as int;
    bool ok = false;
    if (field == 'isActive') ok = await widget.appState.adminToggleUserActive(uid, current);
    if (field == 'isMerchant') ok = await widget.appState.adminSetMerchant(uid, current);
    if (mounted) setState(() => _loading = false);
    if (mounted && !ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la mise à jour')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final active = u['isActive'] as bool? ?? true;
    final isMerchant = u['isMerchant'] as bool? ?? false;
    final isAdmin = u['isAdmin'] as bool? ?? false;
    final kycStatus = (u['kycStatus'] as String? ?? 'NONE').toLowerCase();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                (u['name'] as String? ?? '?').substring(0, 1).toUpperCase(),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(u['name'] as String? ?? '—',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(u['phone'] as String? ?? '',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
            ),
            if (isAdmin) _RoleBadge('ADMIN', AppColors.danger),
            if (isMerchant) _RoleBadge('MARCHAND', AppColors.secondary),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _StatusBadge(kycStatus.toUpperCase()),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: active ? AppColors.success.withValues(alpha: 0.1) : AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(active ? 'ACTIF' : 'DÉSACTIVÉ',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: active ? AppColors.success : AppColors.danger)),
            ),
          ]),
          if (_loading) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(color: AppColors.primary),
          ] else ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: active ? AppColors.danger : AppColors.success,
                      side: BorderSide(color: active ? AppColors.danger : AppColors.success),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () => _toggle('isActive', active),
                  child: Text(active ? 'Désactiver' : 'Réactiver',
                      style: const TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: const BorderSide(color: AppColors.secondary),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () => _toggle('isMerchant', isMerchant),
                  child: Text(isMerchant ? 'Retirer marchand' : 'Passer marchand',
                      style: const TextStyle(fontSize: 11)),
                ),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Disputes Tab
// ─────────────────────────────────────────────────────────────────────────────
class _DisputesTab extends StatelessWidget {
  final List<Map<String, dynamic>> disputes;
  final AppState appState;
  final VoidCallback onRefresh;
  const _DisputesTab({required this.disputes, required this.appState, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (disputes.isEmpty) {
      return _EmptyState(
          icon: LucideIcons.checkCircle,
          message: 'Aucun litige en cours.',
          onRetry: onRefresh);
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: disputes.length,
        itemBuilder: (ctx, i) => _DisputeCard(dispute: disputes[i], appState: appState),
      ),
    );
  }
}

class _DisputeCard extends StatefulWidget {
  final Map<String, dynamic> dispute;
  final AppState appState;
  const _DisputeCard({required this.dispute, required this.appState});
  @override
  State<_DisputeCard> createState() => _DisputeCardState();
}

class _DisputeCardState extends State<_DisputeCard> {
  bool _loading = false;

  Future<void> _resolve(String status) async {
    final notesCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Résoudre : $status'),
        content: TextField(
          controller: notesCtrl,
          decoration: const InputDecoration(
              labelText: 'Notes de résolution', border: OutlineInputBorder()),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _loading = true);
    final ok = await widget.appState.adminUpdateDispute(
      widget.dispute['id'] as String,
      status,
      notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
    );
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Litige mis à jour' : 'Erreur'),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dispute;
    final reporter = d['reporter'] as Map<String, dynamic>? ?? {};
    final status = d['status'] as String? ?? 'OPEN';
    final isOpen = status == 'OPEN' || status == 'IN_REVIEW';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(d['reference'] as String? ?? '',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.grey)),
            ),
            _StatusBadge(status),
          ]),
          const SizedBox(height: 6),
          Text(d['subject'] as String? ?? '—',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Catégorie : ${d['category'] ?? '—'} · Montant : ${formatAmountAbs((d['amount'] as num?)?.toDouble() ?? 0, 'XOF')}',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text('Signalé par : ${reporter['name'] ?? reporter['phone'] ?? '—'}',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          if (_loading) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(color: AppColors.primary),
          ] else if (isOpen) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () => _resolve('RESOLVED_NO_ACTION'),
                  child: const Text('Clore', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () => _resolve('RESOLVED_REFUNDED'),
                  child: const Text('Rembourser', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback onRetry;
  const _EmptyState({required this.icon, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 64, color: Colors.grey.withValues(alpha: 0.4)),
        const SizedBox(height: 16),
        Text(message,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(LucideIcons.refreshCw, size: 16),
          label: const Text('Actualiser'),
        ),
      ]),
    );
  }
}

class _NoneYet extends StatelessWidget {
  final String label;
  const _NoneYet({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text('Aucune $label pour le moment.',
          style: const TextStyle(color: Colors.grey, fontSize: 13)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title.toUpperCase(),
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppColors.primary)),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _MetricCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))),
            Icon(icon, color: color, size: 16),
          ]),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Text('$label : ', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);
  @override
  Widget build(BuildContext context) {
    Color c;
    switch (status) {
      case 'APPROVED': case 'COMPLETED': case 'RESOLVED_NO_ACTION': case 'CLOSED':
        c = AppColors.success; break;
      case 'PENDING': case 'IN_REVIEW': case 'OPEN':
        c = AppColors.warning; break;
      case 'REJECTED': case 'RESOLVED_REFUNDED':
        c = AppColors.danger; break;
      default: c = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: c.withValues(alpha: 0.4))),
      child: Text(status,
          style: TextStyle(fontSize: 9, color: c, fontWeight: FontWeight.bold)),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _RoleBadge(this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold)),
    );
  }
}
