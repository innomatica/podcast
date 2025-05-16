import 'dart:convert';

abstract class SqliteModel {
  Map<String, String> toSqlite();

  String sqlStr(String? input) {
    return input != null ? "'${input.replaceAll("'", "''")}'" : "NULL";
  }

  String sqlInt(int? input) {
    return input != null ? "$input" : "NULL";
  }

  String sqlBool(bool? input) {
    return input != null
        ? input
            ? "TRUE" // 1
            : "FALSE" // 0
        : "NULL";
  }

  String sqlTime(DateTime? input) {
    return input != null ? sqlStr(input.toIso8601String()) : "NULL";
  }

  String sqlJson(Map<String, dynamic>? input) {
    return input != null ? sqlStr(jsonEncode(input)) : "NULL";
  }

  String keys() => toSqlite().entries.map((e) => e.key).join(',');
  String vals() => toSqlite().entries.map((e) => e.value).join(',');
  String sets() =>
      toSqlite().entries.map((e) => "${e.key}=${e.value}").join(',');
}
