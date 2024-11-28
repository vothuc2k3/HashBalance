import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;

final userProvider = StateProvider<UserModel?>((ref) => null);

final authRepositoryProvider = Provider(
  (ref) {
    return AuthRepository(
      firestore: ref.watch(firebaseFirestoreProvider),
      firebaseAuth: ref.watch(firebaseAuthProvider),
      googleSignIn: ref.watch(googleSignInProvider),
    );
  },
);

class AuthRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final _uuid = const Uuid();

  //REFERENCE ALL THE USERS
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);

  AuthRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _firestore = firestore,
        _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn;

  Stream<User?> get authStageChange {
    return _firebaseAuth.authStateChanges();
  }

  //SIGN THE USER IN WITH GOOGLE
  Future<Either<Failures, UserModel>> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return left(Failures('Sign-in process was canceled by the user.'));
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      UserModel? user;
      if (userCredential.additionalUserInfo!.isNewUser) {
        user = UserModel(
          email: userCredential.user!.email!,
          name:
              userCredential.user!.displayName ?? 'nameless_user_${_uuid.v1()}',
          profileImage: userCredential.user!.photoURL ??
              Constants.avatarDefault[
                  Random().nextInt(Constants.avatarDefault.length)],
          bannerImage: Constants.bannerDefault,
          uid: userCredential.user!.uid,
          isAuthenticated: true,
          activityPoint: 0,
          createdAt: Timestamp.now(),
          hashAge: 0,
          isRestricted: false,
        );
        await _users.doc(userCredential.user!.uid).set(user.toMap());
      } else {
        user = await getUserData(userCredential.user!.uid).first;
      }
      return right(user);
    } on FirebaseAuthException catch (e) {
      Logger().d(e.code);
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage =
              'An account already exists with the same email address but different sign-in credentials. Sign in using a provider associated with this email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        default:
          errorMessage = 'An unknown error occurred. Please try again later.';
      }
      return left(Failures(errorMessage));
    } catch (e) {
      Logger().d(e.toString());
      return left(Failures('An unexpected error occurred. Please try again.'));
    }
  }

  //SIGN UP WITH EMAIL AND PASSWORD
  Future<Either<Failures, UserModel>> signUpWithEmailAndPassword(
      UserModel newUser, String password) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: newUser.email,
        password: password,
      );

      UserModel? user;
      String userUid = userCredential.user!.uid;
      UserModel copyUser = newUser.copyWith(uid: userUid);

      await _users.doc(userUid).set(copyUser.toMap());
      user = copyUser;

      return right(user);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage =
              'The email address is already in use by another account.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'weak-password':
          errorMessage =
              'The password is too weak. Please choose a stronger password.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled.';
          break;
        default:
          errorMessage = 'An unknown error occurred. Please try again later.';
      }
      return left(Failures(errorMessage));
    } catch (e) {
      return left(Failures('An unexpected error occurred. Please try again.'));
    }
  }

  //SIGN THE USER IN WITH EMAIL AND PASSWORD
  Future<Either<Failures, UserModel>> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = await getUserData(userCredential.user!.uid).first;
      return right(user);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      Logger().e(e.code);
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage =
              'Too many unsuccessful login attempts. Please try again later.';
          break;
        case 'invalid-credential':
          errorMessage =
              'Wrong Email or Password. Please check and try again....';
          break;
        default:
          errorMessage = 'An error occurred. Please try again.';
      }
      return left(Failures(errorMessage));
    } catch (e) {
      return left(Failures('An unexpected error occurred. Please try again.'));
    }
  }

  //GET THE USER DATA
  Stream<UserModel> getUserData(String uid) {
    final snapshot = _users.doc(uid).snapshots();
    return snapshot.map(
      (event) {
        return UserModel.fromMap(event.data() as Map<String, dynamic>);
      },
    );
  }

  //FETCH USER DATA
  Future<UserModel> fetchUserData(String uid) async {
    final doc = await _users.doc(uid).get();
    return UserModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  //SEND RESET PASSWORD LINK
  Future<Either<Failures, void>> sendResetPasswordLink(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<Either<Failures, bool>> isAdmin(String uid) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.domain}/isAdmin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final isAdmin = responseData['isAdmin'] as bool;
        Logger().d('isAdmin: $isAdmin');
        return right(isAdmin);
      } else {
        final responseData = jsonDecode(response.body);
        return left(
          Failures(responseData['error'] ?? 'Failed to verify admin role'),
        );
      }
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }
}
