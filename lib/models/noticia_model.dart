class NoticiaModel {
  final int id;
  final int autorId;
  final String titulo;
  final String resumo;

  NoticiaModel({
    required this.id,
    required this.autorId,
    required this.titulo,
    required this.resumo,
  });

  factory NoticiaModel.fromJson(Map<String, dynamic> json) {
    return NoticiaModel(
      id: json['id'] ?? 0,
      autorId: json['userId'] ?? 0,
      titulo: json['title'] ?? '',
      resumo: json['body'] ?? '',
    );
  }
}
