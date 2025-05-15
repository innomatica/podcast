import 'dart:convert';

// import 'package:just_audio/just_audio.dart';
// import 'package:just_audio_background/just_audio_background.dart'
//     show MediaItem;

import '../../util/helpers.dart' show sqlBool, sqlInt, sqlStr;

class Episode {
  int? id; // db specific: primary key
  String guid;
  String? title;
  String? subtitle;
  String? author;
  String? description;
  String? language;
  String? categories;
  String? keywords;
  DateTime? updated;
  DateTime? published;
  String? link;
  String? mediaUrl;
  String? mediaType;
  int? mediaSize;
  int? mediaDuration;
  int? mediaSeekPos;
  String? imageUrl;
  Map<String, dynamic>? extras;
  int? channelId;
  String? channelTitle;
  String? channelImageUrl;
  bool? downloaded;
  bool? played;
  bool? liked;

  // bool? mediaDownload;
  // String? channelImageUrl;

  Episode({
    this.id,
    required this.guid,
    this.title,
    this.subtitle,
    this.author,
    this.description,
    this.language,
    this.categories,
    this.keywords,
    this.updated,
    this.published,
    this.link,
    this.mediaUrl,
    this.mediaType,
    this.mediaSize,
    this.mediaDuration,
    this.mediaSeekPos,
    this.imageUrl,
    this.extras,
    this.channelId,
    this.channelTitle,
    this.channelImageUrl,
    this.downloaded,
    this.played,
    this.liked,
  });

  @override
  String toString() {
    return {
      "id": id,
      "guid": guid,
      "title": title,
      // "subtitle": subtitle?.substring(0, 20),
      "author": author,
      // "description": description?.substring(0, 20),
      "language": language,
      "categories": categories,
      "keywords": keywords,
      "updated": updated?.toIso8601String(),
      "published": published?.toIso8601String(),
      "link": link,
      "mediaUrl": mediaUrl,
      "mediaType": mediaType,
      "mediaSize": mediaSize,
      "mediaDuration": mediaDuration,
      "mediaSeekPos": mediaSeekPos,
      "imageUrl": imageUrl,
      "extras": extras,
      "channelId": channelId,
      "channelTitle": channelTitle,
      "channelImageUrl": channelImageUrl,
      "downloaded": downloaded,
      "played": played,
      "liked": liked,
    }.toString();
  }

  factory Episode.fromSqlite(Map<String, Object?> row) {
    return Episode(
      id: row['id'] as int,
      guid: row['guid'] as String,
      title: row['title'] as String?,
      subtitle: row['subtitle'] as String?,
      author: row['author'] as String?,
      description: row['description'] as String?,
      language: row['language'] as String?,
      categories: row['categories'] as String?,
      keywords: row['keywords'] as String?,
      updated:
          row['updated'] != null
              ? DateTime.tryParse(row['updated'] as String)
              : null,
      published:
          row['published'] != null
              ? DateTime.tryParse(row['published'] as String)
              : null,
      link: row['link'] as String?,
      mediaUrl: row['media_url'] as String?,
      mediaType: row['media_type'] as String?,
      mediaSize: row['media_size'] != null ? row['media_size'] as int : null,
      mediaDuration:
          row['media_duration'] != null ? row['media_duration'] as int : null,
      mediaSeekPos:
          row['media_seek_pos'] != null ? row['media_seek_pos'] as int : null,
      imageUrl: row['image_url'] as String?,
      extras: row['extra'] != null ? jsonDecode(row['extras'] as String) : null,
      channelId: row['channel_id'] != null ? row['channel_id'] as int : null,
      channelTitle: row['channel_title'] as String?,
      channelImageUrl: row['channel_image_url'] as String?,
      downloaded: row['downloaded'] == 1 ? true : false,
      played: row['played'] == 1 ? true : false,
      liked: row['liked'] == 1 ? true : false,
    );
  }

  Map<String, String> toSqlite() {
    return {
      "id": sqlInt(id),
      "guid": sqlStr(guid),
      "title": sqlStr(title),
      "subtitle": sqlStr(subtitle),
      "author": sqlStr(author),
      "description": sqlStr(description),
      "language": sqlStr(language),
      "categories": sqlStr(categories),
      "keywords": sqlStr(keywords),
      "updated": sqlStr(updated?.toIso8601String()),
      "published": sqlStr(published?.toIso8601String()),
      "link": sqlStr(link),
      "media_url": sqlStr(mediaUrl),
      "media_type": sqlStr(mediaType),
      "media_size": sqlInt(mediaSize),
      "media_duration": sqlInt(mediaDuration),
      "media_seek_pos": sqlInt(mediaSeekPos),
      "image_url": sqlStr(imageUrl),
      "extras": sqlStr(extras != null ? jsonEncode(extras) : null),
      "channel_id": sqlInt(channelId),
      "downloaded": sqlBool(downloaded),
      "played": sqlBool(played),
      "liked": sqlBool(liked),
    };
  }

  // IndexedAudioSource? toAudioSource() {
  //   return mediaUrl != null
  //       ? AudioSource.uri(
  //         Uri.parse(mediaUrl!),
  //         tag: MediaItem(
  //           id: guid,
  //           title: title ?? 'Unknown Title',
  //           album: channelTitle ?? 'Unknown Album',
  //           artist: author,
  //           artUri: imageUrl != null ? Uri.tryParse(imageUrl!) : null,
  //           extras: {},
  //         ),
  //       )
  //       : null;
  // }
}
