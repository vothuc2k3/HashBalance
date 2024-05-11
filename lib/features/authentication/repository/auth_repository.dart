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

      late UserModel userModel;
      //if the user logs in for the first time, new data is set
      if (userCredential.additionalUserInfo!.isNewUser) {
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

  //Sign the user in with Email
  FutureEither<UserModel> signInWithEmailAndPassword(UserModel user) async {
    try {
      late String userUid;
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
              email: user.email, password: user.password!);
      if (userCredential.additionalUserInfo!.isNewUser) {
        await _firebaseAuth.signInWithEmailAndPassword(
            email: user.email, password: user.password!);
        userUid = userCredential.user!.uid;
        final uid = userCredential.user!.uid;
        user.uid = uid;
        userUid = uid;
        final hashedPassword = user.password;
        user.password = hashedPassword;
        await _user.doc(userUid).set(user.toMap());
      } else {
        userUid = userCredential.user!.uid;
        user = await getUserData(userUid).first;
      }
      return right(user);
    } on FirebaseAuthException catch (e) {
      return left(
        Failures(e.message!),
      );
    } catch (e) {
      return left(
        Failures(
          e.toString(),
        ),
      );
    }
  }

  //get the user data from firebase
  Stream<UserModel> getUserData(String uid) {
    final snapshot = _user.doc(uid).snapshots();
    return snapshot.map(
      (event) => UserModel(
        uid: event['uid'],
        name: event['name'],
        email: event['email'],
        password: event['password'],
        profileImage: event['profileImage'],
        bannerImage: event['bannerImage'],
        isAuthenticated: event['isAuthenticated'],
        activityPoint: event['activityPoint'],
        achivements: (event['achivements'] as List)
            .map((item) => item.toString())
            .toList(),
      ),
    );
  }

  CollectionReference get _user =>
      _firestore.collection(FirebaseConstants.usersCollection);
}
