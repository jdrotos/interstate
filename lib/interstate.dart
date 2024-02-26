import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

import 'event.dart';
import 'response.dart';

typedef ResultBuilder<E, R, S> = R Function(Event<E> event, S currentState, List<Response<E, dynamic>> subResponses);
typedef StateBuilder<E, R, S> = S? Function(
  Event<E> event,
  S currentState,
  R result,
  List<Response<E, dynamic>> subResponses,
);
typedef SideEffectDispatcher<E, R, S> = void Function(
  InterstateController<S> controller,
  Event<E> event,
  R result,
  S updatedState,
);

typedef BubbleUpListener<S> = void Function<E>(Response<E, S> response);

typedef WidgetBuilder<S> = Widget Function(
    BuildContext context, S state, Widget? child, InterstateController<S> controller);
typedef StateListener<S> = void Function(S state);

class EventHandler<E, S> extends Equatable {
  final Type eventDataType;
  final ResultBuilder<E, dynamic, S> resultBuilder;
  final StateBuilder<E, dynamic, S> stateBuilder;
  final SideEffectDispatcher<E, dynamic, S>? sideEffectDispatcher;

  const EventHandler(
      {required this.eventDataType,
      required this.resultBuilder,
      required this.stateBuilder,
      this.sideEffectDispatcher});

  @override
  List<Object?> get props => [eventDataType, resultBuilder, stateBuilder, sideEffectDispatcher];
}

class InterstateController<S> {
  final String id;
  final BubbleUpListener<S> bubbleUpListener;

  // This is how we communicate the state to the UI at this level
  final ValueNotifier<S> state;

  final Set<InterstateController<dynamic>> innerInterstates = {};

  final List<EventHandler<dynamic, S>> handlers;

  bool get disposed => _disposed;
  bool _disposed = false;

  InterstateController({
    required this.id,
    required S initialState,
    required this.bubbleUpListener,
    required this.handlers,
  }) : state = ValueNotifier(initialState);

  void registerInnerInterstate(InterstateController<dynamic> inner) => innerInterstates.add(inner);

  void unRegisterInnerInterstate(InterstateController<dynamic> inner) => innerInterstates.remove(inner);

  void dispose() {
    _disposed = true;
  }

  bool _handlerExists<E>() {
    return handlers.any((handler) => handler.eventDataType == E);
  }

  EventHandler<E, S>? _handlerFor<E>(Event<E> event) {
    if (!_handlerExists<E>()) {
      return null;
    }
    return handlers.firstWhere((handler) => handler.eventDataType == E) as EventHandler<E, S>;
  }

  Response<E, S> send<E>(E data, {bool down = false, bool up = false, bool span = false}) {
    var outcome =
        _dispatch<E>(event: ConcreteEvent(data: data, originId: id, propagateDown: down, propagateUp: up, span: span));
    if (up) {
      _bubbleUp<E>(outcome);
    }
    return outcome;
  }

  Response<E, S> _dispatch<E>({required Event<E> event, Response<E, dynamic>? bubbleUpResponse}) {
    debugPrintSynchronously("_dispatch:$id event:$event");
    List<Response<E, dynamic>> innerResponses = [];
    if (bubbleUpResponse != null) {
      innerResponses.add(bubbleUpResponse);
    }

    // We should propagate down IF:
    // We are the origin of the event (or below it), and propagateDown is set to true
    // OR
    // We are above the origin, and span is set to true
    // -- note: in this case we take special care not to go down branches we've already visited
    if ((event.span && event.originId != id) || (bubbleUpResponse == null && event.propagateDown)) {
      for (var interstate in innerInterstates) {
        // If we are spanning
        if (bubbleUpResponse?.originId == interstate.id) {
          continue;
        }
        innerResponses.add(interstate._dispatch<E>(event: InterstateEvent<E>(id, event)));
      }
    }

    dynamic result;
    S resultingState = state.value;

    var handler = _handlerFor(event);
    if (handler != null) {
      result = handler.resultBuilder(event, resultingState, innerResponses);
      var freshState = handler.stateBuilder(event, resultingState, result, innerResponses);
      if (freshState != null) {
        resultingState = freshState;
        state.value = freshState;
      }

      // TODO: We have no way of collecting any kind of results from these side effects
      // CONTEXT: The original usecase of sideEffectDispatcher was to trigger a SAVE event from an OnChange event
      handler.sideEffectDispatcher?.call(this, event, result, resultingState);
    }

    Response<E, S> response;
    if (innerResponses.isNotEmpty) {
      response = InterstateResponse<E, S>(
        originId: id,
        event: event,
        result: result,
        resultingState: resultingState,
        downStreamResponses: innerResponses,
      );
    } else {
      response = ConcreteResponse<E, S>(
        originId: id,
        event: event,
        result: result,
        resultingState: resultingState,
      );
    }

    return response;
  }

  void _bubbleUp<E>(Response<E, S> response) {
    bubbleUpListener<E>(response);
  }

  void onBubbleUp<E>(Response<E, dynamic> response) {
    /// NOTE: the _dispatch function will wrap this in an InterstateResponse so not much to do here!
    var outcome = _dispatch<E>(event: response.event, bubbleUpResponse: response);
    _bubbleUp<E>(outcome);
  }
}

typedef ControllerInitializer<S> = InterstateController<S> Function(String id, BubbleUpListener<S> listener);

class InterstateWidget<S> extends StatefulWidget {
  final String id;
  final WidgetBuilder<S> widgetBuilder;
  final Widget? child;
  final StateListener<S>? listener;
  final ControllerInitializer<S> controllerInitializer;

  InterstateWidget({
    required this.id,
    required this.widgetBuilder,
    required this.controllerInitializer,
    this.listener,
    this.child,
  }) : super(key: genKey(id));

  static Key genKey(String id) => ValueKey("interstate:$id");

  @override
  State<InterstateWidget<S>> createState() => _InterstateWidgetState<S>();
}

class _InterstateWidgetState<S> extends State<InterstateWidget<S>> {
  late InterstateController<S> controller;
  Interstate? parentInterstate;

  @override
  void initState() {
    super.initState();
    controller = widget.controllerInitializer(widget.id, _bubbleUp);
    controller.state.addListener(_onStateUpdate);
  }

  void _onStateUpdate() {
    widget.listener?.call(controller.state.value);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    parentInterstate = Interstate.of(context);
  }

  @override
  void dispose() {
    controller.state.removeListener(_onStateUpdate);
    parentInterstate?.controller.unRegisterInnerInterstate(controller);
    controller.dispose();
    super.dispose();
  }

  void _bubbleUp<E>(Response<E, S> response) {
    parentInterstate?.controller.onBubbleUp<E>(response);
  }

  @override
  Widget build(BuildContext context) {
    Interstate? parentInterstate = Interstate.of(context);
    parentInterstate?.controller.registerInnerInterstate(controller);
    return Interstate(
        controller: controller,
        child: ValueListenableBuilder<S>(
          builder: (context, state, child) {
            return widget.widgetBuilder(context, state, child, controller);
          },
          valueListenable: controller.state,
          child: widget.child,
        ));
  }
}

class Interstate extends InheritedWidget {
  final InterstateController controller;

  const Interstate({super.key, required super.child, required this.controller});

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return (oldWidget is Interstate) ? oldWidget.controller != controller : true;
  }

  static Interstate? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<Interstate>();
  }
}
