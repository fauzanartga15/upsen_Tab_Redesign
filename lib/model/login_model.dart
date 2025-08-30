import 'user_model.dart';

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
