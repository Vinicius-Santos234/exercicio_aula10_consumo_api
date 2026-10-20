// Testes do feed de notícias da Aula 10.
//
// A API é simulada com um MockClient do pacote http, então os testes não
// dependem da internet. Cobrem o modelo, o serviço (statusCode e try/catch),
// os quatro estados da tela e os três desafios de laboratório.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:pdm_aula10_consumo_api/models/noticia_model.dart';
import 'package:pdm_aula10_consumo_api/screens/detalhe_noticia_screen.dart';
import 'package:pdm_aula10_consumo_api/screens/feed_noticias_screen.dart';
import 'package:pdm_aula10_consumo_api/services/noticia_service.dart';

const _postsFake = [
  {
    'userId': 1,
    'id': 1,
    'title': 'Flutter lança nova versão estável',
    'body': 'Texto completo da notícia sobre o lançamento do Flutter.',
  },
  {
    'userId': 1,
    'id': 2,
    'title': 'Dart ganha melhorias de desempenho',
    'body': 'Texto completo da notícia sobre o Dart.',
  },
  {
    'userId': 2,
    'id': 3,
    'title': 'Fatec abre inscrições para o vestibular',
    'body': 'Texto completo da notícia sobre o vestibular da Fatec.',
  },
];

// Responde como a API real; no domínio .invalid lança erro de rede.
// O atraso permite verificar o estado "Carregando" antes da resposta.
MockClient _clienteFake({
  int statusCode = 200,
  List<Map<String, dynamic>> posts = _postsFake,
}) {
  return MockClient((request) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));

    if (request.url.host.endsWith('.invalid')) {
      throw http.ClientException('Failed host lookup', request.url);
    }

    return http.Response(
      jsonEncode(posts),
      statusCode,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
}

Future<void> _montarFeed(WidgetTester tester, http.Client client) async {
  await tester.pumpWidget(
    MaterialApp(
      home: FeedNoticiasScreen(service: NoticiaService(client: client)),
    ),
  );
}

void main() {
  test('NoticiaModel.fromJson mapeia os campos e aplica valores padrão', () {
    final noticia = NoticiaModel.fromJson(_postsFake.first);

    expect(noticia.id, 1);
    expect(noticia.autorId, 1);
    expect(noticia.titulo, 'Flutter lança nova versão estável');
    expect(noticia.resumo, startsWith('Texto completo'));

    final vazia = NoticiaModel.fromJson({});
    expect(vazia.id, 0);
    expect(vazia.autorId, 0);
    expect(vazia.titulo, '');
    expect(vazia.resumo, '');
  });

  group('NoticiaService', () {
    test('converte a lista JSON quando o statusCode é 200', () async {
      final service = NoticiaService(client: _clienteFake());

      final noticias = await service.buscarNoticias();

      expect(noticias, hasLength(3));
      expect(noticias, everyElement(isA<NoticiaModel>()));
      expect(noticias.last.titulo, 'Fatec abre inscrições para o vestibular');
    });

    test('lança exceção quando o statusCode é diferente de 200', () async {
      final service = NoticiaService(client: _clienteFake(statusCode: 404));

      expect(
        service.buscarNoticias(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'mensagem',
            contains('Status HTTP de erro: 404'),
          ),
        ),
      );
    });

    test('captura a falha de rede com try/catch', () async {
      final service = NoticiaService(client: _clienteFake())
        ..alternarSimulacaoErro();

      expect(service.simulandoErro, isTrue);
      expect(
        service.buscarNoticias(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'mensagem',
            contains('Falha ao conectar com a API'),
          ),
        ),
      );
    });
  });

  testWidgets('exibe o loading e depois as notícias com ListView.builder', (
    tester,
  ) async {
    await _montarFeed(tester, _clienteFake());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    final listView = tester.widget<ListView>(find.byType(ListView));
    expect(listView.childrenDelegate, isA<SliverChildBuilderDelegate>());
    expect(find.byType(Card), findsNWidgets(3));
    expect(find.byType(ListTile), findsNWidgets(3));
    expect(find.text('Dart ganha melhorias de desempenho'), findsOneWidget);
    expect(find.text('Exibindo 3 de 3 notícias'), findsOneWidget);
  });

  testWidgets('exibe o card de erro e recarrega com Tentar Novamente', (
    tester,
  ) async {
    var tentativas = 0;
    final client = MockClient((request) async {
      tentativas++;
      if (tentativas == 1) return http.Response('Erro interno', 500);
      return http.Response(
        jsonEncode(_postsFake),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    await _montarFeed(tester, client);
    await tester.pumpAndSettle();

    expect(find.text('Erro de conexão'), findsOneWidget);
    expect(
      find.text('Falha ao conectar com a API: Status HTTP de erro: 500'),
      findsOneWidget,
    );

    await tester.tap(find.text('Tentar Novamente'));
    await tester.pumpAndSettle();

    expect(tentativas, 2);
    expect(find.text('Erro de conexão'), findsNothing);
    expect(find.byType(ListTile), findsNWidgets(3));
  });

  testWidgets('exibe o estado vazio quando a API retorna uma lista vazia', (
    tester,
  ) async {
    await _montarFeed(tester, _clienteFake(posts: []));
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNothing);
    expect(find.text('Nenhuma notícia disponível no momento.'), findsOneWidget);
  });

  testWidgets('Desafio Básico: filtra as notícias pelo título em tempo real', (
    tester,
  ) async {
    await _montarFeed(tester, _clienteFake());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'FATEC');
    await tester.pump();

    expect(find.byType(ListTile), findsOneWidget);
    expect(
      find.text('Fatec abre inscrições para o vestibular'),
      findsOneWidget,
    );
    expect(find.text('Exibindo 1 de 3 notícias'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'inexistente');
    await tester.pump();

    expect(find.byType(ListTile), findsNothing);
    expect(
      find.text('Nenhuma notícia encontrada para "inexistente".'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Limpar busca'));
    await tester.pump();

    expect(find.byType(ListTile), findsNWidgets(3));
  });

  testWidgets('Desafio Intermediário: tocar no card abre os detalhes', (
    tester,
  ) async {
    await _montarFeed(tester, _clienteFake());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fatec abre inscrições para o vestibular'));
    await tester.pumpAndSettle();

    expect(find.byType(DetalheNoticiaScreen), findsOneWidget);
    expect(find.text('Detalhes da Notícia'), findsOneWidget);
    expect(find.text('Notícia 3'), findsOneWidget);
    expect(find.text('Autor 2'), findsOneWidget);
    expect(
      find.text('Texto completo da notícia sobre o vestibular da Fatec.'),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Feed de Notícias'), findsOneWidget);
  });

  testWidgets('Desafio Avançado: botão de teste simula erro de conexão', (
    tester,
  ) async {
    await _montarFeed(tester, _clienteFake());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Simular erro de conexão'));
    await tester.pumpAndSettle();

    expect(
      find.text('Modo de teste: ${NoticiaService.urlInvalida}'),
      findsOneWidget,
    );
    expect(find.text('Erro de conexão'), findsOneWidget);
    expect(find.textContaining('Falha ao conectar com a API'), findsOneWidget);
    expect(find.text('Tentar Novamente'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);

    await tester.tap(find.text('Restaurar URL padrão'));
    await tester.pumpAndSettle();

    expect(find.text('Erro de conexão'), findsNothing);
    expect(find.byType(ListTile), findsNWidgets(3));
  });
}
