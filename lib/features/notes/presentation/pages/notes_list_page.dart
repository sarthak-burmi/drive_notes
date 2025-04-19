import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drive_notes/core/constants/app_constants.dart';
import 'package:drive_notes/core/theme/theme_provider.dart';
import 'package:drive_notes/core/utils/connectivity_utils.dart';
import 'package:drive_notes/features/auth/providers/auth_provider.dart';
import 'package:drive_notes/features/notes/data/models/note_model.dart';
import 'package:drive_notes/features/notes/presentation/widgets/note_card.dart';
import 'package:drive_notes/features/notes/providers/notes_provider.dart';
import 'package:go_router/go_router.dart';

class NotesListPage extends ConsumerStatefulWidget {
  const NotesListPage({Key? key}) : super(key: key);

  @override
  ConsumerState<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends ConsumerState<NotesListPage>
    with TickerProviderStateMixin {
  late AnimationController _fabAnimController;
  final ScrollController _scrollController = ScrollController();
  bool _showFab = true;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimController.forward();

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (_showFab) {
          setState(() {
            _showFab = false;
            _fabAnimController.reverse();
          });
        }
      }
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (!_showFab) {
          setState(() {
            _showFab = true;
            _fabAnimController.forward();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesListNotifierProvider);
    final userAsync = ref.watch(authProvider);
    final isConnected = ref.watch(connectivityStatusProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConstants.appName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        actions: [
          // Sync button with animation
          if (isConnected.valueOrNull == true)
            Tooltip(
              message: 'Sync offline notes',
              child: IconButton(
                icon: const Icon(Icons.sync),
                onPressed: () {
                  // Add animation when syncing
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Syncing notes...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  ref
                      .read(notesListNotifierProvider.notifier)
                      .syncOfflineNotes(context);
                },
              ),
            ),

          // Theme toggle with animation
          Tooltip(
            message: 'Change theme',
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  key: ValueKey<ThemeMode?>(
                    ref.watch(appThemeModeProvider).valueOrNull,
                  ),
                  ref
                      .watch(appThemeModeProvider)
                      .when(
                        data: (themeMode) {
                          switch (themeMode) {
                            case ThemeMode.light:
                              return Icons.light_mode;
                            case ThemeMode.dark:
                              return Icons.dark_mode;
                            case ThemeMode.system:
                              return Icons.brightness_auto;
                          }
                        },
                        loading: () => Icons.brightness_auto,
                        error: (_, __) => Icons.brightness_auto,
                      ),
                ),
              ),
              onPressed: () {
                ref.read(appThemeModeProvider.notifier).toggleThemeMode();
              },
            ),
          ),

          // Profile menu with animated avatar
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: PopupMenuButton(
              icon: Hero(
                tag: 'profile_avatar',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.primary, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: colorScheme.primaryContainer,
                    backgroundImage:
                        userAsync.valueOrNull?.photoUrl != null
                            ? NetworkImage(userAsync.valueOrNull!.photoUrl!)
                            : null,
                    child:
                        userAsync.valueOrNull?.photoUrl == null
                            ? Text(
                              userAsync.valueOrNull?.displayName?.substring(
                                    0,
                                    1,
                                  ) ??
                                  'U',
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                            : null,
                  ),
                ),
              ),
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text('Profile'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: colorScheme.error),
                          const SizedBox(width: 8),
                          const Text('Sign Out'),
                        ],
                      ),
                    ),
                  ],
              onSelected: (value) {
                if (value == 'logout') {
                  _handleSignOut();
                }
              },
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        color: colorScheme.primary,
        onRefresh:
            () => ref.read(notesListNotifierProvider.notifier).refreshNotes(),
        child: notesAsync.when(
          data: (notes) {
            if (notes.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              controller: _scrollController,
              itemCount: notes.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final note = notes[index];
                // Add staggered animation to list items
                return AnimatedOpacity(
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  opacity: 1.0,
                  curve: Curves.easeInOut,
                  child: AnimatedPadding(
                    duration: Duration(milliseconds: 300 + (index * 50)),
                    padding: const EdgeInsets.only(bottom: 0),
                    child: NoteCard(
                      note: note,
                      onTap: () => _openNoteDetail(note),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load notes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      onPressed: () {
                        ref
                            .read(notesListNotifierProvider.notifier)
                            .refreshNotes();
                      },
                    ),
                  ],
                ),
              ),
        ),
      ),

      // Offline indicator with animation
      bottomNavigationBar: isConnected.when(
        data:
            (connected) =>
                connected
                    ? null
                    : AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 40,
                      color: Colors.orange.shade800,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_off, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'You are offline. Changes will be synced later.',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
        loading: () => null,
        error: (_, __) => null,
      ),

      // Create new note button with animation
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(
          parent: _fabAnimController,
          curve: Curves.easeOut,
        ),
        child: FloatingActionButton.extended(
          onPressed: _createNewNote,
          icon: const Icon(Icons.add),
          label: const Text('New Note'),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty state animation
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.8, end: 1.0),
              duration: const Duration(seconds: 1),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(
                    Icons.note_add,
                    size: 100,
                    color: colorScheme.primary.withOpacity(0.5),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'No notes yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Create your first note to get started with Drive Notes',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _createNewNote,
              icon: const Icon(Icons.add),
              label: const Text('Create Note'),
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
  }

  void _openNoteDetail(NoteModel note) {
    context.push('/notes/${note.id}', extra: note);
  }

  void _createNewNote() {
    context.push('/notes/new');
  }

  void _handleSignOut() async {
    // Show a confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed out successfully')),
        );
        context.go('/login');
      }
    }
  }
}
