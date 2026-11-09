import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

import 'farm_mapping.dart';
import 'work_order_mapping.dart';

abstract final class HttpStatus {
  static const badRequest = 400;
  static const unauthorized = 401;
  static const forbidden = 403;
  static const notFound = 404;
  static const conflict = 409;
  static const unprocessable = 422;
  static const serverError = 500;
}

extension DomainErrorMapping on DomainError {
  ProblemDto toProblem() => switch (this) {
    InvalidHectares() => const ProblemDto(
      status: HttpStatus.unprocessable,
      code: ErrorCodes.invalidHectares,
      title: 'Invalid hectares',
    ),
    InvalidFuelAmount(:final max) => ProblemDto(
      status: HttpStatus.unprocessable,
      code: ErrorCodes.invalidFuelAmount,
      title: 'Invalid fuel amount',
      max: max,
    ),
    InvalidMaterialQuantity() => const ProblemDto(
      status: HttpStatus.unprocessable,
      code: ErrorCodes.invalidMaterialQuantity,
      title: 'Invalid material quantity',
    ),
    ReasonRequired() => const ProblemDto(
      status: HttpStatus.unprocessable,
      code: ErrorCodes.reasonRequired,
      title: 'Reason required',
    ),
    ReasonTooLong(:final length, :final max) => ProblemDto(
      status: HttpStatus.unprocessable,
      code: ErrorCodes.reasonTooLong,
      title: 'Reason too long',
      value: length,
      max: max,
    ),
    InvalidInterval() => const ProblemDto(
      status: HttpStatus.unprocessable,
      code: ErrorCodes.invalidInterval,
      title: 'Invalid interval',
    ),
    ExceedsParcelArea(:final remaining) => ProblemDto(
      status: HttpStatus.unprocessable,
      code: ErrorCodes.exceedsParcelArea,
      title: 'Exceeds parcel area',
      remainingAres: remaining.toAres(),
    ),
    PreviousPhaseNotDone(:final required) => ProblemDto(
      status: HttpStatus.conflict,
      code: ErrorCodes.previousPhaseNotDone,
      title: 'Previous phase not done',
      operation: required.toDto(),
    ),
    InsufficientStock(:final item, :final missing) => ProblemDto(
      status: HttpStatus.conflict,
      code: ErrorCodes.insufficientStock,
      title: 'Insufficient stock',
      itemId: item.value,
      missing: missing,
    ),
    MaterialRequired() => const ProblemDto(
      status: HttpStatus.unprocessable,
      code: ErrorCodes.materialRequired,
      title: 'Material required',
    ),
    WorkerBusy() => const ProblemDto(status: HttpStatus.conflict, code: ErrorCodes.workerBusy, title: 'Worker busy'),
    MachineBusy() => const ProblemDto(status: HttpStatus.conflict, code: ErrorCodes.machineBusy, title: 'Machine busy'),
    InvalidTransition(:final from, :final to) => ProblemDto(
      status: HttpStatus.conflict,
      code: ErrorCodes.invalidTransition,
      title: 'Invalid transition',
      from: from.toDto(),
      to: to.toDto(),
    ),
    NotAllowed() => const ProblemDto(status: HttpStatus.forbidden, code: ErrorCodes.notAllowed, title: 'Not allowed'),
    NotFound() => const ProblemDto(status: HttpStatus.notFound, code: ErrorCodes.notFound, title: 'Not found'),
  };
}

T? _known<T>(T Function() read) {
  try {
    return read();
  } on FormatException {
    return null;
  }
}

Hectares? _remaining(int ares) => ares == 0 ? Hectares.zero : hectaresFromAres(ares).valueOrNull;

extension ProblemMapping on ProblemDto {
  DomainError? toDomainError() => switch (this) {
    ProblemDto(code: ErrorCodes.invalidHectares) => const InvalidHectares(),
    ProblemDto(code: ErrorCodes.invalidFuelAmount, :final max?) => InvalidFuelAmount(max: max),
    ProblemDto(code: ErrorCodes.invalidMaterialQuantity) => const InvalidMaterialQuantity(),
    ProblemDto(code: ErrorCodes.reasonRequired) => const ReasonRequired(),
    ProblemDto(code: ErrorCodes.reasonTooLong, :final value?, :final max?) => ReasonTooLong(value, max: max),
    ProblemDto(code: ErrorCodes.invalidInterval) => const InvalidInterval(),
    ProblemDto(code: ErrorCodes.exceedsParcelArea, :final remainingAres?) => switch (_remaining(remainingAres)) {
      final remaining? => ExceedsParcelArea(remaining),
      null => null,
    },
    ProblemDto(code: ErrorCodes.previousPhaseNotDone, :final operation?) => switch (_known(
      () => operationFromDto(operation),
    )) {
      final required? => PreviousPhaseNotDone(required),
      null => null,
    },
    ProblemDto(code: ErrorCodes.insufficientStock, :final itemId?, :final missing?) => InsufficientStock(
      item: StockItemId(itemId),
      missing: missing,
    ),
    ProblemDto(code: ErrorCodes.materialRequired) => const MaterialRequired(),
    ProblemDto(code: ErrorCodes.workerBusy) => const WorkerBusy(),
    ProblemDto(code: ErrorCodes.machineBusy) => const MachineBusy(),
    ProblemDto(code: ErrorCodes.invalidTransition, :final from?, :final to?) => switch ((
      _known(() => stageFromDto(from)),
      _known(() => stageFromDto(to)),
    )) {
      (final from?, final to?) => InvalidTransition(from: from, to: to),
      _ => null,
    },
    ProblemDto(code: ErrorCodes.notAllowed) => const NotAllowed(),
    ProblemDto(code: ErrorCodes.notFound) => const NotFound(),
    _ => null,
  };
}
