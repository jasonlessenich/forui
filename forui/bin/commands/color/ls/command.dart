import 'package:dart_console/dart_console.dart';

import '../../../args/command.dart';
import '../color.dart';

final console = Console();

class ColorLsCommand extends ForuiCommand {
  @override
  final name = 'ls';

  @override
  final aliases = ['list'];

  @override
  final description = 'List all Forui color schemes.';

  @override
  final arguments = '';

  @override
  void run() {
    final colors =
        ColorScheme.values.asNameMap().values.map((e) => e.name).toList()..sort((a, b) {
          final [aTheme, ...aRest] = a.split('-');
          final [bTheme, ...bRest] = b.split('-');

          if (aTheme != bTheme) {
            return aTheme.compareTo(bTheme);
          }

          if (a.length != b.length) {
            return a.length.compareTo(b.length);
          }

          return (bRest.firstOrNull ?? '').compareTo(aRest.firstOrNull ?? '');
        });

    console
      ..write('Available color schemes:')
      ..writeLine();

    for (final color in colors) {
      console
        ..write('  $color')
        ..writeLine();
    }
  }
}
