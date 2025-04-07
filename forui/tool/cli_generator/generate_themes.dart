import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:code_builder/code_builder.dart';
import 'package:path/path.dart' as p;
import 'package:sugar/sugar.dart';

import 'constructors.dart';
import 'main.dart';

typedef ThemesConstructors =
    ({
      Map<String, ConstructorMatch> typography,
      Map<String, ConstructorMatch> style,
      Map<(String, String?), List<ThemeConstructor>> themes,
    });

typedef ThemeConstructor = ({String theme, String variant, String colors});

final _typography = RegExp('FTypography');
final _typographyConstructor = RegExp(r'(FTypography)\.inherit');
final _style = RegExp('FStyle');
final _styleConstructor = RegExp(r'(FStyle)\.inherit');

String generateThemes(Map<(String, String?), String> fragments) {
  final registry =
      LibraryBuilder()
        ..comments.addAll([header])
        ..body.addAll([
          (EnumBuilder()
                ..docs.addAll(['/// All themes in Forui. Generated by tool/cli_generator.'])
                ..name = 'Theme'
                ..values.addAll([
                  for (final MapEntry(key: (theme, variant), value: source) in fragments.entries)
                    (EnumValueBuilder()
                          ..name = '$theme${variant == null ? '' : variant.capitalize()}'
                          ..arguments.addAll([
                            literalString('$theme${variant == null ? '' : '-$variant'}'),
                            literalString(source),
                          ]))
                        .build(),
                ])
                ..fields.addAll([
                  (FieldBuilder()
                        ..docs.addAll(['/// The name.'])
                        ..name = 'name'
                        ..type = refer('String')
                        ..modifier = FieldModifier.final$)
                      .build(),
                  (FieldBuilder()
                        ..docs.addAll(['/// The code to generate.'])
                        ..name = 'source'
                        ..type = refer('String')
                        ..modifier = FieldModifier.final$)
                      .build(),
                ])
                ..constructors.add(
                  (ConstructorBuilder()
                        ..constant = true
                        ..requiredParameters.addAll([
                          Parameter((p) => p..name = 'this.name'),
                          Parameter((p) => p..name = 'this.source'),
                        ]))
                      .build(),
                ))
              .build(),
        ]);

  return formatter.format(registry.build().accept(emitter).toString());
}

Map<(String, String?), String> mapThemes(ThemesConstructors themes) {
  final typography = ConstructorFragment.inline(_typographyConstructor, themes.typography).values.single;
  final style = ConstructorFragment.inline(_styleConstructor, themes.style).values.single;

  final fragments = <(String, String?), String>{};
  for (final MapEntry(:key, value: constructors) in themes.themes.entries) {
    final buffer = StringBuffer();

    for (final constructor in constructors) {
      final themeFunctionName = '${constructor.theme}${constructor.variant.capitalize()}';
      buffer.writeln('''
        FThemeData get $themeFunctionName {
          const colors = ${constructor.colors.startsWith('const ') ? constructor.colors.replaceFirst('const ', '') : constructor.colors};
          
          final typography = _typography(colors: colors);
          final style = _style(colors: colors, typography: typography);
          
          return FThemeData(
            colors: colors,
            typography: typography,
            style: style,
          );
        }
        
        ''');
    }

    buffer
      ..write(typography.source.substring(0, typography.type.length + 1))
      ..write('_')
      ..writeln(typography.source.substring(typography.type.length + 1))
      ..writeln()
      ..write(style.source.substring(0, style.type.length + 1))
      ..write('_')
      ..writeln(style.source.substring(style.type.length + 1));

    fragments[key] = formatter.format(buffer.toString());
  }

  return fragments;
}

/// Traverses the library and finds all themes.
Future<ThemesConstructors> traverseThemes(AnalysisContextCollection collection) async {
  final typography = await ConstructorMatch.traverse(collection, _typography, _typographyConstructor, {'FTypography'});
  final style = await ConstructorMatch.traverse(collection, _style, _styleConstructor, {'FStyle'});

  final themes = p.join(library, 'src', 'theme', 'themes.dart');
  if (await collection.contextFor(themes).currentSession.getResolvedUnit(themes) case final ResolvedUnitResult result) {
    final visitor = _Visitor();
    result.unit.accept(visitor);

    return (typography: typography, style: style, themes: visitor.themes);
  }

  throw Exception('Failed to parse $themes');
}

class _Visitor extends RecursiveAstVisitor<void> {
  final Map<(String, String?), List<ThemeConstructor>> themes = {};

  @override
  void visitFieldDeclaration(FieldDeclaration field) {
    if (!field.isStatic) {
      return;
    }

    for (final variable in field.fields.variables) {
      final theme = variable.name.lexeme;

      if (variable.initializer case final RecordLiteral record) {
        for (final field in record.fields.whereType<NamedExpression>()) {
          if (field.expression case final InstanceCreationExpression creation) {
            var colors = '';
            for (final expression in creation.argumentList.arguments.whereType<NamedExpression>()) {
              if (expression.name.label.name == 'colors') {
                colors = expression.expression.toSource();
              }
            }

            final constructor = (theme: theme, variant: field.name.label.name, colors: colors);

            (themes[(theme, null)] ??= []).add(constructor);
            (themes[(theme, constructor.variant)] ??= []).add(constructor);
          }
        }
      }
    }
  }
}
