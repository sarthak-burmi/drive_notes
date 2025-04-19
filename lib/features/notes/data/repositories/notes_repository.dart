import 'package:drive_notes/core/error/app_exceptions.dart';
import 'package:drive_notes/core/utils/logger.dart';
import 'package:drive_notes/features/notes/data/datasources/drive_datasource.dart';
import 'package:drive_notes/features/notes/data/models/note_model.dart';

class NotesRepository {
  final DriveDataSource _driveDataSource;

  NotesRepository({required DriveDataSource driveDataSource})
    : _driveDataSource = driveDataSource;

  Future<List<NoteModel>> getNotes() async {
    try {
      return await _driveDataSource.getNotes();
    } catch (e) {
      logger.error('Failed to get notes', e);
      throw DriveException('Failed to load notes: ${e.toString()}');
    }
  }

  Future<NoteModel> getNote(String noteId) async {
    try {
      // For offline notes, we already have all the data
      if (noteId.startsWith('offline_')) {
        final offlineNotes = await _driveDataSource.getOfflineNotes();
        final note = offlineNotes.firstWhere(
          (note) => note.id == noteId,
          orElse: () => throw NotFoundException('Note not found'),
        );
        return note;
      }

      // For online notes, first get all notes to find the title
      final allNotes = await _driveDataSource.getNotes();
      final noteWithMetadata = allNotes.firstWhere(
        (note) => note.id == noteId,
        orElse: () => NoteModel(id: noteId, name: 'Unknown Note'),
      );

      // Then get the content
      final content = await _driveDataSource.getNoteContent(noteId);

      // Return a note with both metadata and content
      return noteWithMetadata.copyWith(content: content);
    } catch (e) {
      logger.error('Failed to get note', e);
      throw DriveException('Failed to load note: ${e.toString()}');
    }
  }

  Future<NoteModel> createNote(String title, String content) async {
    try {
      return await _driveDataSource.createNote(title, content);
    } catch (e) {
      logger.error('Failed to create note', e);
      throw DriveException('Failed to create note: ${e.toString()}');
    }
  }

  Future<NoteModel> updateNote(
    String noteId,
    String content, {
    String? newTitle,
  }) async {
    try {
      return await _driveDataSource.updateNote(
        noteId,
        content,
        newTitle: newTitle,
      );
    } catch (e) {
      logger.error('Failed to update note', e);
      throw DriveException('Failed to update note: ${e.toString()}');
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      await _driveDataSource.deleteNote(noteId);
    } catch (e) {
      logger.error('Failed to delete note', e);
      throw DriveException('Failed to delete note: ${e.toString()}');
    }
  }

  Future<List<NoteModel>> syncOfflineNotes() async {
    try {
      return await _driveDataSource.syncOfflineNotes();
    } catch (e) {
      logger.error('Failed to sync offline notes', e);
      if (e is OfflineException) {
        // Just rethrow offline exceptions
        throw e;
      }
      throw DriveException('Failed to sync offline notes: ${e.toString()}');
    }
  }
}
