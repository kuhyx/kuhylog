import 'package:flutter/material.dart';
import 'package:kuhylog/src/model/tracker.dart';

/// Asks for the value of a tracker that cannot be recorded with one tap.
///
/// Returns the chosen value, or `null` when dismissed.
class ValueDialog extends StatefulWidget {
  /// Creates the dialog for [tracker].
  const ValueDialog({required this.tracker, super.key});

  /// The tracker being recorded.
  final Tracker tracker;

  @override
  State<ValueDialog> createState() => _ValueDialogState();
}

class _ValueDialogState extends State<ValueDialog> {
  late double _value = widget.tracker.defaultValue;
  late final TextEditingController _controller = TextEditingController(
    text: _formatInitial(),
  );

  String _formatInitial() {
    final value = widget.tracker.defaultValue;
    return value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.tracker.label),
      content: _body(),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('value-dialog-save'),
          onPressed: _submit,
          child: const Text('Record'),
        ),
      ],
    );
  }

  Widget _body() {
    switch (widget.tracker.type) {
      case TrackerType.range:
        return _slider();
      case TrackerType.picker:
        return _picker();
      case TrackerType.tally:
      case TrackerType.value:
      case TrackerType.timer:
        return _field();
    }
  }

  Widget _slider() {
    final tracker = widget.tracker;
    final span = tracker.max - tracker.min;
    final divisions = tracker.step > 0 && span > 0
        ? (span / tracker.step).round()
        : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(tracker.uom.format(_value)),
        Slider(
          key: const Key('value-dialog-slider'),
          value: _value.clamp(tracker.min, tracker.max),
          min: tracker.min,
          max: tracker.max,
          divisions: divisions,
          onChanged: (value) => setState(() => _value = value),
        ),
      ],
    );
  }

  Widget _picker() {
    return SizedBox(
      width: double.maxFinite,
      child: RadioGroup<double>(
        groupValue: _value,
        onChanged: (value) => setState(() => _value = value ?? 0),
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            for (var i = 0; i < widget.tracker.options.length; i++)
              RadioListTile<double>(
                key: Key('value-dialog-option-$i'),
                value: i.toDouble(),
                title: Text(widget.tracker.options[i]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _field() {
    return TextField(
      key: const Key('value-dialog-field'),
      controller: _controller,
      autofocus: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: widget.tracker.uom.label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (text) => _value = double.tryParse(text) ?? 0,
      onSubmitted: (_) => _submit(),
    );
  }
}
