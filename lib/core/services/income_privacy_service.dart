import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';

// FORK: income amounts are hidden by default. The state is in memory only, so
// every launch starts hidden, and sending the app to the background hides it
// again.
class IncomePrivacyService {
  IncomePrivacyService._() {
    _lifecycleListener = AppLifecycleListener(onHide: hide);
  }
  static final IncomePrivacyService instance = IncomePrivacyService._();

  // ignore: unused_field
  late final AppLifecycleListener _lifecycleListener;

  final _hidden = BehaviorSubject<bool>.seeded(true);

  Stream<bool> get hiddenStream => _hidden.stream;
  bool get isHidden => _hidden.value;

  void reveal() => _hidden.add(false);

  void hide() => _hidden.add(true);
}
