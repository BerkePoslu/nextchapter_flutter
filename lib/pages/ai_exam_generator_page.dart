import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:convert' as dart_convert;
import 'dart:math' as math;
import '../main.dart';
import '../services/ai_service.dart';

class AIExamGeneratorPage extends StatefulWidget {
  const AIExamGeneratorPage({Key? key}) : super(key: key);

  @override
  State<AIExamGeneratorPage> createState() => _AIExamGeneratorPageState();
}

class _AIExamGeneratorPageState extends State<AIExamGeneratorPage>
    with TickerProviderStateMixin {
  final TextEditingController _bookController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();

  bool _isGenerating = false;
  String _currentStep = '';

  List<ExamQuestion> _multipleChoiceQuestions = [];
  List<EssayQuestion> _essayQuestions = [];
  List<StudyFlashcard> _flashcards = [];

  late AnimationController _progressAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _cardAnimation;

  int _currentFlashcardIndex = 0;
  bool _showFlashcardAnswer = false;

  @override
  void initState() {
    super.initState();
    _progressAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));

    _cardAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _bookController.dispose();
    _authorController.dispose();
    _progressAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  Future<void> _generateExam() async {
    if (_bookController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte geben Sie einen Buchtitel ein')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _multipleChoiceQuestions.clear();
      _essayQuestions.clear();
      _flashcards.clear();
    });

    _progressAnimationController.forward();

    try {
      // Step 1: Generate Multiple Choice Questions
      setState(() => _currentStep = 'Erstelle Multiple-Choice Fragen...');
      await Future.delayed(const Duration(milliseconds: 500));
      _multipleChoiceQuestions = await _generateMultipleChoiceQuestions();

      // Step 2: Generate Essay Questions
      setState(() => _currentStep = 'Erstelle Essay-Fragen...');
      await Future.delayed(const Duration(milliseconds: 500));
      _essayQuestions = await _generateEssayQuestions();

      // Step 3: Generate Flashcards
      setState(() => _currentStep = 'Erstelle Lernkarten...');
      await Future.delayed(const Duration(milliseconds: 500));
      _flashcards = await _generateStudyFlashcards();

      setState(() {
        _isGenerating = false;
        _currentStep = 'Fertig!';
      });

      _cardAnimationController.forward();
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _currentStep = 'KI-Generierung fehlgeschlagen';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Erneut versuchen',
              textColor: Colors.white,
              onPressed: _generateExam,
            ),
          ),
        );
      }
    }
  }

  Future<List<ExamQuestion>> _generateMultipleChoiceQuestions() async {
    try {
      final prompt = '''
Erstelle 8 Multiple-Choice-Fragen für das Buch "${_bookController.text}" ${_authorController.text.isNotEmpty ? 'von ${_authorController.text}' : ''}.

Erstelle verschiedene Schwierigkeitsgrade:
- 3 einfache Fragen (Grundverständnis)
- 3 mittlere Fragen (Analyse)
- 2 schwere Fragen (kritisches Denken)

Format jede Frage als JSON:
{
  "question": "Frage text",
  "options": ["Option A", "Option B", "Option C", "Option D"],
  "correctAnswer": 0,
  "explanation": "Erklärung der richtigen Antwort",
  "difficulty": "einfach|mittel|schwer",
  "topic": "Themenbereich"
}

Gib nur ein valides JSON Array zurück.
''';

      final response = await AIService().generateCustomResponse(prompt);

      // Check if response contains error
      if (response.contains('"error"')) {
        throw Exception('KI-Service nicht verfügbar');
      }

      return _parseMultipleChoiceQuestions(response);
    } catch (e) {
      throw Exception(
          '❌ Multiple-Choice-Generierung fehlgeschlagen: ${e.toString()}');
    }
  }

  Future<List<EssayQuestion>> _generateEssayQuestions() async {
    try {
      final prompt = '''
Erstelle 5 Essay-Fragen für das Buch "${_bookController.text}" ${_authorController.text.isNotEmpty ? 'von ${_authorController.text}' : ''}.

Erstelle verschiedene Typen:
- 2 Analyse-Fragen
- 2 Vergleichs-Fragen
- 1 kritische Bewertung

Format jede Frage als JSON:
{
  "question": "Essay-Frage",
  "type": "Analyse|Vergleich|Bewertung",
  "keywords": ["Schlüsselwort1", "Schlüsselwort2"],
  "suggestedLength": "300-500 Wörter",
  "hints": ["Tipp 1", "Tipp 2"]
}

Gib nur ein valides JSON Array zurück.
''';

      final response = await AIService().generateCustomResponse(prompt);

      if (response.contains('"error"')) {
        throw Exception('KI-Service nicht verfügbar');
      }

      return _parseEssayQuestions(response);
    } catch (e) {
      throw Exception(
          '❌ Essay-Fragen-Generierung fehlgeschlagen: ${e.toString()}');
    }
  }

  Future<List<StudyFlashcard>> _generateStudyFlashcards() async {
    try {
      final prompt = '''
Erstelle 15 Lernkarten für das Buch "${_bookController.text}" ${_authorController.text.isNotEmpty ? 'von ${_authorController.text}' : ''}.

Kategorien:
- 5 Charaktere/Personen
- 5 Themen/Konzepte
- 5 Zitate/Schlüsselstellen

Format jede Karte als JSON:
{
  "front": "Frage oder Begriff",
  "back": "Antwort oder Definition",
  "category": "Charaktere|Themen|Zitate",
  "difficulty": "einfach|mittel|schwer"
}

Gib nur ein valides JSON Array zurück.
''';

      final response = await AIService().generateCustomResponse(prompt);

      if (response.contains('"error"')) {
        throw Exception('KI-Service nicht verfügbar');
      }

      return _parseStudyFlashcards(response);
    } catch (e) {
      throw Exception(
          '❌ Lernkarten-Generierung fehlgeschlagen: ${e.toString()}');
    }
  }

  List<ExamQuestion> _parseMultipleChoiceQuestions(String response) {
    try {
      final cleanResponse =
          response.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> questionsJson = _parseJsonArray(cleanResponse);
      return questionsJson.map((q) => ExamQuestion.fromJson(q)).toList();
    } catch (e) {
      throw Exception(
          '❌ KI-Antwort konnte nicht verarbeitet werden: Ungültiges JSON-Format');
    }
  }

  List<EssayQuestion> _parseEssayQuestions(String response) {
    try {
      final cleanResponse =
          response.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> questionsJson = _parseJsonArray(cleanResponse);
      return questionsJson.map((q) => EssayQuestion.fromJson(q)).toList();
    } catch (e) {
      throw Exception(
          '❌ KI-Antwort konnte nicht verarbeitet werden: Ungültiges JSON-Format');
    }
  }

  List<StudyFlashcard> _parseStudyFlashcards(String response) {
    try {
      final cleanResponse =
          response.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> cardsJson = _parseJsonArray(cleanResponse);
      return cardsJson.map((c) => StudyFlashcard.fromJson(c)).toList();
    } catch (e) {
      throw Exception(
          '❌ KI-Antwort konnte nicht verarbeitet werden: Ungültiges JSON-Format');
    }
  }

  List<dynamic> _parseJsonArray(String jsonString) {
    try {
      return List<dynamic>.from(dart_convert.jsonDecode(jsonString));
    } catch (e) {
      // Try to extract JSON from text
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(jsonString);
      if (jsonMatch != null) {
        return List<dynamic>.from(dart_convert.jsonDecode(jsonMatch.group(0)!));
      }
      throw Exception('Could not parse JSON');
    }
  }

  // REMOVED: All fallback methods - using only real AI generation now

  void _flipFlashcard() {
    setState(() {
      _showFlashcardAnswer = !_showFlashcardAnswer;
    });
  }

  void _nextFlashcard() {
    if (_currentFlashcardIndex < _flashcards.length - 1) {
      setState(() {
        _currentFlashcardIndex++;
        _showFlashcardAnswer = false;
      });
    }
  }

  void _previousFlashcard() {
    if (_currentFlashcardIndex > 0) {
      setState(() {
        _currentFlashcardIndex--;
        _showFlashcardAnswer = false;
      });
    }
  }

  void _showAnswerDialog(ExamQuestion question, int questionIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Antwort zu Frage ${questionIndex + 1}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Richtige Antwort:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Text(
                '${String.fromCharCode(65 + question.correctAnswer)}) ${question.options[question.correctAnswer]}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (question.explanation.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Erklärung:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(question.explanation),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Verstanden'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('KI-Prüfungsgenerator'),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputSection(),
              if (_isGenerating) ...[
                const SizedBox(height: 24),
                _buildGeneratingSection(),
              ],
              if (!_isGenerating && _multipleChoiceQuestions.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildResultsSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Prüfung erstellen',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _bookController,
              decoration: InputDecoration(
                labelText: 'Buchtitel *',
                hintText: 'z.B. Der Große Gatsby',
                prefixIcon: const Icon(Icons.book),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _authorController,
              decoration: InputDecoration(
                labelText: 'Autor (optional)',
                hintText: 'z.B. F. Scott Fitzgerald',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generateExam,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isGenerating)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    else
                      const Icon(Icons.auto_awesome),
                    const SizedBox(width: 8),
                    Text(_isGenerating
                        ? 'Erstelle Prüfung...'
                        : 'Prüfung erstellen'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratingSection() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Column(
                  children: [
                    LinearProgressIndicator(
                      value: _progressAnimation.value,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentStep,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Column(
      children: [
        _buildMultipleChoiceSection(),
        const SizedBox(height: 24),
        _buildEssayQuestionsSection(),
        const SizedBox(height: 24),
        _buildFlashcardsSection(),
      ],
    );
  }

  Widget _buildMultipleChoiceSection() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.quiz,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Multiple-Choice Fragen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    '${_multipleChoiceQuestions.length}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(_multipleChoiceQuestions.length, (index) {
              final question = _multipleChoiceQuestions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getDifficultyColor(question.difficulty)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              question.difficulty.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getDifficultyColor(question.difficulty),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              question.topic,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${index + 1}. ${question.question}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(math.min(question.options.length, 4),
                          (optionIndex) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${String.fromCharCode(65 + optionIndex)})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    question.options[optionIndex],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      // Show answer button
                      ElevatedButton.icon(
                        onPressed: () {
                          _showAnswerDialog(question, index);
                        },
                        icon: const Icon(Icons.help_outline),
                        label: const Text('Antwort anzeigen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEssayQuestionsSection() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.edit_note,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Essay-Fragen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    '${_essayQuestions.length}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(_essayQuestions.length, (index) {
              final question = _essayQuestions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              question.type.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              question.suggestedLength,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${index + 1}. ${question.question}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (question.keywords.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: question.keywords.map((keyword) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .tertiary
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                keyword,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      if (question.hints.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.tips_and_updates,
                                    size: 16,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Hinweise:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...question.hints
                                  .map((hint) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4.0),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '• ',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                hint,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.8),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcardsSection() {
    if (_flashcards.isEmpty) return const SizedBox.shrink();

    final currentCard = _flashcards[_currentFlashcardIndex];

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.style,
                  color: Theme.of(context).colorScheme.tertiary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lernkarten',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    '${_currentFlashcardIndex + 1}/${_flashcards.length}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor:
                      Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Flashcard
            GestureDetector(
              onTap: _flipFlashcard,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                constraints: const BoxConstraints(
                  minHeight: 180,
                  maxHeight: 300,
                ),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _showFlashcardAnswer
                        ? [
                            Theme.of(context)
                                .colorScheme
                                .tertiary
                                .withOpacity(0.8),
                            Theme.of(context)
                                .colorScheme
                                .tertiary
                                .withOpacity(0.4),
                          ]
                        : [
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.8),
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.4),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _showFlashcardAnswer
                                  ? currentCard.back
                                  : currentCard.front,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              currentCard.category,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _showFlashcardAnswer ? 'ANTWORT' : 'FRAGE',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Navigation buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed:
                      _currentFlashcardIndex > 0 ? _previousFlashcard : null,
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Zurück'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.surface.withOpacity(0.8),
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _flipFlashcard,
                  icon: Icon(
                      _showFlashcardAnswer
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 16),
                  label: Text(_showFlashcardAnswer ? 'Frage' : 'Antwort'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _currentFlashcardIndex < _flashcards.length - 1
                      ? _nextFlashcard
                      : null,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Weiter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.surface.withOpacity(0.8),
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'einfach':
        return Colors.green;
      case 'mittel':
        return Colors.orange;
      case 'schwer':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// Data Models
class ExamQuestion {
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;
  final String difficulty;
  final String topic;

  ExamQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.difficulty,
    required this.topic,
  });

  factory ExamQuestion.fromJson(Map<String, dynamic> json) {
    return ExamQuestion(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? 0,
      explanation: json['explanation'] ?? '',
      difficulty: json['difficulty'] ?? 'mittel',
      topic: json['topic'] ?? 'Allgemein',
    );
  }
}

class EssayQuestion {
  final String question;
  final String type;
  final List<String> keywords;
  final String suggestedLength;
  final List<String> hints;

  EssayQuestion({
    required this.question,
    required this.type,
    required this.keywords,
    required this.suggestedLength,
    required this.hints,
  });

  factory EssayQuestion.fromJson(Map<String, dynamic> json) {
    return EssayQuestion(
      question: json['question'] ?? '',
      type: json['type'] ?? 'Analyse',
      keywords: List<String>.from(json['keywords'] ?? []),
      suggestedLength: json['suggestedLength'] ?? '300-500 Wörter',
      hints: List<String>.from(json['hints'] ?? []),
    );
  }
}

class StudyFlashcard {
  final String front;
  final String back;
  final String category;
  final String difficulty;

  StudyFlashcard({
    required this.front,
    required this.back,
    required this.category,
    required this.difficulty,
  });

  factory StudyFlashcard.fromJson(Map<String, dynamic> json) {
    return StudyFlashcard(
      front: json['front'] ?? '',
      back: json['back'] ?? '',
      category: json['category'] ?? 'Allgemein',
      difficulty: json['difficulty'] ?? 'mittel',
    );
  }
}
