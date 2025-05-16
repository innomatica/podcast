import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart'
    show MediaItem;
import 'package:logging/logging.dart';
import 'package:xml/xml.dart';

import '../../model/channel.dart';
import '../../model/episode.dart';
import '../../model/feed.dart';
import '../../model/pcindex.dart';
import '../../model/settings.dart';
import '../../util/constants.dart';
import '../service/api/pcindex.dart';
import '../service/local/sqflite.dart';
import '../service/local/storage.dart';

class FeedRepository {
  // ignore: unused_field
  final DatabaseService _dbSrv;
  final StorageService _stSrv;
  final PCIndexService _pcIdx;
  final AudioPlayer _player;
  FeedRepository({
    required DatabaseService dbSrv,
    required StorageService stSrv,
    required PCIndexService pcIdx,
    required AudioPlayer player,
  }) : _dbSrv = dbSrv,
       _stSrv = stSrv,
       _pcIdx = pcIdx,
       _player = player;

  final _log = Logger('FeedRespository');

  AudioPlayer get player => _player;

  // Feed

  Future<List<Channel>> searchFeed(
    PCIndexSearch method,
    String keywords,
  ) async {
    return await _pcIdx.searchPodcasts(method, keywords);
  }

  Future<Feed?> fetchFeed(String url) async {
    // for testing replace url here
    // url = 'https://feeds.simplecast.com/EmVW7VGp'; // radiolab
    // _log.fine('fetch-url:$url');
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final document = XmlDocument.parse(utf8.decode(res.bodyBytes));
        // first children
        final children = document.childElements;
        if (children.isNotEmpty) {
          final root = children.first;
          // rss or atom
          if (root.name.toString() == 'rss') {
            return Feed.fromRss(root, url);
          } else if (root.name.toString() == 'feed') {
            return Feed.fromAtom(root, url);
          }
          // throw Exception('unknown feed format');
          _log.severe('unknown feed format');
        }
      }
      _log.severe('{res.statusCode} encountered');
      // throw Exception('{res.statusCode} encountered');
    } catch (e) {
      _log.severe(e.toString);
      // throw Exception(e.toString);
    }
    return null;
  }

  Future<Feed?> getFeed(String url) async {
    final channel = await getChannelByUrl(url);
    if (channel != null) {
      final episodes = await getEpisodesByChannel(channel.id!);
      return Feed(channel: channel, episodes: episodes);
    }
    return null;
  }

  Future<bool> subscribe(Feed feed) async {
    await createChannel(feed.channel);
    final channel = await getChannelByUrl(feed.channel.url);
    if (channel != null) {
      for (final episode in feed.episodes) {
        episode.channelId = channel.id;
        await createEpisode(episode);
      }
      return true;
    }
    return false;
  }

  Future<bool> unsubscribe(int channelId) async {
    _log.fine('unsubscribe');
    return await deleteChannel(channelId);
  }

  // Data

  Future<bool> refreshData({bool force = false}) async {
    _log.fine('refreshData: $force');
    bool updated = false;
    final channels = await getChannels();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    for (final channel in channels) {
      if (force ||
          channel.checked == null ||
          channel.checked!.isBefore(yesterday)) {
        _refreshChannel(channel);
        updated = true;
      }
    }
    await purgeOldEpisodes();
    return updated;
  }

  Future<bool> _refreshChannel(Channel channel) async {
    _log.fine('refreshChannel: ${channel.id}');
    final feed = await getFeed(channel.url);
    if (feed != null) {
      await createChannel(feed.channel);
      for (final episode in feed.episodes) {
        await createEpisode(episode);
      }
      return true;
    }
    return false;
  }

  // Channel

  Future<List<Channel>> getChannels() async {
    final rows = await _dbSrv.query("SELECT * FROM channels");
    return rows.map((e) => Channel.fromSqlite(e)).toList();
  }

  Future<Channel?> getChannelByUrl(String url) async {
    final rows = await _dbSrv.query(
      "SELECT * FROM channels WHERE url = '$url'",
    );
    return rows.isNotEmpty ? Channel.fromSqlite(rows.first) : null;
  }

  Future<bool> createChannel(Channel channel) async {
    return await _dbSrv.insert(
          "INSERT INTO channels(${channel.keys()}) VALUES(${channel.vals()})"
          " ON CONFLICT(url) DO UPDATE SET ${channel.sets()}",
        ) ==
        1;
  }

  Future<bool> updateChannel(Channel channel) async {
    if (channel.id != null) {
      return await _dbSrv.update(
            "UPDATE channels SET${channel.sets()} WHERE id=${channel.id}",
          ) ==
          1;
    }
    return false;
  }

  Future<bool> deleteChannel(int channelId) async {
    _log.fine('deleteChannel');
    await _stSrv.deleteDirectory(channelId);
    await deleteEpisodesByChannel(channelId);
    return await _dbSrv.delete("DELETE FROM channels WHERE id = $channelId") ==
        1;
  }

  // Future<int> purgeChannel(int? channelId) async {
  //   final ref =
  //       DateTime.now()
  //           .subtract(Duration(days: 90))
  //           .toIso8601String()
  //           .split("T")
  //           .first;
  //   return await _dbSrv.delete(
  //     "DELETE FROM episodes WHERE channel_id = $channelId "
  //     "AND DATETIME(published) < $ref ",
  //   );
  // }

  // Episode

  Future<List<Episode>> getEpisodes({int period = 90}) async {
    final start =
        DateTime.now()
            .subtract(Duration(days: period))
            .toIso8601String()
            .split('T')
            .first;
    final rows = await _dbSrv.query("""
      SELECT episodes.*, channels.title as channel_title, 
        channels.image_url as channel_image_url 
      FROM episodes 
      INNER JOIN channels ON channels.id=episodes.channel_id
      WHERE DATE(episodes.published) > '$start'
      ORDER BY episodes.published DESC""");
    return rows.map((e) => Episode.fromSqlite(e)).toList();
  }

  Future<List<Episode>> getEpisodesByChannel(
    int channelId, {
    int period = 90,
  }) async {
    final start =
        DateTime.now()
            .subtract(Duration(days: period))
            .toIso8601String()
            .split('T')
            .first;
    final rows = await _dbSrv.query("""
      SELECT episodes.*, channels.title as channel_title, 
        channels.image_url as channel_image_url 
      FROM episodes 
      INNER JOIN channels ON channels.id=episodes.channel_id
      WHERE channel_id = $channelId 
        AND DATE(episodes.published) > '$start'
      ORDER BY episodes.published DESC""");
    return rows.map((e) => Episode.fromSqlite(e)).toList();
  }

  Future<Episode?> getEpisodeByGuid(String? guid) async {
    final rows = await _dbSrv.query("""
      SELECT episodes.*, channels.title as channel_title, 
        channels.image_url as channel_image_url 
      FROM episodes 
      INNER JOIN channels ON channels.id=episodes.channel_id
      WHERE guid = '$guid'""");
    return rows.isNotEmpty ? Episode.fromSqlite(rows.first) : null;
  }

  Future<bool> createEpisode(Episode episode) async {
    return await _dbSrv.insert(
          "INSERT INTO episodes(${episode.keys()}) VALUES(${episode.vals()})"
          " ON CONFLICT(guid) DO UPDATE SET ${episode.sets()}",
        ) ==
        1;
  }

  Future<bool> updateEpisode(Episode episode) async {
    if (episode.id != null) {
      return await _dbSrv.update(
            "UPDATE episodes SET ${episode.sets()} WHERE id=${episode.id}",
          ) ==
          1;
    }
    return false;
  }

  Future<bool> deleteEpisodesByChannel(int channelId) async {
    return await _dbSrv.delete(
          "DELETE FROM episodes WHERE channel_id = $channelId",
        ) >
        0;
  }

  Future<int> purgeOldEpisodes() async {
    _log.fine('purge');
    final ref =
        DateTime.now()
            .subtract(Duration(days: 90))
            .toIso8601String()
            .split("T")
            .first;
    // TODO delete downloaded episode and its image from storage
    return await _dbSrv.delete(
      "DELETE FROM episodes "
      "WHERE DATETIME(published) < $ref AND liked != 1",
    );
  }

  Future<bool> setPlayed(int episodeId) async {
    return await _dbSrv.update(
          "UPDATE episodes SET played = TRUE WHERE id=$episodeId",
        ) ==
        1;
  }

  Future<bool> clearPlayed(int episodeId) async {
    return await _dbSrv.update(
          "UPDATE episodes SET played = FALSE WHERE id=$episodeId",
        ) ==
        1;
  }

  Future<bool> setLiked(int episodeId) async {
    return await _dbSrv.update(
          "UPDATE episodes SET liked = TRUE WHERE id=$episodeId",
        ) ==
        1;
  }

  Future<bool> clearLiked(int episodeId) async {
    return await _dbSrv.update(
          "UPDATE episodes SET liked = FALSE WHERE id=$episodeId",
        ) ==
        1;
  }

  Future updateBookmark(int episodeId, int bookmark) async {
    return await _dbSrv.update(
          "UPDATE episodes SET media_seek_pos = $bookmark WHERE id=$episodeId",
        ) ==
        1;
  }

  // Settings

  Future<Settings> getSettings() async {
    final rows = await _dbSrv.query("SELECT * from settings");
    if (rows.isEmpty) {
      final settings = Settings.init();
      await createSettings(settings);
      return settings;
    } else {
      return Settings.fromSqlite(rows.first);
    }
  }

  Future<bool> createSettings(Settings settings) async {
    return await _dbSrv.insert(
          "INSERT INTO settings(${settings.keys()}) VALUES(${settings.vals()})",
        ) ==
        1;
  }

  Future<bool> updateSettings(Settings settings) async {
    if (settings.id != null) {
      return await _dbSrv.update(
            "UPDATE settings SET ${settings.sets()} WHERE id=${settings.id}",
          ) ==
          1;
    }
    return false;
  }

  // Resources

  Future<bool> _downloadResource(
    int channelId,
    String url,
    String fname,
  ) async {
    bool flag = false;
    final client = http.Client();
    final req = http.Request('GET', Uri.parse(url));
    final res = await client.send(req);
    if (res.statusCode == 200) {
      _log.fine('downloading: $url to $fname');
      final file = await _stSrv.getFile(channelId, fname);
      await file.create(recursive: true);
      final sink = file.openWrite();
      await res.stream.pipe(sink);
      flag = true;
    }
    client.close();
    return flag;
  }

  Future<Uri?> _getAudioUri(int? channelId, String? url, String fname) async {
    if (channelId != null && url != null) {
      final file = await _stSrv.getFile(channelId, fname);
      if (file.existsSync()) {
        return Uri.file(file.path);
      }
      return Uri.parse(url);
    }
    return null;
  }

  Future<Uri?> _getImageUri(int? channelId, String? url) async {
    if (url != null) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        if (channelId != null) {
          final fname = uri.path.split('/').last;
          final file = await _stSrv.getFile(channelId, fname);
          if (file.existsSync() ||
              await _downloadResource(channelId, url, fname)) {
            return Uri.file(file.path);
          }
        }
        return uri;
      }
    }
    return null;
  }

  Future<ImageProvider> getEpisodeImage(Episode episode) async {
    final imageUri = await _getImageUri(
      episode.channelId,
      episode.imageUrl ?? episode.channelImageUrl,
    );
    if (imageUri != null) {
      return imageUri.scheme == 'file'
          ? FileImage(File(imageUri.path))
          : NetworkImage(imageUri.toString());
    }
    return AssetImage(microphoneImage);
  }

  Future<ImageProvider> getChannelImage(dynamic chOrEp) async {
    final imageUri =
        chOrEp is Channel
            ? await _getImageUri(chOrEp.id, chOrEp.imageUrl)
            : chOrEp is Episode
            ? await _getImageUri(chOrEp.channelId, chOrEp.channelImageUrl)
            : null;
    if (imageUri != null) {
      return imageUri.scheme == 'file'
          ? FileImage(File(imageUri.path))
          : NetworkImage(imageUri.toString());
    }
    return AssetImage(microphoneImage);
  }

  Future<bool> downloadEpisode(Episode episode) async {
    if (episode.id != null &&
        episode.channelId != null &&
        episode.mediaUrl != null) {
      if (await _downloadResource(
        episode.channelId!,
        episode.mediaUrl!,
        episode.mediaFname,
      )) {
        // download successful
        episode.downloaded = true;
        await updateEpisode(episode);
        return true;
      }
    }
    return false;
  }

  // Audio Player

  Future<IndexedAudioSource?> getAudioSource(Episode episode) async {
    final audioUri = await _getAudioUri(
      episode.channelId,
      episode.mediaUrl,
      episode.mediaFname,
    );

    if (audioUri != null) {
      return AudioSource.uri(
        audioUri,
        tag: MediaItem(
          id: episode.id.toString(),
          title: episode.title ?? "Title Unknown",
          album: episode.channelTitle ?? "Album Unknown",
          artist: episode.author,
          artUri: await _getImageUri(
            episode.channelId,
            episode.imageUrl ?? episode.channelImageUrl,
          ),
          extras: {},
        ),
      );
    }
    return null;
  }

  Future playEpisode(Episode episode) async {
    final audioSource = await getAudioSource(episode);
    // final audioSource = episode.toAudioSource();
    if (audioSource != null) {
      _log.fine('audioSource:${audioSource.tag}');
      await _player.pause();
      await _player.setAudioSource(audioSource);
      await _player.seek(Duration(seconds: episode.mediaSeekPos ?? 0));
      await _player.play();
    }
  }

  Future addToPlayList(Episode episode) async {
    final audioSource = await getAudioSource(episode);
    // final audioSource = episode.toAudioSource();
    if (audioSource != null) {
      _log.fine('audioSource:${audioSource.tag}');
      await _player.addAudioSource(audioSource);
    }
  }

  Future stop() async {
    await _player.stop();
  }
}
