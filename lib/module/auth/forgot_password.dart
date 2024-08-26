import 'package:couple_app/helper/dimensions.dart';
import 'package:couple_app/overlay/overlays.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Add a FormKey
  bool _isSubmitting = false;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      // Validate the form
      return;
    }

    final email = _emailController.text.trim();

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      Overlays.success(
        message: "Link Reset Password Berhasil Dikirimkan",
      );
      Navigator.pop(context); // Navigate back to the previous page
    } catch (e) {
      Overlays.error(
        message: "Failed to send reset email: $e",
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lupa Password'),
        centerTitle: true,
      ),
      body: Container(
        child: Form(
          // Wrap with Form widget
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.only(left: 18, right: 18, bottom: 18, top: 75),
            child: Column(
              children: [
                Center(
                  child: Lottie.asset(
                    "assets/lottie/forgot.json",
                    frameRate: FrameRate(60),
                    width: Dimensions.size100 * 2,
                    repeat: true,
                  ),
                ),
                SizedBox(
                  height: Dimensions.size20,
                ),
                const Text(
                  'Masukan email kamu, untuk mendapatkan link reset password',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    // Basic email format validation
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _isSubmitting
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _resetPassword,
                        child: const Text('Kirim'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
