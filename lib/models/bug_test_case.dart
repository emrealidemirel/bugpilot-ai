import 'package:bugpilot_ai/models/bug_test_case_type.dart';

const _unset = Object();

class BugTestCase {
  const BugTestCase({
    required this.id,
    required this.title,
    required this.given,
    required this.when,
    required this.then,
    this.type,
  });

  factory BugTestCase.fromJson(Map<String, dynamic> json) {
    final type = json['type'];

    return BugTestCase(
      id: json['id'] as String,
      title: json['title'] as String,
      given: json['given'] as String,
      when: json['when'] as String,
      then: json['then'] as String,
      type: type == null ? null : bugTestCaseTypeFromJson(type as String),
    );
  }

  final String id;
  final String title;
  final String given;
  final String when;
  final String then;
  final BugTestCaseType? type;

  BugTestCase copyWith({
    String? id,
    String? title,
    String? given,
    String? when,
    String? then,
    Object? type = _unset,
  }) {
    return BugTestCase(
      id: id ?? this.id,
      title: title ?? this.title,
      given: given ?? this.given,
      when: when ?? this.when,
      then: then ?? this.then,
      type: identical(type, _unset) ? this.type : type as BugTestCaseType?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'given': given,
      'when': when,
      'then': then,
      'type': type?.jsonValue,
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BugTestCase &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            title == other.title &&
            given == other.given &&
            when == other.when &&
            then == other.then &&
            type == other.type;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, given, when, then, type);
  }
}
