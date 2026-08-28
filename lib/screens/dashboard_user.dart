import 'package:flutter/material.dart';

import '../model/user_model.dart';
import '../services/user_service.dart';
import '../theme.dart';
import 'login_screen.dart';

/// Tela inicial do usuário logado (dashboard).
///
/// Consome o perfil de forma reativa via [UserService.streamUserProfile],
/// então qualquer alteração no Firestore reflete aqui automaticamente.
class DashboardUser extends StatefulWidget {
  const DashboardUser({super.key});

  @override
  State<DashboardUser> createState() => _DashboardUserState();
}

class _DashboardUserState extends State<DashboardUser> {
  final _userService = UserService();

  Future<void> _onLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Deseja realmente encerrar a sessão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _userService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        titleSpacing: 20,
        title: Text(
          'bookface',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: _onLogout,
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: _userService.streamUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final user = snapshot.data;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ProfileHeader(user: user),
              const SizedBox(height: 16),
              const _StatsRow(),
              const SizedBox(height: 16),
              if (user != null) _InfoCard(user: user),
              const SizedBox(height: 16),
              const _FeedPlaceholder(),
            ],
          );
        },
      ),
    );
  }
}

/// Cartão de topo com avatar (inicial do nome), nome e e-mail.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final name =
        user?.name.trim().isNotEmpty == true ? user!.name : 'Usuário';
    final initial = name.substring(0, 1).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.primary,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'E-mail não disponível',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Linha de estatísticas (placeholder — dados reais virão depois).
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: _cardDecoration,
      child: Row(
        children: const [
          _StatItem(value: '0', label: 'Amigos'),
          _StatDivider(),
          _StatItem(value: '0', label: 'Publicações'),
          _StatDivider(),
          _StatItem(value: '0', label: 'Fotos'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.border,
    );
  }
}

/// Cartão com os dados de contato do usuário.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: _cardDecoration,
      child: Column(
        children: [
          _InfoTile(
            icon: Icons.email_outlined,
            label: 'E-mail',
            value: user.email,
          ),
          const Divider(color: AppColors.border, height: 1),
          _InfoTile(
            icon: Icons.phone_outlined,
            label: 'Telefone',
            value: user.phone.isNotEmpty ? user.phone : 'Não informado',
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Área reservada para o feed — a ser implementada futuramente.
class _FeedPlaceholder extends StatelessWidget {
  const _FeedPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: _cardDecoration,
      child: Column(
        children: const [
          Icon(Icons.dynamic_feed_outlined,
              size: 48, color: AppColors.textSecondary),
          SizedBox(height: 12),
          Text(
            'Seu feed aparecerá aqui',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Decoração padrão dos cartões da dashboard.
final BoxDecoration _cardDecoration = BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: AppColors.border),
);
