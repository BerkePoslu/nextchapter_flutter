import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/book.dart';
import '../services/database_service.dart';
import '../main.dart';
import 'book_detail_page.dart';

class CurrentlyReadingPage extends StatefulWidget {
  const CurrentlyReadingPage({Key? key}) : super(key: key);

  @override
  State<CurrentlyReadingPage> createState() => _CurrentlyReadingPageState();
}

class _CurrentlyReadingPageState extends State<CurrentlyReadingPage> {
  List<Book> _currentlyReadingBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentlyReadingBooks();
  }

  Future<void> _loadCurrentlyReadingBooks() async {
    setState(() => _isLoading = true);
    try {
      final books = await DatabaseService().getCurrentlyReadingBooks();
      setState(() {
        _currentlyReadingBooks = books;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der Bücher: $e')),
        );
      }
    }
  }

  void _updateProgress(Book book, int newPage) async {
    try {
      final updatedBook = book.copyWith(currentPage: newPage);
      await DatabaseService().updateBook(updatedBook);

      // Reload the list to show updated progress
      _loadCurrentlyReadingBooks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fortschritt aktualisiert'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Aktualisieren: $e')),
        );
      }
    }
  }

  void _showProgressDialog(Book book) {
    final controller = TextEditingController(text: book.currentPage.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            Theme.of(context).colorScheme.surface.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Lesefortschritt aktualisieren',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              book.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Aktuelle Seite',
                hintText: 'Geben Sie die Seitenzahl ein',
                suffix: Text('von ${book.totalPages}'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              final newPage = int.tryParse(controller.text);
              if (newPage != null &&
                  newPage >= 0 &&
                  newPage <= book.totalPages) {
                Navigator.pop(context);
                _updateProgress(book, newPage);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Bitte geben Sie eine gültige Seitenzahl ein'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Aktualisieren'),
          ),
        ],
      ),
    );
  }

  String _getReadingTimeEstimate(Book book) {
    if (book.currentPage == 0) return 'Noch nicht begonnen';

    final remainingPages = book.totalPages - book.currentPage;
    final estimatedMinutes =
        (remainingPages * 2.5).round(); // ~2.5 minutes per page

    if (estimatedMinutes < 60) {
      return '~$estimatedMinutes Min. verbleibend';
    } else {
      final hours = (estimatedMinutes / 60).round();
      return '~$hours Std. verbleibend';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lese ich gerade'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadCurrentlyReadingBooks,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _currentlyReadingBooks.isEmpty
                ? _buildEmptyState()
                : _buildBooksList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'Keine Bücher in Bearbeitung',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Beginnen Sie mit dem Lesen eines neuen Buches, um es hier zu sehen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to add book page
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Buch hinzufügen'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBooksList() {
    return RefreshIndicator(
      onRefresh: _loadCurrentlyReadingBooks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _currentlyReadingBooks.length,
        itemBuilder: (context, index) {
          final book = _currentlyReadingBooks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: GlassCard(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookDetailPage(book: book),
                    ),
                  ).then((_) => _loadCurrentlyReadingBooks());
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Book cover placeholder
                          Container(
                            width: 60,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.2),
                            ),
                            child: book.coverUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      book.coverUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                        Icons.book,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        size: 30,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.book,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 30,
                                  ),
                          ),
                          const SizedBox(width: 16),

                          // Book info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'von ${book.author}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getReadingTimeEstimate(book),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Progress update button
                          IconButton(
                            onPressed: () => _showProgressDialog(book),
                            icon: Icon(
                              Icons.edit,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            tooltip: 'Fortschritt aktualisieren',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Progress indicator
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Seite ${book.currentPage} von ${book.totalPages}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${(book.progress * 100).round()}%',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: book.progress,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                  minHeight: 6,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (book.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.description,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  book.description!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.8),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
