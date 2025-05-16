import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../util/helpers.dart' show durationStr, sizeStr;
import '../../util/miniplayer.dart' show MiniPlayer;
import '../../util/widgets.dart';
import 'model.dart';

class EpisodeView extends StatelessWidget {
  final EpisodeViewModel model;
  EpisodeView({super.key, required this.model});
  // ignore: unused_field
  final _log = Logger("EpisodeView");

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final episode = model.episode;
        final kwdStyle = TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          fontSize: 12,
        );
        return episode != null
            ? Scaffold(
              appBar: AppBar(
                // back button
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () {
                    context.go('/');
                  },
                ),
                // title
                title: Text(
                  episode.channelTitle ?? 'Episode',
                  style: TextStyle(fontSize: 18),
                ),
                // actions
                actions: [
                  IconButton(
                    icon: Icon(Icons.content_copy_rounded),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(
                          text:
                              "Title: ${episode.title}\n"
                              "Author: ${episode.author}\n"
                              "Link: ${episode.link}",
                        ),
                      );
                    },
                  ),
                ],
              ),
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // image + episode.title, author, pubdate
                      Row(
                        spacing: 8,
                        children: [
                          // thumbnail
                          SizedBox(
                            width: 100,
                            child: FutureImage(
                              future: model.getEpisodeImage(episode),
                            ),
                          ),
                          // title, author
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // title
                                Text(
                                  episode.title ?? 'title',

                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                // author
                                Text(
                                  episode.author ?? 'author',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // keywords
                                episode.keywords != null
                                    ? Text(episode.keywords!, style: kwdStyle)
                                    : Text(
                                      episode.categories ?? '',
                                      style: kwdStyle,
                                    ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // pub date, size, link, playbutton
                      Row(
                        spacing: 8,
                        children: [
                          // pub date
                          Text(
                            episode.published
                                    ?.toIso8601String()
                                    .split('T')
                                    .first ??
                                '',
                          ),
                          // media duration or size
                          episode.mediaDuration != null
                              ? Text(durationStr(episode.mediaDuration))
                              : Text(sizeStr(episode.mediaSize)),
                          // link button
                          Expanded(child: SizedBox()),
                          IconButton(
                            icon: Icon(Icons.link_rounded),
                            onPressed:
                                episode.link != null
                                    ? () {
                                      launchUrl(Uri.parse(episode.link!));
                                    }
                                    : null,
                          ),
                          // play button
                          IconButton(
                            icon: Icon(Icons.headphones_rounded),
                            onPressed: () async {
                              await model.play();
                            },
                          ),
                        ],
                      ),
                      Html(
                        data: episode.description,
                        onLinkTap: (url, attributes, element) {
                          if (url != null) {
                            launchUrl(Uri.parse(url));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // https://github.com/flutter/flutter/issues/50314
              bottomNavigationBar: MiniPlayer(),
            )
            : const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(),
              ),
            );
      },
    );
  }
}
