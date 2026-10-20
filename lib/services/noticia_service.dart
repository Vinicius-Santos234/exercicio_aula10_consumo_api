import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/noticia_model.dart';

class NoticiaService {
  static const String urlPadrao = 'https://jsonplaceholder.typicode.com/posts';

  // Domínio .invalid nunca é resolvido pelo DNS (RFC 2606): força erro de rede
  static const String urlInvalida = 'https://api-noticias.invalid/posts';

  // O client pode ser substituído nos testes por um MockClient
  final http.Client _client;
  String _endpoint = urlPadrao;

  NoticiaService({http.Client? client}) : _client = client ?? http.Client();

  bool get simulandoErro => _endpoint == urlInvalida;

  // Desafio Avançado: alterna entre a URL correta e um endereço incorreto
  void alternarSimulacaoErro() {
    _endpoint = simulandoErro ? urlPadrao : urlInvalida;
  }

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
