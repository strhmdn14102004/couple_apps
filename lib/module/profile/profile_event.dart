part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

class SubmitRoomCodeEvent extends ProfileEvent {
  final String roomCode;

  SubmitRoomCodeEvent(this.roomCode);

  @override
  List<Object> get props => [roomCode];
}
class LoadUserProfileEvent extends ProfileEvent {
  @override
  List<Object> get props => [];
}

class ChangeProfileEvent extends ProfileEvent {
  final String fullName;
  final XFile? profileImage;

  ChangeProfileEvent({required this.fullName, this.profileImage});

  @override
  List<Object> get props => [fullName, profileImage ?? ''];
}

class ToggleRoomCodeInputVisibilityEvent extends ProfileEvent {}

class LogoutEvent extends ProfileEvent {}
