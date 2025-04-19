import 'package:dio/dio.dart';
import 'package:drive_notes/core/error/app_exceptions.dart';
import 'package:drive_notes/core/utils/connectivity_utils.dart';
import 'package:drive_notes/features/auth/providers/auth_provider.dart';
import 'package:drive_notes/features/notes/data/datasources/drive_datasource.dart';
import 'package:drive_notes/features/notes/data/models/note_model.dart';
import 'package:drive_notes/features/notes/data/repositories/notes_repository.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notes_provider.g.dart';

// Provider for the drive data source
@riverpod
DriveDataSource driveDataSource(DriveDataSourceRef ref) {
  return DriveDataSource(dio: ref.watch(dioProvider), ref: ref);
}

// Provider for the notes repository
@riverpod
NotesRepository notesRepository(NotesRepositoryRef ref) {
  return NotesRepository(driveDataSource: ref.watch(driveDataSourceProvider));
}

// Provider for notes list
@riverpod
class NotesListNotifier extends _$NotesListNotifier {
  @override
  Future<List<NoteModel>> build() async {
    return _fetchNotes();
  }

  Future<List<NoteModel>> _fetchNotes() async {
    try {
      final repository = ref.watch(notesRepositoryProvider);
      return await repository.getNotes();
    } catch (e) {
      // Return empty list on error and we'll show error message in UI
      return [];
    }
  }

  Future<void> refreshNotes() async {
    state = const AsyncValue.loading();
    try {
      final notes = await _fetchNotes();
      state = AsyncValue.data(notes);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> createNote(
    String title,
    String content,
    BuildContext context,
  ) async {
    try {
      final repository = ref.watch(notesRepositoryProvider);
      final newNote = await repository.createNote(title, content);

      // Update state with the new note
      state.whenData((notes) {
        state = AsyncValue.data([newNote, ...notes]);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create note: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> deleteNote(String noteId, BuildContext context) async {
    try {
      final repository = ref.watch(notesRepositoryProvider);
      await repository.deleteNote(noteId);

      // Update state by removing the deleted note
      state.whenData((notes) {
        final updatedNotes = notes.where((note) => note.id != noteId).toList();
        state = AsyncValue.data(updatedNotes);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete note: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> syncOfflineNotes(BuildContext context) async {
    final isConnected = await ref.read(connectivityStatusProvider.future);
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot sync while offline'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final repository = ref.watch(notesRepositoryProvider);
      final syncedNotes = await repository.syncOfflineNotes();

      if (syncedNotes.isNotEmpty) {
        // Refresh the notes list
        await refreshNotes();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${syncedNotes.length} notes synced successfully'),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No notes to sync')));
      }
    } catch (e) {
      if (e is OfflineException) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot sync while offline'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync notes: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Provider for the current note
@riverpod
class NoteNotifier extends _$NoteNotifier {
  @override
  Future<NoteModel?> build({String? noteId}) async {
    if (noteId == null) {
      return null;
    }

    return _fetchNote(noteId);
  }

  Future<NoteModel> _fetchNote(String noteId) async {
    final repository = ref.watch(notesRepositoryProvider);
    return await repository.getNote(noteId);
  }

  Future<void> updateNote(
    String content,
    BuildContext context, {
    String? newTitle,
  }) async {
    if (noteId == null) {
      return;
    }

    try {
      state = const AsyncValue.loading();

      final repository = ref.watch(notesRepositoryProvider);
      final updatedNote = await repository.updateNote(
        noteId!,
        content,
        newTitle: newTitle,
      );

      state = AsyncValue.data(updatedNote);

      // Also refresh the notes list
      ref.invalidate(notesListNotifierProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note updated successfully')),
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update note: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
