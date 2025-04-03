import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A mixin that provides a [shouldNotify] method to determine if the data has
/// changed and should notify the listeners.
mixin DistinctData {
  /// Returns true if the data has changed and should notify the listeners.
  bool shouldNotify(covariant DistinctData oldData);
}

/// An interface that holds forwardable data.
abstract class DataHolder<T> {
  /// Registers a [receiver] that provides the data.
  void register(ForwardableDataState<T> receiver);

  /// Unregisters a [receiver] that provides the data.
  void unregister(ForwardableDataState<T> receiver);

  /// Finds the data of the [type] from the [context].
  T? findData(BuildContext context, Type type);
}

/// An abstract InheritedWidget that passes the DataHolder to its descendants.
abstract class InheritedDataHolderWidget<T> extends InheritedWidget {
  /// Creates an InheritedDataHolderWidget.
  const InheritedDataHolderWidget({required super.child, super.key});

  /// The DataHolder that holds the data.
  DataHolder<T> get holder;
}

/// An InheritedWidget that passes the DataHolder to its descendants.
class InheritedDataHolder<T> extends InheritedDataHolderWidget<T> {
  @override
  final DataHolder<T> holder;

  const InheritedDataHolder({required this.holder, required super.child, super.key});

  @override
  bool updateShouldNotify(covariant InheritedDataHolder<T> oldWidget) => oldWidget.holder != holder;
}

/// An InheritedWidget that passes the root DataHolder to its descendants.
class InheritedRootDataHolder extends InheritedDataHolderWidget<dynamic> {
  @override
  final DataHolder<dynamic> holder;

  const InheritedRootDataHolder({super.key, required this.holder, required super.child});

  @override
  bool updateShouldNotify(covariant InheritedRootDataHolder oldWidget) => oldWidget.holder != holder;
}

/// DataMessengerRoot is the root of the data messenger tree.
/// The root stores all kinds of forwardable data and provides them to the
/// descendants.
class DataMessengerRoot extends StatefulWidget {
  /// The child widget.
  final Widget child;

  /// Creates a DataMessengerRoot.
  const DataMessengerRoot({super.key, required this.child});

  @override
  State<DataMessengerRoot> createState() => _DataMessengerRootState();
}

class _DataMessengerRootState extends State<DataMessengerRoot> implements DataHolder {
  final Map<Type, LinkedHashSet<ForwardableDataState>> _senders = {};

  @override
  void register(ForwardableDataState receiver) {
    final type = receiver.dataType;
    _senders.putIfAbsent(type, () => LinkedHashSet());
    _senders[type]!.add(receiver);
  }

  @override
  void unregister(ForwardableDataState receiver) {
    final type = receiver.dataType;
    _senders[type]?.remove(receiver);
  }

  @override
  dynamic findData(BuildContext context, Type type) {
    LinkedHashSet<ForwardableDataState>? receivers = _senders[type];
    if (receivers == null) {
      return null;
    }
    for (ForwardableDataState receiver in receivers) {
      var didFindData = false;
      receiver.context.visitAncestorElements((element) {
        if (element == context) {
          didFindData = true;
          return false;
        }
        return true;
      });
      if (didFindData) {
        return receiver.widget.data;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => InheritedRootDataHolder(holder: this, child: widget.child);
}

/// DataMessenger is a widget that holds the forwardable data.
/// The data is attached/received from the ForwardableData widget
/// and then passed to the descendants. DataMessenger<[T]> can only
/// store ForwardableData<[T]>.
class DataMessenger<T> extends StatefulWidget {
  /// The child widget.
  final Widget child;

  /// Creates a DataMessenger.
  const DataMessenger({super.key, required this.child});

  @override
  State<DataMessenger<T>> createState() => _DataMessengerState<T>();
}

class _DataMessengerState<T> extends State<DataMessenger<T>> implements DataHolder<T> {
  final LinkedHashSet<ForwardableDataState<T>> _receivers = LinkedHashSet();

  @override
  void register(ForwardableDataState<T> receiver) {
    _receivers.add(receiver);
  }

  @override
  void unregister(ForwardableDataState<T> receiver) {
    _receivers.remove(receiver);
  }

  @override
  T? findData(BuildContext context, Type type) {
    for (final receiver in _receivers) {
      var didFindData = false;
      receiver.context.visitAncestorElements((element) {
        if (element == context) {
          didFindData = true;
          return false;
        }
        return true;
      });
      if (didFindData) {
        return receiver.widget.data;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => InheritedDataHolder<T>(holder: this, child: widget.child);
}

/// A widget that holds the data that can be attached to ancestor holders.
class ForwardableData<T> extends StatefulWidget {
  /// The data that will be forwarded.
  final T data;

  /// The child widget.
  final Widget child;

  /// Creates a ForwardableData.
  const ForwardableData({super.key, required this.data, required this.child});

  @override
  State<ForwardableData<T>> createState() => ForwardableDataState<T>();
}

class ForwardableDataState<T> extends State<ForwardableData<T>> {
  DataHolder? _messenger;

  Type get dataType => T;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    InheritedDataHolderWidget? inheritedDataHolder =
        context.dependOnInheritedWidgetOfExactType<InheritedDataHolder<T>>();
    // if not found, try to find
    inheritedDataHolder ??= context.dependOnInheritedWidgetOfExactType<InheritedRootDataHolder>();
    final messenger = inheritedDataHolder?.holder;
    if (messenger != _messenger) {
      _messenger?.unregister(this);
      _messenger = messenger;
      _messenger?.register(this);
    }
  }

  @override
  void dispose() {
    _messenger?.unregister(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Data<T>.inherit(data: widget.data, child: DataMessenger<T>(child: widget.child));
  }
}

/// An internal interface that provides dataType and wrap method.
abstract class MultiDataItem {
  /// The compile-time type of the data.
  Type get dataType;

  /// Wraps the [child] widget with the data.
  Widget wrapWidget(Widget child);
}

/// A widget that passes value from a ValueListenable to its descendants.
/// The data is refreshed when the ValueListenable changes.
class DataNotifier<T> extends StatelessWidget implements MultiDataItem {
  /// The ValueListenable that holds the data.
  final ValueListenable<T> notifier;
  final Widget? _child;

  /// Creates a DataNotifier for MultiData.
  const DataNotifier(this.notifier, {super.key}) : _child = null;

  /// Creates a single DataNotifier widget.
  const DataNotifier.inherit({super.key, required this.notifier, required Widget child}) : _child = child;

  @override
  Widget wrapWidget(Widget child) {
    return DataNotifier<T>.inherit(notifier: notifier, child: child);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: notifier,
      builder: (context, value, child) {
        return Data<T>.inherit(data: value, child: child!);
      },
      child: _child,
    );
  }

  @override
  Type get dataType => T;
}

/// A widget builder that receives the data from the ancestor Data widget.
typedef DataWidgetBuilder<T> = Widget Function(BuildContext context, T data, Widget? child);

/// A widget builder that receives the data (that may be null) from the ancestor
typedef OptionalDataWidgetBuilder<T> = Widget Function(BuildContext context, T? data, Widget? child);

/// A widget that receives the data from the ancestor Data widget.
class DataBuilder<T> extends StatelessWidget {
  final DataWidgetBuilder<T>? _builder;
  final OptionalDataWidgetBuilder<T>? _optionalBuilder;

  /// The child widget.
  final Widget? child;

  /// Creates a DataBuilder that optionally receives the data.
  const DataBuilder.optionally({super.key, required OptionalDataWidgetBuilder<T> builder, this.child})
    : _builder = null,
      _optionalBuilder = builder;

  /// Creates a DataBuilder that must receive the data.
  const DataBuilder({super.key, required DataWidgetBuilder<T> builder, this.child})
    : _builder = builder,
      _optionalBuilder = null;

  @override
  Widget build(BuildContext context) {
    final data = Data.maybeOf<T>(context);
    if (_builder != null) {
      assert(data != null, 'No Data<$T> found in context');
      return _builder(context, data as T, child);
    }
    return _optionalBuilder!(context, data, child);
  }
}

/// A widget that provides multiple data to its descendants.
class MultiData extends StatefulWidget {
  /// The list of data that will be provided to the descendants.
  final List<MultiDataItem> data;

  /// The child widget.
  final Widget child;

  /// Creates a MultiData.
  const MultiData({super.key, required this.data, required this.child});

  @override
  State<MultiData> createState() => _MultiDataState();
}

class _MultiDataState extends State<MultiData> {
  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    Widget result = KeyedSubtree(key: _key, child: widget.child);
    for (final data in widget.data) {
      // make sure dataType is not dynamic
      final Type dataType = data.dataType;
      assert(dataType != dynamic, 'Data must have a type');
      result = data.wrapWidget(result);
    }
    return result;
  }
}

/// A widget that provides the data to its descendants.
class Data<T> extends StatelessWidget implements MultiDataItem {
  final T? _data;

  /// The child widget.
  final Widget? child;

  /// Creates a Data for MultiData.
  const Data(T data, {super.key}) : _data = data, child = null, super();

  /// Creates a single Data widget.
  const Data.inherit({super.key, required T data, this.child}) : _data = data;

  /// Creates a boundary Data widget that stops the data from being passed to its descendants.
  const Data.boundary({super.key, this.child}) : _data = null;

  /// The data that will be provided to the descendants.
  T get data {
    assert(_data != null, 'No Data<$T> found in context');
    return _data!;
  }

  @override
  Widget wrapWidget(Widget child) {
    return _InheritedData<T>._internal(key: key, data: _data, child: child);
  }

  @override
  Widget build(BuildContext context) {
    assert(dataType != dynamic, 'Data must have a type');
    return _InheritedData<T>._internal(data: _data, child: child ?? const SizedBox());
  }

  /// Find and collect all the data of the given type from the context.
  ///
  /// * [T] The type of the data.
  /// * [context] The build context.
  static List<T> collect<T>(BuildContext context) {
    final List<T> data = [];
    context.visitAncestorElements((element) {
      if (element.widget is Data<T>) {
        var currentData = (element.widget as Data<T>)._data;
        if (currentData != null) {
          data.add(currentData);
        } else {
          return false;
        }
      }
      return true;
    });
    return data;
  }

  /// Visit all Data ancestors of the given type from the context.
  ///
  /// * [T] The type of the data.
  /// * [context] The build context.
  /// * [visitor] The visitor function that returns false to stop the visiting.
  static void visitAncestors<T>(BuildContext context, bool Function(T data) visitor) {
    context.visitAncestorElements((element) {
      if (element.widget is Data<T>) {
        var currentData = (element.widget as Data<T>)._data;
        if (currentData != null) {
          if (!visitor(currentData)) {
            return false;
          }
        } else {
          return false;
        }
      }
      return true;
    });
  }

  /// {@template Data.of}
  /// Find and listen to data changes of the data with the given type from the context.
  ///
  /// * [T] The type of the data.
  /// * [context] The build context.
  /// {@endtemplate}
  static T of<T>(BuildContext context) {
    final data = maybeOf<T>(context);
    assert(data != null, 'No Data<$T> found in context');
    return data!;
  }

  /// {@template Data.maybeFind}
  /// Optionally find the data of the given type from the context.
  ///
  /// * [T] The type of the data.
  /// * [context] The build context.
  /// {@endtemplate}
  static T? maybeFind<T>(BuildContext context) {
    assert(context.mounted, 'The context must be mounted');
    final widget = context.findAncestorWidgetOfExactType<Data<T>>();
    if (widget == null) {
      return null;
    }
    return widget.data;
  }

  /// {@template Data.maybeFindMessenger}
  /// Find the DataMessenger that holds all of the data with the given type from the context.
  ///
  /// * [T] The type of the data.
  /// * [context] The build context.
  /// {@endtemplate}
  static T? maybeFindMessenger<T>(BuildContext context) {
    assert(context.mounted, 'The context must be mounted');
    InheritedDataHolderWidget? holder = context.findAncestorWidgetOfExactType<InheritedDataHolder<T>>();
    holder ??= context.findAncestorWidgetOfExactType<InheritedRootDataHolder>();
    if (holder != null) {
      return holder.holder.findData(context, T);
    }
    return null;
  }

  /// {@template Data.findMessenger}
  /// Find the stored data somewhere in the ancestor DataMessenger descendants.
  /// Throws an assertion error if the data is not found.
  /// - [T] The type of the data.
  /// - [context] The build context.
  /// {@endtemplate}
  static T findMessenger<T>(BuildContext context) {
    final data = maybeFindMessenger<T>(context);
    assert(data != null, 'No Data<$T> found in context');
    return data!;
  }

  /// {@template Data.find}
  /// Find the data of the given type from the context. Does not listen
  /// to the data changes.
  ///
  /// * [T] The type of the data.
  /// * [context] The build context.
  /// {@endtemplate}
  static T find<T>(BuildContext context) {
    final data = maybeFind<T>(context);
    assert(data != null, 'No Data<$T> found in context');
    return data!;
  }

  /// {@template Data.maybeFindRoot}
  /// Optionally find the root data of the given type from the context.
  ///
  /// * [T] The type of the data.
  /// * [context] The build context.
  /// {@endtemplate}
  static T? maybeFindRoot<T>(BuildContext context) {
    assert(context.mounted, 'The context must be mounted');
    T? found;
    context.visitAncestorElements((element) {
      if (element.widget is Data<T>) {
        var data = (element.widget as Data<T>)._data;
        if (data != null) {
          found = data;
        }
      }
      return true;
    });
    return found;
  }

  /// {@template Data.findRoot}
  /// Find the root data of the given type from the context.
  /// Throws an assertion error if the data is not found.
  ///
  /// * [T] The type of the data.
  /// * [context] The build context.
  /// {@endtemplate}
  static T findRoot<T>(BuildContext context) {
    final data = maybeFindRoot<T>(context);
    assert(data != null, 'No Data<$T> found in context');
    return data!;
  }

  /// {@template Data.maybeOf}
  /// Optionally find and listen to data changes of the data with the given type from the context.
  ///
  /// * [T] The type of the data.
  /// * [context] The build context.
  /// {@endtemplate}
  static T? maybeOf<T>(BuildContext context) {
    assert(context.mounted, 'The context must be mounted');
    final widget = context.dependOnInheritedWidgetOfExactType<_InheritedData<T>>();
    if (widget == null) {
      return null;
    }
    return widget.data;
  }

  /// Capture all the data from another context and wrap the child that can
  /// receive the data.
  ///
  /// * [context] The context to capture the data.
  /// * [child] The child widget that can receive the data.
  static Widget captureAll(BuildContext context, Widget child, {BuildContext? to}) {
    return capture(from: context, to: to).wrap(child);
  }

  /// Capture all the data from another context.
  ///
  /// * [context] The context to capture the data.
  /// * [to] The context to stop capturing the data.
  static CapturedData capture({required BuildContext from, required BuildContext? to}) {
    if (from == to) {
      return CapturedData._([]);
    }
    final data = <_InheritedData>[];
    final Set<Type> dataTypes = <Type>{};
    late bool debugDidFindAncestor;
    assert(() {
      debugDidFindAncestor = to == null;
      return true;
    }());

    from.visitAncestorElements((ancestor) {
      if (ancestor == to) {
        assert(() {
          debugDidFindAncestor = true;
          return true;
        }());
        return false;
      }
      if (ancestor is InheritedElement && ancestor.widget is _InheritedData) {
        final _InheritedData dataWidget = ancestor.widget as _InheritedData;
        final Type dataType = dataWidget.dataType;
        if (!dataTypes.contains(dataType)) {
          dataTypes.add(dataType);
          data.add(dataWidget);
        }
      }
      return true;
    });

    assert(debugDidFindAncestor, 'The provided `to` context must be an ancestor of the `from` context.');

    return CapturedData._(data);
  }

  @override
  Type get dataType => T;
}

class _InheritedData<T> extends InheritedWidget {
  final T? data;

  Type get dataType => T;

  const _InheritedData._internal({super.key, required this.data, required super.child});

  @override
  bool updateShouldNotify(covariant _InheritedData<T> oldWidget) {
    if (data is DistinctData && oldWidget.data is DistinctData) {
      return (data as DistinctData).shouldNotify(oldWidget.data as DistinctData);
    }
    return oldWidget.data != data;
  }

  Widget? wrap(Widget child, BuildContext context) {
    _InheritedData<T>? ancestor = context.dependOnInheritedWidgetOfExactType<_InheritedData<T>>();
    // if it's the same type, we don't need to wrap it
    if (identical(this, ancestor)) {
      return null;
    }
    final data = this.data;
    if (data == null) {
      return Data<T>.boundary(child: child);
    }
    return Data<T>.inherit(data: data, child: child);
  }
}

/// CapturedData holds all the data captured from another context.
class CapturedData {
  CapturedData._(this._data);

  final List<_InheritedData> _data;

  /// Wraps the child widget with the captured data.
  Widget wrap(Widget child) {
    return _CaptureAllData(data: _data, child: child);
  }
}

class _CaptureAllData extends StatelessWidget {
  const _CaptureAllData({required this.data, required this.child});

  final List<_InheritedData> data;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget result = child;
    for (final data in data) {
      var wrap = data.wrap(result, context);
      if (wrap == null) {
        continue;
      }
      result = wrap;
    }
    return result;
  }
}
