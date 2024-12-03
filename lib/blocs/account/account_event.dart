part of 'account_bloc.dart';



abstract class AccountEvent extends Equatable {
  const AccountEvent();

  @override
  List<Object?> get props => [];
}

class CreateAccountEvent extends AccountEvent {
  final String email;
  final String password;
  final String name;
  final String phone;
  final int age;
  final String userType;
  final File? profilePicture;

  const CreateAccountEvent({
    required this.email,
    required this.password,
    required this.name,
    required this.phone,
    required this.age,
    required this.userType,
    this.profilePicture,
  });

  @override
  List<Object?> get props => [email, password, name, phone, age, userType, profilePicture];
}
