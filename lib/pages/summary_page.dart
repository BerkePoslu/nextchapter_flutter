import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../main.dart';
import '../services/ai_service.dart';
import '../models/book.dart';

class SummaryPage extends StatefulWidget {
  final Book book;

  const SummaryPage({Key? key, required this.book}) : super(key: key);

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  String _summary = '';
  bool _isLoading = true;
  double _fontSize = 16.0;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);
    try {
      final summary = await AIService().generateSummary(widget.book);
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der Zusammenfassung: $e')),
        );
      }
    }
  }

  void _increaseFontSize() {
    setState(() {
      _fontSize = (_fontSize + 2).clamp(12.0, 24.0);
    });
  }

  void _decreaseFontSize() {
    setState(() {
      _fontSize = (_fontSize - 2).clamp(12.0, 24.0);
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _summary));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Zusammenfassung in Zwischenablage kopiert'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareSummary() {
    // In a real app, you would use the share_plus package
    // For now, we'll just copy to clipboard
    _copyToClipboard();
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Zusammenfassung: ${widget.book.title}'),
          actions: [
            if (!_isLoading && _summary.isNotEmpty) ...[
              IconButton(
                onPressed: _decreaseFontSize,
                icon: const Icon(Icons.text_decrease),
                tooltip: 'Schrift verkleinern',
              ),
              IconButton(
                onPressed: _increaseFontSize,
                icon: const Icon(Icons.text_increase),
                tooltip: 'Schrift vergrößern',
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'copy':
                      _copyToClipboard();
                      break;
                    case 'share':
                      _shareSummary();
                      break;
                    case 'regenerate':
                      _loadSummary();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'copy',
                    child: Row(
                      children: [
                        Icon(Icons.copy),
                        SizedBox(width: 8),
                        Text('Kopieren'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share),
                        SizedBox(width: 8),
                        Text('Teilen'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'regenerate',
                    child: Row(
                      children: [
                        Icon(Icons.refresh),
                        SizedBox(width: 8),
                        Text('Neu generieren'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _summary.isEmpty
                ? _buildNoSummary()
                : _buildSummaryView(),
      ),
    );
  }

  Widget _buildSummaryView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book info header
          GlassCard(
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                  child: Icon(
                    Icons.book,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.book.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'von ${widget.book.author}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.pages,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.book.totalPages} Seiten',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.trending_up,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(widget.book.progress * 100).round()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Summary content
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.summarize,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'KI-Zusammenfassung',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Reading time estimate
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Lesezeit: ~${(_summary.length / 200).ceil()} Min.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Summary text
                SelectableText(
                  _summary,
                  style: TextStyle(
                    fontSize: _fontSize,
                    height: 1.6,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loadSummary,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Neu generieren'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy),
                  label: const Text('Kopieren'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Tips card
          GlassCard(
            color: Theme.of(context)
                .colorScheme
                .tertiaryContainer
                .withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Lerntipps',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTip('📝', 'Mache dir Notizen zu den wichtigsten Punkten'),
                _buildTip('🎯', 'Konzentriere dich auf die Hauptthemen'),
                _buildTip('🔄', 'Wiederhole die Zusammenfassung regelmäßig'),
                _buildTip('❓', 'Stelle dir Fragen zum Inhalt'),
              ],
            ),
          ),

          const SizedBox(height: 100), // Space for bottom navigation
        ],
      ),
    );
  }

  Widget _buildTip(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSummary() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                'Zusammenfassung nicht verfügbar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Die Zusammenfassung konnte nicht geladen werden.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadSummary,
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
