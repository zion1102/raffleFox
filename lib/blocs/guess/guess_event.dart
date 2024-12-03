part of 'guess_bloc.dart';

abstract class GuessEvent extends Equatable {
  const GuessEvent();

  @override
  List<Object> get props => [];
}

class AddGuess extends GuessEvent {
  final Offset spot;

  const AddGuess(this.spot);

  @override
  List<Object> get props => [spot];
}

class RemoveGuess extends GuessEvent {
  final Offset spot;

  const RemoveGuess(this.spot);

  @override
  List<Object> get props => [spot];
}
