import 'json.dart';

final class ProblemDto {
  const ProblemDto({
    required this.status,
    required this.code,
    required this.title,
    this.value,
    this.max,
    this.remainingAres,
    this.itemId,
    this.missing,
    this.operation,
    this.from,
    this.to,
  });

  static const mediaType = 'application/problem+json';

  static String typeOf(String code) => 'tag:raf.rs,2026:agroflow/problem/$code';

  final int status;
  final String code;
  final String title;
  final int? value;
  final int? max;
  final int? remainingAres;
  final String? itemId;
  final int? missing;
  final String? operation;
  final String? from;
  final String? to;

  Map<String, Object?> toJson() => {
    'type': typeOf(code),
    'title': title,
    'status': status,
    'code': code,
    'value': ?value,
    'max': ?max,
    'remainingAres': ?remainingAres,
    'itemId': ?itemId,
    'missing': ?missing,
    'operation': ?operation,
    'from': ?from,
    'to': ?to,
  };

  factory ProblemDto.fromJson(Map<String, Object?> json) => ProblemDto(
    status: jsonInt(json, 'status'),
    code: jsonString(json, 'code'),
    title: jsonOptionalString(json, 'title') ?? '',
    value: jsonOptionalInt(json, 'value'),
    max: jsonOptionalInt(json, 'max'),
    remainingAres: jsonOptionalInt(json, 'remainingAres'),
    itemId: jsonOptionalString(json, 'itemId'),
    missing: jsonOptionalInt(json, 'missing'),
    operation: jsonOptionalString(json, 'operation'),
    from: jsonOptionalString(json, 'from'),
    to: jsonOptionalString(json, 'to'),
  );
}
