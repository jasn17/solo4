import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/note.dart';

/// Thin SQLite helper for CRUD on the `notes` table.
///
/// Responsibilities:
/// - Opening/creating the database
/// - CRUD methods with small, defensive error handling
/// - A minimal 'reset' in case of detected corruption
class NotesDb {
  NotesDb._internal();
  static final NotesDb _instance = NotesDb._internal();

  /// Singleton accessor.
  factory NotesDb() => _instance;

  Database? _db;

  /// Lazily open and cache the database.
  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final base = await getDatabasesPath();
    final path = p.join(base, 'solo4_notes.db');

    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        // Foreign keys off by default on Android; safe to keep for future growth.
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            done INTEGER NOT NULL DEFAULT 0,
            createdAt INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  /// Fetch all notes ordered by most recent first.
  Future<List<Note>> fetchAll() async {
    try {
      final db = await _database;
      final rows = await db.query(
        'notes',
        orderBy: 'createdAt DESC',
      );
      return rows.map(Note.fromMap).toList();
    } on DatabaseException catch (e, st) {
      debugPrint('fetchAll(): database exception: $e\n$st');
      // Attempt a soft recovery path on corruption-like errors.
      await _reset();
      return <Note>[];
    } catch (e, st) {
      debugPrint('fetchAll(): unexpected error: $e\n$st');
      return <Note>[];
    }
  }

  /// Insert and return the newly saved note with its generated id.
  Future<Note> insert(Note note) async {
    final db = await _database;
    final id = await db.insert('notes', note.toMap());
    return note.copyWith(id: id);
  }

  /// Toggle the 'done' flag for a given id.
  Future<void> setDone(int id, bool done) async {
    final db = await _database;
    await db.update(
      'notes',
      {'done': done ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /// Delete all rows (used by 'Clear all').
  Future<void> deleteAll() async {
    final db = await _database;
    await db.delete('notes');
  }

  /// Drop and recreate the table (used on corruption recovery).
  Future<void> _reset() async {
    final db = await _database;
    await db.execute('DROP TABLE IF EXISTS notes');
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        done INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL
      )
    ''');
  }
}
