import 'package:flutter/foundation.dart';
import 'db.dart';
import 'prefs.dart';
import 'note.dart';

/// App-level state that controls these features:
/// - Loading persisted data on startup
/// - Mutations (add, toggle, clear)
/// - Small UI preferences (showCompleted)
class NotesModel extends ChangeNotifier {
  NotesModel({
    NotesDb? db,
    AppPrefs? prefs,
  })  : _db = db ?? NotesDb(),
        _prefs = prefs ?? AppPrefs();

  final NotesDb _db;
  final AppPrefs _prefs;

  List<Note> _items = <Note>[];
  bool _showCompleted = true;

  /// Items filtered according to _showCompleted
  List<Note> get items =>
      _showCompleted ? _items : _items.where((n) => !n.done).toList();

  /// Exposed preference state.
  bool get showCompleted => _showCompleted;

  /// Load all persisted data and preferences and call this from the top page's `initState`.
  Future<void> loadOnStart() async {
    final notes = await _db.fetchAll();
    final show = await _prefs.getShowCompleted();
    _items = notes;
    _showCompleted = show;
    notifyListeners();
  }

  /// Add a new note with no-ops on blank/whitespace input
  Future<void> add(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final saved = await _db.insert(Note(text: trimmed));
    _items = <Note>[saved, ..._items];
    notifyListeners();
  }

  /// Toggle the 'done' status
  Future<void> toggle(Note note) async {
    if (note.id == null) return;
    final newDone = !note.done;
    await _db.setDone(note.id!, newDone);

    final idx = _items.indexWhere((n) => n.id == note.id);
    if (idx >= 0) {
      _items[idx] = note.copyWith(done: newDone);
      notifyListeners();
    }
  }

  /// Remove all notes
  Future<void> clearAll() async {
    await _db.deleteAll();
    _items = <Note>[];
    notifyListeners();
  }

  /// Save + apply the 'show completed' preference
  Future<void> setShowCompleted(bool value) async {
    _showCompleted = value;
    await _prefs.setShowCompleted(value);
    notifyListeners();
  }
}
