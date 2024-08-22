import 'dart:io';

import 'package:couple_app/module/auth/auth_bloc.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  File? _profileImage;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        final userId =
            authState.userId; // Access userId from AuthAuthenticated state
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_profile_images')
            .child('$userId.jpg');
        await storageRef.putFile(image);
        return await storageRef.getDownloadURL();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User is not authenticated')),
        );
        return null;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
      return null;
    }
  }

  void _onSignupButtonPressed() async {
    // Trigger sign-up process
    context.read<AuthBloc>().add(
          AuthSignupRequested(
            _emailController.text,
            _passwordController.text,
            _fullNameController.text,
            '', // initially pass an empty string for the photoUrl
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign Up"),
        centerTitle: true,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error)),
            );
          } else if (state is AuthAuthenticated) {
            if (_profileImage != null) {
              setState(() {
                _isUploading = true;
              });
              // Upload image after successful sign-up
              final photoUrl = await _uploadImage(_profileImage!);
              setState(() {
                _isUploading = false;
              });

              // Update user profile with the photoUrl
              if (photoUrl != null) {
                context.read<AuthBloc>().add(
                      AuthUpdateProfile(photoUrl),
                    );
              }
            }

            Navigator.of(context).pushReplacementNamed('/loginPage');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.black,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : const AssetImage('assets/default_avatar.png')
                            as ImageProvider,
                    child: _profileImage == null
                        ? const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 30,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: "Nama Panjang",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is AuthLoading || _isUploading) {
                      return const CircularProgressIndicator();
                    }
                    return ElevatedButton(
                      onPressed: _onSignupButtonPressed,
                      child: const Text("Sign Up"),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Already have an account? Login"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
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
