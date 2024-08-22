import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_app/helper/device_info.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final DeviceInfoService _deviceInfoService = DeviceInfoService();

  AuthBloc(this._firebaseAuth, this._firestore) : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthSignupRequested>(_onSignupRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthUpdateProfile>(_onUpdateProfile);
  }

  Future<void> saveUserSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  void _onLoginRequested(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      await saveUserSession(userCredential.user!.uid);
      await _deviceInfoService.saveDeviceInfoToFirestore();

      // Fetch user info from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        emit(const AuthError("User data not found."));
      } else {
        // Ensure that AuthAuthenticated is emitted after all tasks are done
        emit(AuthAuthenticated(userCredential.user!.uid));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void _onSignupRequested(
      AuthSignupRequested event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      // Save user info in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'fullName': event.fullName,
        'photoProfile': event.photoProfile,
        'location': null,
        'speed': 0.0,
        'distance': 0.0,
      });

      emit(AuthAuthenticated(userCredential.user!.uid));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void _onUpdateProfile(
      AuthUpdateProfile event, Emitter<AuthState> emit) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        // Update the user's profile with the photo URL
        await user.updatePhotoURL(event.photoUrl);
        // Optionally, you can also update the Firestore document with the new photo URL
        await _firestore.collection('users').doc(user.uid).update({
          'photoProfile': event.photoUrl,
        });

        // Notify the state that the profile was successfully updated
        emit(AuthAuthenticated(user.uid));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void _onLogoutRequested(
      AuthLogoutRequested event, Emitter<AuthState> emit) async {
    try {
      // Sign out from Firebase
      await _firebaseAuth.signOut();

      // Clear user session from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');

      emit(AuthInitial()); // Emit AuthInitial to notify the UI
    } catch (e) {
      emit(AuthError('Failed to log out: ${e.toString()}'));
    }
  }
}
