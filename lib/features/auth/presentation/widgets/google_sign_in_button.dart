import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drive_notes/features/auth/providers/auth_provider.dart';

class GoogleSignInButton extends ConsumerWidget {
  final VoidCallback? onSuccess;

  const GoogleSignInButton({Key? key, this.onSuccess}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, stackTrace) {
        // Automatically show error in UI
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign in error: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        });

        // Return a button that allows retry
        return ElevatedButton.icon(
          icon: Icon(Icons.refresh, color: Colors.white),
          label: const Text('Retry Sign in'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () async {
            try {
              await ref.read(authProvider.notifier).signInWithGoogle();
              if (onSuccess != null) {
                onSuccess!();
              }
            } catch (e) {
              // Error will be handled by the authState.when error case
            }
          },
        );
      },
      data: (user) {
        // If user is already signed in, show that they're signed in
        if (user != null) {
          // User is already signed in
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (onSuccess != null) {
              onSuccess!();
            }
          });
          return const CircularProgressIndicator();
        }

        // Normal sign in button
        return ElevatedButton.icon(
          icon: Icon(Icons.login, color: Colors.white),
          label: const Text('Sign in with Google'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () async {
            try {
              await ref.read(authProvider.notifier).signInWithGoogle();
              if (onSuccess != null) {
                onSuccess!();
              }
            } catch (e) {
              // The error should be caught by the provider and shown in the UI
              // through the error case above
            }
          },
        );
      },
    );
  }
}
