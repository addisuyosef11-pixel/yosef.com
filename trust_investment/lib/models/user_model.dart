class UserModel {
  final int id;
  final String username;
  final String email;
  final String phone;
  final String vipLevel;
  final String inviteCode;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.vipLevel,
    required this.inviteCode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user']['id'],
      username: json['user']['username'],
      email: json['user']['email'] ?? '',
      phone: json['phone'] ?? '',
      vipLevel: json['vip_level'] ?? '',
      inviteCode: json['invite_code'] ?? '',
    );
  }
}
