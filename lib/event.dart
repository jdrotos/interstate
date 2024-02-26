import 'package:equatable/equatable.dart';

/// An event is the basic way we pass data into the system to solicit a response.
abstract class Event<E> extends Equatable {
  // where THIS event originated
  String get originId;

  E get data;

  bool get propagateDown;

  bool get propagateUp;

  bool get span;
}

/// A concrete event is the originating event in a call. So generally, this is the event that gets processed at the level
/// where the event originated.
class ConcreteEvent<E> extends Event<E> {
  @override
  final E data;
  @override
  final String originId;
  @override
  final bool propagateDown;
  @override
  final bool propagateUp;
  @override
  final bool span;

  ConcreteEvent(
      {required this.data,
        required this.originId,
        required this.propagateDown,
        required this.propagateUp,
        required this.span});

  @override
  List<Object?> get props => [data, originId, propagateDown, propagateUp, span];
}

/// An [InterstateEvent] wraps another event as it travels DOWN the tree.
/// So the originating event is a [ConcreteEvent]. If that event should propagate down, we wrap it in an [InterstateEvent].
/// This allows for a paper trail as the event travels, and it allows us to figure out if a particular [Interstate] has processed
/// an event or not.
class InterstateEvent<E> extends Event<E> {
  // where THIS event originated
  @override
  final String originId;

  @override
  E get data => inner.data;

  final Event<E> inner;
  final ConcreteEvent<E> concrete;

  InterstateEvent(this.originId, this.inner)
      : concrete = (inner is ConcreteEvent<E>) ? inner : (inner as InterstateEvent<E>).concrete;

  /// Interstate events are created by sending events down the tree, so if our concrete event started this chain, it should
  /// continue
  @override
  bool get propagateDown => concrete.propagateDown;

  /// Because this is an [InterstateEvent], we are inherently traveling down the tree.
  /// Results will be reported back directly to the original [ConcreteEvent] callsite.
  /// This property controls sending response data to [Interstate]s ABOVE the original callsite. (which the [ConcreteEvent] at the center of this thing maintains)
  @override
  bool get propagateUp => false;

  @override
  bool get span => concrete.span;

  @override
  List<Object?> get props => [originId, inner];
}