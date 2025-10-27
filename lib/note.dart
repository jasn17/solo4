/// Note class for representing a single persisted item
class Note {
  /// Autoincrement primary key from SQLite for all variables
  final int? id;
  final String text;
  final bool done;
  final DateTime createdAt;

  Note ({
    this.id,
    required this.text,
    this.done = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create a modified copy of this [Note].
  Note copyWith({
    int? id,
    String? text,
    bool? done,
    DateTime? createdAt,
  }) {
    return Note(
      id: id ?? this.id,
      text: text ?? this.text,
      done: done ?? this.done,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to a map suitable for SQLite operations
  Map<String, Object?> toMap() => {
    'id': id,
    'text': text,
    'done': done ? 1 : 0,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  /// Construct a [Note] from a map originating from SQLite
  static Note fromMap(Map<String, Object?> map) {
    return Note(
      id: map['id'] as int?,
      text: map['text'] as String,
      done: (map['done'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] as int,
      ),
    );
  }
}
