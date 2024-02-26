import 'package:flutter/foundation.dart';
import 'package:interstate/response.dart';

class InterstateUtils {
  static Response<EventType, StateType> requireResponse<EventType, StateType>(
      String id, List<Response<EventType, dynamic>> subResponses) {
    return getResponse(id, subResponses)!;
  }

  static Response<EventType, StateType>? getResponse<EventType, StateType>(
      String id, List<Response<EventType, dynamic>> subResponses) {
    var filtered = subResponses.whereType<Response<EventType, StateType>>().where((resp) => resp.originId == id);
    if (filtered.isNotEmpty) {
      debugPrintSynchronously("filtered:$filtered");
      final first = filtered.first;
      final allSame = filtered.every((element) => element == first);
      if (!allSame) {
        debugPrintSynchronously("varying filtered:$filtered");
        throw Exception("Duplicate ids! Different events! Error!");
      }
      if(filtered.length > 1){
        debugPrintSynchronously("There are duplicates of this event:$first");
      }
      return first;
    }

    var subSubs = subResponses.whereType<InterstateResponse<EventType, dynamic>>().fold(
        <Response<EventType, dynamic>>[], (previousValue, element) => previousValue + element.downStreamResponses);
    if (subSubs.isEmpty) {
      return null;
    }
    return getResponse(id, subSubs);
  }
}
