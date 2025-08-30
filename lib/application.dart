import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:upsen_tablet/helper/face_detection_helper.dart';
import 'package:upsen_tablet/page/login_page.dart';

import 'provider/camera_provider.dart';

class Application extends StatelessWidget {
  const Application({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MultiProvider(
        providers: [
          Provider(create: (context) => FaceDetectionHelper()),
          ChangeNotifierProvider(
            create: (context) => CameraProvider(context.read()),
          ),
        ],
        child: MaterialApp(
          title: 'Upsen Attendance',
          theme: ThemeData(
            primarySwatch: Colors.teal,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            useMaterial3: true,
          ),
          debugShowCheckedModeBanner: false,
          home: const LoginPage(),
        ),
      ),
    );
  }
}
