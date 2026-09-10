import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/user_model.dart';
 
class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
 
  // Coleção principal
  CollectionReference get _usersRef => _firestore.collection('users');
 
  Future<void> createUser({
    required UserModel user,
    required String password,
  }) async {
    // Cria a conta no Firebase Auth
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: user.email,
      password: password,
    );
 
    String? uid = credential.user?.uid;
 
    if (uid != null) {
      // Cria o documento no Firestore com o mesmo ID (UID) do Auth
      await _usersRef.doc(uid).set(user.toMap());
    }
  }
 
  Future<UserModel?> getCurrentUserProfile() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return null;
 
    DocumentSnapshot doc = await _usersRef.doc(uid).get();
 
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }
 
  Stream<UserModel?> streamUserProfile() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
 
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }
 
  Future<void> updateUserProfile({
    required String name,
    required String phone,
  }) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("Usuário não autenticado");

    await _usersRef.doc(uid).update({
      'name': name,
      'phone': phone,
      'updatedAt': DateTime.now(),
    });
  }

  Future<bool> updateAccount({
    required String name,
    required String phone,
    required String email,
    String? newPassword,
    String? currentPassword,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não autenticado");

    final newEmail = email.trim();
    final emailChanged = newEmail != (user.email ?? '');
    final passwordChanged = newPassword != null && newPassword.isNotEmpty;

    // Reautentica antes de mexer em e-mail/senha.
    if (emailChanged || passwordChanged) {
      if (currentPassword == null || currentPassword.isEmpty) {
        throw Exception('Informe a senha atual para alterar e-mail ou senha');
      }
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
    }

    if (passwordChanged) {
      await user.updatePassword(newPassword);
    }

    // Dados que refletem imediatamente no Firestore (e-mail só após confirmar).
    await _usersRef.doc(user.uid).update({
      'name': name,
      'phone': phone,
      'updatedAt': DateTime.now(),
    });

    if (emailChanged) {
      await user.verifyBeforeUpdateEmail(newEmail);
      return true;
    }

    return false;
  }
 
  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;
 
    // Remove o documento do Firestore
    await _usersRef.doc(currentUser.uid).delete();
 
    // Remove a conta de acesso do Firebase Auth
    await currentUser.delete();
  }
}