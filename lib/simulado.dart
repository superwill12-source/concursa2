import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'db.dart';
import 'theme.dart';

class SimuladoScreen extends StatefulWidget {
  const SimuladoScreen({super.key});

  @override
  State<SimuladoScreen> createState() => _SimuladoScreenState();
}

class _SimuladoScreenState extends State<SimuladoScreen> {
  String tab = 'disponiveis';
  int count = 10;
  List<String> subjects = [];
  List<Map<String, Object?>> sessions = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final s = await AppDb.instance.values('subject');
    final h = await AppDb.instance.sessions();
    if (!mounted) return;
    setState(() {
      subjects = s;
      sessions = h;
    });
  }

  Future<void> start(String title, String subject) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SimuladoRunScreen(title: title, subject: subject, count: count),
      ),
    );
    load();
  }

  Widget _simuladoTile(String title, String subject) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$count questões', style: const TextStyle(color: dimText)),
        trailing: FilledButton(
          onPressed: () => start(title, subject),
          child: const Text('Iniciar'),
        ),
      ),
    );
  }

  Widget _historyTile(Map<String, Object?> s) {
    final total = (s['total'] as int?) ?? 0;
    final correct = (s['correct'] as int?) ?? 0;
    final pct = total == 0 ? 0 : (correct * 100 / total).round();
    final secs = (s['seconds'] as int?) ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: lime.withValues(alpha: .15),
          child: Text(
            '$pct%',
            style: const TextStyle(color: lime, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text('${s['title']}'),
        subtitle: Text(
          '$correct de $total acertos · ${fmtTime(secs)}\n${dateBr(s['createdAt'])}',
          style: const TextStyle(color: dimText),
        ),
        isThreeLine: true,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ResultScreen(sessionId: s['id'] as int)),
          );
          load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulados', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'disponiveis', label: Text('Disponíveis')),
              ButtonSegment(value: 'historico', label: Text('Histórico')),
            ],
            selected: {tab},
            onSelectionChanged: (s) => setState(() => tab = s.first),
          ),
          const SizedBox(height: 16),
          if (tab == 'disponiveis') ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quantidade de questões: $count'),
                    Slider(
                      value: count.toDouble(),
                      min: 5,
                      max: 30,
                      divisions: 5,
                      label: '$count',
                      onChanged: (v) => setState(() => count = v.round()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _simuladoTile('Simulado geral', ''),
            for (final s in subjects) _simuladoTile('Simulado de $s', s),
          ] else ...[
            if (sessions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Nenhum simulado feito ainda.', style: TextStyle(color: dimText)),
              ),
            for (final s in sessions) _historyTile(s),
          ],
        ],
      ),
    );
  }
}

class SimuladoRunScreen extends StatefulWidget {
  final String title;
  final String subject;
  final int count;

  const SimuladoRunScreen({
    super.key,
    required this.title,
    required this.subject,
    required this.count,
  });

  @override
  State<SimuladoRunScreen> createState() => _SimuladoRunScreenState();
}

class _SimuladoRunScreenState extends State<SimuladoRunScreen> {
  List<Question>? quiz;
  int index = 0;
  final Map<int, String> chosen = {};
  int seconds = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => seconds++);
    });
    load();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    final all = await AppDb.instance.questions(subject: widget.subject, limit: 1000);
    all.shuffle();
    final list = all.take(widget.count).toList();
    if (!mounted) return;
    setState(() => quiz = list);
  }

  Future<void> advance() async {
    final list = quiz!;
    if (index + 1 < list.length) {
      setState(() => index++);
      return;
    }
    timer?.cancel();
    final id = await AppDb.instance.saveSession(widget.title, list, chosen, seconds);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ResultScreen(sessionId: id)),
    );
  }

  Widget _opt(int i, Question q, String? sel) {
    final l = letters[i];
    final on = sel == l;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => chosen[q.id!] = l),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: on ? lime : Colors.white12, width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: on ? lime : Colors.white12,
                child: Text(
                  l,
                  style: TextStyle(
                    color: on ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(q.options[i])),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = quiz;
    if (list == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (list.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(
          child: Text(
            'Não há questões para este simulado. Importe questões primeiro.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final q = list[index];
    final sel = chosen[q.id];
    final valid = q.validIndexes;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                fmtTime(seconds),
                style: const TextStyle(color: lime, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          LinearProgressIndicator(
            value: (index + 1) / list.length,
            color: lime,
            backgroundColor: cardColor,
            minHeight: 6,
          ),
          const SizedBox(height: 10),
          Text(
            'Questão ${index + 1} de ${list.length}',
            style: const TextStyle(color: lime, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            q.prompt,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, height: 1.3),
          ),
          const SizedBox(height: 16),
          for (final i in valid) _opt(i, q, sel),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: sel == null ? null : advance,
              child: Text(index + 1 < list.length ? 'Próxima questão' : 'Finalizar simulado'),
            ),
          ),
        ],
      ),
    );
  }
}

class ResultScreen extends StatefulWidget {
  final int sessionId;

  const ResultScreen({super.key, required this.sessionId});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  Map<String, Object?>? session;
  List<Question> qs = [];
  Map<int, String> chosen = {};
  bool review = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final s = await AppDb.instance.sessionById(widget.sessionId);
    if (s == null) return;
    final details = jsonDecode((s['details'] ?? '[]').toString()) as List;
    final ids = <int>[];
    final ch = <int, String>{};
    for (final d in details) {
      final m = d as Map;
      final id = m['id'] as int;
      ids.add(id);
      ch[id] = (m['chosen'] ?? '').toString();
    }
    final list = await AppDb.instance.questionsByIds(ids);
    if (!mounted) return;
    setState(() {
      session = s;
      qs = list;
      chosen = ch;
    });
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: dimText)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _reviewTile(int i) {
    final q = qs[i];
    final c = chosen[q.id] ?? '-';
    final ok = c == q.answer;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  ok ? Icons.check_circle : Icons.cancel,
                  color: ok ? okColor : errColor,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(q.subject, style: const TextStyle(color: lime)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(q.prompt),
            const SizedBox(height: 6),
            Text(
              'Sua resposta: $c · Gabarito: ${q.answer}',
              style: const TextStyle(color: dimText),
            ),
            if (q.explanation.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(q.explanation, style: const TextStyle(color: dimText, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = session;
    if (s == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resultado')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final total = (s['total'] as int?) ?? 0;
    final correct = (s['correct'] as int?) ?? 0;
    final wrong = total - correct;
    final secs = (s['seconds'] as int?) ?? 0;
    final pct = total == 0 ? 0.0 : correct / total;

    final bySubject = <String, List<int>>{};
    for (final q in qs) {
      final ok = (chosen[q.id] ?? '') == q.answer;
      final e = bySubject.putIfAbsent(q.subject, () => [0, 0]);
      e[0]++;
      if (ok) e[1]++;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Resultado do simulado')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: CustomPaint(
                painter: DonutPainter(pct),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(pct * 100).round()}%',
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                      const Text('Desempenho', style: TextStyle(color: dimText, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row('Acertos', '$correct'),
                  _row('Erros', '$wrong'),
                  _row('Tempo', fmtTime(secs)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Por matéria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          for (final e in bySubject.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(e.key)),
                      Text(
                        '${(e.value[1] * 100 / e.value[0]).round()}%',
                        style: const TextStyle(color: lime, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: e.value[1] / e.value[0],
                    color: lime,
                    backgroundColor: cardColor,
                    minHeight: 8,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => setState(() => review = !review),
              child: Text(review ? 'Ocultar revisão' : 'Rever questões'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Voltar'),
            ),
          ),
          if (review) ...[
            const SizedBox(height: 16),
            for (var i = 0; i < qs.length; i++) _reviewTile(i),
          ],
        ],
      ),
    );
  }
}

class DonutPainter extends CustomPainter {
  final double value;

  DonutPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final r = (Offset.zero & size).deflate(stroke / 2);
    final base = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final arc = Paint()
      ..color = lime
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, 2 * math.pi, false, base);
    canvas.drawArc(r, -math.pi / 2, 2 * math.pi * value, false, arc);
  }

  @override
  bool shouldRepaint(covariant DonutPainter old) => old.value != value;
}
