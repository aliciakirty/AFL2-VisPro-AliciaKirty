import 'package:equatable/equatable.dart';

class CommandResult extends Equatable {
  const CommandResult.success([this.message = '']) : isSuccess = true;
  const CommandResult.failure(this.message) : isSuccess = false;

  final bool isSuccess;
  final String message;

  @override
  List<Object?> get props => [isSuccess, message];
}