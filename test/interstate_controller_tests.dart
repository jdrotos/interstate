import 'package:flutter_test/flutter_test.dart';
import 'package:interstate/interstate.dart';
import 'package:interstate/response.dart';

import 'number_events.dart';
import 'number_state.dart';



void main() {
  /// We create a tree like:
  ///      A
  ///     / \
  ///    AA  AB
  ///       /  \
  ///     ABA   ABB
  ///
  ///  We wire things up manually here, as to just test the controller.
  ///  The widgets should get tested independently


  InterstateController<NumberState> genController(String id, InterstateController<NumberState>? parent, int initialStateNumber,
      {List<EventHandler<dynamic, NumberState>> additionalHandlers = const []}) {
    void bub<E>(Response<E, NumberState> resp) {
      parent?.onBubbleUp(resp);
    }
    return InterstateController<NumberState>(id: id, initialState: NumberState(initialStateNumber), bubbleUpListener: bub,
        handlers: <EventHandler<dynamic, NumberState>>[
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
        ] + additionalHandlers);
  }

  var addHandler = EventHandler<AddNumberEvent, NumberState>(
      eventDataType: AddNumberEvent,
      resultBuilder: (event, state, subResponses) {
        return state.number + event.data.number;
      },
      stateBuilder: (event, currentState, result, subResponses) {
        return NumberState(result);
      });

  late InterstateController<NumberState> a;
  late InterstateController<NumberState> aa;
  late InterstateController<NumberState> ab;
  late InterstateController<NumberState> aba;
  late InterstateController<NumberState> abb;

  reset() {
    a = genController("A", null, 0, additionalHandlers: [addHandler]);
    aa = genController("AA", a, 0 ,additionalHandlers: [addHandler]);
    ab = genController("AB", a, 0,);
    aba = genController("ABA", ab, 0, additionalHandlers: [addHandler]);
    abb = genController("ABB", ab, 0);

    a.registerInnerInterstate(aa);
    a.registerInnerInterstate(ab);
    ab.registerInnerInterstate(aba);
    ab.registerInnerInterstate(abb);
  }


  test("initial state", () {
    reset();
    expect(a.state.value, const NumberState(0));
    expect(aa.state.value, const NumberState(0));
    expect(ab.state.value, const NumberState(0));
    expect(aba.state.value, const NumberState(0));
    expect(abb.state.value, const NumberState(0));
  });

  group("Communication Tests (checking the up/down/span comms)", () {
    test("set local top", () {
      reset();
      a.send(const SetNumberEvent(1));
      expect(a.state.value, const NumberState(1));
      expect(aa.state.value, const NumberState(0));
      expect(ab.state.value, const NumberState(0));
      expect(aba.state.value, const NumberState(0));
      expect(abb.state.value, const NumberState(0));
    });

    test("set local middle", () {
      reset();
      ab.send(const SetNumberEvent(1));
      expect(a.state.value, const NumberState(0));
      expect(aa.state.value, const NumberState(0));
      expect(ab.state.value, const NumberState(1));
      expect(aba.state.value, const NumberState(0));
      expect(abb.state.value, const NumberState(0));
    });

    test("set local bottom", () {
      reset();
      abb.send(const SetNumberEvent(1));
      expect(a.state.value, const NumberState(0));
      expect(aa.state.value, const NumberState(0));
      expect(ab.state.value, const NumberState(0));
      expect(aba.state.value, const NumberState(0));
      expect(abb.state.value, const NumberState(1));
    });

    test("set down", () {
      reset();
      a.send(const SetNumberEvent(1), down: true);
      expect(a.state.value, const NumberState(1));
      expect(aa.state.value, const NumberState(1));
      expect(ab.state.value, const NumberState(1));
      expect(aba.state.value, const NumberState(1));
      expect(abb.state.value, const NumberState(1));
    });

    test("set up one", () {
      reset();
      aa.send(const SetNumberEvent(2), up: true);
      expect(a.state.value, const NumberState(2));
      expect(aa.state.value, const NumberState(2));
      expect(ab.state.value, const NumberState(0));
      expect(aba.state.value, const NumberState(0));
      expect(abb.state.value, const NumberState(0));
    });

    test("set up from bottom", () {
      reset();
      abb.send(const SetNumberEvent(2), up: true);
      expect(a.state.value, const NumberState(2));
      expect(aa.state.value, const NumberState(0));
      expect(ab.state.value, const NumberState(2));
      expect(aba.state.value, const NumberState(0));
      expect(abb.state.value, const NumberState(2));
    });

    test("set up and down", () {
      reset();
      ab.send(const SetNumberEvent(2), up: true, down: true);
      expect(a.state.value, const NumberState(2));
      expect(aa.state.value, const NumberState(0));
      expect(ab.state.value, const NumberState(2));
      expect(aba.state.value, const NumberState(2));
      expect(abb.state.value, const NumberState(2));
    });

    test("set up span", () {
      reset();
      ab.send(const SetNumberEvent(2), up: true, span: true);
      expect(a.state.value, const NumberState(2));
      expect(aa.state.value, const NumberState(2));
      expect(ab.state.value, const NumberState(2));
      expect(aba.state.value, const NumberState(0));
      expect(abb.state.value, const NumberState(0));
    });

    test("set up span from bottom", () {
      reset();
      abb.send(const SetNumberEvent(2), up: true, span: true);
      expect(a.state.value, const NumberState(2));
      expect(aa.state.value, const NumberState(2));
      expect(ab.state.value, const NumberState(2));
      expect(aba.state.value, const NumberState(2));
      expect(abb.state.value, const NumberState(2));
    });

    test("set up down span from top", () {
      reset();
      a.send(const SetNumberEvent(2), up: true, down: true, span: true,);
      expect(a.state.value, const NumberState(2));
      expect(aa.state.value, const NumberState(2));
      expect(ab.state.value, const NumberState(2));
      expect(aba.state.value, const NumberState(2));
      expect(abb.state.value, const NumberState(2));
    });

    test("set up down span from middle", () {
      reset();
      ab.send(const SetNumberEvent(2), up: true, down: true, span: true,);
      expect(a.state.value, const NumberState(2));
      expect(aa.state.value, const NumberState(2));
      expect(ab.state.value, const NumberState(2));
      expect(aba.state.value, const NumberState(2));
      expect(abb.state.value, const NumberState(2));
    });

    test("set up down span from bottom", () {
      reset();
      abb.send(const SetNumberEvent(2), up: true, down: true, span: true,);
      expect(a.state.value, const NumberState(2));
      expect(aa.state.value, const NumberState(2));
      expect(ab.state.value, const NumberState(2));
      expect(aba.state.value, const NumberState(2));
      expect(abb.state.value, const NumberState(2));
    });
  });

  group("Sparse Handler Tests (some of the controllers handle the event others don't)", () {
    // NOTE: a, aa, and aba handle AddNumberEvent

    test("add test (to ensure the event itself works right)", () {
      reset();
      a.send(const AddNumberEvent(2));
      expect(a.state.value, const NumberState(2));
      a.send(const AddNumberEvent(2));
      expect(a.state.value, const NumberState(4));
    });

    test("add local", () {
      reset();
      aa.send(const AddNumberEvent(2),);
      expect(a.state.value, const NumberState(0));
      expect(aa.state.value, const NumberState(2));
      expect(ab.state.value, const NumberState(0));
      expect(aba.state.value, const NumberState(0));
      expect(abb.state.value, const NumberState(0));
    });

    test("add down pass through (the event must pass through ab which does not handle it)", () {
      reset();
      a.send(const AddNumberEvent(2),down: true);
      expect(a.state.value, const NumberState(2));
      expect(aa.state.value, const NumberState(2));
      expect(ab.state.value, const NumberState(0));
      expect(aba.state.value, const NumberState(2));
      expect(abb.state.value, const NumberState(0));
    });

    test("add down uninterested (calls event on controller, that doesn't handle it, but will still pass it along)", () {
      reset();
      ab.send(const AddNumberEvent(2),down: true);
      expect(a.state.value, const NumberState(0));
      expect(aa.state.value, const NumberState(0));
      expect(ab.state.value, const NumberState(0));
      expect(aba.state.value, const NumberState(2));
      expect(abb.state.value, const NumberState(0));
    });

    test("add up", () {
      reset();
      aa.send(const AddNumberEvent(2),up: true);
      expect(a.state.value, const NumberState(2));
      expect(aa.state.value, const NumberState(2));
      expect(ab.state.value, const NumberState(0));
      expect(aba.state.value, const NumberState(0));
      expect(abb.state.value, const NumberState(0));
    });

    test("add up pass through (event must pass through ab which does not handle it)", () {
      reset();
      aba.send(const AddNumberEvent(2),up: true);
      expect(a.state.value, const NumberState(2));
      expect(aa.state.value, const NumberState(0));
      expect(ab.state.value, const NumberState(0));
      expect(aba.state.value, const NumberState(2));
      expect(abb.state.value, const NumberState(0));
    });

    test("add up uninterested (calls event on controller, that doesn't handle it, but will still pass it along)", () {
      reset();
      abb.send(const AddNumberEvent(2),up: true);
      expect(a.state.value, const NumberState(2));
      expect(aa.state.value, const NumberState(0));
      expect(ab.state.value, const NumberState(0));
      expect(aba.state.value, const NumberState(0));
      expect(abb.state.value, const NumberState(0));
    });
  });

  group("Sub response Tests (where we count on the results of lower tests)", () {
    test("accumulate identity test (to ensure the event itself works right)", () {
      reset();
      a.send(AccumulateEvent());
      expect(a.state.value, const NumberState(0));
      a.send(const SetNumberEvent(2));
      a.send(AccumulateEvent());
      expect(a.state.value, const NumberState(2));
    });

    test("accumulate local (so there are no sub responses)", () {
      reset();
      a.send(const SetNumberEvent(2));
      a.send(AccumulateEvent(),);
      expect(a.state.value, const NumberState(2));
      expect(aa.state.value, const NumberState(0));
      expect(ab.state.value, const NumberState(0));
      expect(aba.state.value, const NumberState(0));
      expect(abb.state.value, const NumberState(0));
    });

    test("accumulate tree", () {
      reset();
      a.send(const SetNumberEvent(1));
      aa.send(const SetNumberEvent(2));
      ab.send(const SetNumberEvent(2));
      aba.send(const SetNumberEvent(3));
      abb.send(const SetNumberEvent(3));
      a.send(AccumulateEvent(),down: true);
      expect(a.state.value, const NumberState(11)); // 3 + 3 + 2 + 2 + 1
      expect(aa.state.value, const NumberState(2));
      expect(ab.state.value, const NumberState(8)); // 3 + 3 + 2
      expect(aba.state.value, const NumberState(3));
      expect(abb.state.value, const NumberState(3));
    });

    test("accumulate sub tree (so there are no sub responses)", () {
      reset();
      a.send(const SetNumberEvent(1));
      aa.send(const SetNumberEvent(2));
      ab.send(const SetNumberEvent(2));
      aba.send(const SetNumberEvent(3));
      abb.send(const SetNumberEvent(3));
      // NOTE: sending from ab this time
      ab.send(AccumulateEvent(),down: true);
      expect(a.state.value, const NumberState(1));
      expect(aa.state.value, const NumberState(2));
      expect(ab.state.value, const NumberState(8)); // 3 + 3 + 2
      expect(aba.state.value, const NumberState(3));
      expect(abb.state.value, const NumberState(3));
    });

    test("accumulate tree multi", () {
      reset();
      a.send(const SetNumberEvent(1));
      aa.send(const SetNumberEvent(2));
      ab.send(const SetNumberEvent(2));
      aba.send(const SetNumberEvent(3));
      abb.send(const SetNumberEvent(3));
      a.send(AccumulateEvent(),down: true);
      expect(a.state.value, const NumberState(11)); // 3 + 3 + 2 + 2 + 1
      expect(aa.state.value, const NumberState(2));
      expect(ab.state.value, const NumberState(8)); // 3 + 3 + 2
      expect(aba.state.value, const NumberState(3));
      expect(abb.state.value, const NumberState(3));
      a.send(AccumulateEvent(),down: true);
      expect(a.state.value, const NumberState(27)); // 14 + 2 + 11
      expect(aa.state.value, const NumberState(2));
      expect(ab.state.value, const NumberState(14)); // 3 + 3 + 8
      expect(aba.state.value, const NumberState(3));
      expect(abb.state.value, const NumberState(3));
    });

    test("accumulate from the bottom", () {
      reset();
      a.send(const SetNumberEvent(1));
      aa.send(const SetNumberEvent(2));
      ab.send(const SetNumberEvent(2));
      aba.send(const SetNumberEvent(3));
      abb.send(const SetNumberEvent(3));
      aba.send(AccumulateEvent(),down: true, up: true, span: true);
      expect(a.state.value, const NumberState(11)); // 3 + 3 + 2 + 2 + 1
      expect(aa.state.value, const NumberState(2));
      expect(ab.state.value, const NumberState(8)); // 3 + 3 + 2
      expect(aba.state.value, const NumberState(3));
      expect(abb.state.value, const NumberState(3));
    });
  });
}