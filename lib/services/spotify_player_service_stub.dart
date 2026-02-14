/// Spotify Player Service Stub
library;

import 'dart:async';
import '../models/player_state.dart';

class SpotifyPlayerService {
  static SpotifyPlayerService get instance => throw UnimplementedError();

  Stream<PlayerState> get stateStream => throw UnimplementedError();
  Stream<bool> get readyStream => throw UnimplementedError();
  PlayerState get currentState => throw UnimplementedError();
  String? get deviceId => throw UnimplementedError();
  bool get isReady => throw UnimplementedError();

  Future<void> initialize(String accessToken) async =>
      throw UnimplementedError();
  void updateToken(String token) => throw UnimplementedError();
  Future<void> play(String uri) async => throw UnimplementedError();
  Future<void> resume() async => throw UnimplementedError();
  Future<void> pause() async => throw UnimplementedError();
  Future<void> togglePlayPause() async => throw UnimplementedError();
  Future<void> seek(int positionMs) async => throw UnimplementedError();
  Future<void> skipNext() async => throw UnimplementedError();
  Future<void> skipPrevious() async => throw UnimplementedError();
  Future<void> setRepeatMode(RepeatMode mode) async =>
      throw UnimplementedError();
  Future<void> setShuffle(bool enabled) async => throw UnimplementedError();
  void dispose() => throw UnimplementedError();
}
