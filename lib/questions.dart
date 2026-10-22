import 'package:flutter/material.dart';

import 'db.dart';
import 'theme.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  List<Map<String, Object?>> counts = [];
  Map<String, Map<String, Object?>> prog = {};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final c = await AppDb.instance.subjectCounts();
    final p = await AppDb.instance.subjectProgress();
    if (!mounted) return;
    setState(() {
      counts = c;
      prog = {for (final r in p) '${r['subject']}': r};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estudar', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (counts.isEmpty)
            const Text('Nenhuma matéria cadastrada ainda.', style: TextStyle(color: dimText)),
          for (final c in counts) _subjectCard(c),
        ],
      ),
    );
  }

  Widget _subjectCard(Map<String, Object?> c) {
    final name = '${c['subject']}';
    final n = (c['n'] as int?) ?? 0;
    final p = prog[name];
    final total = (p?['total'] as int?) ?? 0;
    final correct = (p?['correct'] as int?) ?? 0;
    final pct = total == 0 ? 0.0 : correct / total;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => QuestionsScreen(initialSubject: name)),
          );
          load();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Text('$n questões', style: const TextStyle(color: dimText)),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: pct,
                color: lime,
                backgroundColor: cardColor,
                minHeight: 8,
              ),
              const SizedBox(height: 6),
              Text(
                total == 0
                    ? 'Ainda não respondida'
                    : '${(pct * 100).round()}% de acerto em $total respostas',
                style: const TextStyle(color: dimText, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuestionsScreen extends StatefulWidget {
  final String initialSubject;

  const QuestionsScreen({super.key, this.initialSubject = ''});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  final search = TextEditingController();
  String tab = 'todas';
  late QFilter filter = QFilter(subject: widget.initialSubject);
  List<Question> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    final List<Question> list;
    if (tab == 'recentes') {
      list = await AppDb.instance.recentQuestions();
    } else {
      list = await AppDb.instance.questions(
        search: search.text,
        subject: filter.subject,
        board: filter.board,
        year: filter.year,
        difficulty: filter.difficulty,
        favoritesOnly: tab == 'favoritas',
      );
    }
    if (!mounted) return;
    setState(() {
      items = list;
      loading = false;
    });
  }

  Future<void> openFilters() async {
    final f = await Navigator.push<QFilter>(
      context,
      MaterialPageRoute(builder: (_) => FiltersScreen(filter: filter)),
    );
    if (f != null) {
      filter = f;
      refresh();
    }
  }

  Widget _card(int i) {
    final q = items[i];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => QuestionFlowScreen(items: items, start: i)),
          );
          refresh();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      q.subject,
                      style: const TextStyle(color: lime, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      q.favorite ? Icons.star : Icons.star_border,
                      color: q.favorite ? lime : dimText,
                    ),
                    onPressed: () async {
                      await AppDb.instance.setFavorite(q, !q.favorite);
                      refresh();
                    },
                  ),
                ],
              ),
              Text(
                q.prompt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  pill(q.difficulty, difficultyColor(q.difficulty)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${q.board} · ${q.year}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: dimText, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          filter.subject.isEmpty ? 'Questões' : filter.subject,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: search,
              onChanged: (_) => refresh(),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar questão, matéria, banca...',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'todas', label: Text('Todas')),
                ButtonSegment(value: 'favoritas', label: Text('Favoritas')),
                ButtonSegment(value: 'recentes', label: Text('Recentes')),
              ],
              selected: {tab},
              onSelectionChanged: (s) {
                setState(() => tab = s.first);
                refresh();
              },
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ActionChip(
                  label: Text(filter.subject.isEmpty ? 'Matéria' : filter.subject),
                  onPressed: openFilters,
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: Text(filter.board.isEmpty ? 'Banca' : filter.board),
                  onPressed: openFilters,
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: Text(filter.year.isEmpty ? 'Ano' : filter.year),
                  onPressed: openFilters,
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: Text(filter.difficulty.isEmpty ? 'Dificuldade' : filter.difficulty),
                  onPressed: openFilters,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhuma questão encontrada.',
                          style: TextStyle(color: dimText),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: items.length,
                        itemBuilder: (_, i) => _card(i),
                      ),
          ),
        ],
      ),
    );
  }
}

class FiltersScreen extends StatefulWidget {
  final QFilter filter;

  const FiltersScreen({super.key, required this.filter});

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  static const difficulties = ['Fácil', 'Médio', 'Difícil'];

  late QFilter f = widget.filter;
  List<String> subjects = [];
  List<String> boards = [];
  List<String> years = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final s = await AppDb.instance.values('subject');
    final b = await AppDb.instance.values('board');
    final y = await AppDb.instance.values('year');
    if (!mounted) return;
    setState(() {
      subjects = s;
      boards = b;
      years = y;
    });
  }

  Widget _drop(String label, String value, List<String> options, void Function(String) onChange) {
    final opts = (value.isEmpty || options.contains(value)) ? options : [...options, value];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        key: ValueKey('$label-$value-${opts.length}'),
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: [
          const DropdownMenuItem(value: '', child: Text('Todas')),
          for (final o in opts) DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (v) => onChange(v ?? ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Filtros')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _drop('Matéria', f.subject, subjects, (v) => setState(() => f = f.copyWith(subject: v))),
                  _drop('Banca', f.board, boards, (v) => setState(() => f = f.copyWith(board: v))),
                  _drop('Ano', f.year, years, (v) => setState(() => f = f.copyWith(year: v))),
                  const SizedBox(height: 8),
                  const Text('Dificuldade', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final d in ['', ...difficulties])
                        ChoiceChip(
                          label: Text(d.isEmpty ? 'Todas' : d),
                          selected: f.difficulty == d,
                          onSelected: (_) => setState(() => f = f.copyWith(difficulty: d)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, f),
                child: const Text('Aplicar filtros'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => setState(() => f = const QFilter()),
                child: const Text('Limpar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuestionFlowScreen extends StatefulWidget {
  final List<Question> items;
  final int start;

  const QuestionFlowScreen({super.key, required this.items, this.start = 0});

  @override
  State<QuestionFlowScreen> createState() => _QuestionFlowScreenState();
}

class _QuestionFlowScreenState extends State<QuestionFlowScreen> {
  late int index = widget.start;
  String? chosen;
  bool checked = false;
  late bool fav = widget.items[widget.start].favorite;

  Question get q => widget.items[index];

  Future<void> confirm() async {
    await AppDb.instance.recordAttempt(q, chosen!);
    if (!mounted) return;
    setState(() => checked = true);
  }

  void next() {
    if (index + 1 < widget.items.length) {
      setState(() {
        index++;
        chosen = null;
        checked = false;
        fav = q.favorite;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> toggleFav() async {
    await AppDb.instance.setFavorite(q, !fav);
    if (!mounted) return;
    setState(() => fav = !fav);
  }

  Color _optionColor(String l) {
    if (!checked) return l == chosen ? lime : Colors.white12;
    if (l == q.answer) return okColor;
    if (l == chosen) return errColor;
    return Colors.white12;
  }

  Widget _option(int i) {
    final l = letters[i];
    final color = _optionColor(l);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: checked ? null : () => setState(() => chosen = l),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: color.withValues(alpha: .2),
                child: Text(
                  l,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
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

  Widget _explanation() {
    final isRight = chosen == q.answer;
    final marcou = chosen ?? '-';
    final wrongLetters = [
      for (var i = 0; i < q.options.length; i++)
        if (q.options[i].trim().isNotEmpty && letters[i] != q.answer) letters[i],
    ];
    final sources = q.source.split('\n').where((s) => s.trim().isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            pill(isRight ? 'Resposta correta!' : 'Você marcou $marcou', isRight ? okColor : errColor),
            pill('Alternativa correta: ${q.answer}', okColor),
          ],
        ),
        const SizedBox(height: 12),
        if (q.explanation.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(q.explanation, style: const TextStyle(height: 1.4)),
            ),
          ),
        if (sources.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Fontes', style: TextStyle(fontWeight: FontWeight.bold, color: lime)),
          const SizedBox(height: 6),
          for (final s in sources) Text('• $s', style: const TextStyle(color: dimText)),
        ],
        if (wrongLetters.any((l) => (q.altNotes[l] ?? '').isNotEmpty)) ...[
          const SizedBox(height: 12),
          const Text('Outras alternativas', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          for (final l in wrongLetters)
            if ((q.altNotes[l] ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('$l) ${q.altNotes[l]}', style: const TextStyle(color: dimText)),
              ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final valid = q.validIndexes;
    final banca = q.exam.isEmpty ? q.board : '${q.exam} · ${q.board}';
    return Scaffold(
      appBar: AppBar(
        title: Text(checked ? 'Explicação' : 'Questão ${index + 1} de ${widget.items.length}'),
        actions: [
          IconButton(
            onPressed: toggleFav,
            icon: Icon(fav ? Icons.star : Icons.star_border, color: fav ? lime : null),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Row(
            children: [
              pill(q.subject, lime),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$banca · ${q.year}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: dimText, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            q.prompt,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, height: 1.3),
          ),
          const SizedBox(height: 16),
          for (final i in valid) _option(i),
          const SizedBox(height: 8),
          if (!checked)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: chosen == null ? null : confirm,
                child: const Text('Responder'),
              ),
            )
          else ...[
            _explanation(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: next,
                child: Text(index + 1 < widget.items.length ? 'Próxima questão' : 'Concluir'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
