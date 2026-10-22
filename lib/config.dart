import 'package:flutter/material.dart';

import 'db.dart';
import 'theme.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(t, style: const TextStyle(color: lime, fontWeight: FontWeight.bold)),
      );

  Widget _tile(IconData icon, String title, String sub, VoidCallback? onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: lime),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub, style: const TextStyle(color: dimText)),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final data = await AppDb.instance.exportJson();
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup das questões'),
        content: SizedBox(
          width: double.maxFinite,
          height: 360,
          child: SingleChildScrollView(
            child: SelectableText(data, style: const TextStyle(fontSize: 11)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Banco de dados'),
          _tile(
            Icons.file_upload_outlined,
            'Importar questões (JSON)',
            'Cole a lista de questões no formato indicado',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportScreen())),
          ),
          _tile(
            Icons.ios_share,
            'Exportar backup',
            'Veja o JSON com todas as suas questões',
            () => _export(context),
          ),
          _section('Sobre'),
          _tile(Icons.info_outline, 'Versão', '1.0.0', null),
        ],
      ),
    );
  }
}

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final controller = TextEditingController();
  String status = '';
  bool busy = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> importar() async {
    setState(() {
      busy = true;
      status = '';
    });
    try {
      final n = await AppDb.instance.importJson(controller.text);
      if (!mounted) return;
      setState(() {
        status = n == 0
            ? 'Nenhuma questão válida encontrada. Confira o formato.'
            : '$n questões importadas com sucesso.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => status = 'Erro no JSON: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importar questões')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Cole aqui a lista de questões em JSON. Elas ficam salvas no aparelho e funcionam offline.',
            style: TextStyle(color: dimText),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            minLines: 8,
            maxLines: 14,
            decoration: const InputDecoration(hintText: 'Cole o JSON aqui...'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: busy ? null : importar,
              child: Text(busy ? 'Importando...' : 'Importar questões'),
            ),
          ),
          if (status.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(status, style: const TextStyle(color: lime)),
            ),
          const SizedBox(height: 20),
          const Text('Formato aceito', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                exemploJson,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Use apenas questões que você tenha direito de usar. As questões de exemplo são didáticas, não são provas oficiais.',
            style: TextStyle(color: dimText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

const exemploJson = r'''[
  {
    "prompt": "Enunciado da questão",
    "optionA": "Alternativa A",
    "optionB": "Alternativa B",
    "optionC": "Alternativa C",
    "optionD": "Alternativa D",
    "optionE": "",
    "answer": "B",
    "explanation": "Explicação do gabarito",
    "altNotes": {"A": "Por que a A está errada"},
    "subject": "Português",
    "board": "Banca",
    "exam": "Cargo ou prova",
    "year": "2025",
    "difficulty": "Médio",
    "source": "Referência legal ou fonte"
  }
]''';
