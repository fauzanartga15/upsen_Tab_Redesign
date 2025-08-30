class UserModel {
  final int? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? imageUrl;

  UserModel({this.id, this.name, this.email, this.phone, this.imageUrl});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    name: json['name'],
    email: json['email'],
    phone: json['phone'],
    imageUrl: json['image_url'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'image_url': imageUrl,
  };
}

enum AuthState { loading, authenticated, unauthenticated, error }
