# Liberal Crime Squad: New Age

Play link:

> <https://www.jonathansfox.com/lcs-new-age/>

Welcome to Liberal Crime Squad! The Conservatives have taken the Executive, Legislative, and Judicial branches of government. Over time, the Liberal laws of this nation will erode and turn the country into a BACKWOODS YET CORPORATE NIGHTMARE. To prevent this from happening, the Liberal Crime Squad was established. The mood of the country is shifting, and we need to turn things around. Go out on the streets and indoctrinate Conservative automatons.  That is, let them see their True Liberal Nature. Then arm them and send them forth to Stop Evil.

Liberal Crime Squad: New Age is a complete rewrite and port of Liberal Crime Squad from C++ to Dart, with the aim of making it run natively in modern web browsers. (It should also be possible to compile native builds.)

New Age is additionally intended to be a Radical Design Departure, a Liberal Playground where Jonathan S. Fox can unleash new and inadvisable design ideas on the game.

## Contributing

Liberal Crime Squad: New Age is always looking for Liberal Freedom Fighters to contribute to its development. 

1) [Manually install Flutter](https://docs.flutter.dev/get-started/install) or let the [Flutter extension for VS Code](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter) or [IntelliJ](https://plugins.jetbrains.com/plugin/9212-flutter) install it for you.
2) Run `git clone https://github.com/jonathansfox/lcs-new-age.git` in a convenient location to fetch the source code, and `cd lcs-new-age` into it.
3) Run `flutter pub get` to download and install required library dependencies.
4) Run `dart run build_runner build --delete-conflicting-outputs` to auto-generate some of the required code files. The generated code is used for JSON (de-)serialization of save game files.

> Note: You'll have to regenerate these files by running this command again whenever the save game format changes!

5) Start a dev build with `flutter run -d chrome` or `flutter run -d windows` (you'll need Visual Studio to be installed for the windows build toolchain). 

> Note: LCS:NA does not fully support hot reload. All the gameplay is handled by a thread that is designed to be written the same way LCS code has always been written, with curses-style calls to print text to the console and flush the console and blocking calls to get input and so on. Meanwhile, the actual UI state is only an emulated console widget that has no knowledge of what is happening in the game.

6) Create a release build
    -  For website builds (change or remove --base-href to suit your hosting choices)  
`flutter build web --source-maps --base-href /lcs-new-age`  
    -  For a windows build  
    `flutter build windows` 