import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../main.dart';
import '../services/ai_service.dart';
import '../models/book.dart';

class FlashcardsPage extends StatefulWidget {
  final Book book;

  const FlashcardsPage({Key? key, required this.book}) : super(key: key);

  @override
  State<FlashcardsPage> createState() => _FlashcardsPageState();
}

class _FlashcardsPageState extends State<FlashcardsPage>
    with TickerProviderStateMixin {
  List<Flashcard> _flashcards = [];
  int _currentCardIndex = 0;
  bool _isFlipped = false;
  bool _isLoading = true;
  late AnimationController _flipController;
  late AnimationController _slideController;
  late Animation<double> _flipAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));

    _loadFlashcards();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadFlashcards() async {
    setState(() => _isLoading = true);
    try {
      final flashcards =
          await AIService().generateFlashcards(widget.book, cardCount: 10);
      setState(() {
        _flashcards = flashcards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der Karteikarten: $e')),
        );
      }
    }
  }

  void _flipCard() {
    if (_flipController.isAnimating) return;

    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  void _nextCard() {
    if (_currentCardIndex < _flashcards.length - 1) {
      _slideController.forward().then((_) {
        setState(() {
          _currentCardIndex++;
          _isFlipped = false;
        });
        _flipController.reset();
        _slideController.reset();
      });
    }
  }

  void _previousCard() {
    if (_currentCardIndex > 0) {
      _slideController.forward().then((_) {
        setState(() {
          _currentCardIndex--;
          _isFlipped = false;
        });
        _flipController.reset();
        _slideController.reset();
      });
    }
  }

  void _resetCards() {
    setState(() {
      _currentCardIndex = 0;
      _isFlipped = false;
    });
    _flipController.reset();
    _slideController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Karteikarten: ${widget.book.title}'),
          actions: [
            if (!_isLoading && _flashcards.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    '${_currentCardIndex + 1}/${_flashcards.length}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _flashcards.isEmpty
                ? _buildNoFlashcards()
                : _buildFlashcardView(),
      ),
    );
  }

  Widget _buildFlashcardView() {
    return Column(
      children: [
        // Progress indicator
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: GlassCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fortschritt',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${((_currentCardIndex + 1) / _flashcards.length * 100).round()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_currentCardIndex + 1) / _flashcards.length,
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Flashcard
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: _flipCard,
                onPanEnd: (details) {
                  if (details.velocity.pixelsPerSecond.dx > 500) {
                    _previousCard();
                  } else if (details.velocity.pixelsPerSecond.dx < -500) {
                    _nextCard();
                  }
                },
                child: SlideTransition(
                  position: _slideAnimation,
                  child: AnimatedBuilder(
                    animation: _flipAnimation,
                    builder: (context, child) {
                      final isShowingFront = _flipAnimation.value < 0.5;
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(_flipAnimation.value * math.pi),
                        child: isShowingFront
                            ? _buildCardFront()
                            : Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateY(math.pi),
                                child: _buildCardBack(),
                              ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),

        // Controls
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Navigation buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: _currentCardIndex > 0 ? _previousCard : null,
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: _currentCardIndex > 0
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                    iconSize: 32,
                  ),
                  GestureDetector(
                    onTap: _flipCard,
                    child: GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flip,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Umdrehen',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _currentCardIndex < _flashcards.length - 1
                        ? _nextCard
                        : null,
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      color: _currentCardIndex < _flashcards.length - 1
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                    iconSize: 32,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetCards,
                      child: const Text('Von vorne'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentCardIndex == _flashcards.length - 1
                          ? () => Navigator.pop(context)
                          : null,
                      child: const Text('Fertig'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Hint text
              Text(
                'Tippe zum Umdrehen • Wische für nächste Karte',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 100), // Space for bottom navigation
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardFront() {
    final flashcard = _flashcards[_currentCardIndex];

    return Container(
      width: double.infinity,
      height: 300,
      child: GlassCard(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                flashcard.category,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Text(
                  flashcard.front,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app,
                  size: 16,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  'Tippen für Antwort',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack() {
    final flashcard = _flashcards[_currentCardIndex];

    return Container(
      width: double.infinity,
      height: 300,
      child: GlassCard(
        color:
            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Antwort',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Text(
                  flashcard.back,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.swipe_left,
                  size: 16,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  'Wischen für nächste Karte',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoFlashcards() {
    return Center(
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Karteikarten verfügbar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Die Karteikarten konnten nicht geladen werden.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFlashcards,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }
}
