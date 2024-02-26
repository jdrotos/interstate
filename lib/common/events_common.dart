import 'package:equatable/equatable.dart';

/// We define a handful of common events as a convenience, these do not need to be used.
abstract class CommonEvent {}

class EventSave extends CommonEvent {}

class EventCancel extends CommonEvent {}

class EventEdit extends CommonEvent {}

class EventSetEditable extends CommonEvent with EquatableMixin {
  final bool canEdit;

  EventSetEditable(this.canEdit);

  @override
  List<Object?> get props => [canEdit];
}

class EventValidate extends CommonEvent {}

class EventOnChange extends CommonEvent {}