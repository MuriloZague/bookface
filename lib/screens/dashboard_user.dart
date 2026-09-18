import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../model/post_model.dart';
import '../model/user_model.dart';
import '../services/post_service.dart';
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
  final _postService = PostService();

  // Streams criados UMA vez. Recriar a cada build faz o StreamBuilder
  // reassinar e reemitir em loop infinito (vazamento de memória).
  late final Stream<UserModel?> _profileStream =
      _userService.streamUserProfile();
  late final Stream<List<PostModel>> _postsStream = _postService.streamPosts();

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

  Future<void> _onCreatePost() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PostFormSheet(postService: _postService),
    );

    if (!mounted || result != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Publicação criada com sucesso')),
    );
  }

  Future<void> _onEditPost(PostModel post) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PostFormSheet(postService: _postService, post: post),
    );

    if (!mounted || result != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Publicação atualizada com sucesso')),
    );
  }

  Future<void> _onDeletePost(PostModel post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir publicação'),
        content: const Text('Deseja realmente excluir esta publicação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _postService.deletePost(post);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicação excluída')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir a publicação')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        tooltip: 'Nova publicação',
        onPressed: _onCreatePost,
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
        stream: _profileStream,
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
              _Feed(
                stream: _postsStream,
                onEdit: _onEditPost,
                onDelete: _onDeletePost,
              ),
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

/// Feed reativo de publicações, consumido de [PostService.streamPosts].
class _Feed extends StatelessWidget {
  const _Feed({
    required this.stream,
    required this.onEdit,
    required this.onDelete,
  });

  final Stream<List<PostModel>> stream;
  final void Function(PostModel post) onEdit;
  final void Function(PostModel post) onDelete;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PostModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 48),
            decoration: _cardDecoration,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final posts = snapshot.data ?? const [];
        if (posts.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
            decoration: _cardDecoration,
            child: Column(
              children: const [
                Icon(Icons.dynamic_feed_outlined,
                    size: 48, color: AppColors.textSecondary),
                SizedBox(height: 12),
                Text(
                  'Nenhuma publicação ainda',
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

        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        return Column(
          children: [
            for (final post in posts) ...[
              _PostCard(
                post: post,
                isOwner: post.authorId == currentUid,
                onEdit: () => onEdit(post),
                onDelete: () => onDelete(post),
              ),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }
}

/// Cartão que exibe uma publicação: imagem, nome, descrição e data.
class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
  });

  final PostModel post;
  final bool isOwner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String get _autorNome =>
      post.authorNome.trim().isNotEmpty ? post.authorNome : 'Usuário';

  String get _autorInicial => _autorNome.substring(0, 1).toUpperCase();
//dataslk
  String get _dataFormatada {
    final d = post.data;
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    return '$dia/$mes/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    _autorInicial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _autorNome,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _dataFormatada,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        color: AppColors.textSecondary),
                    onSelected: (value) {
                      if (value == 'editar') onEdit();
                      if (value == 'excluir') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'editar', child: Text('Editar')),
                      PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              post.nome,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (post.imagemBase64.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.memory(
                base64Decode(post.imagemBase64),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.field,
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: AppColors.textSecondary, size: 40),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Text(
              post.descricao,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                height: 1.35,
              ),
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

/// Formulário de criação/edição de publicação, exibido em bottom sheet.
///
/// Sem [post] funciona em modo criação (imagem obrigatória); com [post]
/// funciona em modo edição (imagem opcional — mantém a atual se não trocar).
class _PostFormSheet extends StatefulWidget {
  const _PostFormSheet({required this.postService, this.post});

  final PostService postService;
  final PostModel? post;

  @override
  State<_PostFormSheet> createState() => _PostFormSheetState();
}

class _PostFormSheetState extends State<_PostFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _descricaoController;
  Uint8List? _imagem;
  bool _saving = false;

  bool get _isEditing => widget.post != null;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.post?.nome ?? '');
    _descricaoController =
        TextEditingController(text: widget.post?.descricao ?? '');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // Imagem vai em Base64 no documento do Firestore (limite ~1 MB), então
    // reduzimos resolução/qualidade para caber com folga.
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 50,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _imagem = bytes);
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isEditing && _imagem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma imagem para publicar')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final nome = _nomeController.text.trim();
      final descricao = _descricaoController.text.trim();

      if (_isEditing) {
        await widget.postService.updatePost(
          widget.post!.id!,
          nome: nome,
          descricao: descricao,
          novaImagem: _imagem,
        );
      } else {
        await widget.postService.createPost(
          nome: nome,
          descricao: descricao,
          imagem: _imagem!,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar a publicação')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentBase64 = widget.post?.imagemBase64;

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
              Text(
                _isEditing ? 'Editar publicação' : 'Nova publicação',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nomeController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  prefixIcon: Icon(Icons.title_outlined),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Informe um nome para a publicação'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Informe uma descrição'
                    : null,
              ),
              const SizedBox(height: 16),
              _ImagePickerField(
                imagem: _imagem,
                currentBase64: currentBase64,
                onTap: _pickImage,
              ),
              const SizedBox(height: 20),
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
                      : Text(
                          _isEditing ? 'Salvar' : 'Publicar',
                          style: const TextStyle(
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

/// Campo de seleção de imagem com preview (novo arquivo ou imagem atual).
class _ImagePickerField extends StatelessWidget {
  const _ImagePickerField({
    required this.imagem,
    required this.currentBase64,
    required this.onTap,
  });

  final Uint8List? imagem;
  final String? currentBase64;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (imagem != null) {
      content = Image.memory(imagem!, fit: BoxFit.cover);
    } else if (currentBase64 != null && currentBase64!.isNotEmpty) {
      content = Image.memory(base64Decode(currentBase64!), fit: BoxFit.cover);
    } else {
      content = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined,
              color: AppColors.textSecondary, size: 36),
          SizedBox(height: 8),
          Text(
            'Selecionar imagem',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 180,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.field,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: content,
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
