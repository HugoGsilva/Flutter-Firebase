sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
    Success(data: final d) => d,
    Failure() => null,
  };

  Exception? get errorOrNull => switch (this) {
    Success() => null,
    Failure(error: final e) => e,
  };
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final Exception error;
  const Failure(this.error);
}
