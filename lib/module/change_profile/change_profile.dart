import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_app/module/profile/profile_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class ChangeProfilePage extends StatefulWidget {
  @override
  _ChangeProfilePageState createState() => _ChangeProfilePageState();
}

class _ChangeProfilePageState extends State<ChangeProfilePage> {
  final TextEditingController _fullNameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data();
      if (userData != null) {
        _fullNameController.text = userData['fullName'] ?? '';
        _profileImageUrl = userData['photoProfile'] ?? '';
        setState(() {}); // Refresh the UI to show the loaded data
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ProfileBloc(FirebaseAuth.instance, FirebaseFirestore.instance),
      child: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileChangedSuccess) {
            print("ProfileChangedSuccess state detected"); // Debug line
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Profile updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context); // Navigate back to the previous page
          } else if (state is ProfileError) {
            print(
                "ProfileError state detected: ${state.message}"); // Debug line
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Ubah Profile'),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: () async {
                    _imageFile =
                        await _picker.pickImage(source: ImageSource.gallery);
                    setState(
                        () {}); // Refresh the UI to show the selected image
                  },
                  child: CircleAvatar(
                    radius: 80,
                    backgroundImage: _imageFile != null
                        ? FileImage(File(_imageFile!.path))
                        : _profileImageUrl != null &&
                                _profileImageUrl!.isNotEmpty
                            ? NetworkImage(_profileImageUrl!)
                            : null,
                    child: _imageFile == null &&
                            (_profileImageUrl == null ||
                                _profileImageUrl!.isEmpty)
                        ? const Icon(
                            Icons.camera_alt,
                            size: 40,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Panjang',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: SizedBox(
                    width: 150, // Reduced width for the button
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        final fullName = _fullNameController.text.trim();
                        if (fullName.isNotEmpty) {
                          context.read<ProfileBloc>().add(ChangeProfileEvent(
                                fullName: fullName,
                                profileImage: _imageFile,
                              ));
                        }
                      },
                      child: const Text(
                        'Simpan',
                        style: TextStyle(color: Colors.white),
                      ),
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
