import 'package:ansicolor/ansicolor.dart';

final _red = AnsiPen()..red();
final _green = AnsiPen()..green();
final _blue = AnsiPen()..blue();

void printError(String message) {
  print(_red(message));
}

void printSucces(String message) {
  print(_green(message));
}

void printInfo(String message) {
  print(_blue(message));
}
