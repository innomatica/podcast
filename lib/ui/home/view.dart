import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/episode.dart';
import '../../util/constants.dart';
import '../../util/helpers.dart' show daysAgo, durationStr, sizeStr;
import '../../util/miniplayer.dart' show MiniPlayer;
import '../../util/widgets.dart' show FutureImage;
import 'model.dart';

class HomeView extends StatefulWidget {
  final HomeViewModel model;

  const HomeView({super.key, required this.model});

  @override
  State<HomeView> createState() => _HomeViewState();
}

enum ViewFilter { all, unplayed, liked }

class _HomeViewState extends State<HomeView> {
  // ignore: unused_field
  final _log = Logger('HomeView');
  int pageIndex = 0;
  ViewFilter filter = ViewFilter.unplayed;
  final _searchEngine = TextEditingController();
  Timer? sleepTimer;
  int sleepCount = 0;

  @override
  initState() {
    super.initState();
    widget.model.load();
  }

  @override
  void dispose() {
    _searchEngine.dispose();
    super.dispose();
  }

  void _rotateViewFilter() {
    filter =
        filter == ViewFilter.unplayed
            ? ViewFilter.all
            : filter == ViewFilter.all
            ? ViewFilter.liked
            : ViewFilter.unplayed;
    setState(() {});
  }

  void _setSleepTimer() {
    sleepCount =
        sleepCount <= 0
            ? sleepCount = 60
            : sleepCount > 45
            ? sleepCount = 45
            : sleepCount > 30
            ? sleepCount = 30
            : sleepCount > 10
            ? sleepCount = 10
            : sleepCount > 5
            ? sleepCount = 5
            : sleepCount = 0;
    if (sleepCount == 0) {
      sleepTimer?.cancel();
    } else {
      sleepTimer ??= Timer.periodic(Duration(seconds: 60), (timer) {
        sleepCount--;
        setState(() {});
        if (sleepCount <= 0) {
          timer.cancel();
          widget.model.stop();
          sleepTimer = null;
        }
      });
    }
    setState(() {});
  }

  Widget _buildEpisodeList(List<Episode> episodes) {
    final channelColor = Theme.of(context).colorScheme.secondary;
    final buttonColor = Theme.of(context).colorScheme.primary;
    return episodes.isNotEmpty
        ? ListView.separated(
          itemCount: episodes.length,
          separatorBuilder:
              (context, _) => const Divider(indent: 8, endIndent: 8, height: 0),
          itemBuilder: (context, index) {
            final episode = episodes[index];
            final downloaded = episode.downloaded == true;
            final played = episode.played == true;
            final liked = episode.liked == true;
            return ListTile(
              dense: true,
              enabled: !played,
              contentPadding: EdgeInsets.only(left: 8, right: 8, top: 8),
              title: Row(
                spacing: 8,
                children: [
                  // channel image
                  FutureImage(
                    future: widget.model.getChannelImage(episode),
                    width: 65,
                    height: 65,
                    opacity: played ? 0.5 : null,
                  ),
                  // channel title, pubdate, episode title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          spacing: 4.0,
                          children: [
                            // channel title
                            Expanded(
                              child: Text(
                                episode.channelTitle ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: channelColor),
                              ),
                            ),
                          ],
                        ),
                        // episode title
                        Text(
                          episode.title ?? 'unknown',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // pub date, duration/size, buttons
              subtitle: Row(
                // spacing: 4,
                children: [
                  // pub date
                  Text(
                    episode.published?.toIso8601String().split('T').first ?? '',
                  ),
                  SizedBox(width: 12),
                  // duration or size
                  episode.mediaDuration != null
                      ? Text(durationStr(episode.mediaDuration))
                      : Text(sizeStr(episode.mediaSize)),
                  Expanded(child: SizedBox()),
                  // download
                  IconButton(
                    icon: Icon(
                      Icons.download_rounded,
                      color: downloaded ? null : buttonColor,
                    ),
                    onPressed:
                        downloaded
                            ? null
                            : () => widget.model.downloadEpisode(episode),
                    visualDensity: VisualDensity.compact,
                  ),
                  // liked
                  IconButton(
                    icon: Icon(
                      liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_outline_rounded,
                      color: buttonColor,
                    ),
                    onPressed: () => widget.model.toggleLiked(episode),
                    visualDensity: VisualDensity.compact,
                  ),
                  // played
                  IconButton(
                    icon: Icon(
                      played
                          ? Icons.remove_done_rounded
                          : Icons.done_all_rounded,
                      color: buttonColor,
                    ),
                    onPressed: () => widget.model.togglePlayed(episode),
                    visualDensity: VisualDensity.compact,
                  ),
                  // add to playlist
                  IconButton(
                    icon: Icon(
                      Icons.playlist_add_rounded,
                      color: played ? null : buttonColor,
                    ),
                    onPressed:
                        played
                            ? null
                            : () => widget.model.addToPlayList(episode),
                    visualDensity: VisualDensity.compact,
                  ),
                  // play
                  IconButton(
                    icon: Icon(
                      Icons.headphones_rounded,
                      color: played ? null : buttonColor,
                    ),
                    onPressed:
                        played ? null : () => widget.model.playEpisode(episode),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              onTap: () async {
                context
                    .push(
                      Uri(
                        path: '/episode',
                        queryParameters: {'guid': episode.guid},
                      ).toString(),
                    )
                    .then((value) => widget.model.load());
              },
            );
          },
        )
        : Center(
          child: IconButton(
            icon: Image.asset(microphoneImage, width: 200, height: 200),
            onPressed:
                () => context
                    .push('/follow')
                    .then((value) => widget.model.load()),
          ),
        );
  }

  Widget _buildDrawer() {
    // _log.fine('buildDrawer.settings:${widget.model.settings}');
    final days = daysAgo(widget.model.settings?.lastUpdate);
    int retentionPeriod =
        widget.model.settings?.retentionPeriod ?? defaultRetentionPeriod;
    _searchEngine.text = widget.model.settings?.searchEngineUrl ?? '';
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              'Settings',
              style: TextStyle(
                fontSize: 24,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          ListTile(
            title: Text("Episode retention period"),
            subtitle: Row(
              children: [
                Text('keep episodes up to'),
                SizedBox(width: 8),
                DropdownButton<int>(
                  value: retentionPeriod,
                  items:
                      retentionDays
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.toString()),
                            ),
                          )
                          .toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      retentionPeriod = value;
                      await widget.model.updateRetentionPeriod(value);
                    }
                  },
                ),
                SizedBox(width: 4),
                Text('days'),
              ],
            ),
          ),
          ListTile(
            title: Text('Search engine'),
            subtitle: TextField(
              controller: _searchEngine,
              onSubmitted: (value) async {
                _log.fine(value);
                await widget.model.updateSearchEngine(value);
              },
            ),
          ),
          ListTile(
            title: Text('Last update'),
            subtitle: Text('$days day(s) ago'),
          ),
          ListTile(
            title: Text('Source code repository'),
            subtitle: Text('github'),
            onTap: () => launchUrl(Uri.parse(sourceRepository)),
          ),
          ListTile(
            title: Text('App version'),
            subtitle: Text(appVersion),
            onTap: () => launchUrl(Uri.parse(sourceRepository)),
          ),
          ListTile(
            title: Text('Developer'),
            subtitle: Text('innomatic'),
            onTap: () => launchUrl(Uri.parse(developerWebsite)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.model,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(appName),
            actions: [
              // sleep timer
              TextButton.icon(
                onPressed: () => _setSleepTimer(),
                icon: Icon(Icons.snooze_rounded, size: 24),
                iconAlignment: IconAlignment.end,
                label: Text(sleepCount > 0 ? sleepCount.toString() : ''),
              ),
              // episode filter
              IconButton(
                onPressed: () => _rotateViewFilter(),
                icon: Icon(
                  filter == ViewFilter.unplayed
                      ? Icons.filter_list_rounded
                      : filter == ViewFilter.all
                      ? Icons.menu_rounded
                      : Icons.favorite_outline_rounded,
                ),
              ),
              // subscriptions
              IconButton(
                onPressed: () {
                  context.go('/follow');
                },
                // onPressed: () async {
                //   await context.push('/follow');
                //   await widget.model.load();
                // },
                icon: Icon(Icons.subscriptions_rounded),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: widget.model.refreshData,
            child: _buildEpisodeList(
              filter == ViewFilter.unplayed
                  ? widget.model.unplayed
                  : filter == ViewFilter.liked
                  ? widget.model.liked
                  : widget.model.episodes,
            ),
          ),
          drawer: _buildDrawer(),
          // https://github.com/flutter/flutter/issues/50314
          bottomNavigationBar: MiniPlayer(),
        );
      },
    );
  }
}
