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
import 'package:hash_balance/models/user_model.dart';

final userProvider = StateProvider<UserModel?>((ref) => null);

final authRepositoryProvider = Provider((ref) {
  return AuthRepository(
    firestore: ref.read(firebaseFireStoreProvider),
    firebaseAuth: ref.read(firebaseAuthProvider),
    googleSignIn: ref.read(googleSignInProvider),
  );
});

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

  CollectionReference get _user =>
      _firestore.collection(FirebaseConstants.usersCollection);

  //get the user data from firebase
  Stream<UserModel> getUserData(String uid) {
    return _user.doc(uid).snapshots().map(
          (event) => UserModel.fromMap(event.data() as Map<String, dynamic>),
        );
  }

  //
  Stream<User?> get authStageChange => _firebaseAuth.authStateChanges();

  FutureEither<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      final googleAuth = await googleUser?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      //logging the user in
      UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      late UserModel userModel;
      //if the user logs in for the first time, new data is set
      if (userCredential.additionalUserInfo!.isNewUser) {
        userModel = UserModel(
          name:
              userCredential.user!.displayName ?? 'No name to be displayed...',
          profileImage:
              userCredential.user!.photoURL ?? Constants.avatarDefault,
          bannerImage: Constants.bannerDefault,
          uid: userCredential.user!.uid,
          isAuthenticated: true,
          activityPoint: 0,
          achivements: [],
        );
        await _user.doc(userCredential.user!.uid).set(
              userModel.toMap(),
            );
      } else {
        userModel = await getUserData(userCredential.user!.uid).first;
      }
      return right(userModel);
    } on FirebaseException catch (e) {
      throw e.message!;
    } catch (e) {
      return left(
        Failures(
          e.toString(),
        ),
      );
    }
  }

  Either<Failures, dynamic> logUserOut() {
    try {
      _googleSignIn.disconnect();
      _firebaseAuth.signOut();
      return right(null);
    } on FirebaseException catch (e) {
      throw e.message!;
    } catch (e) {
      return left(
        Failures(
          e.toString(),
        ),
      );
    }
  }
}
