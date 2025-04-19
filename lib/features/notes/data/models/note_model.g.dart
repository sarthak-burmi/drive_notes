// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NoteModel _$NoteModelFromJson(Map<String, dynamic> json) => NoteModel(
  id: json['id'] as String,
  name: json['name'] as String,
  content: json['content'] as String?,
  createdTime:
      json['createdTime'] == null
          ? null
          : DateTime.parse(json['createdTime'] as String),
  modifiedTime:
      json['modifiedTime'] == null
          ? null
          : DateTime.parse(json['modifiedTime'] as String),
  synced: json['synced'] as bool? ?? true,
);

Map<String, dynamic> _$NoteModelToJson(NoteModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'content': instance.content,
  'createdTime': instance.createdTime?.toIso8601String(),
  'modifiedTime': instance.modifiedTime?.toIso8601String(),
  'synced': instance.synced,
};
