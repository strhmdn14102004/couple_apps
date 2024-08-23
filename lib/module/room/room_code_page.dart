import 'package:couple_app/helper/dimensions.dart';
import 'package:couple_app/module/home/home_page.dart';
import 'package:couple_app/module/profile/profile_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for input formatters
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

class RoomCodePage extends StatefulWidget {
  @override
  _RoomCodePageState createState() => _RoomCodePageState();
}

class _RoomCodePageState extends State<RoomCodePage> {
  final TextEditingController _roomCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _showConfirmationDialog() {
    final roomCode = _roomCodeController.text.trim();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Kode Ruangan'),
          content: Text(
            'Apakah Anda yakin ingin menggunakan kode $roomCode sebagai kode ruangan Anda?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _submitRoomCode(); // Proceed with submitting the code
              },
              child: Text('Ya'),
            ),
          ],
        );
      },
    );
  }

  void _submitRoomCode() {
    if (_formKey.currentState?.validate() ?? false) {
      final roomCode = _roomCodeController.text.trim();
      context.read<ProfileBloc>().add(SubmitRoomCodeEvent(roomCode));
    }
  }

  void _handleConfirmation() {
    if (_formKey.currentState?.validate() ?? false) {
      _showConfirmationDialog();
    } else {
      // Optionally, show a Snackbar or other message indicating validation errors
    }
  }

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
                  Text('Kode Ruangan ${state.roomCode} berhasil digunakan!'),
              backgroundColor: Colors.green,
            ),
          );
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
          padding: const EdgeInsets.only(left:16,right:16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        "assets/lottie/lock.json",
                        frameRate: FrameRate(60),
                        width: Dimensions.size100 * 2,
                        repeat: true,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: Dimensions.size10,
                ),
                const Text(
                  "Pastikan Kode Ruangan yang anda masukan adalah kode ruangan terpercaya. jangan bagikan kode ruangan anda ke orang yang tidak anda percayai. kode ruangan bersifat RAHASIA",
                  style: TextStyle(),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: Dimensions.size15,
                ),
                TextFormField(
                  controller: _roomCodeController,
                  decoration: InputDecoration(
                    labelStyle: TextStyle(fontWeight: FontWeight.bold),
                    alignLabelWithHint: true,
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
                  keyboardType:
                      TextInputType.number, // Restrict keyboard to numbers
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Allow only digits
                    LengthLimitingTextInputFormatter(
                        6), // Limit input to 6 characters
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kode ruangan tidak boleh kosong';
                    } else if (value.length != 6) {
                      return 'Kode ruangan harus terdiri dari 6 angka';
                    }
                    return null;
                  },
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
                      onPressed: _handleConfirmation,
                      child: const Text(
                        'Konfirmasi Kode',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
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
