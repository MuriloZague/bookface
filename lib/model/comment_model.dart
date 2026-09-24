/// Representa um comentário feito em uma publicação (post).
///
/// Diferente de [PostModel], os comentários ficam na MockAPI (API REST), então
/// usamos [toJson] / [CommentModel.fromJson] para trafegar via HTTP.
class CommentModel {
  final String? id; // id gerado pela MockAPI
  final String postId; // id do post comentado (doc.id do Firestore)
  final String authorId; // uid do autor do comentário
  final String authorNome; // nome do autor no momento do comentário
  final String texto;
  final DateTime createdAt;

  CommentModel({
    this.id,
    required this.postId,
    required this.authorId,
    required this.authorNome,
    required this.texto,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorNome': authorNome,
      'texto': texto,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id']?.toString(),
      postId: json['postId']?.toString() ?? '',
      authorId: json['authorId']?.toString() ?? '',
      authorNome: json['authorNome']?.toString() ?? '',
      texto: json['texto']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
