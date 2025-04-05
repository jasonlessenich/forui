import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:sugar/sugar.dart';

import '../../../configuration.dart';
import '../../../style_registry.dart';
import 'command.dart';

const _unnamespacedHeader = '''
import 'package:forui/forui.dart';
import 'package:flutter/material.dart';

/// Generated by Forui CLI.
///
/// Modify the generated function bodies to create your own custom style.
/// Then, call the modified functions and pass the results to your FThemeData.
/// 
/// ### Example
/// Generated style:
/// ```dart
/// // Modify this function's body.
/// FDividerStyles dividerStyles({
///   required FColorScheme color,
///   required FStyle style,
/// }) => FDividerStyles(
///   horizontalStyle: FDividerStyle(
///     color: color.secondary,
///     padding: FDividerStyle.defaultPadding.horizontalStyle,
///     width: style.borderWidth,
///   ),
///   verticalStyle: FDividerStyle(
///     color: color.secondary,
///     padding: FDividerStyle.defaultPadding.verticalStyle,
///     width: style.borderWidth,
///   ),
/// );
/// ```
///
/// File that contains your `FThemeData`:
/// ```dart
/// import 'package:my_application/theme/divider_style.dart' // Your generated file.
///
/// FThemeData(
///  color: FThemes.zinc.light.color,
///  style: FThemes.zinc.light.style,
///  dividerStyles: dividerStyles( // The function in your generated file.
///    color: FThemes.zinc.light.color,
///    style: FThemes.zinc.light.style,
///   ),
/// );
/// ```
/// 
/// See https://forui.dev/docs/cli for more information.''';

const _namespacedHeader = '''
import 'package:forui/forui.dart';
import 'package:flutter/material.dart';

/// Generated by Forui CLI.
///
/// Modify the generated function bodies to create your own custom style.
/// Then, call the modified functions and pass the results to your FThemeData.
/// 
/// ### Example
/// Generated style:
/// ```dart
/// extension CustomFDividerStyles on Never {
///   // Modify this function's body.
///   static FDividerStyles dividerStyles({
///     required FColorScheme color,
///     required FStyle style,
///   }) => FDividerStyles(
///     horizontalStyle: FDividerStyle(
///       color: color.secondary,
///       padding: FDividerStyle.defaultPadding.horizontalStyle,
///       width: style.borderWidth,
///     ),
///     verticalStyle: FDividerStyle(
///       color: color.secondary,
///       padding: FDividerStyle.defaultPadding.verticalStyle,
///       width: style.borderWidth,
///     ),
///   );
/// }
/// ```
///
/// File that contains your `FThemeData`:
/// ```dart
/// import 'package:my_application/theme/divider_style.dart' // Your generated file.
///
/// FThemeData(
///  color: FThemes.zinc.light.color,
///  style: FThemes.zinc.light.style,
///  dividerStyles: CustomFDividerStyles.dividerStyles( // The function in your generated file.
///    color: FThemes.zinc.light.color,
///    style: FThemes.zinc.light.style,
///   ),
/// );
/// ```
/// 
/// See https://forui.dev/docs/cli for more information.''';

final _formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);

extension GenerateStyles on StyleCreateCommand {
  void generateStyles(
    List<String> arguments, {
    required bool color,
    required bool input,
    required bool all,
    required bool force,
    required String output,
  }) {
    final paths = <String, List<String>>{};
    final existing = <String>{};

    for (final style in all ? registry.keys.toList() : arguments) {
      final fileName = registry[style.toLowerCase()]!.type.substring(1).toSnakeCase();
      final path =
          '${root.path}${Platform.pathSeparator}${output.endsWith('.dart') ? output : '$output${Platform.pathSeparator}$fileName.dart'}';

      (paths[path] ??= []).add(style);
      if (File(path).existsSync()) {
        existing.add(path);
      }
    }

    if (!force && existing.isNotEmpty) {
      _prompt(existing, input: input);
    }

    _generate(paths);

    console
      ..writeLine()
      ..write('See https://forui.dev/docs/cli for how to use the generated styles.')
      ..writeLine();
  }

  void _prompt(Set<String> existing, {required bool input}) {
    console
      ..write('Found ${existing.length} file(s) that already exist.')
      ..writeLine();

    if (!input) {
      console
        ..write('Style files already exist. Skipping... ')
        ..writeLine();
      exit(0);
    }

    console
      ..writeLine()
      ..write('Existing files:')
      ..writeLine();
    for (final path in existing) {
      console
        ..write('  $path')
        ..writeLine();
    }

    while (true) {
      console
        ..writeLine()
        ..write('${console.supportsEmoji ? '⚠️' : '[Warning]'} Overwrite these files? [Y/n]')
        ..writeLine();

      switch (console.readLine(cancelOnBreak: true)) {
        case 'y' || 'Y' || '':
          console.writeLine();
          return;
        case 'n' || 'N':
          exit(0);
        default:
          console
            ..write('Invalid option. Please enter enter either "y" or "n".')
            ..writeLine();
          continue;
      }
    }
  }

  void _generate(Map<String, List<String>> paths) {
    console
      ..write('${console.supportsEmoji ? '⏳' : '[Waiting]'} Creating styles...')
      ..writeLine()
      ..writeLine();

    for (final MapEntry(key: path, value: styles) in paths.entries) {
      final buffer = StringBuffer();

      if (registry[styles.singleOrNull] case StyleRegistry(:final closure)) {
        buffer.writeln(_unnamespacedHeader);
        _reduce(buffer, closure, many: false);
      } else {
        buffer.writeln(_namespacedHeader);
        for (final style in styles) {
          _reduce(buffer, registry[style.toLowerCase()]!.closure, many: true);
        }
      }

      File(path)
        ..createSync(recursive: true)
        ..writeAsStringSync(_formatter.format(buffer.toString()));

      console
        ..write('${console.supportsEmoji ? '✅' : '[Done]'} $path')
        ..writeLine();
    }
  }

  void _reduce(StringBuffer buffer, List<String> closure, {required bool many}) {
    final root = registry[closure.first.toLowerCase()]!;

    if (many) {
      buffer
        ..writeln('extension Custom${root.type} on Never {')
        ..write('static ');
    }
    buffer.writeln(root.source);

    for (final nested in closure.skip(1)) {
      if (many) {
        buffer.write('static ');
      }
      final style = registry[nested.toLowerCase()]!;
      buffer.write('${style.source.substring(0, style.position)}_${style.source.substring(style.position)}\n');
    }

    if (many) {
      buffer.writeln('}');
    }
  }
}
