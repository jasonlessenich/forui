import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:meta/meta.dart';

import 'package:forui/forui.dart';

part 'select_group_item.style.dart';

@internal
class FSelectGroupItemData<T> extends InheritedWidget {
  static FSelectGroupItemData<T> of<T>(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<FSelectGroupItemData<T>>();
    assert(
      result != null,
      "No FSelectGroupItemData found in context. This likely because FSelectGroup's type parameter could not be inferred. "
      'It is currently inferred as FSelectGroup<$T>. To fix this, provide the type parameter explicitly, i.e. FSelectGroup<MyType>.',
    );
    return result!;
  }

  final FSelectGroupController<T> controller;
  final FSelectGroupStyle style;
  final bool selected;

  const FSelectGroupItemData({
    required this.controller,
    required this.style,
    required this.selected,
    required super.child,
    super.key,
  });

  @override
  bool updateShouldNotify(FSelectGroupItemData old) =>
      controller != old.controller || style != old.style || selected != old.selected;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('controller', controller))
      ..add(DiagnosticsProperty('style', style))
      ..add(FlagProperty('selected', value: selected, ifTrue: 'selected'));
  }
}

/// A [FSelectGroupItem]'s state.
typedef FSelectGroupItemState<T> =
    ({FMultiValueNotifier<T> controller, FSelectGroupStyle style, T value, bool selected});

/// Represents a selection in a [FSelectGroup].
abstract class FSelectGroupItem<T> extends StatelessWidget {
  /// The item's value.
  final T value;

  /// Creates a [FSelectGroupItem].
  const factory FSelectGroupItem({
    required T value,
    required ValueWidgetBuilder<FSelectGroupItemState<T>> builder,
    Widget? child,
    Key? key,
  }) = _Builder<T>;

  /// Creates a checkbox wrapped in a [FSelectGroupItem].
  const factory FSelectGroupItem.checkbox({
    required T value,
    FCheckboxSelectGroupStyle? style,
    Widget? label,
    Widget? description,
    Widget? error,
    String? semanticsLabel,
    bool enabled,
    bool autofocus,
    FocusNode? focusNode,
    ValueChanged<bool>? onFocusChange,
    Key? key,
  }) = _Checkbox<T>;

  /// Creates a radio button wrapped in a [FSelectGroupItem].
  const factory FSelectGroupItem.radio({
    required T value,
    FRadioSelectGroupStyle? style,
    Widget? label,
    Widget? description,
    Widget? error,
    String? semanticsLabel,
    bool enabled,
    bool autofocus,
    FocusNode? focusNode,
    ValueChanged<bool>? onFocusChange,
    Key? key,
  }) = _Radio<T>;

  const FSelectGroupItem._({required this.value, super.key});

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<T>('value', value));
  }
}

class _Builder<T> extends FSelectGroupItem<T> {
  final ValueWidgetBuilder<FSelectGroupItemState<T>> builder;
  final Widget? child;

  const _Builder({required this.builder, required super.value, this.child, super.key}) : super._();

  @override
  Widget build(BuildContext context) {
    final FSelectGroupItemData(:controller, :style, :selected) = FSelectGroupItemData.of<T>(context);
    return builder(context, (controller: controller, style: style, value: value, selected: selected), child);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty.has('builder', builder));
  }
}

class _Checkbox<T> extends FSelectGroupItem<T> {
  final FCheckboxSelectGroupStyle? style;
  final Widget? label;
  final Widget? description;
  final Widget? error;
  final String? semanticsLabel;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;

  const _Checkbox({
    required super.value,
    this.style,
    this.label,
    this.description,
    this.error,
    this.semanticsLabel,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.onFocusChange,
    super.key,
  }) : super._();

  @override
  Widget build(BuildContext context) {
    final FSelectGroupItemData(:controller, :selected, :style) = FSelectGroupItemData.of<T>(context);
    final checkboxStyle = this.style ?? style.checkboxStyle;

    return Padding(
      padding: checkboxStyle.padding,
      child: FCheckbox(
        style: checkboxStyle,
        label: label,
        description: description,
        semanticsLabel: semanticsLabel,
        error: error,
        value: selected,
        onChange: (state) => controller.update(value, add: state),
        enabled: enabled,
        autofocus: autofocus,
        focusNode: focusNode,
        onFocusChange: onFocusChange,
        key: key,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('style', style))
      ..add(StringProperty('semanticsLabel', semanticsLabel))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(FlagProperty('autofocus', value: autofocus, ifFalse: 'not autofocus'))
      ..add(DiagnosticsProperty('focusNode', focusNode))
      ..add(ObjectFlagProperty.has('onFocusChange', onFocusChange));
  }
}

class _Radio<T> extends FSelectGroupItem<T> {
  final FRadioSelectGroupStyle? style;
  final Widget? label;
  final Widget? description;
  final Widget? error;
  final String? semanticsLabel;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;

  const _Radio({
    required super.value,
    this.style,
    this.label,
    this.description,
    this.error,
    this.semanticsLabel,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.onFocusChange,
    super.key,
  }) : super._();

  @override
  Widget build(BuildContext context) {
    final FSelectGroupItemData(:controller, :selected, :style) = FSelectGroupItemData.of<T>(context);
    final radioStyle = this.style ?? style.radioStyle;

    return Padding(
      padding: radioStyle.padding,
      child: FRadio(
        style: radioStyle,
        label: label,
        description: description,
        semanticsLabel: semanticsLabel,
        error: error,
        value: selected,
        onChange: (state) => controller.update(value, add: state),
        enabled: enabled,
        autofocus: autofocus,
        focusNode: focusNode,
        onFocusChange: onFocusChange,
        key: key,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('style', style))
      ..add(StringProperty('semanticsLabel', semanticsLabel))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(FlagProperty('autofocus', value: autofocus, ifFalse: 'not autofocus'))
      ..add(DiagnosticsProperty('focusNode', focusNode))
      ..add(ObjectFlagProperty.has('onFocusChange', onFocusChange));
  }
}

/// A [FSelectGroupItem.checkbox]'s style.
class FCheckboxSelectGroupStyle extends FCheckboxStyle with _$FCheckboxSelectGroupStyleFunctions {
  /// The padding around the checkbox. Defaults to `EdgeInsets.symmetric(vertical: 2)`.
  @override
  final EdgeInsets padding;

  /// Creates a [FCheckboxSelectGroupStyle].
  FCheckboxSelectGroupStyle({
    required super.labelLayoutStyle,
    required super.focusedOutlineStyle,
    required super.enabledStyle,
    required super.disabledStyle,
    required super.errorStyle,
    this.padding = const EdgeInsets.symmetric(vertical: 2),
    super.animationDuration,
    super.curve,
  });

  /// Creates a [FCheckboxSelectGroupStyle] that inherits its properties from the given parameters.
  FCheckboxSelectGroupStyle.inherit({required FCheckboxStyle style})
    : this(
        labelLayoutStyle: style.labelLayoutStyle,
        focusedOutlineStyle: style.focusedOutlineStyle,
        enabledStyle: style.enabledStyle,
        disabledStyle: style.disabledStyle,
        errorStyle: style.errorStyle,
      );
}

/// A [FSelectGroupItem.radio]'s style.
class FRadioSelectGroupStyle extends FRadioStyle with _$FRadioSelectGroupStyleFunctions {
  /// The padding around the radio. Defaults to `EdgeInsets.symmetric(vertical: 2)`.
  @override
  final EdgeInsetsGeometry padding;

  /// Creates a [FRadioSelectGroupStyle].
  FRadioSelectGroupStyle({
    required super.labelLayoutStyle,
    required super.focusedOutlineStyle,
    required super.enabledStyle,
    required super.disabledStyle,
    required super.errorStyle,
    this.padding = const EdgeInsets.symmetric(vertical: 2),
    super.animationDuration,
    super.curve,
  });

  /// Creates a [FRadioSelectGroupStyle] that inherits its properties from the given parameters.
  FRadioSelectGroupStyle.inherit({required FRadioStyle style})
    : this(
        animationDuration: style.animationDuration,
        curve: style.curve,
        labelLayoutStyle: style.labelLayoutStyle,
        focusedOutlineStyle: style.focusedOutlineStyle,
        enabledStyle: style.enabledStyle,
        disabledStyle: style.disabledStyle,
        errorStyle: style.errorStyle,
      );
}
