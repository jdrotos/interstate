import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:interstate/common/events_common.dart';
import 'package:interstate/event.dart';
import 'package:interstate/interstate.dart';
import 'package:interstate/response.dart';
import 'package:interstate/common/responses_common.dart';

/// This is where we keep our current widget state
class NestedTextFieldState extends Equatable {
  final String text;
  final String error;

  const NestedTextFieldState({required this.text, this.error = ""});

  NestedTextFieldState copyWith({String? text, String? error}) =>
      NestedTextFieldState(text: text ?? this.text, error: error ?? this.error);

  @override
  List<Object?> get props => [text, error];
}

/// This is a nestable text input widget that can communicate with its parent and child widgets using events
class NestableTextFieldWidget extends StatelessWidget {
  final String uniqueId;
  final Widget? child;

  const NestableTextFieldWidget({
    super.key,
    required this.uniqueId,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InterstateWidget<NestedTextFieldState>(
      id: uniqueId,
      widgetBuilder: (BuildContext context, NestedTextFieldState state, Widget? child,
          InterstateController<NestedTextFieldState> controller) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: state.text,
              decoration: InputDecoration(
                errorText: state.error,
                border: const OutlineInputBorder()
              ),
              onChanged: (text) {
                // We send a String as an event to the local controller
                controller.send(text);
                // Then we send a validation event up and down the widget tree
                controller.send(EventValidate(), up: true, down: true);
              },
              onEditingComplete: () {
                // We can query the validation state including the validation of our children at save time!
                if ((controller.send(EventValidate(), down: true).result as ValidationResponse).canSave == true) {
                  // We have valid data!
                  debugPrintSynchronously("VALID DATA:${state.text}");
                }
              },
            ),
            if (child != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 32.0),
                child: child,
              ),
          ],
        );
      },
      controllerInitializer: (String id, bubbleUpListener) {
        return InterstateController<NestedTextFieldState>(
          id: id,
          initialState: const NestedTextFieldState(text: ""),
          bubbleUpListener: bubbleUpListener,
          handlers: [
            /// This is a useful example of using the supplied EventValidate and ValidationResponse classes
            /// We can validate our state, and differentiate local errors and child errors
            EventHandler<EventValidate, NestedTextFieldState>(
                eventDataType: EventValidate,
                resultBuilder: (Event<EventValidate> event, NestedTextFieldState currentState,
                        List<Response<EventValidate, dynamic>> subResponses) =>
                    ValidationResponse.fromSubResponses(
                        // The validation error relates to the
                        validationError: currentState.text.isEmpty ? "Required!" : null,
                        // Here we could pass along an existing error message if we wanted, but we just want to replace
                        // any existing error messages, not propagate them
                        stateError: null,
                        // We pass along a set of all the child validation responses, and if we wanted we could do
                        // something with them
                        subResponses: subResponses),
                stateBuilder: (event, state, result, subresponses) {
                  // The result comes from the resultBuilder, so we know it is a ValidationResponse
                  final validationResp = result as ValidationResponse;

                  if (validationResp.dataValidationError != null) {
                    // If we have a local validation error, we update our state accordingly
                    return state.copyWith(error: validationResp.dataValidationError ?? "");
                  } else if (validationResp.childrenHaveErrors) {
                    // If our children have errors, we also report an error
                    return state.copyWith(error: "Children have errors!");
                  } else {
                    // Otherwise clear the error
                    return state.copyWith(error: "");
                  }
                }),
            /// This takes a String event and uses it to update the state text. Generally we would like to wrap something
            /// like this in its own StringUpdateEvent class, but for example code we can call this a demonstration of
            /// typing flexibility
            EventHandler<String, NestedTextFieldState>(
              eventDataType: String,
              resultBuilder: (_, __, ___) => null,
              stateBuilder: (event, currentState, ___, ____) => currentState.copyWith(text: event.data, error: ""),
            ),
          ],
        );
      },
      child: child,
    );
  }
}

/// This widget presents a button, which when clicked is replaced by a [NestableTextField] widget.
/// This swapping in of a widget, allows us to demonstrate how nested_text_field works in dynamic forms.
class AddNestedTextFieldWidget extends StatefulWidget {
  final String uniqueId;

  const AddNestedTextFieldWidget({super.key, required this.uniqueId});

  @override
  State<AddNestedTextFieldWidget> createState() => _AddNestedTextFieldWidgetState();
}

class _AddNestedTextFieldWidgetState extends State<AddNestedTextFieldWidget> {
  bool _showNested = false;

  @override
  Widget build(BuildContext context) {
    if (_showNested) {
      return NestableTextFieldWidget(
        uniqueId: widget.uniqueId,
        child: AddNestedTextFieldWidget(uniqueId: "${widget.uniqueId}.child"),
      );
    }
    return ElevatedButton(
        onPressed: () {
          setState(() {
            _showNested = true;
          });
        },
        child: const Text("Add nested text field"));
  }
}
