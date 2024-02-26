import 'package:equatable/equatable.dart';

import 'event.dart';

/// The response to an event
abstract class Response<E, S> extends Equatable {
  final Event<E> event;
  final dynamic result;
  final S resultingState;

  final String originId;

  const Response({required this.originId, required this.event, required this.result, required this.resultingState});

  @override
  List<Object?> get props => [originId, event, result, resultingState];
}

/// A response that returns a specific value
class ConcreteResponse<E, S> extends Response<E, S> {
  const ConcreteResponse(
      {required super.originId, required super.event, required super.result, required super.resultingState});
}

/// A response that wraps other responses as a response travels up the tree
class InterstateResponse<E, S> extends Response<E, S> {
  final List<Response<E, dynamic>> downStreamResponses;

  const InterstateResponse(
      {required super.event,
      required super.result,
      required super.resultingState,
      required super.originId,
      required this.downStreamResponses});

  @override
  List<Object?> get props => super.props + [downStreamResponses];
}
