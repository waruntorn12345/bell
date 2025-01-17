// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAMqR5BLEpWclkT31M8q2y9ThMJzvn04qg',
    appId: '1:694069926080:web:ede7aae53635852326b525',
    messagingSenderId: '694069926080',
    projectId: 'fir-1-e5261',
    authDomain: 'fir-1-e5261.firebaseapp.com',
    databaseURL: 'https://fir-1-e5261-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'fir-1-e5261.appspot.com',
    measurementId: 'G-4T49C2GSEH',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyABCOhAfcOJuJfFJ8I-_xPPI3VJO8Mom68',
    appId: '1:694069926080:android:54231460c76e7c3126b525',
    messagingSenderId: '694069926080',
    projectId: 'fir-1-e5261',
    databaseURL: 'https://fir-1-e5261-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'fir-1-e5261.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDPa0GZN3EkZWaigMDp6ANwYXaO0HqqdjY',
    appId: '1:694069926080:ios:2c420bd2541922fd26b525',
    messagingSenderId: '694069926080',
    projectId: 'fir-1-e5261',
    databaseURL: 'https://fir-1-e5261-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'fir-1-e5261.appspot.com',
    androidClientId: '694069926080-09baq2vp7uno2jd5pur32f3siusv85gh.apps.googleusercontent.com',
    iosClientId: '694069926080-jq33m9qfrogltfm2ebvj6e927u1p34t8.apps.googleusercontent.com',
    iosBundleId: 'com.mrblab.travelhourapp',
  );
}
