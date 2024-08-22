import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_app/overlay/overlays.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  ProfileBloc(this._auth, this._firestore) : super(ProfileInitial()) {
    on<SubmitRoomCodeEvent>(_onSubmitRoomCode);
    on<ChangeProfileEvent>(_onChangeProfile);
    on<ToggleRoomCodeInputVisibilityEvent>(
        _onToggleRoomCodeInputVisibilityEvent);
    on<LoadUserProfileEvent>(_onLoadUserProfile);
    add(LoadUserProfileEvent());
  }

  Future<void> _onSubmitRoomCode(
      SubmitRoomCodeEvent event, Emitter<ProfileState> emit) async {
    try {
      emit(ProfileLoading());
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'roomCode': event.roomCode,
        });
        emit(RoomCodeSubmittedSuccess(event.roomCode));
      }
    } catch (e) {
      print("Error in _onSubmitRoomCode: $e");
      emit(ProfileError("Failed to submit room code."));
    }
  }

  Future<void> _onChangeProfile(
      ChangeProfileEvent event, Emitter<ProfileState> emit) async {
    try {
      print("ChangeProfileEvent triggered");
      emit(ProfileLoading());

      final user = _auth.currentUser;
      if (user != null) {
        final updates = {'fullName': event.fullName};

        if (event.profileImage != null) {
          final ref = FirebaseStorage.instance
              .ref()
              .child('user_profile_images')
              .child('${user.uid}.jpg');
          await ref.putFile(File(event.profileImage!.path));
          final downloadUrl = await ref.getDownloadURL();

          updates['photoProfile'] = downloadUrl;
          print("Profile image uploaded and URL obtained: $downloadUrl");
        }

        await _firestore.collection('users').doc(user.uid).update(updates);
        Overlays.success(
          message: "Profile Berhasil Diubah.",
        );
        print("Profile updated with: $updates");
        emit(ProfileChangedSuccess());
      }
    } catch (e) {
      print("Error in _onChangeProfile: $e");
      emit(ProfileError("Failed to change profile."));
    }
  }

  void _onToggleRoomCodeInputVisibilityEvent(
    ToggleRoomCodeInputVisibilityEvent event,
    Emitter<ProfileState> emit,
  ) {
    if (state is RoomCodeInputState) {
      final currentState = state as RoomCodeInputState;
      emit(RoomCodeInputState(isVisible: !currentState.isVisible));
    } else {
      emit(RoomCodeInputState(isVisible: true));
    }
  }

  Future<void> _onLoadUserProfile(
      LoadUserProfileEvent event, Emitter<ProfileState> emit) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        final userData = userDoc.data();

        if (userData != null) {
          final fullName = userData['fullName'] ?? '';
          final photoProfile = userData['photoProfile'] ?? '';

          emit(ProfileLoaded(
            user: user,
            fullName: fullName,
            photoProfile: photoProfile,
          ));
        } else {
          emit(ProfileError('User data not found.'));
        }
      } else {
        emit(ProfileError('No user is signed in.'));
      }
    } catch (e) {
      print("Error in _onLoadUserProfile: $e");
      emit(ProfileError('Failed to load user profile.'));
    }
  }
}
