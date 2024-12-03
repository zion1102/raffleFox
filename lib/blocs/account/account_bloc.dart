import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:raffle_fox/services/firebase_services.dart';
import 'dart:io';

part 'account_event.dart';
part 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final FirebaseService firebaseService;

  AccountBloc(this.firebaseService) : super(AccountInitial()) {
    on<CreateAccountEvent>(_onCreateAccount);
  }

  Future<void> _onCreateAccount(
      CreateAccountEvent event, Emitter<AccountState> emit) async {
    emit(AccountLoading());
    try {
      // Call Firebase service to create a user
      final user = await firebaseService.createUser(
        email: event.email,
        password: event.password,
        name: event.name,
        phone: event.phone,
        age: event.age,
        userType: event.userType,
        profilePicture: event.profilePicture,
      );

      if (user != null) {
        emit(AccountCreated());
      } else {
        emit(AccountError("Failed to create account. Please try again."));
      }
    } catch (e) {
      emit(AccountError("Error: ${e.toString()}"));
    }
  }
}
