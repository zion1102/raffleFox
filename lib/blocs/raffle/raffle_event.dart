part of 'raffle_bloc.dart';

abstract class RaffleEvent extends Equatable {
  const RaffleEvent();

  @override
  List<Object> get props => [];
}

class LoadRaffleStatus extends RaffleEvent {
  final String raffleId;
  final String userId;

  const LoadRaffleStatus(this.raffleId, this.userId);

  @override
  List<Object> get props => [raffleId, userId];
}

class ToggleRaffleLike extends RaffleEvent {
  final String raffleId;
  final String userId;
  final bool isLiked;

  const ToggleRaffleLike({
    required this.raffleId,
    required this.userId,
    required this.isLiked,
  });

  @override
  List<Object> get props => [raffleId, userId, isLiked];
}
