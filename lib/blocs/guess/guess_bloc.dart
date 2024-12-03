import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'guess_event.dart';
part 'guess_state.dart';

class GuessBloc extends Bloc<GuessEvent, GuessState> {
  final List<Offset> confirmedSpots = [];

  GuessBloc() : super(GuessInitial()) {
    on<AddGuess>(_onAddGuess);
    on<RemoveGuess>(_onRemoveGuess);
  }

  void _onAddGuess(AddGuess event, Emitter<GuessState> emit) {
    confirmedSpots.add(event.spot);
    emit(GuessUpdated(List.from(confirmedSpots)));
  }

  void _onRemoveGuess(RemoveGuess event, Emitter<GuessState> emit) {
    confirmedSpots.remove(event.spot);
    emit(GuessUpdated(List.from(confirmedSpots)));
  }
}
