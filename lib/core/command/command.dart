import 'package:flutter/foundation.dart';
import '../result/result.dart';

abstract class Command<T> extends ChangeNotifier {
  bool _running = false;
  bool get running => _running;

  Result<T>? _result;
  Result<T>? get result => _result;

  bool get completed => _result != null;

  @protected
  void setRunning(bool value) {
    _running = value;
    notifyListeners();
  }

  @protected
  void setResult(Result<T> result) {
    _result = result;
    notifyListeners();
  }

  Future<void> execute();
}
