import 'package:flutter/material.dart';
import 'dart:ui';
import '../main.dart';
import '../models/book.dart';
import '../services/database_service.dart';
import 'quiz_page.dart';
import 'flashcards_page.dart';
import 'summary_page.dart';
import 'ai_exam_generator_page.dart';

class AIExamPage extends StatefulWidget {
  const AIExamPage({Key? key}) : super(key: key);

  @override
  State<AIExamPage> createState() => _AIExamPageState();
}

class _AIExamPageState extends State<AIExamPage> {
  List<Book> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final books = await DatabaseService().getAllBooks();
    setState(() {
      _books = books;
      _isLoading = false;
    });
  }

  void _showBookSelectionDialog(String feature) {
    if (_books.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Füge zuerst einige Bücher hinzu, um KI-Features zu nutzen.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _buildBookSelectionDialog(feature),
    );
  }

  Widget _buildBookSelectionDialog(String feature) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [
                          Colors.grey[900]!.withOpacity(0.9),
                          Colors.grey[800]!.withOpacity(0.8),
                        ]
                      : [
                          Colors.white.withOpacity(0.9),
                          Colors.grey[100]!.withOpacity(0.8),
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Buch für $feature auswählen',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _books.length,
                      itemBuilder: (context, index) {
                        final book = _books[index];
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.2),
                            ),
                            child: Icon(
                              Icons.book,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            book.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
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
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToFeature(feature, book);
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Abbrechen'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToFeature(String feature, Book book) {
    switch (feature) {
      case 'Quiz Generator':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => QuizPage(book: book)),
        );
        break;
      case 'Zusammenfassungen':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SummaryPage(book: book)),
        );
        break;
      case 'Karteikarten':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FlashcardsPage(book: book)),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('KI-Klausurvorbereitung'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KI-gestützte Lernhilfen',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 16),

              // AI Exam Generator Card
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.psychology_rounded,
                          color: Colors.purple,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'KI-Prüfungsgenerator',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Erstelle eine komplette Prüfung mit Multiple-Choice Fragen, Essay-Fragen und Lernkarten durch einfache Eingabe eines Buchtitels.',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AIExamGeneratorPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Komplette Prüfung erstellen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Quiz Generation Card
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.quiz_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Quiz Generator',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Generiere automatisch Fragen basierend auf deinen gelesenen Büchern.',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showBookSelectionDialog('Quiz Generator');
                        },
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Quiz erstellen'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Summary Generation Card
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.summarize_rounded,
                          color: Theme.of(context).colorScheme.secondary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Zusammenfassungen',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Erstelle KI-generierte Zusammenfassungen deiner Bücher für effizientes Lernen.',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showBookSelectionDialog('Zusammenfassungen');
                        },
                        icon: const Icon(Icons.auto_fix_high),
                        label: const Text('Zusammenfassung erstellen'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Flashcards Card
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.style_rounded,
                          color: Theme.of(context).colorScheme.tertiary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Karteikarten',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Automatisch generierte Karteikarten mit wichtigen Konzepten und Definitionen.',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showBookSelectionDialog('Karteikarten');
                        },
                        icon: const Icon(Icons.auto_stories),
                        label: const Text('Karteikarten erstellen'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Info Card
              GlassCard(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.3),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Wähle ein Buch aus deiner Bibliothek aus, um KI-gestützte Lernhilfen zu erstellen!',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100), // Extra space for bottom navigation
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassCard(
          borderRadius: 20,
          blur: 15,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.construction_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Bald verfügbar!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$feature wird in einem zukünftigen Update implementiert.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Verstanden'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
