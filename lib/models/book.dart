class Book {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final int totalPages;
  int currentPage;
  final DateTime startDate;
  DateTime? finishDate;
  final String? description;
  final List<String>? tags;
  final String? isbn;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    required this.totalPages,
    this.currentPage = 0,
    required this.startDate,
    this.finishDate,
    this.description,
    this.tags,
    this.isbn,
  });

  double get progress => totalPages > 0 ? currentPage / totalPages : 0;

  bool get isFinished => finishDate != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'totalPages': totalPages,
      'currentPage': currentPage,
      'startDate': startDate.toIso8601String(),
      'finishDate': finishDate?.toIso8601String(),
      'description': description,
      'isbn': isbn,
    };
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      coverUrl: json['coverUrl'],
      totalPages: json['totalPages'],
      currentPage: json['currentPage'],
      startDate: DateTime.parse(json['startDate']),
      finishDate: json['finishDate'] != null
          ? DateTime.parse(json['finishDate'])
          : null,
      description: json['description'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      isbn: json['isbn'],
    );
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? coverUrl,
    int? totalPages,
    int? currentPage,
    DateTime? startDate,
    DateTime? finishDate,
    String? description,
    List<String>? tags,
    String? isbn,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      startDate: startDate ?? this.startDate,
      finishDate: finishDate ?? this.finishDate,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      isbn: isbn ?? this.isbn,
    );
  }
}
