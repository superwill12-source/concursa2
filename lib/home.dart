import 'package:flutter/material.dart';

import 'db.dart';
import 'questions.dart';
import 'theme.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int tab) onTab;

  const HomeScreen({super.key, required this.onTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, int> stats = {};
  Question? last;
  List<Map<String, Object?>> progress = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final s = await AppDb.instance.stats();
    final l = await AppDb.instance.lastAnswered();
    final pr = await AppDb.instance.subjectProgress();
    if (!mounted) return;
    setState(() {
      stats = s;
      last = l;
      progress = pr;
    });
  }

  Widget _tile(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(color: dimText)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _action(String title, String sub, IconData icon, int tab) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: lime.withValues(alpha: .15),
          child: Icon(icon, color: lime),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub, style: const TextStyle(color: dimText)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => widget.onTab(tab),
      ),
    );
  }

  Widget _subjectBar(Map<String, Object?> r) {
    final total = (r['total'] as int?) ?? 0;
    final correct = (r['correct'] as int?) ?? 0;
    final v = total == 0 ? 0.0 : correct / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${r['subject']}', overflow: TextOverflow.ellipsis),
              ),
              Text(
                '${(v * 100).round()}%',
                style: const TextStyle(color: lime, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: v,
            color: lime,
            backgroundColor: cardColor,
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lastQ = last;
    final answered = stats['answered'] ?? 0;
    final correct = stats['correct'] ?? 0;
    final pct = answered == 0 ? 0 : (correct * 100 / answered).round();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.school, color: lime),
            SizedBox(width: 8),
            Text('Concursa', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: lime, size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, estudante!',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                          Text(
                            'Continue firme no seu objetivo.',
                            style: TextStyle(color: dimText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.7,
              children: [
                _tile('Questões', '${stats['questions'] ?? 0}'),
                _tile('Simulados', '${stats['simulados'] ?? 0}'),
                _tile('Acertos', '$pct%'),
                _tile('Dias de estudo', '${stats['days'] ?? 0}'),
              ],
            ),
            const SizedBox(height: 16),
            if (lastQ != null)
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuestionFlowScreen(items: [lastQ], start: 0),
                    ),
                  );
                  load();
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: lime,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.play_circle_fill, color: Colors.black, size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Continuar estudando',
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              lastQ.subject,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black87, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward, color: Colors.black),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'Comece agora',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _action('Banco de questões', 'Pesquise por matéria, banca ou palavra-chave', Icons.search, 2),
            _action('Simulado', 'Treine e veja sua pontuação', Icons.quiz, 3),
            _action('Importar questões', 'Adicione questões em formato JSON', Icons.file_upload_outlined, 4),
            const SizedBox(height: 16),
            const Text(
              'Matérias mais estudadas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (progress.isEmpty)
              const Text(
                'Responda questões para ver seu desempenho por matéria.',
                style: TextStyle(color: dimText),
              ),
            for (final r in progress.take(5)) _subjectBar(r),
            const SizedBox(height: 8),
            const Text(
              'As questões de exemplo são didáticas, não são provas oficiais.',
              style: TextStyle(color: dimText, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
