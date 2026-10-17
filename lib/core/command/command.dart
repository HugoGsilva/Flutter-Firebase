import 'package:flutter/foundation.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../result/result.dart';

abstract class Command<T> extends ChangeNotifier {
  Command() {
    _runningSignal = signal<bool>(_running);
    _resultSignal = signal<Result<T>?>(_result);
  }

  bool _running = false;
  bool get running => _running;

  Result<T>? _result;
  Result<T>? get result => _result;

  bool get completed => _result != null;
  bool get error => _result is Failure;

  late final Signal<bool> _runningSignal;
  Signal<bool> get runningSignal => _runningSignal;

  late final Signal<Result<T>?> _resultSignal;
  Signal<Result<T>?> get resultSignal => _resultSignal;

  @protected
  void setRunning(bool value) {
    _running = value;
    _runningSignal.value = value;
    notifyListeners();
  }

  @protected
  void setResult(Result<T> res) {
    _result = res;
    _resultSignal.value = res;
    notifyListeners();
  }

  void clearResult() {
    _result = null;
    _resultSignal.value = null;
    notifyListeners();
  }

  @protected
  Future<Result<T>> runInternal(Future<Result<T>> Function() action) async {
    if (_running) {
      return _result ?? Failure(Exception('Comando em execução'));
    }
    setRunning(true);
    try {
      final res = await action();
      setResult(res);
      return res;
    } catch (e) {
      final res = Failure<T>(e is Exception ? e : Exception(e.toString()));
      setResult(res);
      return res;
    } finally {
      setRunning(false);
    }
  }
}

class Command0<T> extends Command<T> {
  Command0(this._action);

  final Future<Result<T>> Function() _action;

  Future<Result<T>> execute() => runInternal(_action);
  Future<Result<T>> call() => execute();
}

class Command1<T, A> extends Command<T> {
  Command1(this._action);

  final Future<Result<T>> Function(A arg) _action;

  Future<Result<T>> execute(A arg) => runInternal(() => _action(arg));
  Future<Result<T>> call(A arg) => execute(arg);
}

class Command2<T, A, B> extends Command<T> {
  Command2(this._action);

  final Future<Result<T>> Function(A arg1, B arg2) _action;

  Future<Result<T>> execute(A arg1, B arg2) =>
      runInternal(() => _action(arg1, arg2));
  Future<Result<T>> call(A arg1, B arg2) => execute(arg1, arg2);
}

class Command3<T, A, B, C> extends Command<T> {
  Command3(this._action);

  final Future<Result<T>> Function(A arg1, B arg2, C arg3) _action;

  Future<Result<T>> execute(A arg1, B arg2, C arg3) =>
      runInternal(() => _action(arg1, arg2, arg3));
  Future<Result<T>> call(A arg1, B arg2, C arg3) => execute(arg1, arg2, arg3);
}

class CommandOptional1<T, A> extends Command<T> {
  CommandOptional1(this._action);

  final Future<Result<T>> Function([A? arg]) _action;

  Future<Result<T>> execute([A? arg]) => runInternal(() => _action(arg));
  Future<Result<T>> call([A? arg]) => execute(arg);
}
