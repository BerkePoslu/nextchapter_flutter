import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/book.dart';
import '../models/note.dart';
import '../services/database_service.dart';

class NotesPage extends StatefulWidget {
  final Book book;

  const NotesPage({Key? key, required this.book}) : super(key: key);

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Note> _notes = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _pageController = TextEditingController();
  String _selectedType = NoteType.text;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _noteController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      final notes = await DatabaseService().getNotesByBook(widget.book.id);
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der Notizen: $e')),
        );
      }
    }
  }

  Future<void> _searchNotes(String query) async {
    if (query.isEmpty) {
      _loadNotes();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final notes = await DatabaseService().searchNotes(query);
      final bookNotes =
          notes.where((note) => note.bookId == widget.book.id).toList();
      setState(() {
        _notes = bookNotes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler bei der Suche: $e')),
        );
      }
    }
  }

  Future<void> _addNote() async {
    if (_noteController.text.trim().isEmpty) return;

    final note = Note(
      bookId: widget.book.id,
      content: _noteController.text.trim(),
      pageNumber: int.tryParse(_pageController.text),
      type: _selectedType,
    );

    try {
      await DatabaseService().insertNote(note);
      _noteController.clear();
      _pageController.clear();
      _loadNotes();
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $e')),
        );
      }
    }
  }

  Future<void> _deleteNote(Note note) async {
    try {
      await DatabaseService().deleteNote(note.id);
      _loadNotes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Löschen: $e')),
        );
      }
    }
  }

  void _showAddNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Neue Notiz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Notiz',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pageController,
              decoration: const InputDecoration(
                labelText: 'Seitennummer (optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Typ',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: NoteType.text, child: Text('Text')),
                DropdownMenuItem(
                    value: NoteType.highlight, child: Text('Highlight')),
                DropdownMenuItem(
                    value: NoteType.bookmark, child: Text('Lesezeichen')),
                DropdownMenuItem(value: NoteType.quote, child: Text('Zitat')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: _addNote,
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notizen zu "${widget.book.title}"'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddNoteDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Suchleiste
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Notizen durchsuchen...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchNotes('');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _searchNotes(value);
              },
            ),
          ),

          // Notizen-Liste
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.note_alt_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Noch keine Notizen vorhanden'
                                  : 'Keine Notizen gefunden',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _showAddNoteDialog,
                              child: const Text('Erste Notiz hinzufügen'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notes.length,
                        itemBuilder: (context, index) {
                          final note = _notes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _getNoteIcon(note.type),
                                        size: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _getNoteTypeLabel(note.type),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (note.pageNumber != null) ...[
                                        const Spacer(),
                                        Text(
                                          'Seite ${note.pageNumber}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(width: 8),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'delete') {
                                            _deleteNote(note);
                                          } else if (value == 'copy') {
                                            Clipboard.setData(ClipboardData(
                                                text: note.content));
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content:
                                                      Text('Notiz kopiert')),
                                            );
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'copy',
                                            child: Text('Kopieren'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Löschen'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    note.content,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatDate(note.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  IconData _getNoteIcon(String type) {
    switch (type) {
      case NoteType.highlight:
        return Icons.highlight;
      case NoteType.bookmark:
        return Icons.bookmark;
      case NoteType.quote:
        return Icons.format_quote;
      default:
        return Icons.note;
    }
  }

  String _getNoteTypeLabel(String type) {
    switch (type) {
      case NoteType.highlight:
        return 'Highlight';
      case NoteType.bookmark:
        return 'Lesezeichen';
      case NoteType.quote:
        return 'Zitat';
      default:
        return 'Notiz';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
