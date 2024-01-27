import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ilia_challenge/main.dart';
import 'package:ilia_challenge/core/cubit/challenge_core.dart';
import 'package:ilia_challenge/modules/home/view/bloc/home_bloc.dart';
import 'package:ilia_challenge/modules/home/view/widgets/ilia_drawer.dart';
import 'package:ilia_challenge/modules/home/view/widgets/ilia_fullscreen_loader.dart';
import 'package:ilia_challenge/modules/home/view/widgets/pull_to_refresh_infitine_list.dart';

class HomePage extends StatefulWidget {
  static String get route => '/home';
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeBloc bloc = HomeBloc();
  ChallengeCore get core => injector.find<ChallengeCore>();
  final section = MovieSection.nowPlaying;
  @override
  void initState() {
    super.initState();
    bloc.add(const HomeEvent.started());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: Text(widget.title),
            ),
            drawer: const IliaDrawer(),
            body: Center(
              child: BlocBuilder<HomeBloc, HomeState>(
                  bloc: bloc,
                  builder: (context, state) {
                    return PullToRefreshInfiniteList(
                      itemCount:
                          state.movies[state.currentSection]?.length ?? 0,
                      itemBuilder: (context, index) {
                        final movie =
                            state.movies[state.currentSection]?[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(json.encode(movie)),
                          ),
                        );
                      },
                      loadNext: () async {
                        final success = Completer<bool>();

                        bloc.add(HomeEvent.nextPageRequested(
                            section: state.currentSection,
                            success: () {
                              success.complete(true);
                            }));

                        return await success.future;
                      },
                      onRefresh: () async {
                        bloc.add(const HomeEvent.started());
                      },
                    );
                  }),
            ),
          ),
          ValueListenableBuilder(
              valueListenable: core,
              builder: (context, store, _) {
                return const IliaFullscreenLoader(
                  loading: false,
                  color: Colors.white,
                );
              }),
        ],
      ),
    );
  }
}
