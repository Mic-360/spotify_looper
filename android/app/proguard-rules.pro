# ProGuard rules for Spotify SDK and Jackson
# These rules prevent R8 from failing builds due to missing classes 
# and ensure Spotify SDK classes are preserved.

# Keep Spotify SDK protocol and app-remote classes
-keep class com.spotify.protocol.mappers.** { *; }
-keep class com.spotify.android.appremote.** { *; }

# Ignore missing Jackson classes (often happens with Spotify SDK internal mappers)
-dontwarn com.fasterxml.jackson.**
-dontwarn com.spotify.base.annotations.**

# Keep Jackson classes if they are present
-keep class com.fasterxml.jackson.databind.** { *; }
-keep class com.fasterxml.jackson.annotation.** { *; }

# Ignore missing Play Core classes (referenced by Flutter embedding)
-dontwarn com.google.android.play.core.**
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
