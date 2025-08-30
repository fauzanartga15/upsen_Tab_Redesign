import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/user_model.dart';

// Copy model dari mobile Anda
class LoginModel {
  final UserModel? user;
  final String? token;

  LoginModel({this.user, this.token});

  factory LoginModel.fromMap(Map<String, dynamic> json) => LoginModel(
    user: json["user"] == null ? null : UserModel.fromJson(json["user"]),
    token: json["token"],
  );

  Map<String, dynamic> toMap() => {"user": user?.toJson(), "token": token};

  LoginModel copyWith({UserModel? user, String? token}) {
    return LoginModel(user: user ?? this.user, token: token ?? this.token);
  }
}

// Simplified UserModel untuk tablet (ambil field penting saja)

class AuthProvider with ChangeNotifier {
  AuthState _state = AuthState.unauthenticated;
  LoginModel? _loginModel;
  String? _errorMessage;

  // Dio instance untuk API
  final Dio _dio = Dio();

  // Getters
  AuthState get state => _state;
  LoginModel? get loginModel => _loginModel;
  UserModel? get user => _loginModel?.user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == AuthState.loading;
  bool get isAuthenticated => _state == AuthState.authenticated;

  AuthProvider() {
    _initializeDio();
    checkAuthStatus();
  }

  void _initializeDio() {
    _dio.options
      ..baseUrl = 'https://dev.upsen.id/api'
      ..connectTimeout = const Duration(seconds: 15)
      ..receiveTimeout = const Duration(seconds: 15)
      ..headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
  }

  // Set states
  void _setLoading() {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String error) {
    _state = AuthState.error;
    _errorMessage = error;
    notifyListeners();
  }

  void _setAuthenticated(LoginModel loginModel) {
    _state = AuthState.authenticated;
    _loginModel = loginModel;
    _errorMessage = null;
    notifyListeners();
  }

  void _setUnauthenticated() {
    _state = AuthState.unauthenticated;
    _loginModel = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Login method
  Future<bool> login(String email, String password) async {
    try {
      _setLoading();

      final response = await _dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );

      final loginModel = LoginModel.fromMap(response.data);

      // Save token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', loginModel.token ?? '');

      // Update dio headers with token
      _dio.options.headers['Authorization'] = 'Bearer ${loginModel.token}';

      _setAuthenticated(loginModel);
      return true;
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data['message'] ??
          'Login gagal. Periksa email dan password Anda.';
      _setError(errorMessage);
      return false;
    } catch (e) {
      _setError('Terjadi kesalahan. Silakan coba lagi.');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      _setLoading();

      // Call logout API
      await _dio.post('/logout');

      // Clear local data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');

      // Clear dio headers
      _dio.options.headers.remove('Authorization');

      _setUnauthenticated();
    } catch (e) {
      // Even if API fails, clear local data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      _dio.options.headers.remove('Authorization');
      _setUnauthenticated();
    }
  }

  // Check if already logged in
  Future<void> checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null && token.isNotEmpty) {
        // Update dio headers
        _dio.options.headers['Authorization'] = 'Bearer $token';

        // Verify token with API
        final response = await _dio.get('/user');
        final user = UserModel.fromJson(response.data['data']);

        final loginModel = LoginModel(user: user, token: token);
        _setAuthenticated(loginModel);
      } else {
        _setUnauthenticated();
      }
    } catch (e) {
      // Token invalid, clear it
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      _setUnauthenticated();
    }
  }

  // Clear error
  void clearError() {
    if (_state == AuthState.error) {
      _state = AuthState.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    }
  }
}
