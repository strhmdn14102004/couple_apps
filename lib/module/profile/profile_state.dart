part of 'profile_bloc.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();
  
  @override
  List<Object> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class RoomCodeSubmittedSuccess extends ProfileState {
  final String roomCode;

  RoomCodeSubmittedSuccess(this.roomCode);

  @override
  List<Object> get props => [roomCode];
}

class ProfileChangedSuccess extends ProfileState {}

class LogoutSuccess extends ProfileState {}

class ProfileError extends ProfileState {
  final String message;

  ProfileError(this.message);

  @override
  List<Object> get props => [message];
}

class ProfileLoaded extends ProfileState {
  final User user;
  final String fullName;
  final String photoProfile;

  ProfileLoaded({
    required this.user,
    required this.fullName,
    required this.photoProfile,
  });

  @override
  List<Object> get props => [user, fullName, photoProfile];
}

class RoomCodeInputState extends ProfileState {
  final bool isVisible;

  RoomCodeInputState({required this.isVisible});

  @override
  List<Object> get props => [isVisible];
}
