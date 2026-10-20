import 'package:flutter/material.dart';

import '../models/noticia_model.dart';

// Desafio Intermediário: recebe a notícia já carregada no feed pelo construtor
class DetalheNoticiaScreen extends StatelessWidget {
  final NoticiaModel noticia;

  const DetalheNoticiaScreen({super.key, required this.noticia});

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da Notícia')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.tag, size: 16),
                  label: Text('Notícia ${noticia.id}'),
                ),
                Chip(
                  avatar: const Icon(Icons.person, size: 16),
                  label: Text('Autor ${noticia.autorId}'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              noticia.titulo,
              style: textos.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 32),
            Text(
              noticia.resumo,
              style: textos.bodyLarge?.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
