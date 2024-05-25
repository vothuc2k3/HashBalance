import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:hash_balance/core/common/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/models/user_model.dart';

final userProvider = StateProvider<UserModel?>((ref) => null);

final authRepositoryProvider = Provider(
  (ref) {
    return AuthRepository(
      firestore: ref.read(firebaseFireStoreProvider),
      firebaseAuth: ref.read(firebaseAuthProvider),
      googleSignIn: ref.read(googleSignInProvider),
    );
  },
);

class AuthRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _firestore = firestore,
        _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn;

  Stream<User?> get authStageChange => _firebaseAuth.authStateChanges();

  //SIGN THE USER IN WITH GOOGLE
  FutureEither<UserModel> signInWithGoogle() async {
    try {
      //try signing the google account of user in
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      final googleAuth = await googleUser?.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      //logging the user in
      UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      UserModel? userModel;
      //if the user logs in for the first time, new data is set
      if (userCredential.additionalUserInfo!.isNewUser) {
        final createdAt = Timestamp.now();

        userModel = UserModel(
          email: userCredential.user!.email!,
          name: userCredential.user!.displayName ??
              'nameless_user_${generateRandomString()}',
          profileImage:
              userCredential.user!.photoURL ?? Constants.avatarDefault,
          bannerImage: Constants.bannerDefault,
          uid: userCredential.user!.uid,
          isAuthenticated: true,
          activityPoint: 0,
          achivements: ['New boy'],
          createdAt: createdAt,
          hashAge: 0,
          isRestricted: false,
        );
        await _user.doc(userCredential.user!.uid).set(
              userModel.toMap(),
            );
      } else {
        userModel = await getUserData(userCredential.user!.uid).first;
      }
      return right(userModel);
    } on FirebaseException catch (e) {
      throw e.message ?? 'Unknown error occurred?';
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //SIGN UP WITH EMAIL AND PASSWORD
  FutureEither<UserModel> signUpWithEmailAndPassword(
    UserModel newUser,
  ) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: newUser.email,
        password: newUser.password!,
      );

      String userUid = userCredential.user!.uid;
      newUser.uid = userUid;
      if (userCredential.additionalUserInfo!.isNewUser) {
        await _firestore.collection('users').doc(userUid).set(newUser.toMap());
      }
      final user = await getUserData(userUid).first;
      return right(user);
    } on FirebaseAuthException catch (e) {
      return left(Failures(e.message ?? 'Unknown error occurred?'));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //SIGN THE USER IN WITH EMAIL AND PASSWORD
  FutureEither<UserModel> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = await getUserData(userCredential.user!.uid).first;
      return right(user);
    } on FirebaseAuthException catch (e) {
      return left(Failures(e.message ?? 'Unknown error occurred?'));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //SIGN OUT
  void signOut() async {
    await _firebaseAuth.signOut();
  }

  //GET THE USER DATA
  Stream<UserModel> getUserData(String uid) {
    final snapshot = _user.doc(uid).snapshots();
    return snapshot.map((event) {
      Timestamp createdAt = event['createdAt'];
      int hashAge =
          DateTime.now().difference(createdAt.toDate()).inSeconds ~/ 86400;

      return UserModel(
        uid: event['uid'] as String,
        name: event['name'] as String,
        email: event['email'] as String,
        password: event['password'] as String,
        profileImage: event['profileImage'] as String,
        bannerImage: event['bannerImage'] as String,
        isAuthenticated: event['isAuthenticated'] as bool,
        activityPoint: event['activityPoint'] as int,
        achivements: (event['achivements'] as List)
            .map((item) => item.toString())
            .toList(),
        createdAt: event['createdAt'] as Timestamp,
        hashAge: hashAge,
        isRestricted: event['isRestricted'] as bool,
      );
    });
  }

  //CHANGE USER PRIVACY SETTING
  void changeUserPrivacy({
    required bool setting,
    required UserModel user,
  }) {
    final updatedUser = user.copyWith(isRestricted: setting);
    _user.doc(user.uid).update(updatedUser.toMap());
  }

  //REFERENCE ALL THE USERS
  CollectionReference get _user =>
      _firestore.collection(FirebaseConstants.usersCollection);
}
