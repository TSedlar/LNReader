import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

class ObservableValue<T> {
  static final Map<int, List<MapEntry<ObservableValue, StreamSubscription>>>
      _subMap = {};

  T _value;
  StreamController<T> _streamController = StreamController.broadcast();

  T get value => _value;

  T get val => _value;

  bool get seen => val != null;

  Stream<T> get stream => _streamController.stream;

  set value(T t) {
    if (t is Map && !(t is ObservableMap)) {
      try {
        final ObservableMap map = ObservableMap(t as Map);
        t = map as T;
        map._instance = this;
      } catch (err) {
        throw ArgumentError(
          'If using a typed map, use ObservableValue#fromMap',
        );
      }
    } else if (t is List && !(t is _ObservableList)) {
      try {
        final _ObservableList list = _ObservableList(t as List);
        t = list as T;
        list._instance = this;
      } catch (err) {
        throw ArgumentError(
          'If using a typed list, use ObservableValue#fromList',
        );
      }
    }
    _value = t;
    _streamController.add(_value);
  }

  set val(T t) => value = t;

  ObservableValue([T value]) {
    if (value != null) {
      this.value = value;
    }
  }

  StreamSubscription<T> listen(void Function(T) onData) =>
      stream.listen(onData);

  void dispose() {
    _streamController.close();
  }

  static ObservableValue<Map<K, V>> fromMap<K, V>(Map<K, V> map) {
    final observableMap = ObservableMap<K, V>(map);
    final observable = ObservableValue<ObservableMap<K, V>>(observableMap);
    observableMap._instance = observable;
    return observable;
  }

  static ObservableValue<List<E>> fromList<E>(List<E> list) {
    final observableList = _ObservableList<E>(list);
    final observable = ObservableValue<_ObservableList<E>>(observableList);
    observableList._instance = observable;
    return observable;
  }

  void bind(State state) {
    // Ignore the warning below because we dispose in disposeAt
    // ignore: cancel_subscriptions
    final sub = listen((_) {
      // Refresh the state when update is observed
      if (state.mounted) {
        state.setState(() {}); // ignore: invalid_use_of_protected_member
      }
    });

    final hash = state.hashCode;

    if (!_subMap.containsKey(hash)) {
      _subMap[hash] = [];
    }

    _subMap[hash].add(MapEntry(this, sub));
  }

  void disposeAt(State state) {
    final hash = state.hashCode;
    if (_subMap.containsKey(hash)) {
      _subMap[hash].forEach((entry) {
        if (entry.key == this) {
          try {
            entry.value.cancel();
          } catch (err) {
            // ignore, it's already been cancelled.
          }
        }
      });
    }
  }

  static void disposeAll() {
    _subMap.values.forEach((entries) {
      entries.forEach((entry) {
        try {
          entry.value.cancel();
        } catch (err) {
          // ignore, it's already been cancelled.
        }
      });
    });
  }
}

class ObservableMap<K, V> extends DelegatingMap<K, V> {
  ObservableValue _instance;

  ObservableMap(Map<K, V> base) : super(base);

  void operator []=(K key, V value) {
    super[key] = value;
    _instance.value = this;
  }

  void addAll(Map<K, V> other) {
    super.addAll(other);
    _instance.value = this;
  }

  void addEntries(Iterable<MapEntry<K, V>> entries) {
    super.addEntries(entries);
    _instance.value = this;
  }

  void clear() {
    super.clear();
    _instance.value = this;
  }

  V putIfAbsent(K key, V ifAbsent()) {
    V result = super.putIfAbsent(key, ifAbsent);
    _instance.value = this;
    return result;
  }

  V remove(Object key) {
    V removed = super.remove(key);
    _instance.value = this;
    return removed;
  }

  void removeWhere(bool test(K key, V value)) {
    super.removeWhere(test);
    _instance.value = this;
  }

  V update(K key, V update(V value), {V ifAbsent()}) {
    V result = super.update(key, update, ifAbsent: ifAbsent);
    _instance.value = this;
    return result;
  }

  void updateAll(V update(K key, V value)) {
    super.updateAll(update);
    _instance.value = this;
  }
}

class _ObservableList<T> extends DelegatingList<T> {
  ObservableValue _instance;

  _ObservableList(List<T> base) : super(base);

  void operator []=(int index, T value) {
    super[index] = value;
    _instance.value = this;
  }

  void add(T value) {
    super.add(value);
    _instance.value = this;
  }

  void addAll(Iterable<T> iterable) {
    super.addAll(iterable);
    _instance.value = this;
  }

  void clear() {
    super.clear();
    _instance.value = this;
  }

  void fillRange(int start, int end, [T fillValue]) {
    super.fillRange(start, end, fillValue);
    _instance.value = this;
  }

  void insert(int index, T element) {
    super.insert(index, element);
    _instance.value = this;
  }

  insertAll(int index, Iterable<T> iterable) {
    super.insertAll(index, iterable);
    _instance.value = this;
  }

  bool remove(Object value) {
    bool removed = super.remove(value);
    _instance.value = this;
    return removed;
  }

  T removeAt(int index) {
    T removed = super.removeAt(index);
    _instance.value = this;
    return removed;
  }

  T removeLast() {
    T removed = super.removeLast();
    _instance.value = this;
    return removed;
  }

  void removeRange(int start, int end) {
    super.removeRange(start, end);
    _instance.value = this;
  }

  void removeWhere(bool test(T element)) {
    super.removeWhere(test);
    _instance.value = this;
  }

  void replaceRange(int start, int end, Iterable<T> iterable) {
    super.replaceRange(start, end, iterable);
    _instance.value = this;
  }

  void retainWhere(bool test(T element)) {
    super.retainWhere(test);
    _instance.value = this;
  }

  void setAll(int index, Iterable<T> iterable) {
    super.setAll(index, iterable);
    _instance.value = this;
  }

  void setRange(int start, int end, Iterable<T> iterable, [int skipCount = 0]) {
    super.setRange(start, end, iterable, skipCount);
    _instance.value = this;
  }

  void shuffle([Random random]) {
    super.shuffle(random);
    _instance.value = this;
  }

  void sort([int compare(T a, T b)]) {
    super.sort(compare);
    _instance.value = this;
  }
}
