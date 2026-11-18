# DOKUMENTASI ARSITEKTUR APLIKASI TO DO

## 1. Pembagian Lapisan (Layers)

Aplikasi To Do menggunakan Layered Architecture yang terdiri dari empat lapisan:

- **Presentation:** Berisi `TodoPage`, `TodoViewModel`, state, dan widget. Bertanggung jawab menampilkan antarmuka serta mengelola interaksi pengguna.
- **Domain:** Berisi entitas `Todo`, repository interface, use case, dan failure. Lapisan ini mengatur aturan bisnis dan tidak bergantung pada lapisan lain.
- **Data:** Berisi model, data source, dan implementasi repository. Bertanggung jawab mengelola data menggunakan SharedPreferences serta melakukan konversi JSON.
- **Core:** Berisi komponen bersama dan konfigurasi Dependency Injection, termasuk `AppColors` dan `AppDependencies`.

Arah ketergantungan aplikasi adalah Presentation dan Data bergantung pada Domain. Domain tidak bergantung pada lapisan lainnya. Presentation tidak mengakses Data secara langsung.

## 2. Pola Arsitektur (Pattern)

Aplikasi menerapkan pola Model-View-ViewModel (MVVM):

- **Model:** Mengelola data aplikasi melalui entitas Domain dan komponen Data.
- **View:** `TodoPage` bertugas menampilkan data dan menerima interaksi pengguna.
- **ViewModel:** `TodoViewModel` mengelola keadaan layar menggunakan `ChangeNotifier` dan mengoordinasikan pemanggilan use case.

Keadaan aplikasi didefinisikan menggunakan sealed class `TodoState` yang terdiri dari `TodoInitial`, `TodoLoading`, `TodoSuccess`, dan `TodoError`. Setiap state menggunakan Equatable untuk mendukung perbandingan berdasarkan nilai.

## 3. Alasan Pemilihan Arsitektur (Justification)

Layered Architecture dan MVVM dipilih untuk memisahkan tanggung jawab antarkomponen aplikasi. Pemisahan ini membuat logika tampilan tidak bercampur dengan aturan bisnis maupun proses penyimpanan data.

Penggunaan repository interface pada Domain memungkinkan implementasi sumber data diganti tanpa mengubah ViewModel dan use case. Selain itu, pemisahan setiap lapisan mempermudah pengujian, pemeliharaan, dan pengembangan aplikasi.

## 4. Dependency Injection (DI)

Dependency Injection diterapkan melalui `AppDependencies` pada `core/di/injection.dart` sebagai composition root.

Komponen ini bertanggung jawab membuat dan menghubungkan repository, use case, serta `TodoViewModel`.

Aplikasi memiliki dua implementasi repository:

1. `TodoRepositoryImpl`, menggunakan SharedPreferences untuk penyimpanan permanen.
2. `InMemoryTodoRepository`, menggunakan memori sementara.

Pemilihan sumber data dilakukan melalui satu baris konfigurasi pada `AppDependencies.create()`. Pergantian implementasi repository tidak memerlukan perubahan pada ViewModel maupun use case.

Dengan pendekatan ini, ketergantungan aplikasi lebih terstruktur dan sumber data dapat diganti melalui konfigurasi Dependency Injection.