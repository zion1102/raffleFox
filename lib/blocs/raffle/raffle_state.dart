part of 'raffle_bloc.dart';

abstract class RaffleState extends Equatable {
  const RaffleState();

  @override
  List<Object?> get props => [];
}

class RaffleLoading extends RaffleState {}

class RaffleLoaded extends RaffleState {
  final Map<String, dynamic> raffleData;
  final bool isLiked;

  const RaffleLoaded({
    required this.raffleData,
    required this.isLiked,
  });

  @override
  List<Object?> get props => [raffleData, isLiked];
}

class RaffleLikeToggled extends RaffleState {
  final bool isLiked;

  const RaffleLikeToggled(this.isLiked);

  @override
  List<Object?> get props => [isLiked];
}

class RaffleError extends RaffleState {
  final String message;

  const RaffleError(this.message);

  @override
  List<Object?> get props => [message];
}
