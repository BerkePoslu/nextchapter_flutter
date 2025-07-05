import 'package:uuid/uuid.dart';

class Note {
  final String id;
  final String bookId;
  final String content;
  final int? pageNumber;
  final String type;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Note({
    String? id,
    required this.bookId,
    required this.content,
    this.pageNumber,
    this.type = 'TEXT',
    DateTime? createdAt,
    this.updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'content': content,
      'pageNumber': pageNumber,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static Note fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      bookId: json['bookId'],
      content: json['content'],
      pageNumber: json['pageNumber'],
      type: json['type'] ?? 'TEXT',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Note copyWith({
    String? id,
    String? bookId,
    String? content,
    int? pageNumber,
    String? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      content: content ?? this.content,
      pageNumber: pageNumber ?? this.pageNumber,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Note{id: $id, bookId: $bookId, content: $content, pageNumber: $pageNumber, type: $type, createdAt: $createdAt}';
  }
}

// Note-Typen als Konstanten
class NoteType {
  static const String text = 'TEXT';
  static const String highlight = 'HIGHLIGHT';
  static const String bookmark = 'BOOKMARK';
  static const String quote = 'QUOTE';
}
