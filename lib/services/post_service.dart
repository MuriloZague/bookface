import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model/post_model.dart';

/// Serviço responsável pelo CRUD de posts no Firestore.
///
/// A imagem é guardada como texto Base64 dentro do próprio documento do post
/// (sem Firebase Storage). Espelha o padrão de [UserService]: coleção própria,
/// métodos assíncronos e mensagens de erro em português.
class PostService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Limite de segurança: o Firestore aceita no máximo ~1 MB por documento.
  /// Rejeitamos imagens grandes antes de tentar gravar.
  static const int _maxBytes = 900 * 1024; // ~900 KB

  // Coleção principal de posts (IDs gerados automaticamente).
  CollectionReference get _postsRef => _firestore.collection('posts');

  /// Converte os bytes da imagem em Base64, validando o tamanho.
  String _encodeImagem(Uint8List bytes) {
    if (bytes.lengthInBytes > _maxBytes) {
      throw Exception('Imagem muito grande. Escolha uma imagem menor.');
    }
    return base64Encode(bytes);
  }

  /// Cria um novo post gravando a imagem em Base64 no documento.
  Future<void> createPost({
    required String nome,
    required String descricao,
    required Uint8List imagem,
  }) async {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não autenticado');

    // Busca o nome do autor no perfil para exibir no cartão do post.
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final authorNome = (userDoc.data()?['name'] ?? '') as String;

    final post = PostModel(
      nome: nome,
      descricao: descricao,
      imagemBase64: _encodeImagem(imagem),
      data: DateTime.now(),
      authorId: uid,
      authorNome: authorNome,
    );

    await _postsRef.add(post.toMap());
  }

  /// Feed reativo com todos os posts, ordenados do mais recente para o mais antigo.
  Stream<List<PostModel>> streamPosts() {
    return _postsRef
        .orderBy('data', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              PostModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  /// Atualiza nome/descrição e, opcionalmente, troca a imagem do post.
  Future<void> updatePost(
    String postId, {
    required String nome,
    required String descricao,
    Uint8List? novaImagem,
  }) async {
    if (_auth.currentUser == null) {
      throw Exception('Usuário não autenticado');
    }

    final Map<String, dynamic> dados = {
      'nome': nome,
      'descricao': descricao,
      'updatedAt': DateTime.now(),
    };

    if (novaImagem != null) {
      dados['imagemBase64'] = _encodeImagem(novaImagem);
    }

    await _postsRef.doc(postId).update(dados);
  }

  /// Remove o post do Firestore.
  Future<void> deletePost(PostModel post) async {
    if (_auth.currentUser == null) {
      throw Exception('Usuário não autenticado');
    }

    await _postsRef.doc(post.id).delete();
  }
}
