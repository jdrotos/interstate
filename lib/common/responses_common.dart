import 'package:equatable/equatable.dart';

import 'events_common.dart';
import '../response.dart';

/// A Response useful for passing validation data up the tree, maintaining a paper trail of all validation results in the tree.
class ValidationResponse extends Equatable {
  final String? dataValidationError;
  final String? stateError;

  final bool childrenCanSave;
  final bool childrenHaveErrors;

  const ValidationResponse({
    required this.dataValidationError,
    required this.stateError,
    required this.childrenCanSave,
    required this.childrenHaveErrors,
  });

  factory ValidationResponse.fromSubResponses(
      {required String? validationError,
      required String? stateError,
      required List<Response<EventValidate, dynamic>> subResponses}) {
    return ValidationResponse(
      dataValidationError: validationError,
      stateError: stateError,
      childrenCanSave: subResponses.isEmpty ||
          subResponses.every(
              (element) => (element.result is! ValidationResponse || (element.result as ValidationResponse).canSave)),
      childrenHaveErrors: subResponses.isNotEmpty &&
          subResponses.any(
              (element) => (element.result is ValidationResponse && (element.result as ValidationResponse).hasError)),
    );
  }

  bool get canSave => childrenCanSave && dataValidationError == null;

  bool get hasError => childrenHaveErrors || dataValidationError != null || stateError != null;

  @override
  List<Object?> get props => [dataValidationError, stateError, childrenCanSave, childrenHaveErrors];
}
