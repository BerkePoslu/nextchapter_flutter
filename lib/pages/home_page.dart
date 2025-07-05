import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/book.dart';
import '../services/database_service.dart';
import '../main.dart';
import 'add_book_page.dart';
import 'my_books_page.dart';
import 'ai_exam_page.dart';
import 'book_detail_page.dart';
import 'reading_reminders_page.dart';
import 'book_search_page.dart';
import 'reading_statistics_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Book? _currentlyReadingBook;
  int _totalBooksRead = 0;
  int _totalReadingTimeHours = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    setState(() => _isLoading = true);
    try {
      // Get currently reading books
      final currentlyReadingBooks =
          await DatabaseService().getCurrentlyReadingBooks();

      // Get finished books count
      final finishedBooks = await DatabaseService().getFinishedBooks();

      // Calculate total reading time (simplified calculation)
      int totalHours = 0;
      for (var book in finishedBooks) {
        if (book.finishDate != null) {
          final readingDays =
              book.finishDate!.difference(book.startDate).inDays;
          totalHours +=
              (readingDays * 1.5).round(); // Estimate 1.5 hours per day
        }
      }

      setState(() {
        _currentlyReadingBook = currentlyReadingBooks.isNotEmpty
            ? currentlyReadingBooks.first
            : null;
        _totalBooksRead = finishedBooks.length;
        _totalReadingTimeHours = totalHours;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der Daten: $e')),
        );
      }
    }
  }

  Future<void> _showBookSelectionDialog() async {
    final allBooks = await DatabaseService().getAllBooks();
    final unfinishedBooks = allBooks.where((book) => !book.isFinished).toList();

    if (unfinishedBooks.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keine verfügbaren Bücher zum Lesen')),
        );
      }
      return;
    }

    final selectedBook = await showDialog<Book>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: GlassCard(
            borderRadius: 20,
            blur: 15,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Buch auswählen',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: unfinishedBooks.length,
                    itemBuilder: (context, index) {
                      final book = unfinishedBooks[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.white.withOpacity(0.3),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.book_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(
                            book.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            book.author,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                          onTap: () => Navigator.pop(context, book),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5),
                        ),
                      ),
                      child: const Text('Abbrechen'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (selectedBook != null) {
      setState(() {
        _currentlyReadingBook = selectedBook;
      });
    }
  }

  void _navigateToAddBook() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddBookPage()),
    ).then((_) => _loadHomeData());
  }

  void _navigateToMyBooks() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyBooksPage()),
    ).then((_) => _loadHomeData());
  }

  void _navigateToAIQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AIExamPage()),
    );
  }

  void _navigateToReminders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReadingRemindersPage()),
    );
  }

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BookSearchPage()),
    );
  }

  void _navigateToStatistics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReadingStatisticsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NextChapter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _navigateToReminders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHomeData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Currently Reading Section
                      Text(
                        'Aktuell am Lesen',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        child: _currentlyReadingBook != null
                            ? _buildCurrentlyReadingCard()
                            : _buildNoBookSelectedCard(),
                      ),
                      const SizedBox(height: 24),

                      // Reading Statistics
                      Text(
                        'Lese-Statistiken',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Gelesene Bücher',
                              _totalBooksRead.toString(),
                              Icons.book_rounded,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Lesezeit',
                              '${_totalReadingTimeHours}h',
                              Icons.timer_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Quick Actions
                      Text(
                        'Schnellzugriff',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.spaceAround,
                        spacing: 16.0,
                        runSpacing: 16.0,
                        children: [
                          _buildQuickActionButton(
                            context,
                            'Buch hinzufügen',
                            Icons.add_rounded,
                            _navigateToAddBook,
                          ),
                          _buildQuickActionButton(
                            context,
                            'KI-Quiz',
                            Icons.school_rounded,
                            _navigateToAIQuiz,
                          ),
                          _buildQuickActionButton(
                            context,
                            'Meine Bücher',
                            Icons.menu_book_rounded,
                            _navigateToMyBooks,
                          ),
                          _buildQuickActionButton(
                            context,
                            'Erinnerungen',
                            Icons.notifications_rounded,
                            _navigateToReminders,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentlyReadingCard() {
    final book = _currentlyReadingBook!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookDetailPage(book: book),
                  ),
                ).then((_) => _loadHomeData());
              },
              child: Container(
                width: 80,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.black.withOpacity(0.15),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: book.coverUrl != null
                      ? Image.network(
                          book.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.book_rounded,
                                size: 40,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.book_rounded,
                              size: 40,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 16),
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
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'von ${book.author}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${book.currentPage} von ${book.totalPages} Seiten',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: book.progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _showBookSelectionDialog,
                child: const Text('Anderes Buch wählen'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookDetailPage(book: book),
                    ),
                  ).then((_) => _loadHomeData());
                },
                child: const Text('Details'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoBookSelectedCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 80,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.book_rounded,
                      size: 40,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kein Buch ausgewählt',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Wähle ein Buch aus deiner Bibliothek oder füge ein neues hinzu.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _showBookSelectionDialog,
                          child: const Text('Buch auswählen'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _navigateToAddBook,
                          child: const Text('Neues Buch'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return GlassCard(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            icon,
            size: 36,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
