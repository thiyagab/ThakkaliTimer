import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:provider/provider.dart';
import 'package:thakkalitimer/HomeScreen.dart';
import 'package:thakkalitimer/model/TimerProvider.dart';
import 'firebase_options.dart';


/*
TODO if we do this for mobile browsers, to keep the timer from running, when screen is off, is an issue
Should move to android app, and keep the screen on natively, or use onpause, onresume methods to keep the timer running
 */

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(const MyApp());
}

 initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseUIAuth.configureProviders([
    GoogleProvider(clientId: DefaultFirebaseOptions.GOOGLE_CLIENT_ID),
  ]);
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {


    return MaterialApp(

      onGenerateRoute:(settings) {
        print('Url from settings:'+ settings.name!+' '+settings.arguments.toString());
        if(settings.name!.contains('timer=')){
          String? timerId=settings.name!.split('=')[1];
          return buildHomeScreen(timerId);
        }else if(settings.name == '/'){
          String? timerId=Uri.base.queryParameters['timer'];
          return buildHomeScreen(timerId);
        }
      },
      initialRoute: '/',
      // routes: {
      //   '/': (context) {
      //     return ChangeNotifierProvider(create: (context) => timerProvider,child:
      //     FutureBuilder(
      //       future: timerProvider.checkAndFetchTimers(),
      //       builder: (context, snapshot) {
      //         if (snapshot.connectionState == ConnectionState.done) {
      //           return const HomeScreen();
      //         } else {
      //           return const Center(child: CircularProgressIndicator());
      //         }
      //       },
      //     ));
      //   }
      // },
    );
  }

  MaterialPageRoute buildHomeScreen(String? timerId){
    final timerProvider = TimerProvider();
    return MaterialPageRoute(builder: (context) {return ChangeNotifierProvider(create: (context) => timerProvider,child:
    FutureBuilder(
      future: timerProvider.checkAndFetchTimers(timerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return const HomeScreen();
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    ));});
  }
}
