import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ilia_challenge/core/domain/services/movies_uri_builder_service.dart';
import 'package:ilia_challenge/main.dart';
import 'package:ilia_challenge/modules/home/domain/home_repository.dart';
import 'package:ilia_challenge/modules/home/domain/movies_section.dart';

export 'package:ilia_challenge/modules/home/domain/movies_section.dart';

part 'home_event.dart';
part 'home_state.dart';
part 'home_bloc.freezed.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeRepository repo = injector.find<HomeRepository>();
  HomeBloc() : super(HomeState()) {
    on<HomeEvent>(
      (events, emit) async => events.map(
        started: (event) => _homeStarted(event, emit),
        pinSearchBar: (event) => _pinSearchBar(event, emit),
        loadMovies: (event) => _loadMovies(event, emit),
        nextPageRequested: (event) => _nextPageRequested(event, emit),
      ),
    );
  }

  _homeStarted(_HomeStarted event, emit) async {
    print(' ===================== HomeStarted ===================== ');
    emit(state.copyWith(
        loaders: switchLoaders(loaders: state.loaders, key: 'initialLoader')));

    var (sections, movies) = _resetMoviesLists();

    emit(state.copyWith(
      movies: movies,
      sections: sections,
    ));
    final result = Completer<Map<MovieSection, List<dynamic>>>();

    add(HomeEvent.loadMovies(section: state.currentSection, result: result));

    movies = await result.future;

    emit(state.copyWith(movies: movies));
  }

  _pinSearchBar(_PinSearchBar event, emit) {}

  _loadMovies(_LoadMovies event, emit) async {
    print(' ===================== LoadMovies ===================== ');

    MoviesUriBuilderService uriService = state.sections[event.section]!;

    // uri is set to null when reaches last page
    if (uriService.uri == null) return;

    var (error, response) = await repo.loadMovies(route: uriService.uri!);

    print(' ================= uri? ${uriService.uri} ================= ');

    /// TODO: handle incoming errors instead of return only
    if (error != null) return;

    if (uriService.lastPage == 0) {
      uriService.handleLastPage(last: response?.data['total_pages'] ?? 1);
    }

    event.result.complete(handleResult(
        section: event.section, results: response?.data['results'] ?? []));

    emit(state.copyWith(loaders: {}));
  }

  Future _nextPageRequested(_NextPageRequested event, emit) async {
    print(' ===================== NextPageRequested ===================== ');

    emit(state.copyWith(
        loaders: switchLoaders(loaders: state.loaders, key: 'nextPageLoader')));

    final newSection =
        Map<MovieSection, MoviesUriBuilderService>.from(state.sections);
    final newUriBuilder = state.sections[event.section]!..nextPage();

    newSection[event.section] = newUriBuilder;
    emit(state.copyWith(sections: newSection));

    final result = Completer<Map<MovieSection, List<dynamic>>>();

    add(HomeEvent.loadMovies(section: state.currentSection, result: result));

    final movies = await result.future;

    emit(state.copyWith(movies: movies));
    event.success();
  }

  (Map<MovieSection, MoviesUriBuilderService>, Map<MovieSection, List>)
      _resetMoviesLists() {
    Map<MovieSection, MoviesUriBuilderService> sections = {};
    Map<MovieSection, List> movies = {};

    for (var element in MovieSection.values) {
      sections[element] = MoviesUriBuilderService(path: element.path);
      movies[element] = [];
    }

    return (sections, movies);
  }

  switchLoaders({required Map loaders, required String key}) {
    final newState = Map<String, bool>.from(loaders);
    bool loader = loaders[key] ?? false;
    newState[key] = !loader;
    return newState;
  }

  Map<MovieSection, List<dynamic>> handleResult(
      {required MovieSection section, required List results}) {
    // aggregates incoming movies to the current state
    Map<MovieSection, List<dynamic>> movies = Map.from(state.movies);
    List currentSection = List.from(movies[section] ?? []);
    currentSection.addAll(List.from(results));
    movies[section] = currentSection;
    return movies;
    //////////////////////////////
  }
}
