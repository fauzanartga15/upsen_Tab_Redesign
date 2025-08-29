import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:upsen_tablet/helper/face_detection_helper.dart';
import 'package:upsen_tablet/page/success_confirmation_view.dart';

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
        child: const MaterialApp(
          home: SuccessConfirmationPage(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
