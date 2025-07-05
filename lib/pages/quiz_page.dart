import 'package:flutter/material.dart';
import 'dart:ui';
import '../main.dart';
import '../services/ai_service.dart';
import '../models/book.dart';

class QuizPage extends StatefulWidget {
  final Book book;

  const QuizPage({Key? key, required this.book}) : super(key: key);

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int? _selectedAnswer;
  bool _showExplanation = false;
  int _score = 0;
  bool _isLoading = true;
  bool _quizCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() => _isLoading = true);
    try {
      final questions =
          await AIService().generateQuiz(widget.book, questionCount: 5);
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden des Quiz: $e')),
        );
      }
    }
  }

  void _selectAnswer(int answerIndex) {
    if (_showExplanation) return;

    setState(() {
      _selectedAnswer = answerIndex;
    });
  }

  void _showAnswerExplanation() {
    if (_selectedAnswer == null) return;

    setState(() {
      _showExplanation = true;
      if (_selectedAnswer == _questions[_currentQuestionIndex].correctAnswer) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _showExplanation = false;
      });
    } else {
      setState(() {
        _quizCompleted = true;
      });
    }
  }

  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedAnswer = null;
      _showExplanation = false;
      _score = 0;
      _quizCompleted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Quiz: ${widget.book.title}'),
          actions: [
            if (!_isLoading && _questions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    '${_currentQuestionIndex + 1}/${_questions.length}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _quizCompleted
                ? _buildQuizResults()
                : _questions.isEmpty
                    ? _buildNoQuestions()
                    : _buildQuizQuestion(),
      ),
    );
  }

  Widget _buildQuizQuestion() {
    final question = _questions[_currentQuestionIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          GlassCard(
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
                      '${((_currentQuestionIndex + 1) / _questions.length * 100).round()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / _questions.length,
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Question
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Frage ${_currentQuestionIndex + 1}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  question.question,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Answer options
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = _selectedAnswer == index;
            final isCorrect = index == question.correctAnswer;

            Color? backgroundColor;
            Color? borderColor;

            if (_showExplanation) {
              if (isCorrect) {
                backgroundColor = Colors.green.withOpacity(0.2);
                borderColor = Colors.green;
              } else if (isSelected && !isCorrect) {
                backgroundColor = Colors.red.withOpacity(0.2);
                borderColor = Colors.red;
              }
            } else if (isSelected) {
              backgroundColor =
                  Theme.of(context).colorScheme.primary.withOpacity(0.2);
              borderColor = Theme.of(context).colorScheme.primary;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _selectAnswer(index),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderColor ?? Colors.transparent,
                      width: 2,
                    ),
                    color: backgroundColor,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 24),

          // Explanation (if shown)
          if (_showExplanation) ...[
            GlassCard(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Erklärung',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question.explanation,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Action buttons
          Row(
            children: [
              if (!_showExplanation) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _selectedAnswer != null ? _showAnswerExplanation : null,
                    child: const Text('Antwort prüfen'),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: _nextQuestion,
                    child: Text(
                      _currentQuestionIndex < _questions.length - 1
                          ? 'Nächste Frage'
                          : 'Quiz beenden',
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 100), // Extra space for bottom navigation
        ],
      ),
    );
  }

  Widget _buildQuizResults() {
    final percentage = (_score / _questions.length * 100).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          GlassCard(
            child: Column(
              children: [
                Icon(
                  percentage >= 80
                      ? Icons.emoji_events
                      : percentage >= 60
                          ? Icons.thumb_up
                          : Icons.school,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Quiz abgeschlossen!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$_score von ${_questions.length} richtig',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  percentage >= 80
                      ? 'Ausgezeichnet! Du kennst das Buch sehr gut.'
                      : percentage >= 60
                          ? 'Gut gemacht! Du hast ein solides Verständnis.'
                          : 'Noch Raum für Verbesserungen. Lies das Buch noch einmal.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _restartQuiz,
                  child: const Text('Nochmal versuchen'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fertig'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildNoQuestions() {
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
              'Keine Fragen verfügbar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Das Quiz konnte nicht geladen werden.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadQuiz,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }
}
