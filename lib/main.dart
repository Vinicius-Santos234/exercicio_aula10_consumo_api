import 'package:flutter/material.dart';

import 'screens/feed_noticias_screen.dart';

void main() => runApp(const MeuApp());

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aula 10 - Listas e APIs',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const FeedNoticiasScreen(),
    );
  }
}
