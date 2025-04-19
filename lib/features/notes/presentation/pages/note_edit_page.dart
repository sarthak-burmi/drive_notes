import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drive_notes/core/error/error_handler.dart';
import 'package:drive_notes/core/utils/connectivity_utils.dart';
import 'package:drive_notes/features/notes/data/models/note_model.dart';
import 'package:drive_notes/features/notes/presentation/widgets/note_editor.dart';
import 'package:drive_notes/features/notes/providers/notes_provider.dart';
import 'package:go_router/go_router.dart';

class NoteEditPage extends ConsumerStatefulWidget {
  final String? noteId;
  final NoteModel? note; // For passing note directly from the list

  const NoteEditPage({Key? key, this.noteId, this.note}) : super(key: key);

  @override
  ConsumerState<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends ConsumerState<NoteEditPage>
    with TickerProviderStateMixin {
  bool _isNewNote = false;
  final GlobalKey<State<NoteEditor>> _editorKey =
      GlobalKey<State<NoteEditor>>();
  bool _isSaving = false;

  // Animation controllers
  late AnimationController _saveButtonController;
  late Animation<double> _saveButtonAnimation;

  @override
  void initState() {
    super.initState();
    _isNewNote = widget.noteId == null || widget.noteId == 'new';

    // Initialize animation controllers
    _saveButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _saveButtonAnimation = CurvedAnimation(
      parent: _saveButtonController,
      curve: Curves.elasticOut,
    );

    // Start the animation
    _saveButtonController.forward();
  }

  @override
  void dispose() {
    _saveButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isConnected = ref.watch(connectivityStatusProvider);

    // If creating a new note, we don't need to fetch anything
    if (_isNewNote) {
      return _buildScaffold(null, isConnected);
    }

    // For existing notes, we need to watch the note provider
    final noteAsync = ref.watch(noteNotifierProvider(noteId: widget.noteId));

    return noteAsync.when(
      data: (note) => _buildScaffold(note, isConnected),
      loading:
          () => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    'Loading note...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
      error: (error, stackTrace) {
        // Show error snackbar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ErrorHandler.showErrorSnackBar(context, error as dynamic);
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Error'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                const SizedBox(height: 24),
                Text(
                  'Failed to load note',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScaffold(NoteModel? note, AsyncValue<bool> isConnected) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isNewNote ? 'New Note' : (note?.name ?? 'Note'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Cancel and go back',
          onPressed: () {
            // Show confirmation if there are unsaved changes
            if (_editorKey.currentState != null &&
                (_editorKey.currentState as dynamic).hasUnsavedChanges()) {
              _showDiscardChangesDialog();
            } else {
              context.pop();
            }
          },
        ),
        actions: [
          // Animated save button
          ScaleTransition(
            scale: _saveButtonAnimation,
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child:
                  _isSaving
                      ? Container(
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(8),
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                      : FilledButton.icon(
                        onPressed: _saveNote,
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
            ),
          ),
        ],
      ),

      // Offline indicator
      bottomNavigationBar: isConnected.when(
        data:
            (connected) =>
                connected
                    ? null
                    : Container(
                      color: Colors.orange.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_off, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'You are offline. Your note will be synced later.',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
        loading: () => null,
        error: (_, __) => null,
      ),

      body: SafeArea(
        child: NoteEditor(
          key: _editorKey,
          note: note ?? widget.note,
          onSave: (content, title) => _handleSave(note, content, title),
          isNewNote: _isNewNote,
        ),
      ),
    );
  }

  void _saveNote() {
    setState(() {
      _isSaving = true;
    });

    // Access the NoteEditor using our key and call its public saveNote method
    if (_editorKey.currentState != null) {
      // Cast to dynamic is a workaround for accessing a public method on a private state class
      (_editorKey.currentState as dynamic).saveNote();
    }
  }

  Future<void> _handleSave(
    NoteModel? note,
    String content,
    String title,
  ) async {
    try {
      if (_isNewNote) {
        // Create a new note
        await ref
            .read(notesListNotifierProvider.notifier)
            .createNote(title, content, context);

        if (mounted) {
          // Set _isSaving to false
          setState(() {
            _isSaving = false;
          });

          if (_editorKey.currentState != null) {
            (_editorKey.currentState as dynamic).setSavingState(false);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note created successfully'),
              duration: Duration(seconds: 2),
            ),
          );
          context.pop(); // Go back to the list
        }
      } else {
        // Update existing note
        await ref
            .read(noteNotifierProvider(noteId: widget.noteId).notifier)
            .updateNote(content, context, newTitle: title);

        // Force refresh notes list to get updated timestamps from server
        if (mounted) {
          await ref.read(notesListNotifierProvider.notifier).refreshNotes();

          // Set _isSaving to false
          setState(() {
            _isSaving = false;
          });

          if (_editorKey.currentState != null) {
            (_editorKey.currentState as dynamic).setSavingState(false);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note updated successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Set _isSaving to false in case of error
        setState(() {
          _isSaving = false;
        });

        if (_editorKey.currentState != null) {
          (_editorKey.currentState as dynamic).setSavingState(false);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving note: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Show confirmation dialog when discarding changes
  void _showDiscardChangesDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text(
              'You have unsaved changes. Are you sure you want to discard them?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Discard'),
              ),
            ],
          ),
    );
  }
}
