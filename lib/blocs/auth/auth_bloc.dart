import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'package:raffle_fox/services/firebase_services.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseService _firebaseService;

  AuthBloc(this._firebaseService) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  Future<void> _onLoginRequested(
      LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // Call loginUser from FirebaseService
      final userCredential = await _firebaseService.loginUser(
        email: event.email,
        password: event.password,
      );

      if (userCredential?.user == null) {
        emit(const AuthError("Failed to log in user."));
        return;
      }

      // Get user ID and type
      final userId = userCredential!.user!.uid;
      final userType = await _firebaseService.getUserType(userId);

      if (userType == null) {
        emit(const AuthError("Unable to determine user type."));
        return;
      }

      emit(AuthAuthenticated(userId: userId, userType: userType));
    } catch (e) {
      emit(AuthError("Login failed: ${e.toString()}"));
    }
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event, Emitter<AuthState> emit) async {
    try {
      await _firebaseService.logoutUser();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError("Logout failed: ${e.toString()}"));
    }
  }

  Future<void> _onCheckAuthStatus(
      CheckAuthStatus event, Emitter<AuthState> emit) async {
    try {
      final userId = await _firebaseService.getCurrentUserId();
      if (userId == null) {
        emit(AuthUnauthenticated());
        return;
      }

      final userType = await _firebaseService.getUserType(userId);
      if (userType != null) {
        emit(AuthAuthenticated(userId: userId, userType: userType));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError("Failed to check authentication status: ${e.toString()}"));
    }
  }
}
