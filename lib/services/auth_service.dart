import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Aktueller User
  User? get currentUser => _auth.currentUser;

  // Auth State Stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ═══════════════════════════════════════════════════════════════
  // LOGIN
  // ═══════════════════════════════════════════════════════════════

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Ein Fehler ist aufgetreten';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // REGISTRIERUNG MIT EINLADUNGSCODE
  // ═══════════════════════════════════════════════════════════════

  Future<User?> registerWithInviteCode({
    required String email,
    required String password,
    required String inviteCode,
  }) async {
    try {
      // 1. Einladungscode prüfen
      final inviteDoc = await _db

          .collection('invites')
          .doc(inviteCode.toUpperCase())
          .get();

      if (!inviteDoc.exists) {
        throw 'Ungültiger Einladungscode';
      }

      final inviteData = inviteDoc.data()!;

      // Bereits verwendet?
      if (inviteData['used'] == true) {
        throw 'Dieser Einladungscode wurde bereits verwendet';
      }

      // Abgelaufen?
      if (inviteData['expiresAt'] != null) {
        final expiresAt = (inviteData['expiresAt'] as Timestamp).toDate();
        if (DateTime.now().isAfter(expiresAt)) {
          throw 'Dieser Einladungscode ist abgelaufen';
        }
      }

      // Email stimmt überein?
      final storedEmail = inviteData['email'] as String?;
      if (storedEmail != null &&
          storedEmail.toLowerCase() != email.toLowerCase().trim()) {
        throw 'Diese Email-Adresse passt nicht zum Einladungscode';
      }

      // 2. User erstellen
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user == null) {
        throw 'Benutzer konnte nicht erstellt werden';
      }

      // 3. User-Dokument in Firestore erstellen
      final userGroup = inviteData['userGroup'] ?? 1;
      final userName = inviteData['name'] ?? email.split('@').first;

      await _db.collection('users').doc(result.user!.uid).set({
        'email': email.toLowerCase().trim(),
        'name': userName,
        'userGroup': userGroup,
        'createdAt': FieldValue.serverTimestamp(),
        'photoUrl': '',
      });

      // 4. Einladungscode als verwendet markieren
      await inviteDoc.reference.update({
        'used': true,
        'usedAt': FieldValue.serverTimestamp(),
        'usedBy': result.user!.uid,
      });

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PASSWORT ZURÜCKSETZEN
  // ═══════════════════════════════════════════════════════════════

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // LOGOUT
  // ═══════════════════════════════════════════════════════════════

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ═══════════════════════════════════════════════════════════════
  // USER DATEN
  // ═══════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  Stream<DocumentSnapshot> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER
  // ═══════════════════════════════════════════════════════════════

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Kein Benutzer mit dieser Email gefunden';
      case 'wrong-password':
        return 'Falsches Passwort';
      case 'email-already-in-use':
        return 'Diese Email-Adresse ist bereits registriert';
      case 'weak-password':
        return 'Das Passwort ist zu schwach (mind. 6 Zeichen)';
      case 'invalid-email':
        return 'Ungültige Email-Adresse';
      case 'user-disabled':
        return 'Dieser Account wurde deaktiviert';
      case 'too-many-requests':
        return 'Zu viele Versuche. Bitte später erneut versuchen';
      default:
        return 'Authentifizierungsfehler: ${e.message}';
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// USER GROUP HELPER
// ═══════════════════════════════════════════════════════════════

String getUserGroupName(int userGroup) {
  switch (userGroup) {
    case 1:
      return 'Säger';
    case 2:
      return 'Büro';
    case 3:
      return 'Admin';
    default:
      return 'Unbekannt';
  }
}