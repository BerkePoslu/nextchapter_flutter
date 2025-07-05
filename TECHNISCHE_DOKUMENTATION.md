3. Technischer Überblick
3.1 Systemarchitektur und Plattformen
Die NextChapter-Anwendung basiert auf dem Flutter-Framework in Version 3.2.3 und nutzt Dart als Programmiersprache. Diese Architekturentscheidung ermöglicht eine einheitliche Codebasis für iOS- und Android-Plattformen, wodurch Entwicklungszeit und Wartungsaufwand erheblich reduziert werden.
Das Design-System implementiert einen "Liquid Glass"-Ansatz, der moderne UI-Trends mit funktionaler Benutzerführung verbindet. Die App initialisiert sich über eine zentrale main()-Funktion, die kritische Services wie den Benachrichtigungsservice vor dem App-Start lädt:
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  runApp(MyApp());
}
Das Theme-Management erfolgt über ein ValueListenableBuilder-Pattern, das reaktive Änderungen zwischen Hell- und Dunkel-Modus ermöglicht. Die Farbpalette orientiert sich an iOS-Design-Prinzipien mit angepassten Transparenz-Werten für den Liquid Glass-Effekt.
3.2 Datenarchitektur und Framework
Die Anwendung verwendet SQLite als lokale Datenbank über das sqflite-Plugin in Version 2.3.0. Diese Entscheidung begründet sich durch die Offline-First-Strategie und die Notwendigkeit strukturierter Datenbeziehungen. Die Datenbankarchitektur umfasst drei Kerntabellen mit einem klaren Beziehungsmodell:
CREATE TABLE books(
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  author TEXT NOT NULL,
  totalPages INTEGER NOT NULL,
  currentPage INTEGER NOT NULL,
  startDate TEXT NOT NULL,
  finishDate TEXT
);
Der DatabaseService implementiert das Singleton-Pattern zur Sicherstellung einer einzigen Datenbankverbindung während der App-Laufzeit. Die Versionierung der Datenbank erfolgt über Migrations-Logik, die bei Updates automatisch neue Tabellen wie das Notizen-System hinzufügt.
3.3 Plattformübergreifende Kommunikation und API-Handling
Die Künstliche Intelligenz-Funktionalität stellt das Herzstück der Lernfeatures dar. Das System implementiert eine mehrstufige Fallback-Strategie mit drei verschiedenen AI-Providern. Primär wird die Hugging Face Inference API mit dem microsoft/DialoGPT-medium Modell verwendet, gefolgt von ShuttleAI und Free-AI.xyz als Alternativen. 
Die API-Kommunikation erfolgt über strukturierte HTTP-Requests mit konfigurierbaren Timeouts und Retry-Mechanismen. Ein typischer KI-Prompt für Quiz-Generierung sieht folgendermassen aus:
final prompt = '''
Erstelle $questionCount Multiple-Choice-Fragen für das Buch "${book.title}" von ${book.author}.

Format jede Frage als JSON:
{
  "question": "Frage text",
  "options": ["Option A", "Option B", "Option C", "Option D"],
  "correctAnswer": 0,
  "explanation": "Erklärung der richtigen Antwort"
}
''';

4. Features 
4.1 Buchverwaltung und Datenmodellierung
Die Buchverwaltung bildet das Fundament der Anwendung und implementiert vollständige CRUD-Operationen (Create, Read, Update, Delete). Das Book-Datenmodell enthält alle relevanten Metadaten inklusive Fortschrittsberechnung und Tag-System für Kategorisierung.
Das zentrale Book-Modell definiert die Datenstruktur mit automatischer Fortschrittsberechnung und Status-Ermittlung:
class Book {
  final String id;
  final String title;
  final String author;
  final String? description;
  final int totalPages;
  final int currentPage;
  final DateTime startDate;
  final DateTime? finishDate;
  final String? coverUrl;
  final String? isbn;
  final List<String>? tags;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    required this.totalPages,
    required this.currentPage,
    required this.startDate,
    this.finishDate,
    this.coverUrl,
    this.isbn,
    this.tags,
  });

  double get progress => totalPages > 0 ? currentPage / totalPages : 0.0;
  
  bool get isFinished => finishDate != null || (currentPage >= totalPages && totalPages > 0);
  
  BookStatus get status {
    if (isFinished) return BookStatus.finished;
    if (currentPage > 0) return BookStatus.reading;
    return BookStatus.planned;
  }
}

Der Lesefortschritt wird dynamisch als Prozentsatz berechnet, basierend auf dem Verhältnis von aktueller Seite zu Gesamtseitenzahl. Diese Berechnung erfolgt in der Getter-Methode des Book-Modells und wird automatisch bei Datenbankabfragen aktualisiert.
Die CRUD-Operationen sind im DatabaseService implementiert und nutzen asynchrone Methoden für non-blocking Datenbankzugriffe:

class DatabaseService {
  Future<int> insertBook(Book book) async {
    final db = await database;
    final result = await db.insert('books', book.toMap());
    
    // Tags separat speichern
    if (book.tags != null) {
      for (final tag in book.tags!) {
        await db.insert('book_tags', {
          'bookId': book.id,
          'tag': tag,
        });
      }
    }
    return result;
  }

  Future<List<Book>> getAllBooks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('books', orderBy: 'startDate DESC');
    
    List<Book> books = [];
    for (var map in maps) {
      final tags = await getTagsForBook(map['id']);
      books.add(Book.fromMap(map, tags: tags));
    }
    return books;
  }

  Future<void> updateBookProgress(String bookId, int currentPage) async {
    final db = await database;
    final book = await getBookById(bookId);
    
    Map<String, dynamic> updates = {'currentPage': currentPage};
    
    // Automatisches Fertigstellungsdatum setzen
    if (book != null && currentPage >= book.totalPages && book.finishDate == null) {
      updates['finishDate'] = DateTime.now().toIso8601String();
    }
    
    await db.update('books', updates, where: 'id = ?', whereArgs: [bookId]);
  }
}

Die Suchfunktionalität nutzt SQLite's LIKE-Operator für Volltext-Suche in Titeln, Autorennamen und Beschreibungen. Filter-Optionen ermöglichen die Segmentierung nach Lesestatus, was durch entsprechende WHERE-Klauseln in den Datenbankabfragen realisiert wird:

Future<List<Book>> searchBooks(String query, {BookStatus? statusFilter}) async {
  final db = await database;
  String whereClause = '';
  List<dynamic> whereArgs = [];
  
  if (query.isNotEmpty) {
    whereClause = '(title LIKE ? OR author LIKE ? OR description LIKE ?)';
    whereArgs.addAll(['%$query%', '%$query%', '%$query%']);
  }
  
  if (statusFilter != null) {
    if (whereClause.isNotEmpty) whereClause += ' AND ';
    switch (statusFilter) {
      case BookStatus.reading:
        whereClause += 'currentPage > 0 AND finishDate IS NULL';
        break;
      case BookStatus.finished:
        whereClause += 'finishDate IS NOT NULL';
        break;
      case BookStatus.planned:
        whereClause += 'currentPage = 0 AND finishDate IS NULL';
        break;
    }
  }
  
  final maps = await db.query('books', 
    where: whereClause.isNotEmpty ? whereClause : null, 
    whereArgs: whereArgs,
    orderBy: 'title ASC'
  );
  
  return maps.map((map) => Book.fromMap(map)).toList();
}

Das Tag-System ermöglicht flexible Kategorisierung über eine Many-to-Many-Beziehung zwischen Büchern und Tags. Die Implementierung erfolgt über eine separate book_tags-Tabelle, die referenzielle Integrität durch Foreign Key-Constraints sicherstellt. Die Tag-Verwaltung unterstützt sowohl die Zuweisung neuer Tags als auch die Entfernung bestehender Zuordnungen mit automatischer Bereinigung verwaister Tags.Die Fortschritts-Aktualisierung erfolgt über eine dedizierte Methode, die sowohl die aktuelle Seite als auch potenzielle Fertigstellungsdaten automatisch setzt. Bei Erreichen der letzten Seite wird automatisch das Fertigstellungsdatum gesetzt, was die Basis für Statistikberechnungen und Leseverlauf-Analysen bildet.

4.2 Notizfunktion mit Typisierung
Das Notizen-System erweitert die Grundfunktionalität um eine strukturierte Annotation-Möglichkeit. Implementiert sind vier Notiztypen: TEXT für allgemeine Notizen, HIGHLIGHT für wichtige Passagen, BOOKMARK für Markierungen und QUOTE für Zitate.
enum NoteType { TEXT, HIGHLIGHT, BOOKMARK, QUOTE }

class Note {
  final String id;
  final String bookId;
  final String content;
  final int? pageNumber;
  final NoteType type;
  final DateTime createdAt;
}
Die Verknüpfung zur Seitenzahl ermöglicht kontextuelle Bezüge, während die Volltextsuche in Notizen über SQL-Abfragen mit LIKE-Pattern realisiert wird. Das System unterstützt sowohl die Erstellung neuer Notizen als auch die Bearbeitung bestehender Einträge mit automatischer Zeitstempel-Aktualisierung.
4.3 Benachrichtigungssystem und Zeitplanung
Die Implementierung des Benachrichtigungssystems basiert auf dem flutter_local_notifications-Plugin und unterstützt plattformspezifische Konfigurationen für iOS und Android. Das System ermöglicht die Planung wiederkehrender Lese-Erinnerungen mit flexibler Wochentag-Auswahl.
Future<void> scheduleReadingReminder({
  required TimeOfDay time,
  required List<int> weekdays,
  String? bookTitle,
}) async {
  for (int weekday in weekdays) {
    await _notifications.zonedSchedule(
      weekday,
      'Lesezeit! 📚',
      bookTitle != null ? 'Zeit, mit "$bookTitle" weiterzulesen!' : 'Zeit für deine tägliche Lektüre!',
      _nextInstanceOfTime(time, weekday),
      notificationDetails,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }
}
Die Zeitberechnung erfolgt über die timezone-Bibliothek mit automatischer Lokalisierung für die Zeitzone Europe/Berlin. Das System berücksichtigt Wochentag-Wiederholungen und berechnet den nächsten Ausführungstermin automatisch.
4.4 KI-gestützte Lerntools
Die KI-Integration umfasst mehrere Lernmodule: Quiz-Generierung, Flashcard-Erstellung und Essay-Fragen. Jedes Modul nutzt spezialisierte Prompts zur Generierung strukturierter Inhalte.
Die Quiz-Generierung erstellt Multiple-Choice-Fragen mit verschiedenen Schwierigkeitsgraden. Die API-Antwort wird als JSON geparst und in typisierte Dart-Objekte konvertiert. Bei API-Fehlern greift ein lokaler Fallback-Mechanismus, der auf Buchmetadaten basierte Fragen generiert.
Der Flashcard-Generator erstellt Lernkarten mit Kategorisierung nach Themen wie Charaktere, Handlung und literarische Mittel. Die Rückseite der Karten enthält kontextuelle Erklärungen, die das Verständnis fördern.
Future<List<QuizQuestion>> generateQuiz(Book book, {int questionCount = 5}) async {
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
''';

  final response = await generateCustomResponse(prompt);
  return _parseQuizQuestions(response);
}

4.5 Benutzeroberfläche und Interaction Design
Das UI-Design implementiert den Liquid Glass-Ansatz durch eine wiederverwendbare GlassCard-Komponente. Diese nutzt BackdropFilter für Blur-Effekte und Gradientenoverlay für die charakteristische Glasoptik:
child: BackdropFilter(
  filter: ImageFilter.blur(sigmaX: blur * 2, sigmaY: blur * 2),
  child: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.3),
          Colors.white.withOpacity(0.1),
        ],
      ),
    ),
  ),
),
Die Navigation erfolgt über eine Bottom Navigation Bar mit fünf Hauptbereichen. Das State Management nutzt setState() für lokale Zustandsänderungen und ValueNotifier für globale Einstellungen wie das Theme-System.
5 Datenbank- und Backendstruktur
Die SQLite-Datenbank implementiert ein relationales Schema mit Foreign Key-Constraints zur Sicherstellung der Datenintegrität. Die Migrations-Logik ermöglicht strukturierte Updates ohne Datenverlust:
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute('''
      CREATE TABLE notes(
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        content TEXT NOT NULL,
        FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');
  }
}
Die Datenbank nutzt CASCADE-Löschung für referenzielle Integrität, sodass beim Löschen eines Buches automatisch alle zugehörigen Notizen und Tags entfernt werden. Indexierung erfolgt über die Primärschlüssel und Foreign Keys für optimale Abfrageleistung. Das Backend-Design folgt dem Repository-Pattern mit dem DatabaseService als zentrale Datenzugriffsschicht. Alle Datenbankoperationen sind asynchron implementiert und nutzen async/await für non-blocking Operationen.
