import 'package:flutter_test/flutter_test.dart';
import 'package:monekin/app/categories/selectors/category_picker.dart';

void main() {
  group('reorderSubset', () {
    test('keeps ids outside the subset in place', () {
      final all = ['a', 'x', 'b', 'y', 'c'];

      expect(reorderSubset(all, ['c', 'a', 'b']), ['c', 'x', 'a', 'y', 'b']);
    });

    test('same order is a no-op', () {
      final all = ['a', 'b', 'c'];

      expect(reorderSubset(all, ['a', 'b', 'c']), all);
    });
  });
}
