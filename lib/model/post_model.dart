import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa uma publicação (post) do feed do bookface.
///
/// Segue o mesmo estilo do [UserModel]: [toMap] para gravar no Firestore e
/// [PostModel.fromMap] para reconstruir a partir de um documento.
///
/// A imagem é guardada como texto (Base64) no próprio documento do Firestore,
/// em [imagemBase64] — sem Firebase Storage.
class PostModel {
  final String? id; // doc.id do Firestore
  final String nome;
  final String descricao;
  final String imagemBase64; // imagem codificada em Base64
  final DateTime data; // data do post
  final String authorId; // uid do autor (dono do post)
  final String authorNome; // nome do autor no momento da publicação

  PostModel({
    this.id,
    required this.nome,
    required this.descricao,
    required this.imagemBase64,
    required this.data,
    required this.authorId,
    required this.authorNome,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'descricao': descricao,
      'imagemBase64': imagemBase64,
      'data': Timestamp.fromDate(data),
      'authorId': authorId,
      'authorNome': authorNome,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map, String docId) {
    return PostModel(
      id: docId,
      nome: map['nome'] ?? '',
      descricao: map['descricao'] ?? '',
      imagemBase64: map['imagemBase64'] ?? '',
      data: (map['data'] as Timestamp?)?.toDate() ?? DateTime.now(),
      authorId: map['authorId'] ?? '',
      authorNome: map['authorNome'] ?? '',
    );
  }
}
