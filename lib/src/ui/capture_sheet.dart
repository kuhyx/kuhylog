import 'package:flutter/material.dart';
import 'package:kuhylog/src/model/trackable_type.dart';
import 'package:kuhylog/src/parse/note_tokenizer.dart';
import 'package:kuhylog/src/state/app_state.dart';

/// The free text capture surface.
///
/// Shows what the tokenizer found while typing, so the grammar is
/// discoverable instead of documented.
class CaptureSheet extends StatefulWidget {
  /// Creates the sheet over [state].
  const CaptureSheet({required this.state, super.key});

  /// The application state the note is recorded into.
  final AppState state;

  @override
  State<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends State<CaptureSheet> {
  final TextEditingController _controller = TextEditingController();
  String _note = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    widget.state.record(_note);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final refs = NoteTokenizer.parse(_note);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            key: const Key('capture-field'),
            controller: _controller,
            autofocus: true,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Slept well #sleep(7.5) with @ola +home',
              border: OutlineInputBorder(),
            ),
            onChanged: (text) => setState(() => _note = text),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final ref in refs)
                Chip(
                  key: Key('capture-chip-${ref.type.name}-${ref.id}'),
                  label: Text(
                    ref.hasValue ? '${ref.tag} ${ref.value}' : ref.tag,
                  ),
                  avatar: Text(_iconFor(ref.type)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('capture-save'),
            onPressed: _note.trim().isEmpty ? null : _save,
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }

  static String _iconFor(TrackableType type) {
    switch (type) {
      case TrackableType.tracker:
        return '#';
      case TrackableType.person:
        return '@';
      case TrackableType.context:
        return '+';
      case TrackableType.pointer:
        return '^';
      case TrackableType.place:
        return '/';
    }
  }
}
