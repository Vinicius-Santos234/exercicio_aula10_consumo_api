import 'package:flutter/material.dart';
import '../models/noticia_model.dart';
import '../services/noticia_service.dart';

class FeedNoticiasScreen extends StatefulWidget {
  final NoticiaService? service;

  const FeedNoticiasScreen({super.key, this.service});

  @override
  State<FeedNoticiasScreen> createState() => _FeedNoticiasScreenState();
}

class _FeedNoticiasScreenState extends State<FeedNoticiasScreen> {
  late final NoticiaService _service = widget.service ?? NoticiaService();
  List<NoticiaModel> _noticias = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarFeed();
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
      body: _buildConteudo(),
    );
  }

  Widget _buildConteudo() {
    if (_carregando) return const Center(child: CircularProgressIndicator());

    if (_erro != null) return _buildCardErro();

    if (_noticias.isEmpty) {
      return _buildEstadoVazio('Nenhuma notícia disponível no momento.');
    }

    return ListView.builder(
      itemCount: _noticias.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final noticia = _noticias[index];
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

  Widget _buildEstadoVazio(String mensagem) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey[500]),
            const SizedBox(height: 12),
            Text(mensagem, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
