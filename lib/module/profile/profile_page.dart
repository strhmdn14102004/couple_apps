import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_app/module/auth/auth_bloc.dart';
import 'package:couple_app/module/room/room_code_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
            print("Logout successful, navigating to login page");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          }
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(""),
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
            title: const Text('Profile Page'),
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
                        backgroundImage: NetworkImage(state.photoProfile),
                        radius: 50,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        state.fullName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (state is RoomCodeInputState && state.isVisible) ...[
                      TextField(
                        controller: _roomCodeController,
                        decoration: InputDecoration(
                          labelText: 'Masukan Kode Ruangan',
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
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        onPressed: () {
                          final roomCode = _roomCodeController.text.trim();
                          if (roomCode.isNotEmpty) {
                            context
                                .read<ProfileBloc>()
                                .add(SubmitRoomCodeEvent(roomCode));
                          }
                        },
                        child: const Text('Simpan Kode Ruangan'),
                      ),
                      const SizedBox(height: 20),
                    ],
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ChangeProfilePage()),
                        );
                      },
                      child: const Text('Ubah Profile'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
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
                      child: const Text('Kode Ruangan'),
                    ),
                  ],
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            child: const Icon(Icons.exit_to_app),
          ),
        ),
      ),
    );
  }
}
