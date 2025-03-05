import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:forui/forui.dart';

class FocusedOr<T> implements WidgetStateProperty<T> {
  final T _value;
  final T _focused;

  FocusedOr({required T value, T? focused}) : _value = value, _focused = focused ?? value;

  T call() => _value;

  T focused() => _focused;

  @override
  T resolve(Set<WidgetState> states) => states.contains(WidgetState.focused) ? _focused : _value;
}

class HoveredPressedOr<T> extends FocusedOr<T> implements WidgetStateProperty<T> {
  final FocusedOr<T> hovered;
  final FocusedOr<T> pressed;

  HoveredPressedOr({required super.value, FocusedOr<T>? hovered, FocusedOr<T>? pressed, super.focused})
    : hovered = hovered ?? pressed ?? FocusedOr(value: value, focused: focused),
      pressed = pressed ?? hovered ?? FocusedOr(value: value, focused: focused);

  @override
  T resolve(Set<WidgetState> states) {
    if (states.contains(WidgetState.pressed)) {
      return pressed.resolve(states);
    } else if (states.contains(WidgetState.hovered)) {
      return hovered.resolve(states);
    } else {
      return super.resolve(states);
    }
  }
}

class DisabledOr<T> extends HoveredPressedOr<T> implements WidgetStateProperty<T> {
  final HoveredPressedOr<T> disabled;

  DisabledOr({HoveredPressedOr<T>? disabled, super.hovered, super.pressed, required super.value, super.focused})
    : disabled = disabled ?? HoveredPressedOr(value: value, hovered: hovered, pressed: pressed, focused: focused);

  @override
  T resolve(Set<WidgetState> states) =>
      states.contains(WidgetState.disabled) ? disabled.resolve(states) : super.resolve(states);
}

class SelectedOr<T> extends DisabledOr<T> implements WidgetStateProperty<T> {
  final DisabledOr<T> selected;

  SelectedOr({
    DisabledOr<T>? selected,
    super.disabled,
    super.hovered,
    super.pressed,
    required super.value,
    super.focused,
  }) : selected = selected ?? DisabledOr(value: value, hovered: hovered, pressed: pressed, focused: focused);

  @override
  T resolve(Set<WidgetState> states) =>
      states.contains(WidgetState.selected) ? selected.resolve(states) : super.resolve(states);
}

void usage(SelectedOr<Color> background) {
  background.selected.disabled.pressed.focused();
  background.selected.disabled.hovered();

  background.disabled.hovered.focused();
  background.disabled.pressed();

  background.pressed.focused();
  background.hovered();

  background.pressed();
  background();
}

WidgetStateProperty<BoxDecoration> create({
  required FColorScheme colorScheme,
  required FTypography typography,
  required FStyle style,
}) {
  final focusedBorder = Border.all(color: colorScheme.primary, width: style.borderWidth);
  return SelectedOr(
    value: BoxDecoration(
      color: colorScheme.background,
      border: Border.all(color: colorScheme.border),
      borderRadius: style.borderRadius,
      //
    ),
    focused: BoxDecoration(
      color: colorScheme.background,
      border: focusedBorder,
      borderRadius: style.borderRadius,
      //
    ),
    hovered: FocusedOr(
      value: BoxDecoration(
        color: colorScheme.secondary,
        border: Border.all(color: colorScheme.border),
        borderRadius: style.borderRadius,
      ),
      focused: BoxDecoration(color: colorScheme.secondary, border: focusedBorder, borderRadius: style.borderRadius),
    ),
    selected: DisabledOr(
      value: BoxDecoration(color: colorScheme.primary, borderRadius: style.borderRadius),
      hovered: FocusedOr(
        value: BoxDecoration(color: colorScheme.hover(colorScheme.primary), borderRadius: style.borderRadius),
        focused: BoxDecoration(
          color: colorScheme.hover(colorScheme.primary),
          border: focusedBorder,
          borderRadius: style.borderRadius,
        ),
      ),
      focused: BoxDecoration(color: colorScheme.primary, border: focusedBorder, borderRadius: style.borderRadius),
    ),
  );
}
