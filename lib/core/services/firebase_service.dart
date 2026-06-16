/// FirebaseService - Offline Stub
/// 
/// This is a local-only stub implementation that mirrors the Firebase API surface.
/// To enable real Firebase:
///   1. Uncomment Firebase dependencies in pubspec.yaml
///   2. Add google-services.json to android/app/
///   3. Add GoogleService-Info.plist to ios/Runner/
///   4. Replace this file with the full firebase_service.dart implementation
///
library;

import '../../models/project.dart';
import 'database_service.dart';

/// Minimal User stub so UI can still show user-related info without Firebase
class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  const AppUser({required this.uid, this.email, this.displayName});
}

class FirebaseService {
  static final FirebaseService instance = FirebaseService._init();
  FirebaseService._init();

  // Always returns null in offline mode (no user logged in via Firebase)
  AppUser? get currentUser => null;

  Stream<AppUser?> get authStateChanges => const Stream.empty();

  Future<void> registerWithEmail(String email, String password) async {
    // No-op in offline mode
    throw UnimplementedError(
      'Firebase not configured. Add google-services.json to enable auth.',
    );
  }

  Future<void> loginWithEmail(String email, String password) async {
    throw UnimplementedError(
      'Firebase not configured. Add google-services.json to enable auth.',
    );
  }

  Future<void> signInWithGoogle() async {
    throw UnimplementedError('Firebase not configured.');
  }

  Future<void> sendPasswordReset(String email) async {
    throw UnimplementedError('Firebase not configured.');
  }

  Future<void> logout() async {
    // No-op - nothing to log out from
  }

  /// Syncs local projects to Firebase cloud storage.
  /// No-op in offline mode.
  Future<void> syncLocalProjectsToCloud() async {
    // Will upload to Firestore once Firebase is configured
    print('[FirebaseService] Offline mode: sync skipped.');
  }

  /// Downloads projects from Firebase.
  /// No-op in offline mode.
  Future<void> downloadProjectsFromCloud() async {
    print('[FirebaseService] Offline mode: cloud download skipped.');
    // Returns local projects instead
    final localProjects = await DatabaseService.instance.getAllProjects();
    print('[FirebaseService] ${localProjects.length} local projects available.');
  }
}
