import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/book.dart';
import '../models/note.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'nextchapter.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDb,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE books(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        coverUrl TEXT,
        totalPages INTEGER NOT NULL,
        currentPage INTEGER NOT NULL,
        startDate TEXT NOT NULL,
        finishDate TEXT,
        description TEXT,
        isbn TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE book_tags(
        bookId TEXT NOT NULL,
        tag TEXT NOT NULL,
        FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE,
        PRIMARY KEY (bookId, tag)
      )
    ''');

    // Neue Notes-Tabelle
    await db.execute('''
      CREATE TABLE notes(
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        content TEXT NOT NULL,
        pageNumber INTEGER,
        type TEXT NOT NULL DEFAULT 'TEXT',
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Upgrade zu Version 2: Notes-Tabelle hinzufügen
      await db.execute('''
        CREATE TABLE notes(
          id TEXT PRIMARY KEY,
          bookId TEXT NOT NULL,
          content TEXT NOT NULL,
          pageNumber INTEGER,
          type TEXT NOT NULL DEFAULT 'TEXT',
          createdAt TEXT NOT NULL,
          updatedAt TEXT,
          FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  Future<void> insertBook(Book book) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'books',
        book.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (book.tags != null) {
        for (String tag in book.tags!) {
          await txn.insert(
            'book_tags',
            {'bookId': book.id, 'tag': tag},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  // Notes-Methoden hinzufügen
  Future<void> insertNote(Note note) async {
    final db = await database;
    await db.insert(
      'notes',
      note.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Note>> getNotesByBook(String bookId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Note.fromJson(Map<String, dynamic>.from(maps[i]));
    });
  }

  Future<void> updateNote(Note note) async {
    final db = await database;
    await db.update(
      'notes',
      note.toJson(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> deleteNote(String noteId) async {
    final db = await database;
    await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }

  Future<List<Note>> searchNotes(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'content LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Note.fromJson(Map<String, dynamic>.from(maps[i]));
    });
  }

  Future<Book?> getBook(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> bookMaps = await db.query(
      'books',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (bookMaps.isEmpty) return null;

    final List<Map<String, dynamic>> tagMaps = await db.query(
      'book_tags',
      where: 'bookId = ?',
      whereArgs: [id],
    );

    final List<String> tags =
        tagMaps.map((map) => map['tag'] as String).toList();

    final bookData = Map<String, dynamic>.from(bookMaps.first);
    bookData['tags'] = tags;

    return Book.fromJson(bookData);
  }

  Future<List<Book>> getAllBooks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('books');

    return List.generate(maps.length, (i) {
      return Book.fromJson(Map<String, dynamic>.from(maps[i]));
    });
  }

  Future<void> updateBook(Book book) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'books',
        book.toJson(),
        where: 'id = ?',
        whereArgs: [book.id],
      );

      await txn.delete(
        'book_tags',
        where: 'bookId = ?',
        whereArgs: [book.id],
      );

      if (book.tags != null) {
        for (String tag in book.tags!) {
          await txn.insert(
            'book_tags',
            {'bookId': book.id, 'tag': tag},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  Future<void> deleteBook(String id) async {
    final db = await database;
    await db.delete(
      'books',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Book>> getCurrentlyReadingBooks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      where: 'currentPage < totalPages AND currentPage > 0',
    );

    return List.generate(maps.length, (i) {
      return Book.fromJson(Map<String, dynamic>.from(maps[i]));
    });
  }

  Future<List<Book>> getFinishedBooks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      where: 'currentPage >= totalPages',
    );

    return List.generate(maps.length, (i) {
      return Book.fromJson(Map<String, dynamic>.from(maps[i]));
    });
  }

  // Add this method to reset the database (for development/testing)
  static Future<void> resetDatabase() async {
    final dbPath = join(await getDatabasesPath(), 'nextchapter.db');
    await deleteDatabase(dbPath);
    _database = null;
  }
}
