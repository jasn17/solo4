import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notes_model.dart';
import 'note.dart';
import 'prefs.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => NotesModel(),
      child: const PocketNotesApp(),
    ),
  );
}

/// Root app widget with Material 3 and a single home page.
class PocketNotesApp extends StatelessWidget {
  const PocketNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const NotesPage(),
    );
  }
}

/// Main page with input row + list of notes.
/// Loads persistence in [initState] via the [NotesModel].
class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _textCtrl = TextEditingController();
  bool _greeted = false;

  @override
  void initState() {
    super.initState();
    // Load persisted data and preferences.
    final model = context.read<NotesModel>();
    model.loadOnStart().then((_) => _maybeShowFirstRun());
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _maybeShowFirstRun() async {
    if (_greeted) return;
    final prefs = AppPrefs();
    final shown = await prefs.getFirstRunShown();
    if (!shown && mounted) {
      _greeted = true;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Welcome 👋'),
          content: const Text(
            'Add a note, fully close the app, and reopen it to confirm your data persists.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
      await prefs.setFirstRunShown(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<NotesModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pocket Notes'),
        actions: [
          Row(
            children: [
              const Text('Show completed'),
              Switch(
                value: model.showCompleted,
                onChanged: model.setShowCompleted,
              ),
              IconButton(
                tooltip: 'Clear all',
                icon: const Icon(Icons.delete_sweep),
                onPressed: model.items.isEmpty
                    ? null
                    : () async {
                  await model.clearAll();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All notes cleared')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _InputRow(
            controller: _textCtrl,
            onSubmit: (value) async {
              await context.read<NotesModel>().add(value);
              _textCtrl.clear();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved')),
              );
            },
          ),
          const Divider(height: 0),
          Expanded(
            child: model.items.isEmpty
                ? const _EmptyState()
                : _NotesList(notes: model.items),
          ),
        ],
      ),
    );
  }
}

/// Text input + add button row.
class _InputRow extends StatelessWidget {
  const _InputRow({
    required this.controller,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.done,
              onSubmitted: onSubmit,
              decoration: const InputDecoration(
                hintText: 'Add a note…',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => onSubmit(controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

/// Message shown when there are no notes.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No notes yet — add one above.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Scrollable list of notes with checkbox toggles.
class _NotesList extends StatelessWidget {
  const _NotesList({required this.notes});

  final List<Note> notes;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: notes.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (context, index) {
        final note = notes[index];
        return ListTile(
          title: Text(
            note.text,
            style: note.done
                ? const TextStyle(
              decoration: TextDecoration.lineThrough,
              color: Colors.grey,
            )
                : null,
          ),
          subtitle: Text(
            note.createdAt.toLocal().toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Checkbox(
            value: note.done,
            onChanged: (_) => context.read<NotesModel>().toggle(note),
          ),
        );
      },
    );
  }
}
