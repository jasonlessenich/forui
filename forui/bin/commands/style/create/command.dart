import 'dart:io';

import '../../../args/command.dart';
import '../../../configuration.dart';
import '../style.dart';
import 'generate.dart';
import 'validate.dart';

final registry = Style.values.asNameMap();

class StyleCreateCommand extends ForuiCommand {
  @override
  final name = 'create';

  @override
  final aliases = ['c'];

  @override
  final description = 'Create Forui widget style file(s).';

  @override
  final arguments = '[styles]';

  StyleCreateCommand() {
    argParser
      ..addFlag('all', abbr: 'a', help: 'Generate all styles.', negatable: false)
      ..addFlag('force', abbr: 'f', help: 'Overwrite existing files if they exist.', negatable: false)
      ..addOption(
        'output',
        abbr: 'o',
        help: 'The output directory or file, relative to the project directory.',
        defaultsTo: defaultStyleOutput,
      );
  }

  @override
  void run() {
    final input = !globalResults!.flag('no-input');
    final all = argResults!.flag('all');
    final force = argResults!.flag('force');
    final output = argResults!['output'] as String;
    final arguments = argResults!.rest;

    if (arguments.isEmpty && !all) {
      printUsage();
      return;
    }

    if (validateStyles(arguments, all: all)) {
      exit(1);
    }

    generateStyles(arguments, input: input, all: all, force: force, output: output);
  }
}
