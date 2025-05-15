import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';

import '../../data/repository/feed.dart';
import '../../model/episode.dart';

class HomeViewModel extends ChangeNotifier {
  final FeedRepository _feedRepo;
  final AudioPlayer _player;
  HomeViewModel({required FeedRepository feedRepo, required AudioPlayer player})
    : _feedRepo = feedRepo,
      _player = player {
    _init();
  }

  // ignore: unused_field
  final _log = Logger('HomeModel');
  List<Episode> _episodes = [];

  List<Episode> get episodes => _episodes;
  List<Episode> get unplayed =>
      _episodes.where((e) => e.played != true).toList();
  List<Episode> get liked => _episodes.where((e) => e.liked == true).toList();

  void _init() {
    _player.playerStateStream.listen((event) async {
      // _log.fine('playerState: $event');
      if (event.playing == false &&
          event.processingState == ProcessingState.ready) {
        // paused
        await _updateBookmark();
      }
      if (event.playing == true &&
          event.processingState == ProcessingState.buffering) {
        // seek
        _updateBookmark();
      }
    });
  }

  Future _updateBookmark() async {
    final index = _player.currentIndex;
    final sequence = _player.sequence;
    final position = _player.position;
    final duration = _player.duration;

    if (index != null &&
        sequence.isNotEmpty &&
        sequence.length > index &&
        position > Duration(seconds: 30)) {
      final source = sequence[index];
      if (duration != null && (position + Duration(seconds: 30) > duration)) {
        // end of the media
        _log.fine('set played: ${source.tag}');
        await _feedRepo.setPlayed(int.parse(source.tag.id));
        await load();
      } else {
        // paused or seek
        _log.fine('update bookmark: ${source.tag}');
        await _feedRepo.updateBookmark(
          int.parse(source.tag.id),
          position.inSeconds,
        );
      }
    }
  }

  Future load() async {
    _log.fine('load');
    _episodes = await _feedRepo.getEpisodes();
    notifyListeners();
  }

  Future<ImageProvider> getChannelImage(Episode episode) async {
    return _feedRepo.getChannelImage(episode);
  }

  Future playEpisode(Episode episode) async {
    await _feedRepo.playEpisode(episode);
  }

  Future addToPlayList(Episode episode) async {
    await _feedRepo.addToPlayList(episode);
    // notification done via player.sequenceStream
    // notifyListeners();
  }

  Future togglePlayed(Episode episode) async {
    if (episode.id != null) {
      if (episode.played == true) {
        await _feedRepo.clearPlayed(episode.id!);
      } else {
        await _feedRepo.setPlayed(episode.id!);
      }
      await load();
      // _episodes = await _feedRepo.getEpisodes();
      // notifyListeners();
    }
  }

  Future toggleLiked(Episode episode) async {
    if (episode.id != null) {
      if (episode.liked == true) {
        await _feedRepo.clearLiked(episode.id!);
      } else {
        await _feedRepo.setLiked(episode.id!);
      }
      await load();
      // _episodes = await _feedRepo.getEpisodes();
      // notifyListeners();
    }
  }

  Future downloadEpisode(Episode episode) async {
    await _feedRepo.downloadEpisode(episode);
    await load();
    // _episodes = await _feedRepo.getEpisodes();
    // notifyListeners();
  }

  Future refreshData() async {
    await _feedRepo.refreshData(force: true);
    load();
  }

  Future stop() async {
    await _feedRepo.stop();
  }
}
