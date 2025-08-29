import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:upsen_tablet/firebase_options.dart';

import 'application.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const Application());
}
