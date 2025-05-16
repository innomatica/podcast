import 'package:podcast/model/sqlite.dart';

import '../util/constants.dart';

class Settings extends SqliteModel {
  int? id;
  int? retentionPeriod;
  String? searchEngineUrl;
  DateTime? lastUpdate;

  Settings({
    this.id,
    this.retentionPeriod,
    this.searchEngineUrl,
    this.lastUpdate,
  });

  @override
  String toString() {
    return {
      "id": id,
      "retentionPeriod": retentionPeriod,
      "searchEngineUrl": searchEngineUrl,
      "lastUpdate": lastUpdate?.toIso8601String(),
    }.toString();
  }

  factory Settings.init() {
    return Settings(
      retentionPeriod: defaultRetentionPeriod,
      searchEngineUrl: defaultSearchEngineUrl,
      lastUpdate: DateTime.now(),
    );
  }

  factory Settings.fromSqlite(Map<String, Object?> row) {
    return Settings(
      id: row['id'] as int,
      retentionPeriod:
          row['retention_period'] != null
              ? row['retention_period'] as int
              : null,
      searchEngineUrl: row['search_engine_url'] as String?,
      lastUpdate:
          row['last_update'] != null
              ? DateTime.tryParse(row['last_update'] as String)
              : null,
    );
  }

  @override
  Map<String, String> toSqlite() {
    return {
      // "id": sqlInt(id),
      "retention_period": sqlInt(retentionPeriod),
      "search_engine_url": sqlStr(searchEngineUrl),
      "last_update": sqlTime(lastUpdate),
    };
  }
}
