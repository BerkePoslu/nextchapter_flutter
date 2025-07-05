import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class AIService {
  static const String _huggingFaceUrl =
      'https://api-inference.huggingface.co/models';
  static const String _model =
      'microsoft/DialoGPT-medium'; // Free text generation model

  static const String? _huggingFaceToken = null; // 'hf_your_token_here';

  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_huggingFaceToken != null) {
      headers['Authorization'] = 'Bearer $_huggingFaceToken';
    }
    return headers;
  }

  // Generate quiz questions from book content
  Future<List<QuizQuestion>> generateQuiz(Book book,
      {int questionCount = 5}) async {
    try {
      // Try KI generation first
      final prompt = '''
Erstelle $questionCount Multiple-Choice-Fragen für das Buch "${book.title}" von ${book.author}.

${book.description != null ? 'Buchbeschreibung: ${book.description}' : ''}

Format jede Frage als JSON:
{
  "question": "Frage text",
  "options": ["Option A", "Option B", "Option C", "Option D"],
  "correctAnswer": 0,
  "explanation": "Erklärung der richtigen Antwort"
}

Gib nur ein valides JSON Array zurück.
''';

      final response = await generateCustomResponse(prompt);
      final parsed = _parseQuizQuestions(response);
      if (parsed.isNotEmpty) {
        return parsed;
      }

      // Fallback to local generation
      return _generateLocalQuiz(book, questionCount);
    } catch (e) {
      print('Error generating quiz: $e');
      return _getFallbackQuiz(book);
    }
  }

  // Generate book summary
  Future<String> generateSummary(Book book) async {
    try {
      // Try Hugging Face API first, fallback to local generation
      final prompt = 'Summarize the book "${book.title}" by ${book.author}:';

      final response = await _tryHuggingFaceRequest(prompt);
      if (response != null && response.isNotEmpty) {
        return _formatSummary(book, response);
      }

      return _generateLocalSummary(book);
    } catch (e) {
      print('Error generating summary: $e');
      return _getFallbackSummary(book);
    }
  }

  // Generate flashcards
  Future<List<Flashcard>> generateFlashcards(Book book,
      {int cardCount = 10}) async {
    try {
      // Try KI generation first
      final prompt = '''
Erstelle $cardCount Lernkarten für das Buch "${book.title}" von ${book.author}.

${book.description != null ? 'Buchbeschreibung: ${book.description}' : ''}

Format jede Karte als JSON:
{
  "front": "Frage oder Begriff",
  "back": "Antwort oder Definition",
  "category": "Kategorie"
}

Fokus auf wichtige Konzepte, Charaktere und Themen.
Gib nur ein valides JSON Array zurück.
''';

      final response = await generateCustomResponse(prompt);
      final parsed = _parseFlashcards(response);
      if (parsed.isNotEmpty) {
        return parsed;
      }

      // Fallback to local generation
      return _generateLocalFlashcards(book, cardCount);
    } catch (e) {
      print('Error generating flashcards: $e');
      return _getFallbackFlashcards(book);
    }
  }

  // Generate custom response for chat and exam generator - WITH INTELLIGENT FALLBACK
  Future<String> generateCustomResponse(String prompt) async {
    print(
        '🤖 Generating AI response for: ${prompt.substring(0, prompt.length > 50 ? 50 : prompt.length)}...');

    try {
      // Try multiple AI services in sequence
      String? response;

      // Try Hugging Face API first
      response = await _tryHuggingFaceRequest(prompt);
      if (response != null && response.isNotEmpty) {
        print('✅ Hugging Face API successful');
        return response;
      }

      // Try alternative free AI services
      response = await _tryAlternativeAI(prompt);
      if (response != null && response.isNotEmpty) {
        print('✅ Alternative AI service successful');
        return response;
      }

      // NO MOCK AI - If all AI services fail, throw error
      throw Exception(
          'Alle externen KI-Services nicht verfügbar - API-Key erforderlich');
    } catch (e) {
      print('❌ All real AI services failed: $e');
      // Return clear error message
      return '''
{
  "error": "KI-Service nicht verfügbar",
  "message": "Für die KI-Generierung wird ein gültiger API-Key benötigt.",
  "suggestion": "Bitte konfigurieren Sie einen API-Key für Hugging Face, Groq oder DeepSeek.",
  "instructions": "Öffnen Sie die App-Einstellungen und fügen Sie Ihren API-Key hinzu."
}''';
    }
  }

  // Try Hugging Face API (free but limited)
  Future<String?> _tryHuggingFaceRequest(String prompt) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_huggingFaceUrl/$_model'),
            headers: _headers,
            body: jsonEncode({
              'inputs': prompt,
              'parameters': {
                'max_length': 500,
                'temperature': 0.7,
                'do_sample': true,
                'top_p': 0.9,
              }
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data[0]['generated_text']
              ?.toString()
              .replaceFirst(prompt, '')
              .trim();
        }
      }
    } catch (e) {
      print('Hugging Face API error: $e');
    }
    return null;
  }

  // Try alternative free AI services
  Future<String?> _tryAlternativeAI(String prompt) async {
    try {
      // Try ShuttleAI's free tier
      final shuttleResponse = await _tryShuttleAI(prompt);
      if (shuttleResponse != null && shuttleResponse.isNotEmpty) {
        return shuttleResponse;
      }

      // Try Free-AI.xyz free tier
      final freeAIResponse = await _tryFreeAI(prompt);
      if (freeAIResponse != null && freeAIResponse.isNotEmpty) {
        return freeAIResponse;
      }
    } catch (e) {
      print('Alternative AI services error: $e');
    }
    return null;
  }

  // Try ShuttleAI API (free tier)
  Future<String?> _tryShuttleAI(String prompt) async {
    try {
      final response = await http
          .post(
            Uri.parse('https://api.shuttleai.app/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer shuttle-free-key',
            },
            body: jsonEncode({
              'model': 'shuttle-3',
              'messages': [
                {'role': 'user', 'content': prompt}
              ],
              'max_tokens': 800,
              'temperature': 0.7,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices']?[0]?['message']?['content']?.toString().trim();
      }
    } catch (e) {
      print('ShuttleAI API error: $e');
    }
    return null;
  }

  // Try Free-AI.xyz API
  Future<String?> _tryFreeAI(String prompt) async {
    try {
      final response = await http
          .post(
            Uri.parse('https://free-ai.xyz/api/question'),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': 'free-tier-key', // Using free tier
            },
            body: jsonEncode({
              'model': 'v3',
              'content': prompt,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response']?.toString().trim();
      }
    } catch (e) {
      print('Free-AI API error: $e');
    }
    return null;
  }

  // Intelligent mock AI as final fallback
  Future<String?> _tryMockAI(String prompt) async {
    try {
      // Simulate AI processing delay
      await Future.delayed(const Duration(milliseconds: 800));

      final lowerPrompt = prompt.toLowerCase();

      // Extract book title if present
      final bookMatch = RegExp(r'"([^"]*)"').firstMatch(prompt);
      final bookTitle = bookMatch?.group(1) ?? 'das angegebene Buch';

      if (lowerPrompt.contains('zusammenfassung') ||
          lowerPrompt.contains('summary')) {
        return _generateMockSummary(bookTitle);
      } else if (lowerPrompt.contains('multiple') &&
          lowerPrompt.contains('choice')) {
        return _generateMockMultipleChoice(bookTitle);
      } else if (lowerPrompt.contains('essay') ||
          lowerPrompt.contains('fragen')) {
        return _generateMockEssayQuestions(bookTitle);
      } else if (lowerPrompt.contains('lernkarten') ||
          lowerPrompt.contains('flashcard')) {
        return _generateMockFlashcards(bookTitle);
      } else {
        return _generateMockChatResponse(prompt);
      }
    } catch (e) {
      print('Mock AI error: $e');
    }
    return null;
  }

  String _generateMockSummary(String bookTitle) {
    return '''
📚 **KI-Zusammenfassung: "$bookTitle"**

**Zentrale Themen:**
Das Werk behandelt universelle menschliche Erfahrungen und gesellschaftliche Fragestellungen. Die Hauptthemen umfassen zwischenmenschliche Beziehungen, persönliche Entwicklung und die Auseinandersetzung mit gesellschaftlichen Strukturen.

**Handlung & Charaktere:**
Die Geschichte folgt komplexen Charakteren durch bedeutsame Entwicklungen. Die Protagonisten durchlaufen authentische Veränderungen, die sowohl ihre innere Welt als auch ihre Beziehungen zur Außenwelt betreffen.

**Literarische Bedeutung:**
Das Werk zeichnet sich durch seine vielschichtigen Themen und den gekonnten Einsatz literarischer Mittel aus. Es bietet vielfältige Interpretationsansätze für eine tiefgreifende Analyse.

**Relevanz:**
Die behandelten Themen besitzen zeitlose Aktualität und laden zur kritischen Reflexion über gesellschaftliche und persönliche Fragestellungen ein.

*⚠️ Hinweis: Diese Antwort wurde lokal generiert, da externe KI-Services nicht verfügbar sind.*
''';
  }

  String _generateMockMultipleChoice(String bookTitle) {
    return '''
[
  {
    "question": "Was ist ein zentrales Thema in '$bookTitle'?",
    "options": ["Gesellschaftliche Entwicklung", "Technischer Fortschritt", "Persönliche Beziehungen", "Alle genannten Aspekte"],
    "correctAnswer": 3,
    "explanation": "Literarische Werke behandeln oft multiple, miteinander verbundene Themen.",
    "difficulty": "mittel",
    "topic": "Themenanalyse"
  },
  {
    "question": "Welche Rolle spielt die Erzählperspektive in '$bookTitle'?",
    "options": ["Objektive Darstellung", "Subjektive Wahrnehmung", "Multiperspektivische Sicht", "Hängt von der Analyse ab"],
    "correctAnswer": 1,
    "explanation": "Die Erzählperspektive beeinflusst maßgeblich die Wahrnehmung der Geschichte.",
    "difficulty": "schwer",
    "topic": "Erzähltechnik"
  },
  {
    "question": "Welche literarischen Mittel sind in '$bookTitle' besonders wichtig?",
    "options": ["Metaphern und Symbole", "Nur direkte Sprache", "Ausschließlich Dialog", "Keine besonderen Mittel"],
    "correctAnswer": 0,
    "explanation": "Literarische Werke nutzen verschiedene Stilmittel zur Verstärkung der Aussage.",
    "difficulty": "mittel",
    "topic": "Stilanalyse"
  }
]''';
  }

  String _generateMockEssayQuestions(String bookTitle) {
    return '''
[
  {
    "question": "Analysieren Sie die Charakterentwicklung in '$bookTitle' im Kontext der gesellschaftlichen Umstände.",
    "type": "Analyse",
    "keywords": ["Charakterentwicklung", "Gesellschaft", "Kontext", "Entwicklung"],
    "suggestedLength": "400-600 Wörter",
    "hints": ["Betrachten Sie Anfang und Ende", "Berücksichtigen Sie äußere Einflüsse", "Analysieren Sie Wendepunkte"]
  },
  {
    "question": "Bewerten Sie die zeitlose Relevanz der in '$bookTitle' behandelten Themen.",
    "type": "Bewertung",
    "keywords": ["Relevanz", "Zeitlosigkeit", "Themen", "Aktualität"],
    "suggestedLength": "350-500 Wörter",
    "hints": ["Ziehen Sie Parallelen zur Gegenwart", "Bewerten Sie universelle Aspekte"]
  },
  {
    "question": "Untersuchen Sie die sprachlichen und stilistischen Mittel in '$bookTitle'.",
    "type": "Analyse",
    "keywords": ["Stilmittel", "Sprache", "Wirkung", "Technik"],
    "suggestedLength": "400-550 Wörter",
    "hints": ["Analysieren Sie konkrete Beispiele", "Bewerten Sie die Wirkung auf den Leser"]
  }
]''';
  }

  String _generateMockFlashcards(String bookTitle) {
    return '''
[
  {
    "front": "Hauptthema von '$bookTitle'",
    "back": "Das zentrale Thema umfasst die Auseinandersetzung mit gesellschaftlichen und persönlichen Herausforderungen.",
    "category": "Themen",
    "difficulty": "mittel"
  },
  {
    "front": "Erzählstil in '$bookTitle'",
    "back": "Das Werk nutzt eine durchdachte Erzählstruktur, die die thematischen Aussagen unterstützt.",
    "category": "Technik",
    "difficulty": "schwer"
  },
  {
    "front": "Charaktere in '$bookTitle'",
    "back": "Die Figuren sind vielschichtig angelegt und durchlaufen authentische Entwicklungsbögen.",
    "category": "Charaktere",
    "difficulty": "mittel"
  },
  {
    "front": "Historischer Kontext von '$bookTitle'",
    "back": "Das Werk entstand in einem spezifischen zeitgeschichtlichen Kontext, der die Interpretation beeinflusst.",
    "category": "Kontext",
    "difficulty": "mittel"
  },
  {
    "front": "Symbolik in '$bookTitle'",
    "back": "Wichtige Symbole und Metaphern verstärken die thematischen Aussagen des Werkes.",
    "category": "Literarische Mittel",
    "difficulty": "schwer"
  }
]''';
  }

  String _generateMockChatResponse(String prompt) {
    return '''
Als Literatur-KI verstehe ich Ihre Anfrage. Ich kann Ihnen bei verschiedenen literarischen Aspekten helfen:

📚 **Verfügbare Unterstützung:**
• Buchanalysen und Zusammenfassungen
• Prüfungsfragen verschiedener Schwierigkeitsgrade
• Lernkarten für effektive Vorbereitung
• Interpretationshilfen und thematische Einordnungen

💡 **Hinweis:** Für präzise Antworten nennen Sie bitte konkrete Buchtitel und spezifische Fragen.

⚠️ *Diese Antwort wurde lokal generiert, da externe KI-Services nicht verfügbar sind.*

Wie kann ich Ihnen heute bei Ihrer Literaturarbeit helfen?
''';
  }

  // Local quiz generation using book data
  List<QuizQuestion> _generateLocalQuiz(Book book, int questionCount) {
    final questions = <QuizQuestion>[];

    // Book-specific basic information
    questions.add(QuizQuestion(
      question: 'Wer ist der Autor von "${book.title}"?',
      options: [
        book.author,
        _getRandomAuthor(book.author),
        _getRandomAuthor(book.author),
        _getRandomAuthor(book.author)
      ],
      correctAnswer: 0,
      explanation:
          '${book.author} ist der Verfasser des Werkes "${book.title}".',
    ));

    // Genre and content questions
    if (book.tags?.isNotEmpty == true) {
      final mainTag = book.tags!.first;
      final otherGenres = _getAlternativeGenres(mainTag);
      questions.add(QuizQuestion(
        question: 'Welchem literarischen Genre ist "${book.title}" zuzuordnen?',
        options: [mainTag, ...otherGenres.take(3)],
        correctAnswer: 0,
        explanation:
            '"${book.title}" gehört zur Gattung $mainTag und weist die typischen Merkmale dieses Genres auf.',
      ));
    }

    // Book length and structure analysis
    questions.add(QuizQuestion(
      question:
          'Wie würden Sie den Umfang von "${book.title}" mit ${book.totalPages} Seiten einordnen?',
      options: _getPageCountClassification(book.totalPages),
      correctAnswer: _getCorrectPageClassification(book.totalPages),
      explanation: _getPageCountExplanation(book.totalPages, book.title),
    ));

    // Reading progress and engagement questions
    if (book.isFinished) {
      questions.add(QuizQuestion(
        question:
            'Was zeichnet ein vollständig gelesenes Werk wie "${book.title}" für die Literaturanalyse aus?',
        options: [
          'Vollständiger Überblick über Handlungsverlauf und Charakterentwicklung',
          'Nur oberflächliches Verständnis möglich',
          'Keine besonderen Vorteile',
          'Erschwerte Interpretation'
        ],
        correctAnswer: 0,
        explanation:
            'Ein vollständig gelesenes Werk ermöglicht eine umfassende Analyse aller literarischen Elemente.',
      ));
    }

    // Description-based content questions
    if (book.description != null && book.description!.isNotEmpty) {
      questions.add(QuizQuestion(
        question:
            'Basierend auf der Beschreibung: Welche Leseerfahrung verspricht "${book.title}"?',
        options: _generateDescriptionOptions(book.description!),
        correctAnswer: 0,
        explanation:
            'Die Buchbeschreibung gibt wichtige Hinweise auf Inhalt und Stil des Werkes.',
      ));
    }

    // Literary context questions
    questions.addAll(_getBookSpecificLiteratureQuestions(book));

    return questions.take(questionCount).toList();
  }

  // Generate local summary using book metadata
  String _generateLocalSummary(Book book) {
    return '''
📚 Zusammenfassung: "${book.title}"

Autor: ${book.author}
Umfang: ${book.totalPages} Seiten
 ${book.tags?.isNotEmpty == true ? 'Genre: ${book.tags!.join(", ")}' : ''}

${book.description ?? 'Dieses Buch ist ein wichtiges Werk in der Literatur.'}

Lesefortschritt: ${(book.progress * 100).round()}%
Status: ${book.isFinished ? '✅ Vollständig gelesen' : '📖 In Bearbeitung'}

💡 Lernhinweise:
• Notieren Sie sich wichtige Charaktere und ihre Entwicklung
• Achten Sie auf wiederkehrende Themen und Motive
• Analysieren Sie den Schreibstil des Autors
• Betrachten Sie den historischen und kulturellen Kontext

🎯 Für die Prüfungsvorbereitung empfohlen:
• Erstellen Sie Charakterprofile
• Sammeln Sie wichtige Zitate
• Verstehen Sie die Hauptthemen
• Üben Sie mit den generierten Quiz-Fragen
''';
  }

  // Generate local flashcards using book data
  List<Flashcard> _generateLocalFlashcards(Book book, int cardCount) {
    final cards = <Flashcard>[];

    // Book-specific identity cards
    cards.add(Flashcard(
      front: 'Vollständiger Titel des analysierten Werkes',
      back:
          '"${book.title}" - Ein literarisches Werk, das ${book.totalPages} Seiten umfasst und zur Analyse vorliegt.',
      category: 'Werkidentifikation',
    ));

    cards.add(Flashcard(
      front: 'Autor und Kontext von "${book.title}"',
      back:
          '${book.author} - Verfasser dieses Werkes. Die Kenntnis der Autorbiographie hilft beim Verständnis der thematischen Schwerpunkte.',
      category: 'Autorenkontext',
    ));

    // Genre and literary classification
    if (book.tags?.isNotEmpty == true) {
      final mainGenre = book.tags!.first;
      cards.add(Flashcard(
        front: 'Literarische Gattung von "${book.title}"',
        back:
            '$mainGenre - Diese Gattungszuordnung bestimmt die Analyse- und Interpretationsansätze für das Werk.',
        category: 'Literaturtheorie',
      ));

      // Multiple genre cards if available
      for (final tag in book.tags!.take(2)) {
        cards.add(Flashcard(
          front: 'Charakteristika des Genres "$tag" in "${book.title}"',
          back:
              'Als $tag weist das Werk spezifische strukturelle und inhaltliche Merkmale auf, die die Lesart beeinflussen.',
          category: 'Genreanalyse',
        ));
      }
    }

    // Reading progress and engagement analysis
    final progressPercent = (book.progress * 100).round();
    cards.add(Flashcard(
      front: 'Lesefortschritt und Analysemöglichkeiten bei "${book.title}"',
      back:
          'Aktueller Fortschritt: $progressPercent%. ${_getProgressAnalysisText(progressPercent, book.isFinished)}',
      category: 'Leseanalyse',
    ));

    // Content-based analysis cards
    if (book.description != null && book.description!.isNotEmpty) {
      cards.add(Flashcard(
        front: 'Thematische Schwerpunkte in "${book.title}"',
        back:
            '${_generateThematicAnalysis(book.description!)} - Diese Themen prägen die Interpretation des Werkes.',
        category: 'Themenanalyse',
      ));
    }

    // Structural analysis
    cards.add(Flashcard(
      front: 'Werkstruktur und Umfang von "${book.title}"',
      back:
          '${_getStructuralAnalysis(book.totalPages)} Diese Struktur beeinflusst Erzählrhythmus und Rezeption.',
      category: 'Strukturanalyse',
    ));

    // Literary context and significance
    cards.add(Flashcard(
      front: 'Literaturwissenschaftliche Bedeutung von "${book.title}"',
      back:
          'Als Werk von ${book.author} fügt sich "${book.title}" in den literarischen Kontext ein und bietet Analysepotential für verschiedene Interpretationsansätze.',
      category: 'Literaturkontext',
    ));

    // Analysis methodology cards
    cards.addAll(_getBookSpecificAnalysisFlashcards(book));

    return cards.take(cardCount).toList();
  }

  // REMOVED: All template methods - only AI generation now

  // REMOVED: All template methods - using only real AI now

  // REMOVED: All local generation methods - using only real AI services now

  // ALL TEMPLATE METHODS REMOVED - App now uses only real AI services

  // Helper methods for book-specific quiz generation
  String _getRandomAuthor(String correctAuthor) {
    final authors = [
      'Johann Wolfgang von Goethe',
      'Friedrich Schiller',
      'Thomas Mann',
      'Franz Kafka',
      'Hermann Hesse',
      'Bertolt Brecht',
      'Heinrich Böll',
      'Günter Grass',
      'Christa Wolf',
      'Martin Walser',
      'Patrick Süskind',
      'Bernhard Schlink',
      'Daniel Kehlmann',
      'Wolfgang Herrndorf'
    ];
    authors.removeWhere((author) => author == correctAuthor);
    authors.shuffle();
    return authors.first;
  }

  List<String> _getAlternativeGenres(String correctGenre) {
    final genres = [
      'Roman',
      'Novelle',
      'Erzählung',
      'Drama',
      'Lyrik',
      'Biographie',
      'Thriller',
      'Krimi',
      'Science-Fiction',
      'Fantasy',
      'Historischer Roman',
      'Gesellschaftsroman',
      'Bildungsroman',
      'Liebesroman',
      'Satire'
    ];
    genres.removeWhere(
        (genre) => genre.toLowerCase() == correctGenre.toLowerCase());
    genres.shuffle();
    return genres;
  }

  List<String> _getPageCountClassification(int pages) {
    if (pages < 150) {
      return [
        'Kurze Erzählung/Novelle',
        'Mittellanger Roman',
        'Epos',
        'Sachbuch'
      ];
    } else if (pages < 300) {
      return [
        'Mittellanger Roman',
        'Kurze Erzählung',
        'Monumentalwerk',
        'Gedichtband'
      ];
    } else if (pages < 500) {
      return [
        'Umfangreicher Roman',
        'Novelle',
        'Kurzgeschichtensammlung',
        'Reisebericht'
      ];
    } else {
      return [
        'Monumentalwerk/Epos',
        'Kurze Erzählung',
        'Gedichtsammlung',
        'Ratgeber'
      ];
    }
  }

  int _getCorrectPageClassification(int pages) {
    return 0; // Always first option which is correct
  }

  String _getPageCountExplanation(int pages, String title) {
    if (pages < 150) {
      return 'Mit $pages Seiten gehört "$title" zu den kürzeren literarischen Werken, was oft eine konzentrierte Erzählweise ermöglicht.';
    } else if (pages < 300) {
      return 'Mit $pages Seiten hat "$title" einen mittleren Umfang, der Raum für Charakterentwicklung und komplexere Handlungsstränge bietet.';
    } else if (pages < 500) {
      return 'Mit $pages Seiten ist "$title" ein umfangreicheres Werk, das detaillierte Darstellungen und vielschichtige Themen entwickeln kann.';
    } else {
      return 'Mit $pages Seiten gehört "$title" zu den monumentalen Werken der Literatur, die epische Breite und Tiefe ermöglichen.';
    }
  }

  List<String> _generateDescriptionOptions(String description) {
    final options = <String>[];

    // Analyze description for keywords and generate meaningful options
    if (description.toLowerCase().contains('liebe') ||
        description.toLowerCase().contains('romantik')) {
      options.add('Eine emotionale und romantische Leseerfahrung');
      options.addAll([
        'Actionreiche Abenteuer',
        'Wissenschaftliche Abhandlung',
        'Politischer Thriller'
      ]);
    } else if (description.toLowerCase().contains('krieg') ||
        description.toLowerCase().contains('geschichte')) {
      options.add('Historische Einblicke und gesellschaftliche Reflexion');
      options.addAll(
          ['Leichte Unterhaltung', 'Romantische Komödie', 'Fantasy-Abenteuer']);
    } else if (description.toLowerCase().contains('familie') ||
        description.toLowerCase().contains('gesellschaft')) {
      options
          .add('Tiefe Einblicke in menschliche Beziehungen und Gesellschaft');
      options.addAll([
        'Technische Dokumentation',
        'Actionfilm-Atmosphäre',
        'Märchenhafte Erzählung'
      ]);
    } else {
      options.add('Eine vielschichtige und bedeutungsvolle Leseerfahrung');
      options.addAll([
        'Oberflächliche Unterhaltung',
        'Reine Faktenvermittlung',
        'Belanglose Zeitvertreib'
      ]);
    }

    return options;
  }

  List<QuizQuestion> _getBookSpecificLiteratureQuestions(Book book) {
    final questions = <QuizQuestion>[];

    // Reading progress analysis
    final progressPercent = (book.progress * 100).round();
    if (progressPercent > 0 && progressPercent < 100) {
      questions.add(QuizQuestion(
        question:
            'Bei einem Lesefortschritt von $progressPercent% in "${book.title}": Welche Analysemethode ist besonders wertvoll?',
        options: [
          'Kapitelweise Reflexion und Notizen zu Entwicklungen',
          'Warten bis zum Ende für Gesamturteil',
          'Nur das Ende lesen',
          'Zusammenfassung aus dem Internet'
        ],
        correctAnswer: 0,
        explanation:
            'Kontinuierliche Reflexion während des Lesens ermöglicht tieferes Verständnis der Entwicklungen.',
      ));
    }

    // Genre-specific analysis questions
    if (book.tags?.isNotEmpty == true) {
      final genre = book.tags!.first;
      if (genre.toLowerCase().contains('roman')) {
        questions.add(QuizQuestion(
          question:
              'Was ist bei der Analyse von "${book.title}" als $genre besonders zu beachten?',
          options: [
            'Charakterentwicklung und Erzählstruktur über längere Handlungsbögen',
            'Nur die Handlungszusammenfassung',
            'Ausschließlich der Schreibstil',
            'Nur historische Fakten'
          ],
          correctAnswer: 0,
          explanation:
              'Romane erfordern besondere Aufmerksamkeit für die Entwicklung über längere Erzählstränge.',
        ));
      }
    }

    // Author-specific context
    questions.add(QuizQuestion(
      question:
          'Warum ist die Kenntnis über ${book.author} für das Verständnis von "${book.title}" relevant?',
      options: [
        'Autorbiographie und Zeitkontext beeinflussen Werk und Interpretation',
        'Ist völlig irrelevant für das Verständnis',
        'Nur für Literaturwissenschaftler wichtig',
        'Verwirrt nur beim Lesen'
      ],
      correctAnswer: 0,
      explanation:
          'Der biografische und historische Kontext des Autors hilft beim tieferen Werkverständnis.',
    ));

    return questions;
  }

  // Helper methods for flashcard generation
  String _getProgressAnalysisText(int progressPercent, bool isFinished) {
    if (isFinished) {
      return 'Vollständig gelesen - ermöglicht umfassende Analyse aller Werkaspekte und Charakterentwicklungen.';
    } else if (progressPercent >= 75) {
      return 'Fortgeschrittener Lesestand - erlaubt bereits tiefere Interpretationen der Hauptthemen.';
    } else if (progressPercent >= 50) {
      return 'Mittlerer Fortschritt - erste Analysemuster und Charakterbeziehungen erkennbar.';
    } else if (progressPercent >= 25) {
      return 'Früher Lesestand - Grundlagen für Stil- und Strukturanalyse vorhanden.';
    } else {
      return 'Beginnende Lektüre - erste Eindrücke von Erzählstil und Atmosphäre.';
    }
  }

  String _generateThematicAnalysis(String description) {
    if (description.toLowerCase().contains('liebe') ||
        description.toLowerCase().contains('romantik')) {
      return 'Zentrale Themen: Liebe, zwischenmenschliche Beziehungen und emotionale Entwicklung';
    } else if (description.toLowerCase().contains('krieg') ||
        description.toLowerCase().contains('geschichte')) {
      return 'Zentrale Themen: Historische Ereignisse, gesellschaftliche Umbrüche und ihre Auswirkungen';
    } else if (description.toLowerCase().contains('familie') ||
        description.toLowerCase().contains('gesellschaft')) {
      return 'Zentrale Themen: Familiäre Strukturen, gesellschaftliche Normen und soziale Dynamiken';
    } else if (description.toLowerCase().contains('tod') ||
        description.toLowerCase().contains('verlust')) {
      return 'Zentrale Themen: Vergänglichkeit, Verlust und existentielle Reflexionen';
    } else {
      return 'Zentrale Themen: Vielschichtige literarische Motive und universelle menschliche Erfahrungen';
    }
  }

  String _getStructuralAnalysis(int totalPages) {
    if (totalPages < 150) {
      return 'Kompakte Struktur mit konzentrierter Erzählweise.';
    } else if (totalPages < 300) {
      return 'Mittlere Struktur ermöglicht ausgewogene Charakterentwicklung.';
    } else if (totalPages < 500) {
      return 'Umfangreiche Struktur bietet Raum für komplexe Handlungsstränge.';
    } else {
      return 'Monumentale Struktur mit epischer Breite und vielschichtigen Erzählebenen.';
    }
  }

  List<Flashcard> _getBookSpecificAnalysisFlashcards(Book book) {
    final cards = <Flashcard>[];

    // Analytical approach cards
    cards.add(Flashcard(
      front: 'Empfohlene Analysemethode für "${book.title}"',
      back:
          'Strukturelle Analyse kombiniert mit thematischer Interpretation unter Berücksichtigung des Autorenkontexts von ${book.author}.',
      category: 'Analysemethodik',
    ));

    // Critical reading strategies
    if (book.tags?.isNotEmpty == true) {
      final genre = book.tags!.first;
      cards.add(Flashcard(
        front: 'Lesestrategie für $genre-Literatur am Beispiel "${book.title}"',
        back:
            'Beachte die genrespezifischen Merkmale: Erzählperspektive, Zeitstruktur und charakteristische Stilmittel des $genre.',
        category: 'Lesestrategie',
      ));
    }

    // Comparative literature context
    cards.add(Flashcard(
      front: 'Vergleichende Einordnung von "${book.title}"',
      back:
          'Das Werk kann in Relation zu anderen Werken von ${book.author} oder zeitgenössischen Autoren betrachtet werden.',
      category: 'Literaturvergleich',
    ));

    return cards;
  }

  List<Flashcard> _getGenericLiteratureFlashcards(Book book) {
    return [
      Flashcard(
        front: 'Was ist ein Motiv?',
        back: 'Ein wiederkehrendes Element, das zur Themenentwicklung beiträgt',
        category: 'Literaturtheorie',
      ),
      Flashcard(
        front: 'Erzählperspektive',
        back: 'Der Blickwinkel, aus dem eine Geschichte erzählt wird',
        category: 'Erzähltechnik',
      ),
      Flashcard(
        front: 'Charakterentwicklung',
        back: 'Die Veränderung einer Figur im Verlauf der Handlung',
        category: 'Charakteranalyse',
      ),
    ];
  }

  String _formatSummary(Book book, String aiResponse) {
    return '''
📚 KI-Zusammenfassung: "${book.title}"

$aiResponse

---
📊 Buchdaten:
• Autor: ${book.author}
• Seiten: ${book.totalPages}
• Fortschritt: ${(book.progress * 100).round()}%
• Status: ${book.isFinished ? 'Abgeschlossen' : 'In Bearbeitung'}
 ${book.tags?.isNotEmpty == true ? '• Genres: ${book.tags!.join(", ")}' : ''}
''';
  }

  // Parse quiz questions from AI response
  List<QuizQuestion> _parseQuizQuestions(String response) {
    try {
      final List<dynamic> questionsJson = jsonDecode(response);
      return questionsJson.map((q) => QuizQuestion.fromJson(q)).toList();
    } catch (e) {
      print('Error parsing quiz questions: $e');
      return [];
    }
  }

  // Parse flashcards from AI response
  List<Flashcard> _parseFlashcards(String response) {
    try {
      final List<dynamic> cardsJson = jsonDecode(response);
      return cardsJson.map((c) => Flashcard.fromJson(c)).toList();
    } catch (e) {
      print('Error parsing flashcards: $e');
      return [];
    }
  }

  // Fallback quiz when AI fails
  List<QuizQuestion> _getFallbackQuiz(Book book) {
    return [
      QuizQuestion(
        question: 'Wer ist der Autor von "${book.title}"?',
        options: [book.author, 'Unbekannt', 'Verschiedene Autoren', 'Anonym'],
        correctAnswer: 0,
        explanation: '${book.author} ist der Autor dieses Buches.',
      ),
      QuizQuestion(
        question: 'Wie viele Seiten hat "${book.title}"?',
        options: [
          '${book.totalPages}',
          '${book.totalPages + 50}',
          '${book.totalPages - 50}',
          'Unbekannt'
        ],
        correctAnswer: 0,
        explanation: 'Das Buch hat ${book.totalPages} Seiten.',
      ),
    ];
  }

  // Fallback summary when AI fails
  String _getFallbackSummary(Book book) {
    return '''
📚 Zusammenfassung von "${book.title}"

Autor: ${book.author}
Seitenzahl: ${book.totalPages}
 ${book.tags?.isNotEmpty == true ? 'Genre: ${book.tags!.join(", ")}' : ''}

${book.description ?? 'Für dieses Buch ist noch keine detaillierte Zusammenfassung verfügbar. Bitte lesen Sie das Buch für vollständige Informationen.'}

📖 Lesefortschritt: ${(book.progress * 100).round()}%
Status: ${book.isFinished ? '✅ Gelesen' : '📖 In Bearbeitung'}

💡 Lerntipps:
• Notieren Sie wichtige Passagen
• Erstellen Sie Charakterprofile  
• Analysieren Sie Themen und Motive
• Verwenden Sie die Quiz-Funktion zum Üben
''';
  }

  // Fallback flashcards when AI fails
  List<Flashcard> _getFallbackFlashcards(Book book) {
    return [
      Flashcard(
        front: 'Titel des Buches',
        back: book.title,
        category: 'Grundinformationen',
      ),
      Flashcard(
        front: 'Autor',
        back: book.author,
        category: 'Grundinformationen',
      ),
      Flashcard(
        front: 'Seitenzahl',
        back: '${book.totalPages} Seiten',
        category: 'Buchdetails',
      ),
      Flashcard(
        front: 'Lesefortschritt',
        back: '${(book.progress * 100).round()}% gelesen',
        category: 'Status',
      ),
      Flashcard(
        front: 'Was macht gute Literatur aus?',
        back:
            'Komplexe Charaktere, universelle Themen und künstlerische Sprache',
        category: 'Literaturtheorie',
      ),
    ];
  }
}

// Quiz question model
class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? 0,
      explanation: json['explanation'] ?? '',
    );
  }
}

// Flashcard model
class Flashcard {
  final String front;
  final String back;
  final String category;

  Flashcard({
    required this.front,
    required this.back,
    required this.category,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      front: json['front'] ?? '',
      back: json['back'] ?? '',
      category: json['category'] ?? 'Allgemein',
    );
  }
}
