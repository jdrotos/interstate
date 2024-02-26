import 'package:equatable/equatable.dart';

class NumberState extends Equatable {
  final int number;

  const NumberState(this.number);

  @override
  List<Object?> get props => [number];
}