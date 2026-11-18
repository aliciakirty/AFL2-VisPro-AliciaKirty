import '../../domain/failures/todo_failure.dart';

String describeFailure(TodoFailure failure, {required String fallback}) {
  return switch (failure) {
    EmptyTitleFailure() => 'Judul tugas tidak boleh kosong.',
    NetworkFailure() =>
    'Tidak ada koneksi internet. Periksa koneksimu lalu coba lagi.',
    ServerFailure() => 'Server sedang bermasalah. Silakan coba lagi nanti.',
    NotFoundFailure() => 'Tugas tidak ditemukan. Mungkin sudah dihapus.',
    StorageFailure() || UnknownFailure() => '$fallback Silakan coba lagi.',
  };
}