import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drive_notes/features/auth/presentation/pages/login_page.dart';
import 'package:drive_notes/features/auth/presentation/pages/splash_page.dart';
import 'package:drive_notes/features/auth/providers/auth_provider.dart';
import 'package:drive_notes/features/notes/data/models/note_model.dart';
import 'package:drive_notes/features/notes/presentation/pages/notes_list_page.dart';
import 'package:drive_notes/features/notes/presentation/pages/note_edit_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Check if the user is logged in
      final isLoggedIn = authState.value != null;
      final isGoingToLogin = state.uri.path == '/login';

      // If not logged in and not going to login page, redirect to login
      if (!isLoggedIn && !isGoingToLogin && state.uri.path != '/') {
        return '/login';
      }

      // If logged in and going to login page, redirect to notes
      if (isLoggedIn && isGoingToLogin) {
        return '/notes';
      }

      // No redirection needed
      return null;
    },
    routes: [
      // Splash screen route
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      // Login route
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      // Notes list route
      GoRoute(
        path: '/notes',
        builder: (context, state) => const NotesListPage(),
        routes: [
          // New note route
          GoRoute(
            path: 'new',
            builder: (context, state) => const NoteEditPage(),
          ),
          // Note detail route
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final noteId = state.pathParameters['id']!;
              final note = state.extra as NoteModel?;
              return NoteEditPage(noteId: noteId, note: note);
            },
          ),
        ],
      ),
    ],
    // Global error handling
    errorBuilder:
        (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Page Not Found',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'The page you are looking for does not exist.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => GoRouter.of(context).go('/'),
                  child: const Text('Go Home'),
                ),
              ],
            ),
          ),
        ),
  );
});
