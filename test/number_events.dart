// Event that sets the number of a state
import 'package:equatable/equatable.dart';

class SetNumberEvent extends Equatable {
  final int number;

  const SetNumberEvent(this.number);

  @override
  List<Object?> get props => [number];
}
// Event that adds this number argument to the state
class AddNumberEvent extends Equatable {
  final int number;

  const AddNumberEvent(this.number);

  @override
  List<Object?> get props => [number];
}

// Event that accumulates the value of this state with the state of its children
class AccumulateEvent extends Equatable {
  @override
  List<Object?> get props => [];

}