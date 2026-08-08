/// The kinds of trackable reference that can appear inside a note.
///
/// Each kind is introduced by a single sigil character, mirroring the
/// note grammar popularised by Nomie: `#tracker`, `@person`,
/// `+context`, `^pointer`, `/place`.
enum TrackableType {
  /// A user defined tracker, written `#tag` or `#tag(value)`.
  tracker('#'),

  /// A person, written `@name`.
  person('@'),

  /// A context or situation, written `+name`.
  context('+'),

  /// A pointer to a moment or entity, written `^name`.
  pointer('^'),

  /// A place, written `/name`.
  place('/');

  const TrackableType(this.sigil);

  /// The single character that introduces this kind in a note.
  final String sigil;

  /// Returns the type introduced by [sigil], or `null` if unknown.
  static TrackableType? fromSigil(String sigil) {
    switch (sigil) {
      case '#':
        return TrackableType.tracker;
      case '@':
        return TrackableType.person;
      case '+':
        return TrackableType.context;
      case '^':
        return TrackableType.pointer;
      case '/':
        return TrackableType.place;
      default:
        return null;
    }
  }
}
