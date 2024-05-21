import 'package:test/test.dart';

// Partially copied from the `package:test` library.
abstract class FeatureMatcher<T> extends TypeMatcher<T> {
  const FeatureMatcher();

  @override
  bool matches(dynamic item, Map matchState) =>
      super.matches(item, matchState) && typedMatches(item as T, matchState);

  bool typedMatches(T item, Map matchState);

  @override
  Description describeMismatch(Object? item, Description mismatchDescription,
      Map matchState, bool verbose) {
    if (item is T) {
      return describeTypedMismatch(
          item, mismatchDescription, matchState, verbose);
    }

    return super.describe(mismatchDescription.add('not an '));
  }

  Description describeTypedMismatch(T item, Description mismatchDescription,
          Map matchState, bool verbose) =>
      mismatchDescription;
}

/// Matches [Iterable]s where exactly one element matches the expected
/// value, and all other elements don't match.
Matcher containsAtMostOne(Object? expected) => _ContainsAtMostOne(expected);

class _ContainsAtMostOne extends FeatureMatcher<Iterable> {
  final Object? _expected;

  _ContainsAtMostOne(this._expected);

  String? _test(Iterable item, Map matchState) {
    var matcher = wrapMatcher(_expected);
    var matches = [
      for (var value in item)
        if (matcher.matches(value, matchState)) value,
    ];
    if (matches.length <= 1) {
      return null;
    }
    return StringDescription()
        .add('expected at most one value matching ')
        .addDescriptionOf(matcher)
        .add(' but found multiple: ')
        .addAll('', ', ', '', matches)
        .toString();
  }

  @override
  bool typedMatches(Iterable item, Map matchState) =>
      _test(item, matchState) == null;

  @override
  Description describe(Description description) => description
      .add('contains at most one(')
      .addDescriptionOf(_expected)
      .add(')');

  @override
  Description describeTypedMismatch(Iterable item,
          Description mismatchDescription, Map matchState, bool verbose) =>
      mismatchDescription.add(_test(item, matchState)!);
}
