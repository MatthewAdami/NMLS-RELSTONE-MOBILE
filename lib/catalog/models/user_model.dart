class UserModel {
  final String id;
  final String name;
  final String email;
  final String state;
  final String role;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.state,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final stateValue =
        json['state'] ?? json['state_code'] ?? json['stateCode'] ?? '';
    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      state: stateValue.toString(),
      role: json['role']?.toString() ?? '',
    );
  }
}
