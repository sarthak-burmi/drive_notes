import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drive_notes/features/notes/data/models/note_model.dart';

class NoteEditor extends ConsumerStatefulWidget {
  final NoteModel? note;
  final Function(String content, String title) onSave;
  final bool isNewNote;

  const NoteEditor({
    Key? key,
    this.note,
    required this.onSave,
    this.isNewNote = false,
  }) : super(key: key);

  @override
  ConsumerState<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<NoteEditor>
    with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late FocusNode _titleFocusNode;
  late FocusNode _contentFocusNode;
  bool _hasFocus = false;
  bool _isEdited = false;
  bool _isSaving = false;

  // Animation controller for save banner
  late AnimationController _bannerController;
  late Animation<double> _bannerAnimation;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.note?.name ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );

    _titleFocusNode = FocusNode();
    _contentFocusNode = FocusNode();

    // Listen for focus changes
    _titleFocusNode.addListener(_handleFocusChange);
    _contentFocusNode.addListener(_handleFocusChange);

    // Listen for text changes
    _titleController.addListener(_handleTextChange);
    _contentController.addListener(_handleTextChange);

    // Initialize animation controller for save banner
    _bannerController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bannerAnimation = CurvedAnimation(
      parent: _bannerController,
      curve: Curves.easeOut,
    );

    // Auto-focus on title for new notes
    if (widget.isNewNote) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _titleFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _hasFocus = _titleFocusNode.hasFocus || _contentFocusNode.hasFocus;
    });
  }

  void _handleTextChange() {
    final bool shouldBeEdited =
        _titleController.text != widget.note?.name ||
        _contentController.text != widget.note?.content;

    if (!_isEdited && shouldBeEdited) {
      setState(() {
        _isEdited = true;
      });
      _bannerController.forward();
    } else if (_isEdited && !shouldBeEdited) {
      setState(() {
        _isEdited = false;
      });
      _bannerController.reverse();
    }
  }

  // Public methods accessible from parent
  void saveNote() {
    final title =
        _titleController.text.trim().isEmpty
            ? 'Untitled Note'
            : _titleController.text.trim();

    setState(() {
      _isSaving = true;
      _isEdited = false;
    });
    _bannerController.reverse();

    widget.onSave(_contentController.text, title);
  }

  void setSavingState(bool saving) {
    if (mounted) {
      setState(() {
        _isSaving = saving;
      });
    }
  }

  // Check if there are unsaved changes
  bool hasUnsavedChanges() {
    return _isEdited;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Column(
          children: [
            // Animated save banner
            SizeTransition(
              sizeFactor: _bannerAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(_bannerAnimation),
                child: Container(
                  color: colorScheme.primaryContainer,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_note,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'You have unsaved changes',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: saveNote,
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Title input with improved styling
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
                decoration: InputDecoration(
                  hintText: 'Note title',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontWeight: FontWeight.normal,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onSubmitted: (_) {
                  // Move focus to content when title is submitted
                  _contentFocusNode.requestFocus();
                },
              ),
            ),

            // Divider with improved styling
            Divider(
              height: 1,
              thickness: 1,
              indent: 16,
              endIndent: 16,
              color: colorScheme.outlineVariant,
            ),

            // Content input with improved styling
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: TextField(
                  controller: _contentController,
                  focusNode: _contentFocusNode,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.5),
                  decoration: InputDecoration(
                    hintText: 'Start typing...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ),
          ],
        ),

        // Add overlay loading indicator with improved styling
        if (_isSaving)
          Container(
            color: colorScheme.background.withOpacity(0.7),
            child: Center(
              child: Card(
                elevation: 8,
                shadowColor: colorScheme.shadow.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: colorScheme.primary),
                      const SizedBox(height: 24),
                      Text(
                        'Saving note...',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please wait while we save your changes',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
