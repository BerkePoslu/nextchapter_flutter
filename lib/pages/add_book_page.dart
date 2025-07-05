import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/book.dart';
import '../services/database_service.dart';

class AddBookPage extends StatefulWidget {
  final VoidCallback? onNavigateBack;

  const AddBookPage({Key? key, this.onNavigateBack}) : super(key: key);

  @override
  State<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _totalPagesController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _isbnController = TextEditingController();
  final _tagsController = TextEditingController();
  String? _coverUrl;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _totalPagesController.dispose();
    _descriptionController.dispose();
    _isbnController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _saveBook() async {
    if (_formKey.currentState!.validate()) {
      final book = Book(
        id: const Uuid().v4(),
        title: _titleController.text,
        author: _authorController.text,
        totalPages: int.parse(_totalPagesController.text),
        startDate: DateTime.now(),
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        isbn: _isbnController.text.isEmpty ? null : _isbnController.text,
        tags: _tagsController.text.isEmpty
            ? null
            : _tagsController.text.split(',').map((e) => e.trim()).toList(),
        coverUrl: _coverUrl,
      );

      try {
        await DatabaseService().insertBook(book);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Buch erfolgreich hinzugefügt')),
          );
          _clearForm();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Speichern: $e')),
          );
        }
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _authorController.clear();
    _totalPagesController.clear();
    _descriptionController.clear();
    _isbnController.clear();
    _tagsController.clear();
    setState(() {
      _coverUrl = null;
    });
  }

  void _showCoverUrlDialog() {
    final TextEditingController urlController =
        TextEditingController(text: _coverUrl ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cover-Bild URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                hintText: 'https://example.com/book-cover.jpg',
                labelText: 'Bild-URL',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Geben Sie eine URL zu einem Buchcover-Bild ein.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _coverUrl = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Entfernen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _coverUrl =
                    urlController.text.isEmpty ? null : urlController.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buch hinzufügen'),
        leading: widget.onNavigateBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onNavigateBack,
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover Image
              GestureDetector(
                onTap: _showCoverUrlDialog,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _coverUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _coverUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.add_photo_alternate,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titel',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte geben Sie einen Titel ein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Author
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(
                  labelText: 'Autor',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte geben Sie einen Autor ein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Total Pages
              TextFormField(
                controller: _totalPagesController,
                decoration: const InputDecoration(
                  labelText: 'Anzahl Seiten',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte geben Sie die Anzahl der Seiten ein';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Bitte geben Sie eine gültige Zahl ein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // ISBN
              TextFormField(
                controller: _isbnController,
                decoration: const InputDecoration(
                  labelText: 'ISBN (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Tags
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (optional, durch Kommas getrennt)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _saveBook,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Buch speichern'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
