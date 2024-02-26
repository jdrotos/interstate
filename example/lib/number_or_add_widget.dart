import 'package:equatable/equatable.dart';
import 'package:example/number_or_add_events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:interstate/interstate.dart';
import 'package:interstate/util/interstate_utils.dart';

// Define a state we can use to build our widget
class NumberOrAddState extends Equatable {
  // The number to display
  final double number;

  // If we are in add mode
  final bool addMode;

  // If there is an error this will not be empty
  final String error;

  const NumberOrAddState({this.number = 0, this.addMode = false, this.error = ""});

  NumberOrAddState copyWith({double? number, bool? addMode, String? error}) {
    return NumberOrAddState(
      number: number ?? this.number,
      addMode: addMode ?? this.addMode,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [number, addMode, error];
}

class NumberOrAddWidget extends StatefulWidget {
  final String uniqueId;
  final double initialValue;

  String get leftId => "$uniqueId:left";

  String get rightId => "$uniqueId:right";

  NumberOrAddWidget({required this.uniqueId, this.initialValue = 0}) : super(key: ValueKey(uniqueId));

  @override
  State<NumberOrAddWidget> createState() => _NumberOrAddWidgetState();
}

class _NumberOrAddWidgetState extends State<NumberOrAddWidget> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: "");
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => InterstateWidget<NumberOrAddState>(
        id: widget.uniqueId,
        controllerInitializer: (id, bubbleUpListener) {
          return InterstateController<NumberOrAddState>(
            id: id,
            initialState: NumberOrAddState(number: widget.initialValue, addMode: false),
            // NOTE: we MUST pass along the bubbleUpListener
            bubbleUpListener: bubbleUpListener,
            handlers: [
              EventHandler<EventChangeAddMode, NumberOrAddState>(
                  eventDataType: EventChangeAddMode,
                  // We don't need to do any kind of calculating in this case
                  resultBuilder: (_, __, ___) => null,
                  stateBuilder: (event, currentState, result, subResponses) {
                    // Flip a flag in the state
                    return currentState.copyWith(addMode: event.data.addMode);
                  }),
              EventHandler<EventChangeNumber, NumberOrAddState>(
                  eventDataType: EventChangeNumber,
                  // The result builder is useful for generating an output based on the responses of the children
                  // This is the mechanism we use to query child widgets.
                  // The EventChangeNumber contains text, and we parse it here, or return null.
                  // We can't add null to a number, so if we encounter a child result as null, we also return null
                  resultBuilder: (event, currentState, subResponses) {
                    if (!currentState.addMode && event.originId == widget.uniqueId) {
                      // If the event originated here, parse the text
                      return double.tryParse(event.data.numberText);
                    } else if (currentState.addMode) {
                      // subResponses contains all of the responses returning from widgets below us in the tree,
                      // we only care about 2 of those responses, those of our direct children
                      final leftResponse =
                          InterstateUtils.getResponse<EventChangeNumber, NumberOrAddState>(widget.leftId, subResponses);
                      final rightResponse = InterstateUtils.getResponse<EventChangeNumber, NumberOrAddState>(
                          widget.rightId, subResponses);

                      // If our children are invalid, we can say we are invalid too
                      if (leftResponse?.result == null || rightResponse?.result == null) return null;

                      // Add them together
                      return leftResponse!.result + rightResponse!.result;
                    }
                    // Just return the current value if there isn't anything to do
                    return currentState.number;
                  },
                  // If we have a result, we are golden
                  // If the result is null we have an error
                  stateBuilder: (event, currentState, result, subResponses) {
                    if (result == null) {
                      return currentState.copyWith(number: 0.0, error: "Invalid number!");
                    }
                    return currentState.copyWith(number: result, error: "");
                  }),
            ],
          );
        },
        widgetBuilder: (context, state, child, controller) {
          // Here we build a widget, with access to the controller where we can send events

          final txt = state.error.isEmpty ? state.number.toString() : "";
          if (_textController.text != txt) {
            _textController.value = TextEditingValue(text: txt);
          }

          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(16),
              color: Colors.primaries[state.number.toInt() % Colors.primaries.length].shade50,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 32.0),
                      child: Text(
                        "${state.error.isEmpty ? state.number : "!"}",
                        style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                if (!state.addMode)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 128, maxWidth: 256),
                              child: TextField(
                                style: const TextStyle(fontSize: 24),
                                decoration: InputDecoration(
                                  errorText: state.error,
                                ),
                                controller: _textController,
                                onChanged: (value) {
                                  debugPrintSynchronously("onChanged:${widget.uniqueId}");
                                  // If the number here changes, we pass that change event up the tree, so any add calculations can be performed
                                  controller.send(EventChangeNumber(value), up: true, span: true, down: true);
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: ElevatedButton(
                              child: const Text("+Add"),
                              onPressed: () {
                                controller.send(EventChangeAddMode(true));
                              },
                            ),
                          ),
                        ],
                      )),
                if (state.addMode)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () {
                            controller.send(EventChangeAddMode(false));
                          },
                          child: const Text("Collapse")),
                    ],
                  ),
                if (state.addMode)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                              child: NumberOrAddWidget(
                            uniqueId: widget.leftId,
                            initialValue: state.number,
                          )),
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Icon(
                              Icons.add,
                              size: 64,
                            ),
                          ),
                          Flexible(
                            child: NumberOrAddWidget(uniqueId: widget.rightId),
                          ),
                        ],
                      )),
              ],
            ),
          );
        },
      );
}
