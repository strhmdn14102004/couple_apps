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
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  HttpOverrides.global = CustomHttpOverrides();
  initializeDateFormatting();
  await _requestPermissions();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await Preferences.getInstance().init();
  runApp(App());
}

Future<void> _requestPermissions() async {
  await _requestLocationPermission(); // Request location permission first
}

Future<void> _requestLocationPermission() async {
  PermissionStatus status = await Permission.locationWhenInUse.request();

  if (status.isGranted) {
    status = await Permission.locationAlways.request();

    if (status.isGranted) {
      await Future.delayed(const Duration(seconds: 2));
      await _requestNotificationPermission(); // Request notification permission after location permission is granted
    }
  } else if (status.isDenied || status.isRestricted) {
    // Handle permission denial appropriately
  }
}

Future<void> _requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permission for notifications
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted notification permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('User granted provisional notification permission');
  } else {
    print('User declined or has not accepted notification permission');
  }

  // Handle incoming messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Handle the message
  });

  // Get the token and send it to the server
  String? token = await messaging.getToken();
  print("FCM Token: $token");

  // Listen for token refresh
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    print("New FCM Token: $newToken");
    // Send new token to server if needed
  });
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
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission for notifications
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Get the token each time the application loads
    String? token = await messaging.getToken();
    print("FCM Token: $token");

    // Handle incoming messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New message: ${message.notification?.title}'),
          ),
        );
      }
    });

    // Handle incoming messages when the app is opened from a terminated state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'App opened from notification: ${message.notification?.title}'),
          ),
        );
      }
    });
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
