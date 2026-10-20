import 'package:flutter/material.dart';

import '../models/noticia_model.dart';
import '../services/noticia_service.dart';
import 'detalhe_noticia_screen.dart';

class FeedNoticiasScreen extends StatefulWidget {
  final NoticiaService? service;

  const FeedNoticiasScreen({super.key, this.service});

  @override
  State<FeedNoticiasScreen> createState() => _FeedNoticiasScreenState();
}

class _FeedNoticiasScreenState extends State<FeedNoticiasScreen> {
  late final NoticiaService _service = widget.service ?? NoticiaService();
  final _buscaController = TextEditingController();
  List<NoticiaModel> _noticias = [];
  bool _carregando = true;
  String? _erro;
  String _termoBusca = '';

  @override
  void initState() {
    super.initState();
    _carregarFeed();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  // Desafio Básico: filtra a lista já carregada, sem nova requisição à API
  List<NoticiaModel> get _noticiasFiltradas {
    final termo = _termoBusca.trim().toLowerCase();
    if (termo.isEmpty) return _noticias;
    return _noticias
        .where((noticia) => noticia.titulo.toLowerCase().contains(termo))
        .toList();
  }

  void _limparBusca() {
    _buscaController.clear();
    setState(() => _termoBusca = '');
  }

  void _abrirDetalhes(NoticiaModel noticia) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalheNoticiaScreen(noticia: noticia),
      ),
    );
  }

  Future<void> _carregarFeed() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final lista = await _service.buscarNoticias();
      if (mounted) setState(() => _noticias = lista);
    } catch (e) {
      if (mounted) {
        setState(() => _erro = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed de Notícias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recarregar',
            onPressed: _carregarFeed,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCampoBusca(),
          Expanded(child: _buildConteudo()),
        ],
      ),
    );
  }

  Widget _buildCampoBusca() {
    final exibirContador =
        !_carregando && _erro == null && _noticias.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _buscaController,
            onChanged: (valor) => setState(() => _termoBusca = valor),
            decoration: InputDecoration(
              hintText: 'Buscar notícias pelo título',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _termoBusca.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Limpar busca',
                      onPressed: _limparBusca,
                    ),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (exibirContador)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Text(
                'Exibindo ${_noticiasFiltradas.length} de ${_noticias.length} notícias',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConteudo() {
    if (_carregando) return const Center(child: CircularProgressIndicator());

    if (_erro != null) return _buildCardErro();

    if (_noticias.isEmpty) {
      return _buildEstadoVazio('Nenhuma notícia disponível no momento.');
    }

    final noticias = _noticiasFiltradas;
    if (noticias.isEmpty) {
      return _buildEstadoVazio(
        'Nenhuma notícia encontrada para "$_termoBusca".',
        icone: Icons.search_off,
      );
    }

    return ListView.builder(
      itemCount: noticias.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final noticia = noticias[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(noticia.id.toString())),
            title: Text(
              noticia.titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              noticia.resumo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _abrirDetalhes(noticia),
          ),
        );
      },
    );
  }

  Widget _buildCardErro() {
    final cores = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            color: cores.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off, size: 48, color: cores.error),
                  const SizedBox(height: 12),
                  Text(
                    'Erro de conexão',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: cores.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _erro!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cores.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _carregarFeed,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoVazio(
    String mensagem, {
    IconData icone = Icons.inbox_outlined,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 56, color: Colors.grey[500]),
            const SizedBox(height: 12),
            Text(mensagem, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
