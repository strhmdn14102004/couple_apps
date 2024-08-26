import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_app/helper/dimensions.dart';
import 'package:couple_app/module/auth/change_password_page.dart';
import 'package:couple_app/module/room/room_code_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/auth_bloc.dart';
import '../auth/auth_page.dart';
import '../change_profile/change_profile.dart';
import 'profile_bloc.dart';

class ProfilePage extends StatelessWidget {
  final TextEditingController _roomCodeController = TextEditingController();
  final VoidCallback? onBack;

  ProfilePage({this.onBack});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ProfileBloc(FirebaseAuth.instance, FirebaseFirestore.instance),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthInitial) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          }
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Error occurred"),
              backgroundColor: Colors.red,
            ));
          } else if (state is ProfileChangedSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ));
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (onBack != null) onBack!();
                Navigator.pop(context);
              },
            ),
          ),
          body: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              if (state is ProfileLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state is ProfileLoaded) ...[
                      CircleAvatar(
                        radius: 75,
                        backgroundColor: Colors.transparent,
                        child: ClipOval(
                          child: Image.network(
                            state.photoProfile,
                            fit: BoxFit.cover,
                            width: 150,
                            height: 150,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        state.fullName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: Dimensions.size35),
                    ],
                    Center(
                      child: SizedBox(
                        width: 150,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 15.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ChangeProfilePage()),
                            );
                          },
                          child: const Text(
                            'Ubah Profile',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: SizedBox(
                        width: 150,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 15.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RoomCodePage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Kode Ruangan',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: SizedBox(
                        width: 150,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 15.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChangePasswordPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Ganti Password',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.black,
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Konfirmasi Logout'),
                    content: const Text('Apakah Anda yakin ingin logout?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.read<AuthBloc>().add(AuthLogoutRequested());
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  );
                },
              );
            },
            child: const Icon(
              Icons.directions_run_rounded,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
