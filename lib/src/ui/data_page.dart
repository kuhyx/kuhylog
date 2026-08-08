import 'package:flutter/material.dart';
import 'package:kuhylog/src/importer/import_result.dart';
import 'package:kuhylog/src/state/app_state.dart';

/// Import and export, with no file picker and no cloud.
///
/// Text in, text out: paste a backup to import it, and read an export
/// straight off the screen. That keeps the whole data path inspectable
/// and free of platform plugins.
class DataPage extends StatefulWidget {
  /// Creates the page over [state].
  const DataPage({required this.state, super.key});

  /// The application state being imported into or exported from.
  final AppState state;

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  final TextEditingController _input = TextEditingController();
  String _output = '';
  ImportResult? _result;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _importJson() {
    setState(() => _result = widget.state.importBackup(_input.text));
  }

  void _importCsv() {
    setState(() => _result = widget.state.importCsv(_input.text));
  }

  void _export(String Function() render) {
    setState(() => _output = render());
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Data')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('Import', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            key: const Key('data-input'),
            controller: _input,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Paste a JSON backup or a CSV export',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              FilledButton(
                key: const Key('data-import-json'),
                onPressed: _importJson,
                child: const Text('Import JSON'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('data-import-csv'),
                onPressed: _importCsv,
                child: const Text('Import CSV'),
              ),
            ],
          ),
          if (result != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(result.summary, key: const Key('data-import-summary')),
            for (final warning in result.warnings)
              Text('- $warning', style: Theme.of(context).textTheme.bodySmall),
          ],
          const Divider(height: 32),
          Text('Export', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: <Widget>[
              OutlinedButton(
                key: const Key('data-export-json'),
                onPressed: () => _export(widget.state.exportBackup),
                child: const Text('Backup JSON'),
              ),
              OutlinedButton(
                key: const Key('data-export-journal'),
                onPressed: () => _export(widget.state.exportJournalCsv),
                child: const Text('Journal CSV'),
              ),
              OutlinedButton(
                key: const Key('data-export-time'),
                onPressed: () => _export(widget.state.exportTimeCsv),
                child: const Text('Time CSV'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_output.isNotEmpty)
            SelectableText(_output, key: const Key('data-output')),
        ],
      ),
    );
  }
}
