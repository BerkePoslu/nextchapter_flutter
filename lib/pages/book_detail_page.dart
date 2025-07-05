import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/database_service.dart';
import 'notes_page.dart';

class BookDetailPage extends StatefulWidget {
  final Book book;

  const BookDetailPage({Key? key, required this.book}) : super(key: key);

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  late Book _book;
  final _pageController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _pageController.text = _book.currentPage.toString();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _updateProgress() async {
    final newPage = int.tryParse(_pageController.text);
    if (newPage != null && newPage >= 0 && newPage <= _book.totalPages) {
      final updatedBook = _book.copyWith(
        currentPage: newPage,
        finishDate: newPage == _book.totalPages ? DateTime.now() : null,
      );

      try {
        await DatabaseService().updateBook(updatedBook);
        setState(() {
          _book = updatedBook;
          _isEditing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fortschritt aktualisiert')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Aktualisieren: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bitte geben Sie eine gültige Seitenzahl ein'),
          ),
        );
      }
    }
  }

  Future<void> _deleteBook() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buch löschen'),
        content: const Text('Möchten Sie dieses Buch wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseService().deleteBook(_book.id);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Löschen: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_book.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteBook,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            Center(
              child: Container(
                width: 200,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _book.coverUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _book.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.book, size: 100),
                        ),
                      )
                    : const Icon(Icons.book, size: 100),
              ),
            ),
            const SizedBox(height: 24),

            // Book Details
            Text(
              _book.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'von ${_book.author}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Progress
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fortschritt',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _book.progress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _book.isFinished
                            ? Colors.green
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isEditing)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _pageController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Aktuelle Seite',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _updateProgress,
                            child: const Text('Speichern'),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_book.currentPage} von ${_book.totalPages} Seiten',
                            style: const TextStyle(fontSize: 16),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() => _isEditing = true);
                            },
                            child: const Text('Bearbeiten'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Additional Information
            if (_book.description != null) ...[
              const Text(
                'Beschreibung',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(_book.description!),
              const SizedBox(height: 16),
            ],

            // Notizen-Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotesPage(book: _book),
                    ),
                  );
                },
                icon: const Icon(Icons.note_alt),
                label: const Text('Notizen'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_book.isbn != null) ...[
              const Text(
                'ISBN',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(_book.isbn!),
              const SizedBox(height: 16),
            ],

            if (_book.tags != null && _book.tags!.isNotEmpty) ...[
              const Text(
                'Tags',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    _book.tags!.map((tag) => Chip(label: Text(tag))).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
