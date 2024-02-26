import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interstate/interstate.dart';

import 'number_events.dart';
import 'number_state.dart';

typedef InterstateCallback = void Function(InterstateController controller);
class InterstateFinder extends StatelessWidget{
  final InterstateCallback callback;
  final Widget? child;
  const InterstateFinder({super.key, required this.callback, this.child});
  @override
  Widget build(BuildContext context) {
    callback(Interstate.of(context)!.controller);
    return Container(child: child);
  }
}

void main() {
  Widget genInterstateWidget(String id, {int? defState, Widget? child}) {
    return InterstateWidget<NumberState>(id: id, widgetBuilder: (context, state, child, controller) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text("${state.number}"),
        ] + (child == null ? [] : [child]),
      );
    }, controllerInitializer: (id, bubbleUpListener) {
      return InterstateController(
          id: id, initialState: NumberState(defState ?? 0), bubbleUpListener: bubbleUpListener, handlers: [
        EventHandler<SetNumberEvent, NumberState>(
          eventDataType: SetNumberEvent,
          resultBuilder: (_, __, ___) => null,
          stateBuilder: (event, currentState, result, subResponses) => NumberState(event.data.number),
        ),
        EventHandler<AccumulateEvent, NumberState>(
            eventDataType: AccumulateEvent,
            resultBuilder: (event, state, subResponses) {
              int subTotal = 0;
              for (var sub in subResponses) {
                var resultingStateNum = (sub.resultingState as NumberState).number;
                subTotal += resultingStateNum;
              }
              subTotal += state.number;
              return subTotal;
            },
            stateBuilder: (event, currentState, result, subResponses) {
              return NumberState(result);
            }
        )
      ]);
    }, child: child,);
  }

  testWidgets('Solo Interstate', (WidgetTester tester) async {
    var a = MaterialApp(home: genInterstateWidget("a"));

    // Build our app and trigger a frame.
    await tester.pumpWidget(a);
    expect(find.text('0'), findsOneWidget);
    expect(find.byKey(InterstateWidget.genKey("a")), findsOneWidget);
  });

  testWidgets('Nested Interstate', (WidgetTester tester) async {
    var interstateAA = genInterstateWidget("aa");
    var interstateA = genInterstateWidget("a",child: interstateAA);

    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(home: interstateA));
    expect(find.text('0'), findsNWidgets(2));
    expect(find.byKey(InterstateWidget.genKey("a")), findsOneWidget);
    expect(find.byKey(InterstateWidget.genKey("aa")), findsOneWidget);
  });

  testWidgets('Root Local event', (WidgetTester tester) async {
    InterstateController<NumberState>? controller;
    var interstateAA = genInterstateWidget("aa");
    var interstateA = genInterstateWidget("a",child: InterstateFinder(callback: (interstateController){
      controller = interstateController as InterstateController<NumberState>;
    }, child: interstateAA));

    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(home: interstateA));
    expect(find.text('0'), findsNWidgets(2));
    expect(find.byKey(InterstateWidget.genKey("a")), findsOneWidget);
    expect(find.byKey(InterstateWidget.genKey("aa")), findsOneWidget);

    controller!.send(const SetNumberEvent(2));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('Leaf Local event', (WidgetTester tester) async {
    InterstateController<NumberState>? controller;
    var interstateAA = genInterstateWidget("aa",child: InterstateFinder(callback: (interstateController){
      controller = interstateController as InterstateController<NumberState>;
    }));
    var interstateA = genInterstateWidget("a", child: interstateAA);

    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(home: interstateA));
    expect(find.text('0'), findsNWidgets(2));
    expect(find.byKey(InterstateWidget.genKey("a")), findsOneWidget);
    expect(find.byKey(InterstateWidget.genKey("aa")), findsOneWidget);

    controller!.send(const SetNumberEvent(2));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('Down event', (WidgetTester tester) async {
    InterstateController<NumberState>? controller;
    var interstateAA = genInterstateWidget("aa");
    var interstateA = genInterstateWidget("a",child: InterstateFinder(callback: (interstateController){
      controller = interstateController as InterstateController<NumberState>;
    }, child: interstateAA));

    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(home: interstateA));
    expect(find.text('0'), findsNWidgets(2));
    expect(find.byKey(InterstateWidget.genKey("a")), findsOneWidget);
    expect(find.byKey(InterstateWidget.genKey("aa")), findsOneWidget);

    controller!.send(const SetNumberEvent(2), down: true);
    await tester.pumpAndSettle();

    expect(find.text('2'), findsNWidgets(2));
  });

  testWidgets('Down event multi', (WidgetTester tester) async {
    InterstateController<NumberState>? controller;
    var interstateAA = genInterstateWidget("aa");
    var interstateAB = genInterstateWidget("ab");
    var interstateA = genInterstateWidget("a",child: InterstateFinder(callback: (interstateController){
      controller = interstateController as InterstateController<NumberState>;
    }, child: Column(children: [interstateAA, interstateAB])));

    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(home: interstateA));
    expect(find.text('0'), findsNWidgets(3));
    expect(find.byKey(InterstateWidget.genKey("a")), findsOneWidget);
    expect(find.byKey(InterstateWidget.genKey("aa")), findsOneWidget);
    expect(find.byKey(InterstateWidget.genKey("ab")), findsOneWidget);

    controller!.send(const SetNumberEvent(2), down: true);
    await tester.pumpAndSettle();

    expect(find.text('2'), findsNWidgets(3));
  });

  testWidgets('Up event', (WidgetTester tester) async {
    InterstateController<NumberState>? controller;
    var interstateAA = genInterstateWidget("aa", child: InterstateFinder(callback: (interstateController){
      controller = interstateController as InterstateController<NumberState>;
    },));
    var interstateA = genInterstateWidget("a",child: interstateAA);

    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(home: interstateA));
    expect(find.text('0'), findsNWidgets(2));
    expect(find.byKey(InterstateWidget.genKey("a")), findsOneWidget);
    expect(find.byKey(InterstateWidget.genKey("aa")), findsOneWidget);

    controller!.send(const SetNumberEvent(2), up: true);
    await tester.pumpAndSettle();

    expect(find.text('2'), findsNWidgets(2));
  });

  testWidgets('Up event doesnt span by default', (WidgetTester tester) async {
    InterstateController<NumberState>? controller;
    var interstateAA = genInterstateWidget("aa", child: InterstateFinder(callback: (interstateController){
      controller = interstateController as InterstateController<NumberState>;
    },));
    var interstateAB = genInterstateWidget("ab");
    var interstateA = genInterstateWidget("a",child: Column(children: [interstateAA, interstateAB]));

    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(home: interstateA));
    expect(find.text('0'), findsNWidgets(3));
    expect(find.byKey(InterstateWidget.genKey("a")), findsOneWidget);
    expect(find.byKey(InterstateWidget.genKey("aa")), findsOneWidget);
    expect(find.byKey(InterstateWidget.genKey("ab")), findsOneWidget);

    controller!.send(const SetNumberEvent(2), up: true);
    await tester.pumpAndSettle();

    expect(find.text('2'), findsNWidgets(2));
  });

  testWidgets('Up event with span', (WidgetTester tester) async {
    InterstateController<NumberState>? controller;
    var interstateAA = genInterstateWidget("aa", child: InterstateFinder(callback: (interstateController){
      controller = interstateController as InterstateController<NumberState>;
    },));
    var interstateAB = genInterstateWidget("ab");
    var interstateA = genInterstateWidget("a",child: Column(children: [interstateAA, interstateAB]));

    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(home: interstateA));
    expect(find.text('0'), findsNWidgets(3));
    expect(find.byKey(InterstateWidget.genKey("a")), findsOneWidget);
    expect(find.byKey(InterstateWidget.genKey("aa")), findsOneWidget);
    expect(find.byKey(InterstateWidget.genKey("ab")), findsOneWidget);

    controller!.send(const SetNumberEvent(2), up: true, span: true);
    await tester.pumpAndSettle();

    expect(find.text('2'), findsNWidgets(3));
  });
}
