import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../ui/browser/model.dart';
import '../ui/episode/model.dart';
import '../ui/feed/model.dart';
import '../ui/feed/view.dart';
import '../ui/episode/view.dart';
import '../ui/browser/view.dart';
import '../ui/follow/model.dart';
import '../ui/follow/view.dart';
import '../ui/home/model.dart';
import '../ui/home/view.dart';
import '../ui/search/model.dart';
import '../ui/search/view.dart';
import '../ui/settings/view.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        final model = context.read<HomeViewModel>();
        return HomeView(model: model);
      },
      routes: [
        // browser
        GoRoute(
          path: 'browser',
          builder:
              (context, state) =>
                  BrowserView(model: context.read<BrowserViewModel>()),
        ),
        // episode
        GoRoute(
          path: 'episode',
          builder:
              (context, state) => EpisodeView(
                model:
                    context.read<EpisodeViewModel>()
                      ..load(state.uri.queryParameters['guid']),
              ),
        ),
        // feed
        GoRoute(
          path: 'channel',
          builder:
              (context, state) => FeedView(
                model:
                    context.read<FeedViewModel>()
                      ..load(state.uri.queryParameters['url']),
              ),
        ),
        // follow
        GoRoute(
          path: 'follow',
          builder:
              (context, state) =>
                  FollowView(model: context.read<FollowViewModel>()..load()),
        ),
        // search
        GoRoute(
          path: 'search',
          builder:
              (context, state) =>
                  SearchView(model: context.read<SearchViewModel>()),
        ),
        // settings
        GoRoute(
          path: 'settings',
          builder: (context, state) => const SettingsView(),
        ),
      ],
    ),
  ],
);
