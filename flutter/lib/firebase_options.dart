// IMPORTANT: Ce fichier est un placeholder.
// Remplacez-le par le vrai fichier généré via :
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Ne commitez jamais vos vraies clés Firebase dans le dépôt.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions n\'est pas configuré pour cette plateforme. '
          'Lancez "flutterfire configure" pour générer ce fichier.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBaw-3DAatPFwNoLNXlreyKlDJ4OKX9m10',
    appId: '1:360416043038:web:8cd253b947ae2cced10e0f',
    messagingSenderId: '360416043038',
    projectId: 'innovation-dda6d',
    authDomain: 'innovation-dda6d.firebaseapp.com',
    storageBucket: 'innovation-dda6d.firebasestorage.app',
    measurementId: 'G-1Z1RM6B8Q2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAIx_hAm4j6HtYWxA3CamWb6h86g3OtEkg',
    appId: '1:360416043038:android:2cd1ce218097d344d10e0f',
    messagingSenderId: '360416043038',
    projectId: 'innovation-dda6d',
    storageBucket: 'innovation-dda6d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD5eNuVlug5VDdhp_s_FHqDrCwS7Sen08g',
    appId: '1:360416043038:ios:11a04ceabef2a2d6d10e0f',
    messagingSenderId: '360416043038',
    projectId: 'innovation-dda6d',
    storageBucket: 'innovation-dda6d.firebasestorage.app',
    iosBundleId: 'com.remedia.remedia',
  );

}