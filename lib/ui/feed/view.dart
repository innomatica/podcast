import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../model/feed.dart';
import '../../util/widgets.dart';
import 'model.dart';

class FeedView extends StatelessWidget {
  final FeedViewModel model;
  FeedView({super.key, required this.model});
  // ignore: unused_field
  final _log = Logger('FeedView');

  Widget _buildError(String error) {
    return Center(child: Text(error));
  }

  Widget _buildFeedInfo(Feed data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      // spacing: 8.0,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            FutureImage(
              future: model.getChannelImage(data.channel),
              height: 160,
              width: double.maxFinite,
              opacity: 0.30,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                spacing: 8.0,
                children: [
                  // title
                  Text(
                    data.channel.title ?? 'Unknown',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(color: Colors.blueGrey, blurRadius: 10.0),
                      ],
                    ),
                  ),
                  // author
                  Text(
                    data.channel.author ?? 'author unknown',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(color: Colors.blueGrey, blurRadius: 10.0),
                      ],
                    ),
                  ),
                  // categories
                  Text(
                    data.channel.categories ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      // fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(color: Colors.blueGrey, blurRadius: 10.0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Text(data.channel.description ?? ''),
        // Text(data.channel.language ?? 'language null'),
        // Text(data.channel.link ?? 'link null'),
        // Text(data.channel.updated?.toString() ?? 'updated null'),
        // Text(data.channel.published?.toString() ?? 'published null'),
        // Text(data.channel.imageUrl ?? 'image_url null'),
        // Text(data.channel.extras.toString()),
        Divider(),
        // ...data.episodes.map((e) => Text(e.title ?? '')),
        ...data.episodes.map(
          (e) => ListTile(
            visualDensity: VisualDensity.compact,
            title: Text(
              e.title ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(),
            ),
            subtitle: Text(
              e.published?.toIso8601String().split('T').first ?? '',
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => context.pop(),
            ),
            title: Text("Feed Channel"),
            actions: [
              model.subscribed
                  ? TextButton.icon(
                    label: Text('unsubscribe'),
                    icon: Icon(Icons.unsubscribe_rounded, size: 24),
                    onPressed: () async {
                      await model.unsubscribe();
                      if (context.mounted) {
                        context.pop();
                      }
                    },
                  )
                  : TextButton.icon(
                    label: Text('subscribe'),
                    icon: Icon(Icons.subscriptions_rounded),
                    onPressed: () async => await model.subscribe(),
                  ),
              IconButton(
                icon: Icon(Icons.content_copy_rounded),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(
                      text:
                          "Title: ${model.feed?.channel.title}\n"
                          "Author: ${model.feed?.channel.author}\n"
                          "Link: ${model.feed?.channel.link}",
                    ),
                  );
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child:
                  model.feed != null
                      ? _buildFeedInfo(model.feed!)
                      : model.error != null
                      ? _buildError(model.error!)
                      : const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(),
                        ),
                      ),
            ),
          ),
        );
      },
    );
  }
}
