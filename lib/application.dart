import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:upsen_tablet/helpers/face_detection_helper.dart';
import 'package:upsen_tablet/model/user_model.dart';
import 'package:upsen_tablet/page/login_page.dart';
import 'package:upsen_tablet/page/home_page.dart';

import 'provider/camera_provider/camera_provider.dart';
import 'provider/auth_provider/auth_provider.dart';

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
          // TAMBAHKAN AuthProvider di sini
          ChangeNotifierProvider(create: (context) => AuthProvider()),
        ],
        child: MaterialApp(
          title: 'Upsen Attendance',
          theme: ThemeData(
            primarySwatch: Colors.teal,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            useMaterial3: true,
          ),
          debugShowCheckedModeBanner: false,
          home: const AuthWrapper(), // Ganti dengan AuthWrapper
          routes: {
            '/login': (context) => const LoginPageTablet(),
            '/home': (context) => const HomePage(),
          },
        ),
      ),
    );
  }
}

// Tambahkan AuthWrapper untuk handle auto-navigation
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        // Show loading while checking auth status
        if (auth.state == AuthState.loading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }

        // Navigate based on auth state
        if (auth.isAuthenticated) {
          return const HomePage();
        } else {
          return const LoginPageTablet();
        }
      },
    );
  }
}
