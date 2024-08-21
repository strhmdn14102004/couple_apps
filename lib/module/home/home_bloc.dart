import "package:couple_app/module/home/home_event.dart";
import "package:couple_app/module/home/home_state.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial());
}
