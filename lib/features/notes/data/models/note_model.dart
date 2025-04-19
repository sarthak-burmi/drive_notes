import 'package:json_annotation/json_annotation.dart';

part 'note_model.g.dart';

@JsonSerializable()
class NoteModel {
  final String id;
  final String name;
  final String? content;
  final DateTime? createdTime;
  final DateTime? modifiedTime;
  final bool synced;

  NoteModel({
    required this.id,
    required this.name,
    this.content,
    this.createdTime,
    this.modifiedTime,
    this.synced = true,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) =>
      _$NoteModelFromJson(json);

  Map<String, dynamic> toJson() => _$NoteModelToJson(this);

  // Create a new note from GoogleAPI response
  factory NoteModel.fromDriveFile(Map<String, dynamic> file) {
    return NoteModel(
      id: file['id'],
      name: _getNoteName(file['name']),
      createdTime:
          file['createdTime'] != null
              ? DateTime.parse(file['createdTime'])
              : null,
      modifiedTime:
          file['modifiedTime'] != null
              ? DateTime.parse(file['modifiedTime'])
              : null,
      synced: true,
    );
  }

  // Create a new offline note
  factory NoteModel.offline({required String name, required String content}) {
    final now = DateTime.now();
    return NoteModel(
      id: 'offline_${now.millisecondsSinceEpoch}',
      name: name,
      content: content,
      createdTime: now,
      modifiedTime: now,
      synced: false,
    );
  }

  NoteModel copyWith({
    String? id,
    String? name,
    String? content,
    DateTime? createdTime,
    DateTime? modifiedTime,
    bool? synced,
  }) {
    return NoteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      createdTime: createdTime ?? this.createdTime,
      modifiedTime: modifiedTime ?? this.modifiedTime,
      synced: synced ?? this.synced,
    );
  }

  // Helper function to strip file extension from note name
  static String _getNoteName(String fileName) {
    if (fileName.endsWith('.txt')) {
      return fileName.substring(0, fileName.length - 4);
    }
    return fileName;
  }
}
