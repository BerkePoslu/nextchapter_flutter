import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../models/book.dart';
import '../services/database_service.dart';
import '../main.dart';

class ReadingStatisticsPage extends StatefulWidget {
  const ReadingStatisticsPage({Key? key}) : super(key: key);

  @override
  State<ReadingStatisticsPage> createState() => _ReadingStatisticsPageState();
}

class _ReadingStatisticsPageState extends State<ReadingStatisticsPage>
    with TickerProviderStateMixin {
  List<Book> _allBooks = [];
  List<Book> _finishedBooks = [];
  List<Book> _currentlyReadingBooks = [];
  bool _isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  // Statistics
  int _totalBooksRead = 0;
  int _totalPagesRead = 0;
  int _totalReadingDays = 0;
  double _averageBooksPerMonth = 0.0;
  double _averagePagesPerDay = 0.0;
  String _favoriteAuthor = '';
  String _longestBook = '';
  String _fastestRead = '';
  Map<String, int> _genreStats = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _loadStatistics();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      final allBooks = await DatabaseService().getAllBooks();
      final finishedBooks = await DatabaseService().getFinishedBooks();
      final currentlyReadingBooks =
          await DatabaseService().getCurrentlyReadingBooks();

      setState(() {
        _allBooks = allBooks;
        _finishedBooks = finishedBooks;
        _currentlyReadingBooks = currentlyReadingBooks;
      });

      _calculateStatistics();
      _animationController.forward();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der Statistiken: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateStatistics() {
    _totalBooksRead = _finishedBooks.length;
    _totalPagesRead =
        _finishedBooks.fold(0, (sum, book) => sum + book.totalPages);

    // Calculate reading days
    if (_finishedBooks.isNotEmpty) {
      final firstBook = _finishedBooks
          .reduce((a, b) => a.startDate.isBefore(b.startDate) ? a : b);
      final lastBook = _finishedBooks.reduce((a, b) =>
          (a.finishDate ?? DateTime.now())
                  .isAfter(b.finishDate ?? DateTime.now())
              ? a
              : b);

      _totalReadingDays = (lastBook.finishDate ?? DateTime.now())
          .difference(firstBook.startDate)
          .inDays;

      if (_totalReadingDays > 0) {
        _averageBooksPerMonth = (_totalBooksRead * 30.0) / _totalReadingDays;
        _averagePagesPerDay = _totalPagesRead / _totalReadingDays;
      }
    }

    // Find favorite author
    final authorCounts = <String, int>{};
    for (var book in _finishedBooks) {
      authorCounts[book.author] = (authorCounts[book.author] ?? 0) + 1;
    }

    if (authorCounts.isNotEmpty) {
      _favoriteAuthor =
          authorCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    // Find longest book
    if (_finishedBooks.isNotEmpty) {
      final longest =
          _finishedBooks.reduce((a, b) => a.totalPages > b.totalPages ? a : b);
      _longestBook = '${longest.title} (${longest.totalPages} S.)';
    }

    // Find fastest read (shortest reading time)
    Book? fastest;
    int shortestDays = 999999;

    for (var book in _finishedBooks) {
      if (book.finishDate != null) {
        final readingDays =
            book.finishDate!.difference(book.startDate).inDays + 1;
        if (readingDays < shortestDays) {
          shortestDays = readingDays;
          fastest = book;
        }
      }
    }

    if (fastest != null) {
      _fastestRead =
          '${fastest.title} ($shortestDays Tag${shortestDays != 1 ? 'e' : ''})';
    }

    // Calculate genre stats (using tags if available)
    _genreStats.clear();
    for (var book in _finishedBooks) {
      if (book.tags != null && book.tags!.isNotEmpty) {
        for (var tag in book.tags!) {
          _genreStats[tag] = (_genreStats[tag] ?? 0) + 1;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lese-Statistiken'),
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildStatisticsContent(),
      ),
    );
  }

  Widget _buildStatisticsContent() {
    if (_allBooks.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCards(),
                    const SizedBox(height: 24),
                    _buildReadingProgress(),
                    const SizedBox(height: 24),
                    _buildDetailedStats(),
                    const SizedBox(height: 24),
                    _buildGenreBreakdown(),
                    const SizedBox(height: 24),
                    _buildReadingStreak(),
                    const SizedBox(
                        height: 100), // Bottom padding for navigation
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
                  Icons.bar_chart,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'Keine Statistiken verfügbar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fügen Sie Bücher hinzu und beginnen Sie zu lesen, um Ihre Statistiken zu sehen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Gelesene Bücher',
            value: _totalBooksRead.toString(),
            icon: Icons.book,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Gelesene Seiten',
            value: _formatNumber(_totalPagesRead),
            icon: Icons.pages,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingProgress() {
    final currentlyReadingCount = _currentlyReadingBooks.length;
    final totalCurrentPages =
        _currentlyReadingBooks.fold(0, (sum, book) => sum + book.currentPage);
    final totalCurrentMaxPages =
        _currentlyReadingBooks.fold(0, (sum, book) => sum + book.totalPages);
    final overallProgress = totalCurrentMaxPages > 0
        ? totalCurrentPages / totalCurrentMaxPages
        : 0.0;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Theme.of(context).colorScheme.tertiary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Aktueller Fortschritt',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$currentlyReadingCount',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                      Text(
                        'Bücher in Bearbeitung',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: overallProgress,
                        strokeWidth: 8,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .tertiary
                            .withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                      Center(
                        child: Text(
                          '${(overallProgress * 100).round()}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStats() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Detaillierte Statistiken',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailStatRow(
              'Durchschnitt pro Monat',
              '${_averageBooksPerMonth.toStringAsFixed(1)} Bücher',
              Icons.calendar_month,
            ),
            _buildDetailStatRow(
              'Seiten pro Tag',
              '${_averagePagesPerDay.toStringAsFixed(1)} Seiten',
              Icons.today,
            ),
            if (_favoriteAuthor.isNotEmpty)
              _buildDetailStatRow(
                'Lieblings-Autor',
                _favoriteAuthor,
                Icons.person,
              ),
            if (_longestBook.isNotEmpty)
              _buildDetailStatRow(
                'Längstes Buch',
                _longestBook,
                Icons.book,
              ),
            if (_fastestRead.isNotEmpty)
              _buildDetailStatRow(
                'Schnellster Read',
                _fastestRead,
                Icons.speed,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreBreakdown() {
    if (_genreStats.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedGenres = _genreStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.category,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Genre-Verteilung',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...sortedGenres.take(5).map((entry) {
              final percentage = (entry.value / _totalBooksRead * 100);
              return _buildGenreBar(entry.key, entry.value, percentage);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreBar(String genre, int count, double percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                genre,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '$count Bücher',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor:
                Theme.of(context).colorScheme.secondary.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.secondary,
            ),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildReadingStreak() {
    // Calculate current streak (simplified)
    int currentStreak = 0;
    DateTime now = DateTime.now();

    // Check last 30 days for reading activity
    for (int i = 0; i < 30; i++) {
      final checkDate = now.subtract(Duration(days: i));
      bool hasReadingActivity = _finishedBooks.any((book) =>
          book.finishDate != null &&
          book.finishDate!.year == checkDate.year &&
          book.finishDate!.month == checkDate.month &&
          book.finishDate!.day == checkDate.day);

      if (hasReadingActivity) {
        currentStreak++;
      } else if (i > 0) {
        break; // Streak is broken
      }
    }

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Lese-Streak',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  '$currentStreak',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tage in Folge',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        currentStreak > 0
                            ? 'Großartig! Machen Sie weiter so!'
                            : 'Beginnen Sie eine neue Streak!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}
