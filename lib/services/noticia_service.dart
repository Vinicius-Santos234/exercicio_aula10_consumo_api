import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/noticia_model.dart';

class NoticiaService {
  static const String _endpoint = 'https://jsonplaceholder.typicode.com/posts';

  // O client pode ser substituído nos testes por um MockClient
  final http.Client _client;

  NoticiaService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<NoticiaModel>> buscarNoticias() async {
    try {
      final response = await _client.get(Uri.parse(_endpoint));

      if (response.statusCode == 200) {
        final List<dynamic> listaJson = jsonDecode(response.body);
        return listaJson.map((json) => NoticiaModel.fromJson(json)).toList();
      } else {
        throw Exception('Status HTTP de erro: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Falha ao conectar com a API: $e');
    }
  }
}
