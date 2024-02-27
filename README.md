<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

A library for managing state and communicating across dynamic forms and widget trees.

## Features

Widgets can pass events to other interstate widgets in the tree.

Widgets can query state from widgets below them in the tree.

Dynamically added widgets are automatically connected to the interstate.

Build dynamic forms without mirroring the structure in your data model.

Widgets in your form can manage their own states and children, without a higher level state object
to define structures.

![Sample](https://raw.githubusercontent.com/jdrotos/interstate/main/readme_assets/add_numbers_1.gif)

## Basic explainer

This is not intended as a replacement for a more powerful state management solution, this is generally
useful when constructing forms that have interesting dynamic properties and or convoluted validation
scenarios.

When a new InterstateWidget attaches to the tree, it registers itself with the nearest ancestor
InterstateWidget. This is how we pass events through the tree.

EventHandlers define which event types any particular InterstateWidget cares about.

At the time of firing an event, we can decide how we want to broadcast the event.

The event is always sent to the local handler.
- if the `down` flag is set to true: The event will be sent to every interstate widget below us in the tree.
- if the `up` flag is set to true: The event will be sent to up the tree until the root InterstateWidget is reached. 
- if the `span` flag is set to true (with the `up` flag also set to true): The event will travel up the tree, and then back down any branch it encounters.

## Getting started

### 1. Depend on it

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  interstate: '^1.0.0'
```

#### 2. Install it

You can install packages from the command line:

```bash
$ pub get
..
```

Alternatively, your editor might support pub. Check the docs for your editor to learn more.

#### 3. Import it

Now in your Dart code, you can use:

```Dart
import 'package:interstate/interstate.dart';
```

## Usage

### 1. Define a state object

```dart
class NestedTextFieldState extends Equatable {
  final String text;
  final String error;

  const NestedTextFieldState({required this.text, this.error = ""});

  NestedTextFieldState copyWith({String? text, String? error}) =>
      NestedTextFieldState(text: text ?? this.text, error: error ?? this.error);

  @override
  List<Object?> get props => [text, error];
}
```

### 2. Define an interstate widget

```dart 
InterstateWidget<NestedTextFieldState>(
      id: uniqueId,
      widgetBuilder: (BuildContext context, NestedTextFieldState state, Widget? child, InterstateController<NestedTextFieldState> controller) {
            return TextFormField(
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
        );
      },
      controllerInitializer: (String id, bubbleUpListener) {
        return InterstateController<NestedTextFieldState>(
          id: id,
          initialState: const NestedTextFieldState(text: ""),
          bubbleUpListener: bubbleUpListener,
          handlers: [],
        );
      },
      child: child,
    );
```

### 3. Define handlers to respond to events

```dart 
...
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
...
```

## Additional information

https://github.com/jdrotos/interstate
