import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

const letters = ['A', 'B', 'C', 'D', 'E'];

class Question {
  final int? id;
  final String prompt;
  final List<String> options;
  final String answer;
  final String explanation;
  final Map<String, String> altNotes;
  final String subject;
  final String board;
  final String exam;
  final String year;
  final String difficulty;
  final String source;
  final bool favorite;

  Question({
    this.id,
    required this.prompt,
    required this.options,
    required this.answer,
    this.explanation = '',
    this.altNotes = const {},
    this.subject = 'Geral',
    this.board = 'Não informada',
    this.exam = '',
    this.year = '',
    this.difficulty = 'Médio',
    this.source = '',
    this.favorite = false,
  });

  factory Question.fromRow(Map<String, Object?> r) {
    final notes = <String, String>{};
    try {
      final m = jsonDecode((r['altNotes'] ?? '{}').toString()) as Map;
      m.forEach((k, v) {
        notes[k.toString()] = v.toString();
      });
    } catch (_) {}
    return Question(
      id: r['id'] as int?,
      prompt: (r['prompt'] ?? '').toString(),
      options: [
        for (final l in ['optionA', 'optionB', 'optionC', 'optionD', 'optionE'])
          (r[l] ?? '').toString(),
      ],
      answer: (r['answer'] ?? 'A').toString(),
      explanation: (r['explanation'] ?? '').toString(),
      altNotes: notes,
      subject: (r['subject'] ?? 'Geral').toString(),
      board: (r['board'] ?? 'Não informada').toString(),
      exam: (r['exam'] ?? '').toString(),
      year: (r['year'] ?? '').toString(),
      difficulty: (r['difficulty'] ?? 'Médio').toString(),
      source: (r['source'] ?? '').toString(),
      favorite: (r['favorite'] ?? 0) == 1,
    );
  }

  Map<String, Object?> toMap() {
    final m = <String, Object?>{
      'prompt': prompt,
      'answer': answer,
      'explanation': explanation,
      'altNotes': jsonEncode(altNotes),
      'subject': subject,
      'board': board,
      'exam': exam,
      'year': year,
      'difficulty': difficulty,
      'source': source,
      'favorite': favorite ? 1 : 0,
    };
    for (var i = 0; i < 5; i++) {
      m['option${letters[i]}'] = i < options.length ? options[i] : '';
    }
    return m;
  }

  List<int> get validIndexes => [
        for (var i = 0; i < options.length; i++)
          if (options[i].trim().isNotEmpty) i,
      ];
}

class QFilter {
  final String subject;
  final String board;
  final String year;
  final String difficulty;

  const QFilter({
    this.subject = '',
    this.board = '',
    this.year = '',
    this.difficulty = '',
  });

  QFilter copyWith({String? subject, String? board, String? year, String? difficulty}) =>
      QFilter(
        subject: subject ?? this.subject,
        board: board ?? this.board,
        year: year ?? this.year,
        difficulty: difficulty ?? this.difficulty,
      );
}

final demoQuestions = <Question>[
  Question(
    prompt: 'Acerca de princípios da Administração Pública, assinale a alternativa correta.',
    options: [
      'A impessoalidade é um princípio que se aplica apenas aos atos administrativos.',
      'A moralidade administrativa é um princípio que visa apenas à legalidade dos atos.',
      'A eficiência pode ser alcançada por meio da simplificação de procedimentos.',
      'A publicidade é um princípio que se limita à divulgação de atos administrativos.',
      '',
    ],
    answer: 'C',
    explanation:
        'A eficiência é um princípio da Administração Pública que visa à obtenção de resultados com o melhor uso dos recursos públicos. Pode ser alcançada, entre outras formas, pela simplificação de procedimentos.',
    altNotes: {
      'A': 'Incorreta: a impessoalidade se aplica a todos os atos administrativos, não apenas a alguns.',
      'B': 'Incorreta: a moralidade está ligada à ética e à probidade, e não se limita à legalidade.',
      'D': 'Incorreta: a publicidade também exige transparência e acesso à informação, não apenas divulgação.',
    },
    subject: 'Direito Administrativo',
    board: 'Exemplo didático',
    exam: 'Questão demonstrativa',
    year: '2026',
    difficulty: 'Fácil',
    source: 'CF/88 – Art. 37, caput',
  ),
  Question(
    prompt: 'Na língua portuguesa, qual classe de palavra normalmente caracteriza um substantivo?',
    options: ['Verbo', 'Preposição', 'Adjetivo', 'Conjunção', 'Interjeição'],
    answer: 'C',
    explanation: 'O adjetivo atribui característica ou qualidade a um substantivo.',
    subject: 'Português',
    board: 'Exemplo didático',
    exam: 'Questão demonstrativa',
    year: '2026',
    difficulty: 'Fácil',
    source: 'Gramática normativa da língua portuguesa',
  ),
  Question(
    prompt: 'Qual é o resultado de 15% de 200?',
    options: ['15', '20', '25', '30', '35'],
    answer: 'D',
    explanation: '10% de 200 é 20 e 5% de 200 é 10. Somando, 15% de 200 é 30.',
    subject: 'Raciocínio Lógico',
    board: 'Exemplo didático',
    exam: 'Questão demonstrativa',
    year: '2026',
    difficulty: 'Fácil',
    source: 'Porcentagem básica',
  ),
  Question(
    prompt: 'Qual órgão exerce tipicamente a função legislativa em um município brasileiro?',
    options: ['Câmara Municipal', 'Prefeitura', 'Tribunal de Justiça', 'Ministério Público', 'Defensoria Pública'],
    answer: 'A',
    explanation: 'A Câmara Municipal é o órgão legislativo do município. A prefeitura exerce a função executiva.',
    subject: 'Conhecimentos Gerais',
    board: 'Exemplo didático',
    exam: 'Questão demonstrativa',
    year: '2026',
    difficulty: 'Médio',
    source: 'Constituição Federal de 1988, arts. 29 e 31',
  ),
  Question(
    prompt: 'Em informática, para que serve principalmente um navegador web?',
    options: [
      'Editar hardware',
      'Acessar páginas e aplicações da web',
      'Substituir o sistema operacional',
      'Criar memória RAM',
      'Formatar automaticamente o computador',
    ],
    answer: 'B',
    explanation: 'Navegadores permitem acessar e interagir com páginas e aplicações disponíveis na internet.',
    subject: 'Informática',
    board: 'Exemplo didático',
    exam: 'Questão demonstrativa',
    year: '2026',
    difficulty: 'Fácil',
    source: 'Conceitos básicos de informática',
  ),
  Question(
    prompt: 'Se 3 operários fazem uma obra em 12 dias, quantos dias 4 operários, no mesmo ritmo, levariam?',
    options: ['8 dias', '9 dias', '10 dias', '16 dias', '36 dias'],
    answer: 'B',
    explanation: 'Trabalho total = 3 × 12 = 36 operário-dia. Com 4 operários: 36 ÷ 4 = 9 dias.',
    subject: 'Matemática',
    board: 'Exemplo didático',
    exam: 'Questão demonstrativa',
    year: '2026',
    difficulty: 'Difícil',
    source: 'Regra de três inversa',
  ),
];

class AppDb {
  AppDb._();
  static final AppDb instance = AppDb._();

  late final Database db;

  Future<void> init() async {
    final path = p.join(await getDatabasesPath(), 'concursa_v3.db');
    db = await openDatabase(path, version: 1, onCreate: (d, _) async {
      await d.execute(
        'CREATE TABLE questions(id INTEGER PRIMARY KEY AUTOINCREMENT, prompt TEXT NOT NULL, '
        'optionA TEXT, optionB TEXT, optionC TEXT, optionD TEXT, optionE TEXT, answer TEXT NOT NULL, '
        'explanation TEXT, altNotes TEXT, subject TEXT, board TEXT, exam TEXT, year TEXT, '
        'difficulty TEXT, source TEXT, favorite INTEGER DEFAULT 0)',
      );
      await d.execute(
        'CREATE TABLE attempts(id INTEGER PRIMARY KEY AUTOINCREMENT, questionId INTEGER, '
        'chosen TEXT, correct INTEGER, createdAt TEXT)',
      );
      await d.execute(
        'CREATE TABLE sessions(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, total INTEGER, '
        'correct INTEGER, seconds INTEGER, details TEXT, createdAt TEXT)',
      );
      final batch = d.batch();
      for (final q in demoQuestions) {
        batch.insert('questions', q.toMap());
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<Question>> questions({
    String search = '',
    String subject = '',
    String board = '',
    String year = '',
    String difficulty = '',
    bool favoritesOnly = false,
    int limit = 1000,
  }) async {
    final where = <String>[];
    final args = <Object?>[];
    if (search.trim().isNotEmpty) {
      where.add('(prompt LIKE ? OR subject LIKE ? OR board LIKE ? OR exam LIKE ?)');
      final s = '%${search.trim()}%';
      args.addAll([s, s, s, s]);
    }
    if (subject.isNotEmpty) {
      where.add('subject = ?');
      args.add(subject);
    }
    if (board.isNotEmpty) {
      where.add('board = ?');
      args.add(board);
    }
    if (year.isNotEmpty) {
      where.add('year = ?');
      args.add(year);
    }
    if (difficulty.isNotEmpty) {
      where.add('difficulty = ?');
      args.add(difficulty);
    }
    if (favoritesOnly) where.add('favorite = 1');
    final rows = await db.query(
      'questions',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
      orderBy: 'id DESC',
      limit: limit,
    );
    return rows.map(Question.fromRow).toList();
  }

  Future<List<Question>> recentQuestions() async {
    final rows = await db.rawQuery(
      'SELECT q.* FROM questions q JOIN (SELECT questionId, MAX(id) AS mx FROM attempts '
      'GROUP BY questionId) a ON a.questionId = q.id ORDER BY a.mx DESC LIMIT 100',
    );
    return rows.map(Question.fromRow).toList();
  }

  Future<Question?> lastAnswered() async {
    final rows = await db.rawQuery(
      'SELECT q.* FROM attempts a JOIN questions q ON q.id = a.questionId ORDER BY a.id DESC LIMIT 1',
    );
    if (rows.isEmpty) return null;
    return Question.fromRow(rows.first);
  }

  Future<List<Question>> questionsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final marks = List.filled(ids.length, '?').join(',');
    final rows = await db.query(
      'questions',
      where: 'id IN ($marks)',
      whereArgs: ids,
    );
    final list = rows.map(Question.fromRow).toList();
    list.sort((a, b) => ids.indexOf(a.id!).compareTo(ids.indexOf(b.id!)));
    return list;
  }

  Future<List<String>> values(String col) async {
    final rows = await db.rawQuery(
      "SELECT DISTINCT $col AS v FROM questions WHERE $col IS NOT NULL AND $col != '' ORDER BY $col",
    );
    return rows.map((r) => r['v'].toString()).toList();
  }

  Future<List<Map<String, Object?>>> subjectCounts() => db.rawQuery(
        'SELECT subject, COUNT(*) AS n FROM questions GROUP BY subject ORDER BY subject',
      );

  Future<List<Map<String, Object?>>> subjectProgress() => db.rawQuery(
        'SELECT q.subject AS subject, COUNT(a.id) AS total, SUM(a.correct) AS correct '
        'FROM attempts a JOIN questions q ON q.id = a.questionId '
        'GROUP BY q.subject ORDER BY total DESC',
      );

  Future<int> _count(String sql) async {
    final r = await db.rawQuery(sql);
    return (r.first.values.first as int?) ?? 0;
  }

  Future<Map<String, int>> stats() async {
    return {
      'questions': await _count('SELECT COUNT(*) FROM questions'),
      'answered': await _count('SELECT COUNT(*) FROM attempts'),
      'correct': await _count('SELECT COUNT(*) FROM attempts WHERE correct = 1'),
      'simulados': await _count('SELECT COUNT(*) FROM sessions'),
      'days': await _count('SELECT COUNT(DISTINCT substr(createdAt, 1, 10)) FROM attempts'),
      'favorites': await _count('SELECT COUNT(*) FROM questions WHERE favorite = 1'),
    };
  }

  Future<void> setFavorite(Question q, bool value) async {
    await db.update(
      'questions',
      {'favorite': value ? 1 : 0},
      where: 'id = ?',
      whereArgs: [q.id],
    );
  }

  Future<void> recordAttempt(Question q, String chosen) async {
    await db.insert('attempts', {
      'questionId': q.id,
      'chosen': chosen,
      'correct': chosen == q.answer ? 1 : 0,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<int> saveSession(
    String title,
    List<Question> qs,
    Map<int, String> chosen,
    int seconds,
  ) async {
    var correct = 0;
    final details = <Map<String, Object?>>[];
    final now = DateTime.now().toIso8601String();
    for (final q in qs) {
      final c = chosen[q.id];
      final ok = c != null && c == q.answer;
      if (ok) correct++;
      details.add({'id': q.id, 'chosen': c ?? ''});
      if (c != null) {
        await db.insert('attempts', {
          'questionId': q.id,
          'chosen': c,
          'correct': ok ? 1 : 0,
          'createdAt': now,
        });
      }
    }
    return db.insert('sessions', {
      'title': title,
      'total': qs.length,
      'correct': correct,
      'seconds': seconds,
      'details': jsonEncode(details),
      'createdAt': now,
    });
  }

  Future<List<Map<String, Object?>>> sessions() =>
      db.query('sessions', orderBy: 'id DESC', limit: 50);

  Future<Map<String, Object?>?> sessionById(int id) async {
    final rows = await db.query('sessions', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> importJson(String text) async {
    final decoded = jsonDecode(text);
    if (decoded is! List) {
      throw const FormatException('O JSON deve ser uma lista de questões entre colchetes.');
    }
    var count = 0;
    final batch = db.batch();
    for (final item in decoded) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final prompt = (m['prompt'] ?? m['question'] ?? '').toString().trim();
      final answer = (m['answer'] ?? '').toString().toUpperCase().trim();
      if (prompt.isEmpty || !letters.contains(answer)) continue;
      String opt(String l) => (m['option$l'] ?? m[l] ?? '').toString().trim();
      final an = m['altNotes'];
      final notes = <String, String>{};
      if (an is Map) {
        an.forEach((k, v) {
          notes[k.toString()] = v.toString();
        });
      }
      final q = Question(
        prompt: prompt,
        options: [for (final l in letters) opt(l)],
        answer: answer,
        explanation: (m['explanation'] ?? '').toString(),
        altNotes: notes,
        subject: (m['subject'] ?? 'Geral').toString(),
        board: (m['board'] ?? 'Não informada').toString(),
        exam: (m['exam'] ?? '').toString(),
        year: (m['year'] ?? '').toString(),
        difficulty: (m['difficulty'] ?? 'Médio').toString(),
        source: (m['source'] ?? '').toString(),
      );
      batch.insert('questions', q.toMap());
      count++;
    }
    await batch.commit(noResult: true);
    return count;
  }

  Future<String> exportJson() async {
    final rows = await db.query('questions');
    return const JsonEncoder.withIndent('  ').convert(rows);
  }
}
