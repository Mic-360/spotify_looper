/// Spotify Player Service (Facade)
library;

export '../models/player_state.dart';

export 'spotify_player_service_stub.dart'
    if (dart.library.js_interop) 'spotify_player_service_web.dart'
    if (dart.library.io) 'spotify_player_service_mobile.dart';
