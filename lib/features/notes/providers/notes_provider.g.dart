// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$driveDataSourceHash() => r'96c9219eb829c5307701e2379271f99cc76c1dfe';

/// See also [driveDataSource].
@ProviderFor(driveDataSource)
final driveDataSourceProvider = AutoDisposeProvider<DriveDataSource>.internal(
  driveDataSource,
  name: r'driveDataSourceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$driveDataSourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DriveDataSourceRef = AutoDisposeProviderRef<DriveDataSource>;
String _$notesRepositoryHash() => r'48c9ac178bb4f59e2d72191372f991158f6ab875';

/// See also [notesRepository].
@ProviderFor(notesRepository)
final notesRepositoryProvider = AutoDisposeProvider<NotesRepository>.internal(
  notesRepository,
  name: r'notesRepositoryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notesRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotesRepositoryRef = AutoDisposeProviderRef<NotesRepository>;
String _$notesListNotifierHash() => r'71e49cf248ac938e7a0f3b22dbed1460fe1d44f7';

/// See also [NotesListNotifier].
@ProviderFor(NotesListNotifier)
final notesListNotifierProvider = AutoDisposeAsyncNotifierProvider<
  NotesListNotifier,
  List<NoteModel>
>.internal(
  NotesListNotifier.new,
  name: r'notesListNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notesListNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NotesListNotifier = AutoDisposeAsyncNotifier<List<NoteModel>>;
String _$noteNotifierHash() => r'a02dc18c4ef76bd7c83ca4e333eb968e223d7b83';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$NoteNotifier
    extends BuildlessAutoDisposeAsyncNotifier<NoteModel?> {
  late final String? noteId;

  FutureOr<NoteModel?> build({String? noteId});
}

/// See also [NoteNotifier].
@ProviderFor(NoteNotifier)
const noteNotifierProvider = NoteNotifierFamily();

/// See also [NoteNotifier].
class NoteNotifierFamily extends Family<AsyncValue<NoteModel?>> {
  /// See also [NoteNotifier].
  const NoteNotifierFamily();

  /// See also [NoteNotifier].
  NoteNotifierProvider call({String? noteId}) {
    return NoteNotifierProvider(noteId: noteId);
  }

  @override
  NoteNotifierProvider getProviderOverride(
    covariant NoteNotifierProvider provider,
  ) {
    return call(noteId: provider.noteId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'noteNotifierProvider';
}

/// See also [NoteNotifier].
class NoteNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<NoteNotifier, NoteModel?> {
  /// See also [NoteNotifier].
  NoteNotifierProvider({String? noteId})
    : this._internal(
        () => NoteNotifier()..noteId = noteId,
        from: noteNotifierProvider,
        name: r'noteNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$noteNotifierHash,
        dependencies: NoteNotifierFamily._dependencies,
        allTransitiveDependencies:
            NoteNotifierFamily._allTransitiveDependencies,
        noteId: noteId,
      );

  NoteNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.noteId,
  }) : super.internal();

  final String? noteId;

  @override
  FutureOr<NoteModel?> runNotifierBuild(covariant NoteNotifier notifier) {
    return notifier.build(noteId: noteId);
  }

  @override
  Override overrideWith(NoteNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: NoteNotifierProvider._internal(
        () => create()..noteId = noteId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        noteId: noteId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<NoteNotifier, NoteModel?>
  createElement() {
    return _NoteNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NoteNotifierProvider && other.noteId == noteId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, noteId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin NoteNotifierRef on AutoDisposeAsyncNotifierProviderRef<NoteModel?> {
  /// The parameter `noteId` of this provider.
  String? get noteId;
}

class _NoteNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<NoteNotifier, NoteModel?>
    with NoteNotifierRef {
  _NoteNotifierProviderElement(super.provider);

  @override
  String? get noteId => (origin as NoteNotifierProvider).noteId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
