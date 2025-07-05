import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/book.dart';
import '../services/database_service.dart';
import '../main.dart';
import 'book_detail_page.dart';

class BookSearchPage extends StatefulWidget {
  const BookSearchPage({Key? key}) : super(key: key);

  @override
  State<BookSearchPage> createState() => _BookSearchPageState();
}

class _BookSearchPageState extends State<BookSearchPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Book> _allBooks = [];
  List<Book> _filteredBooks = [];
  bool _isLoading = true;
  bool _showFilters = false;

  // Filter states
  String _sortBy = 'title'; // title, author, dateAdded, progress
  bool _sortAscending = true;
  Set<String> _selectedAuthors = {};
  Set<String> _selectedTags = {};
  String _progressFilter = 'all'; // all, reading, finished, notStarted

  // Available filter options
  List<String> _allAuthors = [];
  List<String> _allTags = [];

  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  @override
  void initState() {
    super.initState();
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );

    _loadBooks();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _filterAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);

    try {
      final books = await DatabaseService().getAllBooks();
      setState(() {
        _allBooks = books;
        _filteredBooks = books;
        _allAuthors = books.map((b) => b.author).toSet().toList()..sort();
        _allTags = books.expand((b) => b.tags ?? <String>[]).toSet().toList()
          ..sort();
      });

      _applyFilters();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der Bücher: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredBooks = _allBooks.where((book) {
        // Text search
        final matchesSearch = query.isEmpty ||
            book.title.toLowerCase().contains(query) ||
            book.author.toLowerCase().contains(query) ||
            (book.description?.toLowerCase().contains(query) ?? false);

        // Author filter
        final matchesAuthor =
            _selectedAuthors.isEmpty || _selectedAuthors.contains(book.author);

        // Tags filter
        final matchesTags = _selectedTags.isEmpty ||
            (book.tags?.any((tag) => _selectedTags.contains(tag)) ?? false);

        // Progress filter
        final matchesProgress = _progressFilter == 'all' ||
            (_progressFilter == 'reading' &&
                book.currentPage > 0 &&
                book.currentPage < book.totalPages) ||
            (_progressFilter == 'finished' &&
                book.currentPage >= book.totalPages) ||
            (_progressFilter == 'notStarted' && book.currentPage == 0);

        return matchesSearch && matchesAuthor && matchesTags && matchesProgress;
      }).toList();

      // Apply sorting
      _filteredBooks.sort((a, b) {
        int comparison = 0;

        switch (_sortBy) {
          case 'title':
            comparison = a.title.compareTo(b.title);
            break;
          case 'author':
            comparison = a.author.compareTo(b.author);
            break;
          case 'dateAdded':
            comparison = a.startDate.compareTo(b.startDate);
            break;
          case 'progress':
            comparison = a.progress.compareTo(b.progress);
            break;
        }

        return _sortAscending ? comparison : -comparison;
      });
    });
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });

    if (_showFilters) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedAuthors.clear();
      _selectedTags.clear();
      _progressFilter = 'all';
      _sortBy = 'title';
      _sortAscending = true;
      _searchController.clear();
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bücher durchsuchen'),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                color:
                    _showFilters ? Theme.of(context).colorScheme.primary : null,
              ),
              onPressed: _toggleFilters,
            ),
            if (_isFilterActive())
              IconButton(
                icon: const Icon(Icons.clear_all),
                onPressed: _resetFilters,
                tooltip: 'Filter zurücksetzen',
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildSearchContent(),
      ),
    );
  }

  bool _isFilterActive() {
    return _selectedAuthors.isNotEmpty ||
        _selectedTags.isNotEmpty ||
        _progressFilter != 'all' ||
        _sortBy != 'title' ||
        !_sortAscending ||
        _searchController.text.isNotEmpty;
  }

  Widget _buildSearchContent() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: GlassCard(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Bücher, Autoren oder Beschreibungen durchsuchen...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchFocusNode.unfocus();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),

        // Filters panel
        AnimatedBuilder(
          animation: _filterAnimation,
          builder: (context, child) {
            return SizeTransition(
              sizeFactor: _filterAnimation,
              child: _buildFiltersPanel(),
            );
          },
        ),

        // Results
        Expanded(
          child: _buildResults(),
        ),
      ],
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter & Sortierung',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // Sort options
              _buildSortSection(),
              const SizedBox(height: 16),

              // Progress filter
              _buildProgressFilterSection(),
              const SizedBox(height: 16),

              // Author filter
              if (_allAuthors.isNotEmpty) ...[
                _buildAuthorFilterSection(),
                const SizedBox(height: 16),
              ],

              // Tags filter
              if (_allTags.isNotEmpty) ...[
                _buildTagsFilterSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sortieren nach',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _sortBy,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'title', child: Text('Titel')),
                  DropdownMenuItem(value: 'author', child: Text('Autor')),
                  DropdownMenuItem(
                      value: 'dateAdded', child: Text('Hinzugefügt')),
                  DropdownMenuItem(
                      value: 'progress', child: Text('Fortschritt')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                  _applyFilters();
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                setState(() {
                  _sortAscending = !_sortAscending;
                });
                _applyFilters();
              },
              icon: Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lesestatus',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _progressFilter,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Alle Bücher')),
            DropdownMenuItem(value: 'reading', child: Text('Aktuell lesen')),
            DropdownMenuItem(value: 'finished', child: Text('Abgeschlossen')),
            DropdownMenuItem(
                value: 'notStarted', child: Text('Noch nicht begonnen')),
          ],
          onChanged: (value) {
            setState(() {
              _progressFilter = value!;
            });
            _applyFilters();
          },
        ),
      ],
    );
  }

  Widget _buildAuthorFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Autoren',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _allAuthors.map((author) {
            final isSelected = _selectedAuthors.contains(author);
            return FilterChip(
              label: Text(author),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedAuthors.add(author);
                  } else {
                    _selectedAuthors.remove(author);
                  }
                });
                _applyFilters();
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTagsFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _allTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
                _applyFilters();
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (_filteredBooks.isEmpty) {
      return _buildEmptyResults();
    }

    return Column(
      children: [
        // Results count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Text(
                '${_filteredBooks.length} ${_filteredBooks.length == 1 ? 'Buch' : 'Bücher'} gefunden',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),

        // Books list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _filteredBooks.length,
            itemBuilder: (context, index) {
              final book = _filteredBooks[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildBookCard(book),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookCard(Book book) {
    return GlassCard(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailPage(book: book),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Book cover
              Container(
                width: 50,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
                child: book.coverUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          book.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.book,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.book,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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

                    // Progress indicator
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: book.progress,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(book.progress * 100).round()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),

                    // Tags
                    if (book.tags != null && book.tags!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children: book.tags!.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyResults() {
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
                  Icons.search_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'Keine Bücher gefunden',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Versuchen Sie andere Suchbegriffe oder passen Sie die Filter an.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Alle Filter zurücksetzen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
