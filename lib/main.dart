import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/firebase_options.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:hash_balance/router.dart';
import 'package:hash_balance/theme/pallette.dart';
import 'package:routemaster/routemaster.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return MyAppState();
  }
}

class MyAppState extends ConsumerState<MyApp> {
  bool _hasInitialized = false;
  UserModel? userData;

  void getUserData(WidgetRef ref, User? user) async {
    if (user != null) {
      userData = await ref
          .read(authControllerProvider.notifier)
          .getUserData(user.uid)
          .first;
    } else {
      userData = null;
    }
    ref.read(userProvider.notifier).update((_) {
      return userData;
    });
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      final data = ref.read(authStageChangeProvider);
      data.whenOrNull(
        data: (user) {
          getUserData(ref, user);
        },
      );
      _hasInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(authStageChangeProvider).when(
          data: (user) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'Hash Balance',
              theme: Pallete.darkModeAppTheme,
              routerDelegate: RoutemasterDelegate(routesBuilder: (context) {
                if (user != null) {
                  getUserData(ref, user);
                  if (userData != null) {
                    return loggedInRoute;
                  }
                }
                return loggedOutRoute;
              }),
              routeInformationParser: const RoutemasterParser(),
            );
          },
          error: (error, stackTrace) => ErrorText(
            error: error.toString(),
          ),
          loading: () => const LoadingCircular(),
        );
  }
}
