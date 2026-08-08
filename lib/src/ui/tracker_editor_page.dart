import 'package:flutter/material.dart';
import 'package:kuhylog/src/model/tracker.dart';
import 'package:kuhylog/src/model/uom.dart';
import 'package:kuhylog/src/state/app_state.dart';

/// Creates or edits one tracker.
class TrackerEditorPage extends StatefulWidget {
  /// Creates the editor.
  ///
  /// A `null` [tracker] means a new one is being created.
  const TrackerEditorPage({required this.state, this.tracker, super.key});

  /// The application state the tracker is saved into.
  final AppState state;

  /// The tracker being edited, or `null` when creating.
  final Tracker? tracker;

  @override
  State<TrackerEditorPage> createState() => _TrackerEditorPageState();
}

class _TrackerEditorPageState extends State<TrackerEditorPage> {
  late final TextEditingController _label = TextEditingController(
    text: widget.tracker?.label ?? '',
  );
  late final TextEditingController _emoji = TextEditingController(
    text: widget.tracker?.emoji ?? '',
  );
  late TrackerType _type = widget.tracker?.type ?? TrackerType.tally;
  late Uom _uom = widget.tracker?.uom ?? Uom.count;
  late double _positivity = (widget.tracker?.positivity ?? 0).toDouble();

  /// Whether a new tracker is being created rather than edited.
  bool get isNew => widget.tracker == null;

  @override
  void dispose() {
    _label.dispose();
    _emoji.dispose();
    super.dispose();
  }

  void _save() {
    final label = _label.text.trim();
    if (label.isEmpty) {
      return;
    }
    final tag = widget.tracker?.tag ?? Tracker.slug(label);
    final base = widget.tracker ?? Tracker(tag: tag, label: label);
    widget.state.saveTracker(
      base.copyWith(
        label: label,
        emoji: _emoji.text.trim(),
        type: _type,
        uom: _uom,
        positivity: _positivity.round(),
      ),
    );
    Navigator.of(context).pop();
  }

  void _delete() {
    widget.state.deleteTracker(widget.tracker!.tag);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'New tracker' : 'Edit ${widget.tracker!.tag}'),
        actions: <Widget>[
          if (!isNew)
            IconButton(
              key: const Key('editor-delete'),
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TextField(
            key: const Key('editor-label'),
            controller: _label,
            decoration: const InputDecoration(
              labelText: 'Label',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('editor-emoji'),
            controller: _emoji,
            decoration: const InputDecoration(
              labelText: 'Emoji',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TrackerType>(
            key: const Key('editor-type'),
            initialValue: _type,
            decoration: const InputDecoration(
              labelText: 'Type',
              border: OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<TrackerType>>[
              for (final type in TrackerType.values)
                DropdownMenuItem<TrackerType>(
                  value: type,
                  child: Text(type.name),
                ),
            ],
            onChanged: (value) =>
                setState(() => _type = value ?? TrackerType.tally),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Uom>(
            key: const Key('editor-uom'),
            initialValue: _uom,
            decoration: const InputDecoration(
              labelText: 'Unit',
              border: OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<Uom>>[
              for (final unit in Uom.values)
                DropdownMenuItem<Uom>(
                  value: unit,
                  child: Text(unit.label),
                ),
            ],
            onChanged: (value) => setState(() => _uom = value ?? Uom.count),
          ),
          const SizedBox(height: 12),
          Text('Positivity ${_positivity.round()}'),
          Slider(
            key: const Key('editor-positivity'),
            value: _positivity,
            min: -5,
            max: 5,
            divisions: 10,
            onChanged: (value) => setState(() => _positivity = value),
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('editor-save'),
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
