import 'package:flutter/material.dart';

import 'package:meta/meta.dart';

import 'package:forui/forui.dart';

@internal
class Field extends FormField<String> {
  static InputDecoration _decoration(
    _State state,
    FTextField parent,
    FTextFieldStyle style,
    FTextFieldStateStyle stateStyle,
    EdgeInsetsGeometry contentPadding,
    Widget? suffix,
  ) {
    final textDirection = Directionality.maybeOf(state.context) ?? TextDirection.ltr;
    final padding = contentPadding.resolve(textDirection);

    return InputDecoration(
      isDense: true,
      prefixIcon: parent.prefixBuilder?.call(state.context, stateStyle, null),
      suffixIcon: suffix,
      // See https://stackoverflow.com/questions/70771410/flutter-how-can-i-remove-the-content-padding-for-error-in-textformfield
      prefix: Padding(
        padding: switch (textDirection) {
          TextDirection.ltr => EdgeInsets.only(left: parent.prefixBuilder == null ? padding.left : 0),
          TextDirection.rtl => EdgeInsets.only(right: parent.prefixBuilder == null ? padding.right : 0),
        },
      ),
      prefixIconConstraints: const BoxConstraints(),
      suffixIconConstraints: const BoxConstraints(),
      contentPadding: switch (textDirection) {
        TextDirection.ltr => padding.copyWith(left: 0),
        TextDirection.rtl => padding.copyWith(right: 0),
      },
      hintText: parent.hint,
      hintStyle: stateStyle.hintTextStyle,
      fillColor: style.fillColor,
      filled: style.filled,
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: stateStyle.unfocusedStyle.color, width: stateStyle.unfocusedStyle.width),
        borderRadius: stateStyle.unfocusedStyle.radius,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: stateStyle.unfocusedStyle.color, width: stateStyle.unfocusedStyle.width),
        borderRadius: stateStyle.unfocusedStyle.radius,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: stateStyle.focusedStyle.color, width: stateStyle.focusedStyle.width),
        borderRadius: stateStyle.focusedStyle.radius,
      ),
    );
  }

  final FTextField parent;

  Field({required this.parent, required FTextFieldStyle style, super.key})
    : super(
        onSaved: parent.onSaved,
        validator: parent.validator,
        initialValue: parent.initialValue,
        enabled: parent.enabled,
        autovalidateMode: parent.autovalidateMode,
        forceErrorText: parent.forceErrorText,
        restorationId: parent.restorationId,
        builder: (field) {
          final state = field as _State;
          final (labelState, stateStyle) = switch (parent) {
            _ when !parent.enabled => (FLabelState.disabled, style.disabledStyle),
            _ when state.errorText != null => (FLabelState.error, style.errorStyle),
            _ => (FLabelState.enabled, style.enabledStyle),
          };

          final suffixIcon = parent.suffixBuilder?.call(state.context, stateStyle, null);
          final clear =
              parent.clearable(state._effectiveController.value)
                  ? Padding(
                    padding: style.clearButtonPadding,
                    child: FButton.icon(
                      style: style.clearButtonStyle,
                      onPress: () {
                        field.didChange('');
                        parent.onChange?.call('');
                      },
                      child: Icon(
                        FIcons.x,
                        semanticLabel:
                            (FLocalizations.of(state.context) ?? FDefaultLocalizations())
                                .textFieldClearButtonSemanticsLabel,
                      ),
                    ),
                  )
                  : null;

          final suffix = switch ((suffixIcon, clear)) {
            (final icon?, final clear?) when labelState != FLabelState.disabled => Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [clear, icon],
            ),
            (null, final clear?) when labelState != FLabelState.disabled => clear,
            (final icon, _) => icon,
          };

          final textfield = TextField(
            controller: state._effectiveController,
            decoration: _decoration(state, parent, style, stateStyle, style.contentPadding, suffix),
            focusNode: parent.focusNode,
            undoController: parent.undoController,
            cursorErrorColor: style.cursorColor,
            keyboardType: parent.keyboardType,
            textInputAction: parent.textInputAction,
            textCapitalization: parent.textCapitalization,
            style: stateStyle.contentTextStyle,
            textAlign: parent.textAlign,
            textAlignVertical: parent.textAlignVertical,
            textDirection: parent.textDirection,
            readOnly: parent.readOnly,
            showCursor: parent.showCursor,
            autofocus: parent.autofocus,
            statesController: parent.statesController,
            obscuringCharacter: parent.obscuringCharacter,
            obscureText: parent.obscureText,
            autocorrect: parent.autocorrect,
            smartDashesType: parent.smartDashesType,
            smartQuotesType: parent.smartQuotesType,
            enableSuggestions: parent.enableSuggestions,
            maxLines: parent.maxLines,
            minLines: parent.minLines,
            expands: parent.expands,
            maxLength: parent.maxLength,
            maxLengthEnforcement: parent.maxLengthEnforcement,
            onChanged: (value) {
              field.didChange(value);
              parent.onChange?.call(value);
            },
            onTap: parent.onTap,
            onTapAlwaysCalled: parent.onTapAlwaysCalled,
            onEditingComplete: parent.onEditingComplete,
            onSubmitted: parent.onSubmit,
            onAppPrivateCommand: parent.onAppPrivateCommand,
            inputFormatters: parent.inputFormatters,
            enabled: parent.enabled,
            ignorePointers: parent.ignorePointers,
            enableInteractiveSelection: parent.enableInteractiveSelection,
            keyboardAppearance: style.keyboardAppearance,
            scrollPadding: style.scrollPadding,
            dragStartBehavior: parent.dragStartBehavior,
            mouseCursor: parent.mouseCursor,
            buildCounter: (context, {required currentLength, required isFocused, required maxLength}) {
              final counter = parent.counterBuilder?.call(context, currentLength, maxLength, isFocused);
              return counter == null
                  ? null
                  : DefaultTextStyle.merge(style: stateStyle.counterTextStyle, child: counter);
            },
            selectionControls: parent.selectionControls,
            scrollController: parent.scrollController,
            scrollPhysics: parent.scrollPhysics,
            autofillHints: parent.autofillHints,
            restorationId: parent.restorationId,
            stylusHandwritingEnabled: parent.stylusHandwritingEnabled,
            enableIMEPersonalizedLearning: parent.enableIMEPersonalizedLearning,
            contentInsertionConfiguration: parent.contentInsertionConfiguration,
            contextMenuBuilder: parent.contextMenuBuilder,
            canRequestFocus: parent.canRequestFocus,
            spellCheckConfiguration: parent.spellCheckConfiguration,
            magnifierConfiguration: parent.magnifierConfiguration,
          );

          return UnmanagedRestorationScope(
            bucket: state.bucket,
            child: FLabel(
              axis: Axis.vertical,
              state: labelState,
              label: parent.label,
              style: style.labelStyle,
              description: parent.description,
              error: switch (state.errorText) {
                null => const SizedBox(),
                final error => parent.errorBuilder(state.context, error),
              },
              child: parent.builder(state.context, stateStyle, textfield),
            ),
          );
        },
      );

  @override
  FormFieldState<String> createState() => _State();
}

// This class is based on Material's _TextFormFieldState implementation.
class _State extends FormFieldState<String> {
  RestorableTextEditingController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.parent.controller case final controller?) {
      controller.addListener(_handleControllerChanged);
    } else {
      _registerController(RestorableTextEditingController(text: widget.initialValue));
    }
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    super.restoreState(oldBucket, initialRestore);
    if (_controller case final controller?) {
      registerForRestoration(controller, 'controller');
    }

    // Make sure to update the internal [FormFieldState] value to sync up with text editing controller value.
    setValue(_effectiveController.text);
  }

  void _registerController(RestorableTextEditingController controller) {
    assert(_controller == null, '_controller is already initialized.');
    _controller = controller;
    if (!restorePending) {
      registerForRestoration(controller, 'controller');
    }
  }

  @override
  void didUpdateWidget(Field old) {
    super.didUpdateWidget(old);
    if (widget.parent.controller == old.parent.controller) {
      return;
    }

    widget.parent.controller?.addListener(_handleControllerChanged);
    old.parent.controller?.removeListener(_handleControllerChanged);

    switch ((widget.parent.controller, old.parent.controller)) {
      case (final current?, _):
        setValue(current.text);
        if (_controller != null) {
          unregisterFromRestoration(_controller!);
          _controller?.dispose();
          _controller = null;
        }

      case (null, final old?):
        _registerController(RestorableTextEditingController.fromValue(old.value));
    }
  }

  @override
  void dispose() {
    widget.parent.controller?.removeListener(_handleControllerChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChange(String? value) {
    super.didChange(value);
    if (_effectiveController.text != value) {
      _effectiveController.text = value ?? '';
    }
  }

  @override
  void reset() {
    // Set the controller value before calling super.reset() to let _handleControllerChanged suppress the change.
    _effectiveController.text = widget.initialValue ?? '';
    super.reset();
    widget.parent.onChange?.call(_effectiveController.text);
  }

  void _handleControllerChanged() {
    // Suppress changes that originated from within this class.
    //
    // In the case where a controller has been passed in to this widget, we register this change listener. In these
    // cases, we'll also receive change notifications for changes originating from within this class -- for example, the
    // reset() method. In such cases, the FormField value will already have been set.
    if (_effectiveController.text != value) {
      didChange(_effectiveController.text);
    }
  }

  @override
  Field get widget => super.widget as Field;

  TextEditingController get _effectiveController => widget.parent.controller ?? _controller!.value;
}
