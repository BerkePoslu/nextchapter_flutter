import 'package:flutter_test/flutter_test.dart';
import 'package:nextchapter/models/book.dart';
import 'package:nextchapter/models/note.dart';

void main() {
  group('📚 Book Model Tests', () {
    test('should create book with valid data', () {
      final book = Book(
        id: '1',
        title: 'Test Book',
        author: 'Test Author',
        totalPages: 300,
        currentPage: 50,
        startDate: DateTime.now(),
        tags: ['fiction', 'test'],
        isbn: '1234567890',
        coverUrl: 'test_cover.jpg',
        description: 'Test description',
      );

      expect(book.title, equals('Test Book'));
      expect(book.author, equals('Test Author'));
      expect(book.totalPages, equals(300));
      expect(book.currentPage, equals(50));
      expect(book.tags, contains('fiction'));
      expect(book.isbn, equals('1234567890'));
    });

    test('should calculate reading progress correctly', () {
      final book = Book(
        id: '1',
        title: 'Test Book',
        author: 'Test Author',
        totalPages: 200,
        currentPage: 50,
        startDate: DateTime.now(),
      );

      expect(book.progress, equals(0.25));
    });

    test('should handle zero pages correctly', () {
      final book = Book(
        id: '1',
        title: 'Test Book',
        author: 'Test Author',
        totalPages: 0,
        currentPage: 0,
        startDate: DateTime.now(),
      );

      expect(book.progress, equals(0.0));
    });

    test('should determine if book is finished', () {
      final finishedBook = Book(
        id: '1',
        title: 'Finished Book',
        author: 'Author',
        totalPages: 100,
        currentPage: 100,
        startDate: DateTime.now(),
        finishDate: DateTime.now(),
      );

      final unfinishedBook = Book(
        id: '2',
        title: 'Unfinished Book',
        author: 'Author',
        totalPages: 100,
        currentPage: 50,
        startDate: DateTime.now(),
      );

      expect(finishedBook.isFinished, isTrue);
      expect(unfinishedBook.isFinished, isFalse);
    });

    test('should convert book to JSON', () {
      final book = Book(
        id: '1',
        title: 'Test Book',
        author: 'Test Author',
        totalPages: 300,
        currentPage: 50,
        startDate: DateTime(2023, 1, 1),
        tags: ['fiction'],
        isbn: '1234567890',
        coverUrl: 'cover.jpg',
      );

      final json = book.toJson();

      expect(json['id'], equals('1'));
      expect(json['title'], equals('Test Book'));
      expect(json['author'], equals('Test Author'));
      expect(json['totalPages'], equals(300));
      expect(json['currentPage'], equals(50));
      expect(json['isbn'], equals('1234567890'));
      expect(json['coverUrl'], equals('cover.jpg'));
    });

    test('should create book from JSON', () {
      final json = {
        'id': '1',
        'title': 'Test Book',
        'author': 'Test Author',
        'totalPages': 300,
        'currentPage': 50,
        'startDate': '2023-01-01T00:00:00.000Z',
        'tags': ['fiction', 'drama'],
        'isbn': '1234567890',
        'coverUrl': 'cover.jpg',
      };

      final book = Book.fromJson(json);

      expect(book.id, equals('1'));
      expect(book.title, equals('Test Book'));
      expect(book.author, equals('Test Author'));
      expect(book.totalPages, equals(300));
      expect(book.currentPage, equals(50));
      expect(book.tags, contains('fiction'));
      expect(book.tags, contains('drama'));
      expect(book.isbn, equals('1234567890'));
      expect(book.coverUrl, equals('cover.jpg'));
    });
  });

  group('📝 Note Model Tests', () {
    test('should create note with valid data', () {
      final note = Note(
        id: '1',
        bookId: '1',
        type: 'TEXT',
        content: 'Test note content',
        pageNumber: 42,
        createdAt: DateTime.now(),
      );

      expect(note.id, equals('1'));
      expect(note.bookId, equals('1'));
      expect(note.type, equals('TEXT'));
      expect(note.content, equals('Test note content'));
      expect(note.pageNumber, equals(42));
    });

    test('should handle different note types', () {
      final textNote = Note(
        id: '1',
        bookId: '1',
        type: 'TEXT',
        content: 'Text note',
        pageNumber: 10,
        createdAt: DateTime.now(),
      );

      final highlightNote = Note(
        id: '2',
        bookId: '1',
        type: 'HIGHLIGHT',
        content: 'Highlighted text',
        pageNumber: 20,
        createdAt: DateTime.now(),
      );

      final bookmarkNote = Note(
        id: '3',
        bookId: '1',
        type: 'BOOKMARK',
        content: 'Bookmark',
        pageNumber: 30,
        createdAt: DateTime.now(),
      );

      final quoteNote = Note(
        id: '4',
        bookId: '1',
        type: 'QUOTE',
        content: 'Famous quote',
        pageNumber: 40,
        createdAt: DateTime.now(),
      );

      expect(textNote.type, equals('TEXT'));
      expect(highlightNote.type, equals('HIGHLIGHT'));
      expect(bookmarkNote.type, equals('BOOKMARK'));
      expect(quoteNote.type, equals('QUOTE'));
    });

    test('should convert note to JSON', () {
      final note = Note(
        id: '1',
        bookId: '1',
        type: 'TEXT',
        content: 'Test note',
        pageNumber: 42,
        createdAt: DateTime(2023, 1, 1),
      );

      final json = note.toJson();

      expect(json['id'], equals('1'));
      expect(json['bookId'], equals('1'));
      expect(json['type'], equals('TEXT'));
      expect(json['content'], equals('Test note'));
      expect(json['pageNumber'], equals(42));
    });

    test('should create note from JSON', () {
      final json = {
        'id': '1',
        'bookId': '1',
        'type': 'HIGHLIGHT',
        'content': 'Test highlight',
        'pageNumber': 42,
        'createdAt': '2023-01-01T00:00:00.000Z',
      };

      final note = Note.fromJson(json);

      expect(note.id, equals('1'));
      expect(note.bookId, equals('1'));
      expect(note.type, equals('HIGHLIGHT'));
      expect(note.content, equals('Test highlight'));
      expect(note.pageNumber, equals(42));
    });
  });

  group('🔧 Utility Functions Tests', () {
    test('should validate ISBN format', () {
      expect(isValidISBN('1234567890'), isTrue);
      expect(isValidISBN('123-456-789-0'), isTrue);
      expect(isValidISBN(''), isFalse);
      expect(isValidISBN('abc'), isFalse);
      expect(isValidISBN('12345'), isFalse);
    });

    test('should validate page numbers', () {
      expect(isValidPageNumber(1), isTrue);
      expect(isValidPageNumber(100), isTrue);
      expect(isValidPageNumber(0), isFalse);
      expect(isValidPageNumber(-1), isFalse);
    });

    test('should validate book titles', () {
      expect(isValidTitle('Valid Title'), isTrue);
      expect(isValidTitle('A'), isTrue);
      expect(isValidTitle(''), isFalse);
      expect(isValidTitle('   '), isFalse);
    });

    test('should validate author names', () {
      expect(isValidAuthor('John Doe'), isTrue);
      expect(isValidAuthor('J.R.R. Tolkien'), isTrue);
      expect(isValidAuthor(''), isFalse);
      expect(isValidAuthor('   '), isFalse);
    });

    test('should format progress percentage', () {
      expect(formatProgressPercentage(0.25), equals('25%'));
      expect(formatProgressPercentage(0.505), equals('51%'));
      expect(formatProgressPercentage(1.0), equals('100%'));
      expect(formatProgressPercentage(0.0), equals('0%'));
    });

    test('should calculate reading time estimation', () {
      expect(estimateReadingTime(200, 50),
          equals(3)); // 200 pages, 50 current = 150 left, ~3 hours
      expect(estimateReadingTime(100, 100), equals(0)); // finished book
      expect(estimateReadingTime(0, 0), equals(0)); // no pages
    });

    test('should parse tags correctly', () {
      expect(parseTags('fiction,drama,romance'),
          equals(['fiction', 'drama', 'romance']));
      expect(parseTags('single'), equals(['single']));
      expect(parseTags(''), equals([]));
      expect(parseTags('  fiction  ,  drama  '), equals(['fiction', 'drama']));
    });

    test('should format tags for storage', () {
      expect(formatTags(['fiction', 'drama', 'romance']),
          equals('fiction,drama,romance'));
      expect(formatTags(['single']), equals('single'));
      expect(formatTags([]), equals(''));
    });
  });

  group('📊 Statistics Tests', () {
    test('should calculate total books read', () {
      final books = [
        createTestBook(
            id: '1',
            totalPages: 100,
            currentPage: 100,
            finishDate: DateTime.now()),
        createTestBook(id: '2', totalPages: 200, currentPage: 150),
        createTestBook(
            id: '3',
            totalPages: 300,
            currentPage: 300,
            finishDate: DateTime.now()),
      ];

      expect(countFinishedBooks(books), equals(2));
    });

    test('should calculate total pages read', () {
      final books = [
        createTestBook(id: '1', totalPages: 100, currentPage: 50),
        createTestBook(id: '2', totalPages: 200, currentPage: 100),
        createTestBook(id: '3', totalPages: 300, currentPage: 300),
      ];

      expect(calculateTotalPagesRead(books), equals(450));
    });

    test('should calculate average progress', () {
      final books = [
        createTestBook(id: '1', totalPages: 100, currentPage: 50), // 50%
        createTestBook(id: '2', totalPages: 200, currentPage: 100), // 50%
        createTestBook(id: '3', totalPages: 100, currentPage: 100), // 100%
      ];

      expect(calculateAverageProgress(books), equals(66.67));
    });

    test('should handle empty book list', () {
      expect(countFinishedBooks([]), equals(0));
      expect(calculateTotalPagesRead([]), equals(0));
      expect(calculateAverageProgress([]), equals(0.0));
    });
  });
}

// Helper functions for testing
bool isValidISBN(String isbn) {
  if (isbn.isEmpty) return false;
  final cleaned = isbn.replaceAll(RegExp(r'[^0-9]'), '');
  return cleaned.length == 10 || cleaned.length == 13;
}

bool isValidPageNumber(int page) {
  return page > 0;
}

bool isValidTitle(String title) {
  return title.trim().isNotEmpty;
}

bool isValidAuthor(String author) {
  return author.trim().isNotEmpty;
}

String formatProgressPercentage(double progress) {
  return '${(progress * 100).round()}%';
}

int estimateReadingTime(int totalPages, int currentPage) {
  if (totalPages == 0 || currentPage >= totalPages) return 0;
  final remainingPages = totalPages - currentPage;
  return (remainingPages / 50).ceil(); // ~50 pages per hour
}

List<String> parseTags(String tagsString) {
  if (tagsString.isEmpty) return [];
  return tagsString
      .split(',')
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toList();
}

String formatTags(List<String> tags) {
  return tags.join(',');
}

int countFinishedBooks(List<Book> books) {
  return books.where((book) => book.isFinished).length;
}

int calculateTotalPagesRead(List<Book> books) {
  return books.fold(0, (sum, book) => sum + book.currentPage);
}

double calculateAverageProgress(List<Book> books) {
  if (books.isEmpty) return 0.0;
  final totalProgress = books.fold(0.0, (sum, book) => sum + book.progress);
  return double.parse(
      ((totalProgress / books.length) * 100).toStringAsFixed(2));
}

Book createTestBook({
  required String id,
  String title = 'Test Book',
  String author = 'Test Author',
  required int totalPages,
  required int currentPage,
  DateTime? finishDate,
  List<String>? tags,
}) {
  return Book(
    id: id,
    title: title,
    author: author,
    totalPages: totalPages,
    currentPage: currentPage,
    startDate: DateTime.now(),
    finishDate: finishDate,
    tags: tags,
  );
}
