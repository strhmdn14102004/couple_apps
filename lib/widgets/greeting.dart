import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GreetingPopupManager {
  Timer? _timer;
  bool _isMorningGreetingShown = false;
  bool _isAfternoonGreetingShown = false;
  bool _isEveningGreetingShown = false;
  bool _isAfternoonLateGreetingShown =
      false; // Penambahan flag untuk greeting sore

  void start(BuildContext context) {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkAndShowGreeting(context);
    });
  }

  void stop() {
    _timer?.cancel();
  }

  Future<void> _checkAndShowGreeting(BuildContext context) async {
    final now = DateTime.now();
    final currentHour = now.hour;

    if (currentHour >= 7 && currentHour < 12 && !_isMorningGreetingShown) {
      _isMorningGreetingShown = true;
      await _showGreeting(context, 'Pagi');
    } else if (currentHour >= 12 &&
        currentHour < 15 &&
        !_isAfternoonGreetingShown) {
      _isAfternoonGreetingShown = true;
      await _showGreeting(context, 'Siang');
    } else if (currentHour >= 15 &&
        currentHour < 18 &&
        !_isAfternoonLateGreetingShown) {
      _isAfternoonLateGreetingShown = true;
      await _showGreeting(context, 'Sore');
    } else if (currentHour >= 18 &&
        currentHour < 24 &&
        !_isEveningGreetingShown) {
      _isEveningGreetingShown = true;
      await _showGreeting(context, 'Malam');
    }
  }

  Future<void> _showGreeting(BuildContext context, String greetingTime) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final fullName = userDoc['fullName'] ?? 'User';

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Camattt $greetingTime $fullName! ♡♡♡',
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black, // Warna teks tombol
                    ),
                    child: Text(
                      '$greetingTime duniaku',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }
}
