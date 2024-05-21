import 'package:test/expect.dart';

List<Matcher> _wrapArgs(Object? arg0, Object? arg1, Object? arg2, Object? arg3,
    Object? arg4, Object? arg5, Object? arg6) {
  Iterable args;
  if (arg0 is List) {
    if (arg1 != null ||
        arg2 != null ||
        arg3 != null ||
        arg4 != null ||
        arg5 != null ||
        arg6 != null) {
      throw ArgumentError('If arg0 is a List, all other arguments must be'
          ' null.');
    }

    args = arg0;
  } else {
    args = [arg0, arg1, arg2, arg3, arg4, arg5, arg6].where((e) => e != null);
  }

  return args.map(wrapMatcher).toList();
}

Matcher allOfOrNone(
  Object? arg0, [
  Object? arg1,
  Object? arg2,
  Object? arg3,
  Object? arg4,
  Object? arg5,
  Object? arg6,
]) {
  return _AllOfOrNone(_wrapArgs(
    arg0,
    arg1,
    arg2,
    arg3,
    arg4,
    arg5,
    arg6,
  ));
}

class _AllOfOrNone extends Matcher {
  final List<Matcher> _matchers;

  const _AllOfOrNone(this._matchers);

  @override
  bool matches(dynamic item, Map matchState) {
    bool? lastMatch;
    for (var matcher in _matchers) {
      final result = matcher.matches(item, matchState);

      if (lastMatch == null) {
        lastMatch = result;
      } else if (lastMatch != result) {
        addStateInfo(matchState, {'matcher': matcher});
        return false;
      }
    }
    return true;
  }

  @override
  Description describeMismatch(dynamic item, Description mismatchDescription,
      Map matchState, bool verbose) {
    var matcher = matchState['matcher'];
    matcher.describeMismatch(
        item, mismatchDescription, matchState['state'], verbose);
    return mismatchDescription;
  }

  @override
  Description describe(Description description) =>
      description.addAll('(', ' and ', ') or none', _matchers);
}
