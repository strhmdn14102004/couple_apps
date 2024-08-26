import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_app/api/custom_http_overrides.dart';
import 'package:couple_app/firebase_options.dart';
import 'package:couple_app/helper/app_colors.dart';
import 'package:couple_app/helper/dimensions.dart';
import 'package:couple_app/helper/navigators.dart';
import 'package:couple_app/helper/preferences.dart';
import 'package:couple_app/module/auth/auth_bloc.dart';
import 'package:couple_app/module/auth/auth_page.dart';
import 'package:couple_app/module/home/home_bloc.dart';
import 'package:couple_app/module/home/home_page.dart';
import 'package:couple_app/module/profile/profile_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  HttpOverrides.global = CustomHttpOverrides();
  initializeDateFormatting();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await Preferences.getInstance().init();
  runApp(App());
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  String? userId;

  @override
  void initState() {
    super.initState();
    _checkUserSession();
  }

  Future<void> _checkUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('user_id');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (BuildContext context) => HomeBloc()),
        BlocProvider(
            create: (context) =>
                AuthBloc(FirebaseAuth.instance, FirebaseFirestore.instance)),
        BlocProvider(
            create: (context) =>
                ProfileBloc(FirebaseAuth.instance, FirebaseFirestore.instance)),
      ],
      child: GlobalLoaderOverlay(
        useDefaultLoading: false,
        overlayWidget: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                "assets/lottie/loading_clock.json",
                frameRate: FrameRate(60),
                width: Dimensions.size100 * 2,
                repeat: true,
              ),
              Text(
                "Memuat...",
                style: TextStyle(
                  fontSize: Dimensions.text20,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        overlayColor: Colors.black,
        overlayOpacity: 0.8,
        child: DismissKeyboard(
          child: GetMaterialApp(
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            title: "Mentahan Project",
            navigatorKey: Navigators.navigatorState,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: "Barlow",
              colorScheme: AppColors.lightColorScheme,
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              fontFamily: "Barlow",
              colorScheme: AppColors.darkColorScheme,
            ),
            themeMode: ThemeMode.system,
            builder: (BuildContext context, Widget? child) {
              return MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.0)),
                child: child ?? Container(),
              );
            },
            home: userId != null ? HomePage() : LoginPage(),
          ),
        ),
      ),
    );
  }
}

class DismissKeyboard extends StatelessWidget {
  final Widget child;

  const DismissKeyboard({
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);

        if (!currentFocus.hasPrimaryFocus &&
            currentFocus.focusedChild != null) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: child,
    );
  }
}
