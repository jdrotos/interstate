import 'package:equatable/equatable.dart';


abstract class NumberOrAddEvent extends Equatable {}

class EventChangeAddMode extends NumberOrAddEvent {
  final bool addMode;

  EventChangeAddMode(this.addMode);

  @override
  List<Object?> get props => [addMode];
}

class EventChangeNumber extends NumberOrAddEvent {
  final String numberText;

  EventChangeNumber(this.numberText);

  @override
  List<Object?> get props => [numberText];
}