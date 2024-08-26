import 'package:couple_app/overlay/overlays.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChangePasswordPage extends StatefulWidget {
  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();

  bool _currentPasswordObscure = true;
  bool _newPasswordObscure = true;
  bool _confirmNewPasswordObscure = true;

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubah Password'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPasswordField(
                  controller: _currentPasswordController,
                  label: 'Password Saat Ini',
                  obscureText: _currentPasswordObscure,
                  onToggleObscure: () {
                    setState(() {
                      _currentPasswordObscure = !_currentPasswordObscure;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password saat ini wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildPasswordField(
                  controller: _newPasswordController,
                  label: 'Password Baru',
                  obscureText: _newPasswordObscure,
                  onToggleObscure: () {
                    setState(() {
                      _newPasswordObscure = !_newPasswordObscure;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password baru wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildPasswordField(
                  controller: _confirmNewPasswordController,
                  label: 'Konfirmasi Password Baru',
                  obscureText: _confirmNewPasswordObscure,
                  onToggleObscure: () {
                    setState(() {
                      _confirmNewPasswordObscure = !_confirmNewPasswordObscure;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Konfirmasi password baru wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      String currentPassword = _currentPasswordController.text;
                      String newPassword = _newPasswordController.text;
                      String confirmNewPassword = _confirmNewPasswordController.text;
        
                      if (newPassword != confirmNewPassword) {
                        Overlays.error(
                          message: "Password Baru Tidak Cocok",
                        );
                        return;
                      }
        
                      try {
                        User? user = FirebaseAuth.instance.currentUser;
        
                        if (user != null) {
                          // Verify the current password
                          AuthCredential credential = EmailAuthProvider.credential(
                            email: user.email!,
                            password: currentPassword,
                          );
        
                          await user.reauthenticateWithCredential(credential);
                          await user.updatePassword(newPassword);
        
                          Overlays.success(
                            message: "Password Berhasil Diperbarui",
                          );
                        }
                      } catch (e) {
                        Overlays.error(
                          message: "$e",
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Ubah Password',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: onToggleObscure,
        ),
      ),
      validator: validator,
    );
  }
}
