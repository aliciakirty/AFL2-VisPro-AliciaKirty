stateDiagram-v2
[*] --> Initial

    Initial --> Loading: Aplikasi dibuka

    Loading --> SuccessIdle: Data berhasil dimuat
    Loading --> Error: Data gagal dimuat

    Error --> Loading: Pengguna menekan Coba Lagi

    state "TodoSuccess (isBusy = false)" as SuccessIdle
    state "TodoSuccess (isBusy = true)" as SuccessBusy

    SuccessIdle --> SuccessBusy: Tambah / Edit / Hapus / Toggle / Refresh

    SuccessBusy --> SuccessIdle: Operasi berhasil
    SuccessBusy --> SuccessIdle: Operasi gagal

    SuccessIdle --> SuccessIdle: Mengubah filter

    note right of SuccessBusy
      Tampilan daftar tetap tersedia.
      Tombol aksi dinonaktifkan.
      Indikator proses ditampilkan.
    end note

    note right of Error
      Menampilkan pesan kesalahan
      dan tombol Coba Lagi.
    end note

    note left of SuccessIdle
      Jika operasi gagal:
      daftar lama dipertahankan.
      CommandResult.failure ditampilkan
      melalui Snackbar.
    end note