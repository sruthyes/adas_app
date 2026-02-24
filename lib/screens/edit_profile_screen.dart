import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {

  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final licenseController = TextEditingController();
  final vehicleModelController = TextEditingController();
  final vehicleNumberController = TextEditingController();
  final vehicleTypeController = TextEditingController();
  final emergencyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final data =
        await _authService.getUserData(user.uid);

    if (data != null) {
      nameController.text = data.name;
      phoneController.text = data.phone ?? '';
      licenseController.text =
          data.licenseNumber ?? '';
      vehicleModelController.text =
          data.vehicleModel ?? '';
      vehicleNumberController.text =
          data.vehicleNumber ?? '';
      vehicleTypeController.text =
          data.vehicleType ?? '';
      emergencyController.text =
          data.emergencyContact ?? '';
      setState(() {});
    }
  }

  Future<void> _saveProfile() async {
    final user = _authService.currentUser;
    if (user == null) return;

    await _authService.updateUserProfile(
      user.uid,
      {
        "name": nameController.text.trim(),
        "phone": phoneController.text.trim(),
        "licenseNumber": licenseController.text.trim(),
        "vehicleModel": vehicleModelController.text.trim(),
        "vehicleNumber": vehicleNumberController.text.trim(),
        "vehicleType": vehicleTypeController.text.trim(),
        "emergencyContact": emergencyController.text.trim(),
      },
    );

    Navigator.pop(context);
  }

  Widget _field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _field("Full Name", nameController),
              _field("Phone", phoneController),
              _field("License Number", licenseController),
              _field("Vehicle Model", vehicleModelController),
              _field("Vehicle Number", vehicleNumberController),
              _field("Vehicle Type", vehicleTypeController),
              _field("Emergency Contact", emergencyController),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text("Save"),
              )
            ],
          ),
        ),
      ),
    );
  }
}