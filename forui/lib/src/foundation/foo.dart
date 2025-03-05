import 'package:flutter/cupertino.dart';
import 'package:forui/forui.dart';

class Tappable<T> {
  T enabled;
  T disabled;

  T hovered;
  T pressed;
  T focused;

  T disabledHovered;
  T disabledPressed;
  T disabledFocused;
}

extension type A<T>(FWidgetStateMap<T> map) {
  T get selectedHovered => map[WidgetState.selected & WidgetState.hovered]!;

}

class Selected<T> {
  T enabled;
  T disabled;

  T hovered;
  T pressed;
  T focused;

  T hoveredFocused;
  T pressedFocused;

  T selectedHovered;
  T selectedPressed;
  T selectedFocused;

  T selectedHoveredFocused;
  T selectedPressedFocused;

  T disabledSelected;
  T disabledFocused;

  T disabledSelectedHovered;
  T disabledSelectedPressed;
  T disabledSelectedFocused;

  T disabledSelectedHoveredFocused;
  T disabledSelectedPressedFocused;

  // Rip performance.
  T resolve(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.hovered)) {
          if (states.contains(WidgetState.focused)) {
            return disabledSelectedHoveredFocused;
          }

          return disabledSelectedHovered;
        }

        if (states.contains(WidgetState.pressed)) {
          if (states.contains(WidgetState.focused)) {
            return disabledSelectedPressedFocused;
          }

          return disabledSelectedPressed;
        }

        if (states.contains(WidgetState.focused)) {
          return disabledSelectedFocused;
        }

        return disabledSelected;
      }

      return disabled;
    }
  }
}
