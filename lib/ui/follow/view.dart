import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../util/widgets.dart';
import 'model.dart';

class FollowView extends StatelessWidget {
  final FollowViewModel model;
  const FollowView({super.key, required this.model});

  Future _showModal(BuildContext context) async {
    return await showDialog<void>(
      context: context,
      builder:
          (BuildContext context) => SimpleDialog(
            title: const Text('Add New Feed'),
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, 'pcidx'),
                child: const Text('Search PodcastIndex'),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, 'rss'),
                child: const Text('Browse Web and Find RSS'),
              ),
            ],
          ),
    );
  }

  Widget _buildChannelList(BuildContext context) {
    return model.channels.isNotEmpty
        ? GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width ~/ 120,
          children:
              model.channels.map((e) {
                return GestureDetector(
                  onTap: () {
                    context
                        .push(
                          Uri(
                            path: '/channel',
                            queryParameters: {'url': e.url},
                          ).toString(),
                        )
                        .then((value) => model.load());
                  },
                  child: GridTile(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // thumbnail
                        FutureImage(
                          future: model.getChannelImage(e),
                          width: 100,
                          height: 100,
                        ),
                        // title
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            e.title ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        )
        : Center(
          child: Opacity(
            opacity: 0.3,
            child: Icon(Icons.subscriptions_rounded, size: 100),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
          // onPressed: () => context.go('/'),
        ),
      ),
      body: ListenableBuilder(
        listenable: model,
        builder: (context, _) => _buildChannelList(context),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          final res = await _showModal(context);
          // _log.fine(res);
          if (res == 'pcidx') {
            // ignore: use_build_context_synchronously
            context.push('/search').then((value) => model.load());
          } else if (res == 'rss') {
            // ignore: use_build_context_synchronously
            context.push('/browser').then((value) => model.load());
          }
        },
      ),
    );
  }
}
