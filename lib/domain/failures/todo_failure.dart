sealed class TodoFailure implements Exception {
  const TodoFailure();
}

final class EmptyTitleFailure extends TodoFailure {
  const EmptyTitleFailure();
}

final class StorageFailure extends TodoFailure {
  const StorageFailure([this.cause]);
  final Object? cause;
}

final class NotFoundFailure extends TodoFailure {
  const NotFoundFailure();
}

final class NetworkFailure extends TodoFailure {
  const NetworkFailure();
}

final class ServerFailure extends TodoFailure {
  const ServerFailure([this.statusCode]);
  final int? statusCode;
}

final class UnknownFailure extends TodoFailure {
  const UnknownFailure([this.cause]);
  final Object? cause;
}