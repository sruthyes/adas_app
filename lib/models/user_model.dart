class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLogin;
  final String? phone;
  final String? licenseNumber;
  final String? vehicleModel;
  final String? vehicleNumber;
  final String? vehicleType;
  final String? emergencyContact;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.createdAt,
    required this.lastLogin,
    this.phone,
    this.licenseNumber,
    this.vehicleModel,
    this.vehicleNumber,
    this.vehicleType,
    this.emergencyContact,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      lastLogin: map['lastLogin']?.toDate() ?? DateTime.now(),
      phone: map['phone'],
      licenseNumber: map['licenseNumber'],
      vehicleModel: map['vehicleModel'],
      vehicleNumber: map['vehicleNumber'],
      vehicleType: map['vehicleType'],
      emergencyContact: map['emergencyContact'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
      'phone': phone,
      'licenseNumber': licenseNumber,
      'vehicleModel': vehicleModel,
      'vehicleNumber': vehicleNumber,
      'vehicleType': vehicleType,
      'emergencyContact': emergencyContact,
    };
  }
}