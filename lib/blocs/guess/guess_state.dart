part of 'guess_bloc.dart';

abstract class GuessState extends Equatable {
  const GuessState();

  @override
  List<Object> get props => [];
}

class GuessInitial extends GuessState {}

class GuessUpdated extends GuessState {
  final List<Offset> confirmedSpots;

  const GuessUpdated(this.confirmedSpots);

  @override
  List<Object> get props => [confirmedSpots];
}
