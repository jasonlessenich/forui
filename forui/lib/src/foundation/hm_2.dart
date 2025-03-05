import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:forui/forui.dart';

class Interactions<T> implements WidgetStateProperty<T> {
  final T _value;
  final T _focused;
  final T _hovered;
  final T _hoveredFocused;
  final T _pressed;
  final T _pressedFocused;

  const Interactions(this._value, {T? hovered, T? hoveredFocused, T? pressed, T? pressedFocused, T? focused})
    : _hovered = hovered ?? pressed ?? _value,
      _hoveredFocused = hoveredFocused ?? pressedFocused ?? focused ?? _value,
      _pressed = pressed ?? hovered ?? _value,
      _pressedFocused = pressedFocused ?? hoveredFocused ?? focused ?? _value,
      _focused = focused ?? _value;

  @override
  T resolve(Set<WidgetState> states) {
    if (states.contains(WidgetState.pressed)) {
      return states.contains(WidgetState.focused) ? _pressedFocused : _pressed;
    } else if (states.contains(WidgetState.hovered)) {
      return states.contains(WidgetState.focused) ? _hoveredFocused : _hovered;
    } else {
      return states.contains(WidgetState.focused) ? _focused : _value;
    }
  }
}

class EnabledState<T> extends Interactions<T> implements WidgetStateProperty<T> {
  final Interactions<T> disabled;

  EnabledState(
    super._value, {
    Interactions<T>? disabled,
    super.hovered,
    super.hoveredFocused,
    super.pressed,
    super.pressedFocused,
    super.focused,
  }) : disabled = disabled ?? Interactions(_value, hovered: hovered, pressed: pressed, focused: focused);

  @override
  T resolve(Set<WidgetState> states) =>
      states.contains(WidgetState.disabled) ? disabled.resolve(states) : super.resolve(states);
}

class SelectionState<T> extends EnabledState<T> implements WidgetStateProperty<T> {
  final EnabledState<T> selected;

  SelectionState(
    super._value, {
    EnabledState<T>? selected,
    super.disabled,
    super.hovered,
    super.hoveredFocused,
    super.pressed,
    super.pressedFocused,
    super.focused,
  }) : selected = selected ?? EnabledState(_value, hovered: hovered, pressed: pressed, focused: focused);

  @override
  T resolve(Set<WidgetState> states) =>
      states.contains(WidgetState.selected) ? super.resolve(states) : selected.resolve(states);
}

void usage(SelectionState<Color> background) {
  background.selected.disabled.pressedFocused();
  background.selected.disabled.hovered();

  background._pressed.focused();
  background._hovered();

  background.pressed();
  background();
}

WidgetStateProperty<BoxDecoration> create({
  required FColorScheme colorScheme,
  required FTypography typography,
  required FStyle style,
}) {
  final focusedBorder = Border.all(color: colorScheme.primary, width: style.borderWidth);
  return SelectionState(
    BoxDecoration(
      color: colorScheme.background,
      border: Border.all(color: colorScheme.border),
      borderRadius: style.borderRadius,
    ),
    focused: BoxDecoration(color: colorScheme.background, border: focusedBorder, borderRadius: style.borderRadius),
    hovered: BoxDecoration(
      color: colorScheme.secondary,
      border: Border.all(color: colorScheme.border),
      borderRadius: style.borderRadius,
    ),
    hoveredFocused: BoxDecoration(
      color: colorScheme.secondary,
      border: focusedBorder,
      borderRadius: style.borderRadius,
    ),
    selected: EnabledState(
      BoxDecoration(color: colorScheme.primary, borderRadius: style.borderRadius),
      hovered: BoxDecoration(color: colorScheme.hover(colorScheme.primary), borderRadius: style.borderRadius),
      hoveredFocused: BoxDecoration(
        color: colorScheme.hover(colorScheme.primary),
        border: focusedBorder,
        borderRadius: style.borderRadius,
      ),
      focused: BoxDecoration(color: colorScheme.primary, border: focusedBorder, borderRadius: style.borderRadius),
    ),
  );
}

WidgetStateProperty<BoxDecoration> create({
  required FColorScheme colorScheme,
  required FTypography typography,
  required FStyle style,
}) {
  final focusedBorder = Border.all(color: colorScheme.primary, width: style.borderWidth);
  return SelectionState(
    value: BoxDecoration(
      color: colorScheme.background,
      border: Border.all(color: colorScheme.border),
      borderRadius: style.borderRadius,
    ),
    focused: BoxDecoration(color: colorScheme.background, border: focusedBorder, borderRadius: style.borderRadius),
    hovered: MaybeFocused(
      value: BoxDecoration(
        color: colorScheme.secondary,
        border: Border.all(color: colorScheme.border),
        borderRadius: style.borderRadius,
      ),
      focused: BoxDecoration(color: colorScheme.secondary, border: focusedBorder, borderRadius: style.borderRadius),
    ),
    selected: EnabledState(
      value: BoxDecoration(color: colorScheme.primary, borderRadius: style.borderRadius),
      hovered: MaybeFocused(
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
