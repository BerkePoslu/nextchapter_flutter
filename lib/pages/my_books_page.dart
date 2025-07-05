import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/database_service.dart';
import 'book_detail_page.dart';
import 'book_search_page.dart';

class MyBooksPage extends StatefulWidget {
  const MyBooksPage({Key? key}) : super(key: key);

  @override
  State<MyBooksPage> createState() => _MyBooksPageState();
}

class _MyBooksPageState extends State<MyBooksPage> {
  List<Book> _books = [];
  bool _isLoading = true;
  String _filter = 'all'; // 'all', 'reading', 'finished'

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);
    try {
      List<Book> books;
      switch (_filter) {
        case 'reading':
          books = await DatabaseService().getCurrentlyReadingBooks();
          break;
        case 'finished':
          books = await DatabaseService().getFinishedBooks();
          break;
        default:
          books = await DatabaseService().getAllBooks();
      }
      setState(() {
        _books = books;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Bücher'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookSearchPage(),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (String value) {
              setState(() => _filter = value);
              _loadBooks();
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('Alle Bücher'),
              ),
              const PopupMenuItem(
                value: 'reading',
                child: Text('Aktuell am Lesen'),
              ),
              const PopupMenuItem(
                value: 'finished',
                child: Text('Gelesen'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
              ? const Center(
                  child: Text(
                    'Keine Bücher gefunden',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _books.length,
                  itemBuilder: (context, index) {
                    final book = _books[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: book.coverUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  book.coverUrl!,
                                  width: 50,
                                  height: 75,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.book, size: 50),
                                ),
                              )
                            : const Icon(Icons.book, size: 50),
                        title: Text(book.title),
                        subtitle: Text(book.author),
                        trailing: SizedBox(
                          width: 80,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${book.currentPage}/${book.totalPages}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 60,
                                child: LinearProgressIndicator(
                                  value: book.progress,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    book.isFinished
                                        ? Colors.green
                                        : Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookDetailPage(book: book),
                            ),
                          ).then((_) => _loadBooks());
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
