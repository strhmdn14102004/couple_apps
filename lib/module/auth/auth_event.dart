part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested(this.email, this.password);
}

class AuthSignupRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String photoProfile;

  const AuthSignupRequested(this.email, this.password, this.fullName, this.photoProfile);
}
class AuthUpdateProfile extends AuthEvent {
  final String photoUrl;

  const AuthUpdateProfile(this.photoUrl);

  @override
  List<Object> get props => [photoUrl];
}

class AuthLogoutRequested extends AuthEvent {}
