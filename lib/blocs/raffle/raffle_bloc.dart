import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

part 'raffle_event.dart';
part 'raffle_state.dart';

class RaffleBloc extends Bloc<RaffleEvent, RaffleState> {
  final FirebaseFirestore firestore;

  RaffleBloc({required this.firestore}) : super(RaffleLoading()) {
    on<LoadRaffleStatus>(_onLoadRaffleStatus);
    on<ToggleRaffleLike>(_onToggleRaffleLike);
  }

  Future<void> _onLoadRaffleStatus(
    LoadRaffleStatus event,
    Emitter<RaffleState> emit,
  ) async {
    try {
      emit(RaffleLoading());
      final doc = await firestore.collection('raffles').doc(event.raffleId).get();
      final userLikesDoc = await firestore
          .collection('userLikes')
          .doc('${event.userId}_${event.raffleId}')
          .get();

      if (doc.exists) {
        emit(RaffleLoaded(
          raffleData: doc.data() as Map<String, dynamic>,
          isLiked: userLikesDoc.exists,
        ));
      } else {
        emit(const RaffleError('Raffle not found.'));
      }
    } catch (e) {
      emit(RaffleError(e.toString()));
    }
  }

  Future<void> _onToggleRaffleLike(
    ToggleRaffleLike event,
    Emitter<RaffleState> emit,
  ) async {
    try {
      final userId = event.userId;
      final raffleId = event.raffleId;
      final likeRef = firestore.collection('userLikes').doc('${userId}_$raffleId');

      if (event.isLiked) {
        await likeRef.delete();
        emit(RaffleLikeToggled(false));
      } else {
        await likeRef.set({'raffleId': raffleId, 'userId': userId});
        emit(RaffleLikeToggled(true));
      }
    } catch (e) {
      emit(RaffleError(e.toString()));
    }
  }
}
