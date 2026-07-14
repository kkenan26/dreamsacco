class UserModel{
  final String uid;
  final String name;
  final String phone;
  final String email;
  final int creditScore;
  final double loanLimit;
  final int contributionStreak;
  final double totalContributions;
  final double totalLoansRepaid;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    this.creditScore = 50,
    this.loanLimit = 0.0,
    this.contributionStreak = 0,
    this.totalContributions= 0.0,
    this.totalLoansRepaid= 0.0,
    required this.createdAt,
});

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'email': email,
      'creditScore': creditScore,
      'loanLimit': loanLimit,
      'contributionStreak': contributionStreak,
      'totalContributions': totalContributions,
      'totalLoansRepaid': totalLoansRepaid,
      'createdAt': createdAt.toIso8601String(),
  };
}

factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'] ?? '',
      creditScore: map['creditScore']?.toDouble() ?? 50.0,
      loanLimit: map['loanLimit']?. toDouble() ?? 0.0,
      contributionStreak: map['contributionStreak']?.toInt() ?? 0,
      totalContributions: map['totalContributions']?.toDouble() ?? 0.0,
      totalLoansRepaid: map['totalLoansRepaid']?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['createdAt']),
    );
}
}