# Keep Flutter/plugin entry points reached only via reflection.
-keep class io.flutter.** { *; }
-keep class com.sayankabir.passwordzzz_v2.** { *; }

# sqlite3 native bindings used by drift.
-keep class org.sqlite.** { *; }
