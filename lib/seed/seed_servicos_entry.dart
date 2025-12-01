import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:chegaja_v2/firebase_options.dart';
import 'package:chegaja_v2/seed/initial_servicos.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase com as opções do teu projecto
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // >>> AQUI: login anónimo só para o seed funcionar com as regras atuais
  await FirebaseAuth.instance.signInAnonymously();

  runApp(const SeedServicosApp());
}

class SeedServicosApp extends StatelessWidget {
  const SeedServicosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seed Serviços – ChegaJá',
      debugShowCheckedModeBanner: false,
      home: const SeedServicosPage(),
    );
  }
}

class SeedServicosPage extends StatefulWidget {
  const SeedServicosPage({super.key});

  @override
  State<SeedServicosPage> createState() => _SeedServicosPageState();
}

class _SeedServicosPageState extends State<SeedServicosPage> {
  bool _running = false;
  bool _done = false;
  String? _error;
  int _total = 0;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _runSeed();
  }

  Future<void> _runSeed() async {
    setState(() {
      _running = true;
      _done = false;
      _error = null;
      _total = initialServicos.length;
      _current = 0;
    });

    try {
      final db = FirebaseFirestore.instance;

      for (final servico in initialServicos) {
        final id = servico['id'] as String?;
        if (id == null || id.trim().isEmpty) {
          // ignora itens sem id
          continue;
        }

        // Cópia sem o campo 'id'
        final data = Map<String, dynamic>.from(servico);
        data.remove('id');

        await db.collection('servicos').doc(id).set(
              data,
              SetOptions(merge: true), // se já existir, faz merge
            );

        setState(() {
          _current++;
        });
      }

      setState(() {
        _running = false;
        _done = true;
      });
    } catch (e, st) {
      // ignore: avoid_print
      print('Erro ao fazer seed de servicos: $e\n$st');
      setState(() {
        _running = false;
        _done = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _total == 0 ? 0.0 : _current / _total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seed Serviços – ChegaJá'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_running) ...[
                const Text(
                  'A criar documentos na coleção "servicos"...',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: progress == 0 ? null : progress),
                const SizedBox(height: 8),
                Text('$_current / $_total'),
              ] else if (_error != null) ...[
                const Text(
                  'Ocorreu um erro ao fazer o seed:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _runSeed,
                  child: const Text('Tentar novamente'),
                ),
              ] else if (_done) ...[
                const Icon(Icons.check_circle, size: 48, color: Colors.green),
                const SizedBox(height: 12),
                const Text(
                  'Seed concluído com sucesso! 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Foram escritos $_total documentos na coleção "servicos".',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Agora já podes fechar esta janela\n'
                  'e voltar a correr o ChegaJá normalmente.',
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                const Text(
                  'Pronto para executar o seed de serviços.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _runSeed,
                  child: const Text('Executar seed'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
