import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _customAuth = auth,
        _customFirestore = firestore;

  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customFirestore;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  User? _user;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<User?>? _authSubscription;

  User? get user => _user;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get displayName {
    if (_userProfile != null && _userProfile!['name'] != null) {
      final name = _userProfile!['name'].toString().trim();
      if (name.isNotEmpty) return name;
    }
    if (_user?.displayName != null && _user!.displayName!.trim().isNotEmpty) {
      return _user!.displayName!.trim();
    }
    if (_user?.email != null) {
      return _user!.email!.split('@').first;
    }
    return 'Motorista MecLoc';
  }

  String get email => _user?.email ?? '';
  String? get photoUrl => _user?.photoURL;
  String get role => (_userProfile?['role'] as String?) ?? 'driver';
  bool get isWorkshopOwner => role == 'workshop_owner';

  void initialize() {
    try {
      _authSubscription = _auth.authStateChanges().listen((User? user) async {
        _user = user;
        if (user != null) {
          await _fetchUserProfile(user.uid);
        } else {
          _userProfile = null;
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Auth initialize fallback: $e');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userProfile = doc.data();
      }
    } catch (e) {
      debugPrint('Erro ao buscar perfil do usuário: $e');
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _user = credential.user;
      if (_user != null) {
        await _fetchUserProfile(_user!.uid);
      }
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e.code);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Ocorreu um erro ao realizar login. Tente novamente.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String role = 'driver',
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _user = credential.user;

      if (_user != null) {
        await _user!.updateDisplayName(name.trim());
        final profileData = <String, dynamic>{
          'name': name.trim(),
          'email': email.trim(),
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        await _firestore.collection('users').doc(_user!.uid).set(profileData);
        _userProfile = profileData;
      }

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e.code);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Ocorreu um erro ao criar a conta. Tente novamente.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithGoogle({String role = 'driver'}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      UserCredential credential;
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        credential = await _auth.signInWithPopup(googleProvider);
      } else {
        final googleProvider = GoogleAuthProvider();
        credential = await _auth.signInWithProvider(googleProvider);
      }

      _user = credential.user;
      if (_user != null) {
        final userDocRef = _firestore.collection('users').doc(_user!.uid);
        final doc = await userDocRef.get();
        if (!doc.exists) {
          final profileData = <String, dynamic>{
            'name': _user!.displayName ?? 'Usuário MecLoc',
            'email': _user!.email ?? '',
            'role': role,
            'photoUrl': _user!.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };
          await userDocRef.set(profileData);
          _userProfile = profileData;
        } else {
          _userProfile = doc.data();
        }
      }

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e.code);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Falha ao autenticar com o Google. Tente novamente.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e.code);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Não foi possível enviar o e-mail de recuperação.';
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _userProfile = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao deslogar: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Nenhum usuário cadastrado com este e-mail.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'email-already-in-use':
        return 'Este e-mail já está em uso por outra conta.';
      case 'invalid-email':
        return 'Formato de e-mail inválido.';
      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres.';
      case 'user-disabled':
        return 'Esta conta foi desativada temporariamente.';
      case 'too-many-requests':
        return 'Muitas tentativas sem sucesso. Aguarde alguns instantes.';
      case 'popup-closed-by-user':
        return 'A janela do Google foi fechada antes de concluir.';
      case 'cancelled':
        return 'Operação cancelada.';
      default:
        return 'Erro na autenticação ($code). Tente novamente.';
    }
  }
}
