import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../model/comment_model.dart';
import '../model/post_model.dart';
import '../services/comment_service.dart';
import '../theme.dart';
import '../utils/validators.dart';

/// Bottom sheet com os comentários de uma publicação.
///
/// Faz o CRUD completo na MockAPI via [CommentService]: lista (Read), campo
/// no rodapé para comentar (Create) ou editar (Update), e exclusão com
/// confirmação (Delete). Erros aparecem dentro do próprio sheet, pois um
/// SnackBar ficaria escondido atrás dele.
class CommentsSheet extends StatefulWidget {
  const CommentsSheet({super.key, required this.post});

  final PostModel post;

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _commentService = CommentService();
  final _formKey = GlobalKey<FormState>();
  final _textoController = TextEditingController();
  final _currentUid = FirebaseAuth.instance.currentUser?.uid;

  List<CommentModel> _comments = [];
  bool _loading = true;
  String? _loadError; // erro ao carregar a lista
  String? _actionError; // erro ao criar/editar/excluir
  bool _saving = false;
  CommentModel? _editing; // comentário em edição (null = novo comentário)

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _textoController.dispose();
    super.dispose();
  }

  String _errorMessage(Object e) =>
      e.toString().replaceFirst('Exception: ', '');

  Future<void> _loadComments() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final comments = await _commentService.fetchByPost(widget.post.id!);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = _errorMessage(e);
        _loading = false;
      });
    }
  }

  void _startEdit(CommentModel comment) {
    setState(() {
      _editing = comment;
      _actionError = null;
      _textoController.text = comment.texto;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editing = null;
      _actionError = null;
      _textoController.clear();
    });
    _formKey.currentState?.reset();
  }

  Future<void> _onSend() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _actionError = null;
    });
    try {
      final texto = _textoController.text.trim();
      if (_editing != null) {
        await _commentService.update(_editing!.id!, texto: texto);
      } else {
        await _commentService.create(postId: widget.post.id!, texto: texto);
      }
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      setState(() {
        _saving = false;
        _editing = null;
        _textoController.clear();
      });
      await _loadComments();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _actionError = _errorMessage(e);
      });
    }
  }

  Future<void> _onDelete(CommentModel comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir comentário'),
        content: const Text('Deseja realmente excluir este comentário?'),
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

    setState(() => _actionError = null);
    try {
      await _commentService.delete(comment.id!);
      if (!mounted) return;
      if (_editing?.id == comment.id) _cancelEdit();
      await _loadComments();
    } catch (e) {
      if (!mounted) return;
      setState(() => _actionError = _errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.75;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                  SizedBox(width: 10),
                  Text(
                    'Comentários',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(child: _buildList()),
            const Divider(height: 1, color: AppColors.border),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_loadError != null) {
      return _Message(
        icon: Icons.cloud_off_outlined,
        text: _loadError!,
        action: TextButton(
          onPressed: _loadComments,
          child: const Text('Tentar novamente'),
        ),
      );
    }

    if (_comments.isEmpty) {
      return const _Message(
        icon: Icons.forum_outlined,
        text: 'Nenhum comentário ainda.\nSeja o primeiro a comentar!',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _comments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return _CommentTile(
          comment: comment,
          isOwner: comment.authorId == _currentUid,
          onEdit: () => _startEdit(comment),
          onDelete: () => _onDelete(comment),
        );
      },
    );
  }

  Widget _buildInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_editing != null)
              Row(
                children: [
                  const Icon(Icons.edit_outlined,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Editando comentário',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _saving ? null : _cancelEdit,
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            if (_actionError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8, right: 8),
                child: Text(
                  _actionError!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _textoController,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      hintText: 'Escreva um comentário...',
                      counterText: '',
                    ),
                    validator: Validators.comment,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: _editing != null ? 'Salvar' : 'Comentar',
                  onPressed: _saving ? null : _onSend,
                  icon: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Icon(
                          _editing != null ? Icons.check : Icons.send,
                          color: AppColors.primary,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Um comentário da lista: avatar, nome, data, texto e menu do autor.
class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
  });

  final CommentModel comment;
  final bool isOwner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String get _autorNome =>
      comment.authorNome.trim().isNotEmpty ? comment.authorNome : 'Usuário';

  String get _dataFormatada {
    final d = comment.createdAt.toLocal();
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    final hora = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${d.year} às $hora:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary,
          child: Text(
            _autorNome.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _autorNome,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _dataFormatada,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comment.texto,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz,
                        size: 20, color: AppColors.textSecondary),
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
        ),
      ],
    );
  }
}

/// Mensagem centralizada (lista vazia ou erro), com ação opcional.
class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}
