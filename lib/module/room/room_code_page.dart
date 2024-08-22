import 'package:couple_app/module/home/home_page.dart';
import 'package:couple_app/module/profile/profile_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoomCodePage extends StatelessWidget {
  final TextEditingController _roomCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is RoomCodeSubmittedSuccess) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Kode Ruangan ${state.roomCode} berhasil disimpan!'),
              backgroundColor: Colors.green,
            ),
          );
          // Use a safe navigation method
        } else if (state is ProfileError) {
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
          title: const Text('Masukkan Kode Ruangan'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _roomCodeController,
                decoration: InputDecoration(
                  labelText: 'Masukkan Kode Ruangan',
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
            ],
          ),
        ),
      ),
    );
  }
}
