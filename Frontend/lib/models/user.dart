class User {
  final int id;
  final String email;
  final String name;
  final String? ageGroup;
  final String? gender;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.ageGroup,
    this.gender,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      ageGroup: json['age_group'],
      gender: json['gender'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'age_group': ageGroup,
      'gender': gender,
    };
  }
}
