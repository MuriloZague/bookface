import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../model/user_model.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import 'home_screen.dart';
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

  Future<void> _onEditProfile(UserModel user) async {
    final result = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _EditProfileSheet(
        user: user,
        userService: _userService,
      ),
    );

    if (!mounted || result == null) return;

    final message = result == 'email'
        ? 'Perfil atualizado. Confira seu novo e-mail para confirmar a alteração.'
        : 'Perfil atualizado com sucesso';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
        title: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              'bookface',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
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
              _ProfileHeader(
                user: user,
                onEdit: user == null ? null : () => _onEditProfile(user),
              ),
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
  const _ProfileHeader({required this.user, this.onEdit});

  final UserModel? user;
  final VoidCallback? onEdit;

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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (user != null)
                      IconButton(
                        tooltip: 'Editar perfil',
                        onPressed: onEdit,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.only(left: 6),
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
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

/// Formulário para editar nome e telefone do perfil, exibido em bottom sheet.
class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.user, required this.userService});

  final UserModel user;
  final UserService userService;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _obscureCurrent = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone);
    _emailController = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }

  /// Precisa de reautenticação quando o e-mail muda ou uma nova senha é definida.
  bool get _needsCurrentPassword {
    final emailChanged = _emailController.text.trim() != widget.user.email;
    return emailChanged || _passwordController.text.isNotEmpty;
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final newPassword = _passwordController.text;
      final emailVerificationPending =
          await widget.userService.updateAccount(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        newPassword: newPassword.isEmpty ? null : newPassword,
        currentPassword: _currentPasswordController.text.isEmpty
            ? null
            : _currentPasswordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(emailVerificationPending ? 'email' : true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_authErrorMessage(e))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível atualizar o perfil')),
      );
    }
  }

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Senha atual incorreta';
      case 'email-already-in-use':
        return 'Este e-mail já está em uso';
      case 'invalid-email':
        return 'E-mail inválido';
      case 'requires-recent-login':
        return 'Faça login novamente para alterar e-mail ou senha';
      case 'weak-password':
        return 'A nova senha é muito fraca';
      default:
        return 'Não foi possível atualizar o perfil';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Text(
              'Editar perfil',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: Validators.name,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [PhoneInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Telefone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: Validators.phone,
            ),
            const SizedBox(height: 16),
            
          
            const SizedBox(height: 16),
            if (_passwordController.text.isNotEmpty)
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirmar nova senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (value) => Validators.confirmPassword(
                  value,
                  _passwordController.text,
                ),
              ),
            if (_passwordController.text.isNotEmpty)
              const SizedBox(height: 16),
            if (_needsCurrentPassword) ...[
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'Senha atual',
                  helperText: 'Necessária para alterar e-mail ou senha',
                  prefixIcon: const Icon(Icons.lock_person_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrent
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
                validator: (value) {
                  if (!_needsCurrentPassword) return null;
                  if ((value ?? '').isEmpty) return 'Informe sua senha atual';
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Salvar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            ],
          ),
        ),
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
