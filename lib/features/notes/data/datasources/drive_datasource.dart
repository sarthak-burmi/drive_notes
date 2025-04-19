import 'dart:convert';
import 'package:drive_notes/core/utils/connectivity_utils.dart';
import 'package:dio/dio.dart';
import 'package:drive_notes/core/constants/drive_constants.dart';
import 'package:drive_notes/core/error/app_exceptions.dart';
import 'package:drive_notes/features/auth/providers/auth_provider.dart';
import 'package:drive_notes/features/notes/data/models/note_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriveDataSource {
  final Dio _dio;
  final Ref _ref;

  DriveDataSource({required Dio dio, required Ref ref})
    : _dio = dio,
      _ref = ref;

  // Get drive folder, create if it doesn't exist
  Future<String> getDriveNotesFolder() async {
    try {
      final token = await _getAccessToken();

      // Add debug logging to see what's happening
      print(
        'Getting DriveNotes folder with token: ${token.substring(0, 10)}...',
      );

      // Check if folder exists - use proper query format
      final response = await _dio.get(
        DriveConstants.filesEndpoint,
        queryParameters: {
          'q':
              "mimeType='${DriveConstants.folderMimeType}' and name='${DriveConstants.folderName}' and trashed=false",
          'fields': 'files(id,name)',
          'spaces': 'drive',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      final Map<String, dynamic> data = response.data;
      final List<dynamic> files = data['files'] ?? [];

      // If folder exists, return its ID
      if (files.isNotEmpty) {
        print('Found existing folder: ${files[0]['id']}');
        return files[0]['id'];
      }

      // Create folder if it doesn't exist
      print('No folder found, creating new folder');
      return await _createDriveNotesFolder(token);
    } catch (e) {
      print('Error in getDriveNotesFolder: $e');
      // Check if this is a token issue
      if (e is DioException &&
          (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        throw AuthException('Authentication error: ${e.toString()}');
      }
      throw DriveException(
        'Failed to get or create DriveNotes folder: ${e.toString()}',
      );
    }
  }

  // Create DriveNotes folder
  Future<String> _createDriveNotesFolder(String token) async {
    try {
      // Proper formatting of the request body
      final response = await _dio.post(
        DriveConstants.filesEndpoint,
        data: jsonEncode({
          'name': DriveConstants.folderName,
          'mimeType': DriveConstants.folderMimeType,
        }),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final Map<String, dynamic> data = response.data;
      print('Created new folder with ID: ${data['id']}');
      return data['id'];
    } catch (e) {
      print('Error in _createDriveNotesFolder: $e');
      throw DriveException(
        'Failed to create DriveNotes folder: ${e.toString()}',
      );
    }
  }

  // Get all notes from drive
  Future<List<NoteModel>> getNotes() async {
    try {
      final token = await _getAccessToken();
      final folderId = await getDriveNotesFolder();

      final query =
          "mimeType='${DriveConstants.textFileMimeType}' and '${folderId}' in parents and trashed=false";

      final response = await _dio.get(
        DriveConstants.filesEndpoint,
        queryParameters: {
          'q': query,
          'fields': 'files(id,name,createdTime,modifiedTime)',
          'spaces': 'drive',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      final Map<String, dynamic> data = response.data;
      final List<dynamic> files = data['files'] ?? [];

      List<NoteModel> notes =
          files
              .map<NoteModel>((file) => NoteModel.fromDriveFile(file))
              .toList();

      // Get offline notes and merge
      final offlineNotes = await getOfflineNotes();
      notes.addAll(offlineNotes);

      return notes;
    } catch (e) {
      // If there's a network error, try to get offline notes
      if (e is OfflineException) {
        return await getOfflineNotes();
      }
      throw DriveException('Failed to get notes: ${e.toString()}');
    }
  }

  // Get a specific note content
  Future<String?> getNoteContent(String noteId) async {
    // Check if it's an offline note
    if (noteId.startsWith('offline_')) {
      final offlineNotes = await getOfflineNotes();
      final note = offlineNotes.firstWhere(
        (note) => note.id == noteId,
        orElse: () => throw NotFoundException('Note not found'),
      );
      return note.content;
    }

    // Get online note
    try {
      final token = await _getAccessToken();

      final response = await _dio.get(
        '${DriveConstants.filesEndpoint}/$noteId',
        queryParameters: {'alt': 'media'},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.plain,
        ),
      );

      return response.data as String;
    } catch (e) {
      throw DriveException('Failed to get note content: ${e.toString()}');
    }
  }

  // Create a new note
  Future<NoteModel> createNote(String title, String content) async {
    try {
      // If offline, save to local storage and return
      final isConnected = await _isConnected();
      if (!isConnected) {
        final offlineNote = NoteModel.offline(name: title, content: content);
        await _saveOfflineNote(offlineNote);
        return offlineNote;
      }

      final token = await _getAccessToken();
      final folderId = await getDriveNotesFolder();

      // First create the metadata - use proper JSON format
      final metadataResponse = await _dio.post(
        DriveConstants.filesEndpoint,
        data: jsonEncode({
          'name': '$title${DriveConstants.fileExtension}',
          'mimeType': DriveConstants.textFileMimeType,
          'parents': [folderId],
        }),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final String fileId = metadataResponse.data['id'];

      // Then upload the content
      await _dio.patch(
        '${DriveConstants.uploadEndpoint}/$fileId',
        data: content,
        queryParameters: {'uploadType': 'media'},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': DriveConstants.textFileMimeType,
          },
        ),
      );

      // Return the created note
      return NoteModel(
        id: fileId,
        name: title,
        content: content,
        createdTime: DateTime.now(),
        modifiedTime: DateTime.now(),
      );
    } catch (e) {
      // If there's a network error, save as offline note
      if (e is OfflineException) {
        final offlineNote = NoteModel.offline(name: title, content: content);
        await _saveOfflineNote(offlineNote);
        return offlineNote;
      }
      throw DriveException('Failed to create note: ${e.toString()}');
    }
  }

  // Update an existing note
  Future<NoteModel> updateNote(
    String noteId,
    String content, {
    String? newTitle,
  }) async {
    // Handle offline note
    if (noteId.startsWith('offline_')) {
      final offlineNotes = await getOfflineNotes();
      final noteIndex = offlineNotes.indexWhere((note) => note.id == noteId);
      if (noteIndex == -1) {
        throw NotFoundException('Note not found');
      }
      final updatedNote = offlineNotes[noteIndex].copyWith(
        name: newTitle ?? offlineNotes[noteIndex].name,
        content: content,
        modifiedTime: DateTime.now(),
      );
      offlineNotes[noteIndex] = updatedNote;
      await _saveOfflineNotes(offlineNotes);
      // Try to sync if we have connection
      final isConnected = await _isConnected();
      if (isConnected) {
        try {
          final syncedNote = await createNote(updatedNote.name, content);
          // Remove from offline notes
          offlineNotes.removeAt(noteIndex);
          await _saveOfflineNotes(offlineNotes);
          return syncedNote;
        } catch (e) {
          // Just return the offline note if sync fails
          return updatedNote;
        }
      }
      return updatedNote;
    }

    // Handle online note
    try {
      final token = await _getAccessToken();

      // Get the current note data before updating (to preserve the name if not provided)
      String currentName = '';
      if (newTitle == null) {
        try {
          final fileMetadata = await _dio.get(
            '${DriveConstants.filesEndpoint}/$noteId',
            queryParameters: {'fields': 'name'},
            options: Options(
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            ),
          );
          currentName = _getNoteName(fileMetadata.data['name'] ?? '');
        } catch (e) {
          // If we can't get the current name, we'll use the provided newTitle or empty string
          print('Could not fetch current note name: $e');
        }
      }

      // Update title if provided
      if (newTitle != null) {
        await _dio.patch(
          '${DriveConstants.filesEndpoint}/$noteId',
          data: jsonEncode({
            'name': '$newTitle${DriveConstants.fileExtension}',
          }),
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ),
        );
      }

      // Update content
      await _dio.patch(
        '${DriveConstants.uploadEndpoint}/$noteId',
        data: content,
        queryParameters: {'uploadType': 'media'},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': DriveConstants.textFileMimeType,
          },
        ),
      );

      // Get the updated file metadata to get the correct modifiedTime
      final updatedFileResponse = await _dio.get(
        '${DriveConstants.filesEndpoint}/$noteId',
        queryParameters: {'fields': 'id,name,modifiedTime'},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      final Map<String, dynamic> updatedFileData = updatedFileResponse.data;

      // Return the updated note with correct metadata
      return NoteModel(
        id: noteId,
        name:
            newTitle ??
            currentName, // Use provided name or keep the existing one
        content: content,
        modifiedTime:
            updatedFileData['modifiedTime'] != null
                ? DateTime.parse(updatedFileData['modifiedTime'])
                : DateTime.now(),
      );
    } catch (e) {
      throw DriveException('Failed to update note: ${e.toString()}');
    }
  }

  // Helper function to strip file extension from note name
  String _getNoteName(String fileName) {
    if (fileName.endsWith('.txt')) {
      return fileName.substring(0, fileName.length - 4);
    }
    return fileName;
  }

  // Delete a note
  Future<void> deleteNote(String noteId) async {
    // Handle offline note
    if (noteId.startsWith('offline_')) {
      final offlineNotes = await getOfflineNotes();
      offlineNotes.removeWhere((note) => note.id == noteId);
      await _saveOfflineNotes(offlineNotes);
      return;
    }

    // Handle online note
    try {
      final token = await _getAccessToken();

      await _dio.delete(
        '${DriveConstants.filesEndpoint}/$noteId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw DriveException('Failed to delete note: ${e.toString()}');
    }
  }

  // Sync offline notes
  Future<List<NoteModel>> syncOfflineNotes() async {
    final offlineNotes = await getOfflineNotes();

    if (offlineNotes.isEmpty) {
      return [];
    }

    final isConnected = await _isConnected();
    if (!isConnected) {
      throw OfflineException();
    }

    final syncedNotes = <NoteModel>[];
    final remainingOfflineNotes = <NoteModel>[];

    for (final note in offlineNotes) {
      try {
        final syncedNote = await createNote(note.name, note.content ?? '');
        syncedNotes.add(syncedNote);
      } catch (e) {
        remainingOfflineNotes.add(note);
      }
    }

    // Update offline notes
    if (remainingOfflineNotes.length != offlineNotes.length) {
      await _saveOfflineNotes(remainingOfflineNotes);
    }

    return syncedNotes;
  }

  // Get offline notes
  Future<List<NoteModel>> getOfflineNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineNotesJson = prefs.getString('offline_notes');

      if (offlineNotesJson == null) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(offlineNotesJson);
      return decoded.map((e) => NoteModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // Save an offline note
  Future<void> _saveOfflineNote(NoteModel note) async {
    final offlineNotes = await getOfflineNotes();
    offlineNotes.add(note);
    await _saveOfflineNotes(offlineNotes);
  }

  // Save offline notes list
  Future<void> _saveOfflineNotes(List<NoteModel> notes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedNotes = jsonEncode(notes.map((e) => e.toJson()).toList());
      await prefs.setString('offline_notes', encodedNotes);
    } catch (e) {
      throw DriveException('Failed to save offline notes: ${e.toString()}');
    }
  }

  // Helper to get access token
  Future<String> _getAccessToken() async {
    try {
      return await _ref.read(authProvider.notifier).getAccessToken();
    } catch (e) {
      throw AuthException('Not authenticated');
    }
  }

  // Check if device is connected
  Future<bool> _isConnected() async {
    try {
      final connectivityResult = await _ref.read(
        connectivityStatusProvider.future,
      );
      return connectivityResult;
    } catch (e) {
      return false;
    }
  }
}
