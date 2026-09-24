import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../model/comment_model.dart';

/// Serviço responsável pelo CRUD de comentários na MockAPI (API REST).
///
/// Todas as operações usam requisições HTTP (GET, POST, PUT e DELETE) no
/// resource `comments`. A URL base vem do `.env` em `MOCKAPI_BASE_URL`.
/// Erros de rede e respostas fora de 2xx viram [Exception] com mensagem em
/// português, prontas para exibir na tela.
class CommentService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final http.Client _client = http.Client();

  static const Duration _timeout = Duration(seconds: 10);
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  Uri _uri([String path = '', Map<String, String>? query]) {
    final base = dotenv.env['MOCKAPI_BASE_URL'] ?? '';
    if (base.isEmpty) {
      throw Exception('MOCKAPI_BASE_URL não configurada no .env');
    }
    return Uri.parse('$base/comments$path')
        .replace(queryParameters: query);
  }

  /// Executa a requisição tratando timeout e falta de conexão.
  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } on TimeoutException {
      throw Exception('O servidor demorou para responder. Tente novamente.');
    } on http.ClientException {
      throw Exception('Sem conexão com o servidor. Verifique sua internet.');
    }
  }

  /// Lança uma [Exception] quando o status HTTP não é de sucesso (2xx).
  void _check(http.Response response, String erro) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('$erro (código ${response.statusCode})');
    }
  }

  /// Lista os comentários de um post, do mais antigo para o mais recente.
  Future<List<CommentModel>> fetchByPost(String postId) async {
    final response =
        await _send(() => _client.get(_uri('', {'postId': postId})));

    // A MockAPI responde 404 quando o filtro não encontra nenhum registro.
    if (response.statusCode == 404) return [];
    _check(response, 'Não foi possível carregar os comentários');

    final List<dynamic> data = jsonDecode(response.body);
    final comments = data
        .map((json) => CommentModel.fromJson(json as Map<String, dynamic>))
        // O filtro da MockAPI é por "contém"; garantimos o post exato.
        .where((c) => c.postId == postId)
        .toList();
    comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return comments;
  }

  /// Cria um comentário no post informado, em nome do usuário logado.
  Future<CommentModel> create({
    required String postId,
    required String texto,
  }) async {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não autenticado');

    // Busca o nome do autor no perfil para exibir junto ao comentário.
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final authorNome = (userDoc.data()?['name'] ?? '') as String;

    final comment = CommentModel(
      postId: postId,
      authorId: uid,
      authorNome: authorNome,
      texto: texto,
      createdAt: DateTime.now(),
    );

    final response = await _send(() => _client.post(
          _uri(),
          headers: _headers,
          body: jsonEncode(comment.toJson()),
        ));
    _check(response, 'Não foi possível publicar o comentário');

    return CommentModel.fromJson(jsonDecode(response.body));
  }

  /// Atualiza o texto de um comentário existente.
  Future<void> update(String id, {required String texto}) async {
    if (_auth.currentUser == null) {
      throw Exception('Usuário não autenticado');
    }

    final response = await _send(() => _client.put(
          _uri('/$id'),
          headers: _headers,
          body: jsonEncode({'texto': texto}),
        ));
    _check(response, 'Não foi possível atualizar o comentário');
  }

  /// Remove um comentário.
  Future<void> delete(String id) async {
    if (_auth.currentUser == null) {
      throw Exception('Usuário não autenticado');
    }

    final response = await _send(() => _client.delete(_uri('/$id')));
    _check(response, 'Não foi possível excluir o comentário');
  }

  /// Remove todos os comentários de um post (usado ao excluir o post).
  Future<void> deleteByPost(String postId) async {
    final comments = await fetchByPost(postId);
    for (final comment in comments) {
      await delete(comment.id!);
    }
  }
}
