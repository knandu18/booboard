// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appName => 'BooBoard';

  @override
  String get homeTagline => 'Pengetikan pribadi, di ponsel ini';

  @override
  String get homeOfflinePromise =>
      'BooBoard berfungsi luring dan *tidak mengirim apa pun ke mana pun.*';

  @override
  String get cancel => 'Batal';

  @override
  String get delete => 'Hapus';

  @override
  String get save => 'Simpan';

  @override
  String get useAction => 'Gunakan';

  @override
  String get off => 'Nonaktif';

  @override
  String get left => 'Kiri';

  @override
  String get right => 'Kanan';

  @override
  String get settingsLanguages => 'Bahasa';

  @override
  String get settingsTyping => 'Pengetikan';

  @override
  String get settingsFeel => 'Rasa';

  @override
  String get settingsThemes => 'Tema';

  @override
  String get settingsPanels => 'Panel';

  @override
  String get settingsVoice => 'Suara';

  @override
  String get settingsTranslation => 'Terjemahan';

  @override
  String get settingsPrivacy => 'Privasi';

  @override
  String get settingsAbout => 'Tentang';

  @override
  String get settingsModelPacks => 'Paket model';

  @override
  String get homeSetupTurnOn => 'Aktifkan BooBoard di daftar keyboard Android.';

  @override
  String get homeSetupChoose =>
      'Pilih BooBoard sebagai keyboard untuk mengetik.';

  @override
  String get homeFinishSetup => 'Selesaikan pengaturan BooBoard';

  @override
  String get homeTypingSubtitle => 'Koreksi, saran, tombol, dan geser';

  @override
  String get homeFeelSubtitle => 'Getaran, suara, tinggi, dan mode satu tangan';

  @override
  String get homePanelsSubtitle => 'Papan klip dan emoji';

  @override
  String get homeVoiceSubtitle => 'Bicara untuk mengetik, di ponsel ini';

  @override
  String get homeTranslationSubtitle => 'Terjemahkan saat mengetik, luring';

  @override
  String get homePrivacySubtitle =>
      'Apa yang disimpan, penyamaran, kunci aplikasi, dan cadangan';

  @override
  String get homeAboutSubtitle => 'Versi, lisensi, dan kode sumber';

  @override
  String get homeImages => 'Gambar';

  @override
  String get homeAboutBooBoard => 'Tentang BooBoard';

  @override
  String get websiteOpenHint => 'Membuka booboard.com di browser Anda';

  @override
  String get websiteNoBrowser =>
      'Tidak ada browser yang bisa membuka booboard.com.';

  @override
  String get imagesSoonTitle => 'Gambar *segera hadir*';

  @override
  String get imagesSoonBody =>
      'Buat gambar dari kata-kata Anda, langsung di ponsel ini. Seperti semua hal di BooBoard, fitur ini akan bekerja offline.';

  @override
  String get aboutWebsite => 'Situs web';

  @override
  String get aboutTitle => 'Tentang';

  @override
  String aboutVersion(String versionCode, String versionName) {
    return 'Versi $versionName ($versionCode)';
  }

  @override
  String aboutVersionDebug(String versionCode, String versionName) {
    return 'Versi $versionName ($versionCode) · build debug';
  }

  @override
  String get aboutReadingVersion => 'Membaca versi…';

  @override
  String get aboutPrivacy => 'Privasi';

  @override
  String get aboutNoInternet => 'BooBoard tidak dapat menggunakan internet';

  @override
  String get aboutNoInternetBody =>
      'Build rilis tidak punya izin internet, jadi tidak ada yang Anda ketik yang keluar dari ponsel ini.';

  @override
  String get aboutLicence => 'Lisensi';

  @override
  String get aboutGplTitle => 'GNU General Public License v3 atau lebih baru';

  @override
  String get aboutGplBody =>
      'BooBoard adalah perangkat lunak bebas. Anda boleh mempelajari, mengubah, dan membagikannya di bawah GPL.';

  @override
  String get aboutSourceCode => 'Kode sumber';

  @override
  String get aboutSourceBody =>
      'BooBoard adalah GPL-3.0-or-later. Kode sumbernya tersedia di halaman proyek.';

  @override
  String get aboutLicences => 'Lisensi';

  @override
  String get aboutOpenSource => 'Lisensi sumber terbuka';

  @override
  String get aboutOpenSourceBody =>
      'Flutter, material_ui, dan setiap paket yang dipakai BooBoard';

  @override
  String get aboutTextLoadFailed => 'Teks ini tidak dapat dimuat.';

  @override
  String get languagesEnabledHeader => 'Aktif, yang pertama adalah default';

  @override
  String get languagesActive => 'Bahasa aktif';

  @override
  String get languagesAdd => 'Tambah bahasa';

  @override
  String get languagesAllEnabled => 'Semua bahasa aktif';

  @override
  String get languagesAllEnabledBody =>
      'Hapus salah satu di atas untuk memberi ruang.';

  @override
  String get languagesMultilingual => 'Pengetikan multibahasa';

  @override
  String get languagesMultilingualBody =>
      'Menyarankan kata dari hingga tiga bahasa aktif yang memakai aksara yang sama. Kata yang dikenali salah satunya tidak pernah dikoreksi otomatis.';

  @override
  String get languagesNativeDigits => 'Angka asli';

  @override
  String get languagesNativeDigitsBody =>
      'Mengetik angka dalam aksara bahasa aktif jika bahasa itu memilikinya (०१२, ٠١٢).';

  @override
  String get languagesOptions => 'Opsi bahasa';

  @override
  String get languagesZhSubtitle =>
      'Pinyin, karakter tradisional, dan paket kamus';

  @override
  String get languagesJaSubtitle => 'Input flick, konversi, dan paket kamus';

  @override
  String languagesReorderLabel(String language) {
    return 'Seret untuk mengurutkan ulang $language';
  }

  @override
  String languageDefaultLabel(String language) {
    return '$language, default';
  }

  @override
  String languageLayoutTooltip(String language) {
    return 'Tata letak untuk $language';
  }

  @override
  String languageRemoveTooltip(String language) {
    return 'Hapus $language';
  }

  @override
  String get feelHaptics => 'Haptik';

  @override
  String get feelHapticFeedback => 'Umpan balik haptik';

  @override
  String get feelHapticFeedbackBody =>
      'Getaran singkat di setiap tombol, mengikuti pengaturan sistem';

  @override
  String get feelHapticStrength => 'Kekuatan haptik';

  @override
  String get feelSounds => 'Suara';

  @override
  String get feelKeySounds => 'Suara tombol';

  @override
  String get feelKeySoundsBody => 'Klik untuk tombol, spasi, hapus, dan enter';

  @override
  String get feelUseSystemVolume => 'Gunakan volume sistem';

  @override
  String get feelKeySoundVolume => 'Volume suara tombol';

  @override
  String get feelHeight => 'Tinggi';

  @override
  String get feelPortraitHeight => 'Tinggi potret';

  @override
  String get feelLandscapeHeight => 'Tinggi lanskap';

  @override
  String get feelOneHandedFloating => 'Satu tangan dan mengambang';

  @override
  String get feelOneHandedSide => 'Sisi mode satu tangan';

  @override
  String get feelFloatingKeyboard => 'Keyboard mengambang';

  @override
  String get feelFloatingBody => 'Seret ke mana saja di layar';

  @override
  String get panelsClipboard => 'Papan klip';

  @override
  String get panelsClipboardHistory => 'Riwayat papan klip';

  @override
  String get panelsClipboardHistoryBody =>
      'Simpan yang Anda salin, terenkripsi di ponsel ini';

  @override
  String get panelsRecentChip => 'Chip salinan terbaru';

  @override
  String get panelsRecentChipBody =>
      'Tawarkan salinan terakhir Anda di bilah saran selama semenit';

  @override
  String get panelsKeepUnpinned =>
      'Simpan salinan yang tidak disematkan selama';

  @override
  String get panelsClipsToKeep => 'Klip yang disimpan';

  @override
  String get panelsEmoji => 'Emoji';

  @override
  String get emojiSuggestions => 'Saran emoji';

  @override
  String get emojiSuggestionsPanelBody =>
      'Tawarkan emoji untuk beberapa kata di bilah saran';

  @override
  String get panelsPasswordsNeverSaved => 'Kata sandi tidak pernah disimpan';

  @override
  String get panelsSensitiveBody =>
      'Salinan yang ditandai Android sebagai sensitif tidak pernah disimpan.';

  @override
  String get typingCorrections => 'Koreksi';

  @override
  String get typingAutocorrect => 'Koreksi otomatis';

  @override
  String get typingAutocorrectBody =>
      'Memperbaiki salah ketik yang mungkin saat kata selesai';

  @override
  String get typingAutoCapitalise => 'Kapitalisasi otomatis';

  @override
  String get typingAutoCapitaliseBody => 'Huruf kapital di awal kalimat';

  @override
  String get typingDoubleSpace => 'Spasi ganda untuk titik';

  @override
  String get typingDoubleSpaceBody => 'Dua ketukan spasi menulis \". \"';

  @override
  String get typingSmartPunctuation => 'Tanda baca cerdas';

  @override
  String get typingSmartPunctuationBody =>
      'Merapikan spasi di sekitar tanda baca dan memakai tanda kutip lokal';

  @override
  String get typingSuggestions => 'Saran';

  @override
  String get typingSuggestionsBody => 'Menampilkan kata di bilah saran';

  @override
  String get typingNextWord => 'Prediksi kata berikutnya';

  @override
  String get typingNextWordBody => 'Menyarankan kata yang sering mengikuti';

  @override
  String get typingEmojiBody => 'Tawarkan emoji untuk beberapa kata';

  @override
  String get typingHideOffensive => 'Sembunyikan kata kasar';

  @override
  String get typingHideOffensiveBody =>
      'Tidak pernah disarankan kecuali diketik lengkap';

  @override
  String get typingKeys => 'Tombol';

  @override
  String get typingKeyPopups => 'Popup tombol';

  @override
  String get typingKeyPopupsBody => 'Memperbesar tombol saat ditekan';

  @override
  String get typingLongPressDelay => 'Jeda tekan lama';

  @override
  String get typingNumberRow => 'Baris angka';

  @override
  String get typingNumberRowBody => 'Menampilkan 0 sampai 9 di atas huruf';

  @override
  String get typingHintLabels => 'Label petunjuk';

  @override
  String get typingHintLabelsBody => 'Simbol kecil di tombol, misalnya aksen';

  @override
  String get typingLowercaseLabels => 'Label huruf kecil';

  @override
  String get typingLowercaseLabelsBody => 'Tetap huruf kecil saat shift aktif';

  @override
  String get typingSwipe => 'Geser';

  @override
  String get typingSwipeTyping => 'Mengetik dengan geser';

  @override
  String get typingSwipeTypingBody => 'Geser di atas huruf untuk menulis kata';

  @override
  String get typingShowTrail => 'Tampilkan jejak';

  @override
  String get typingTrailWidth => 'Lebar jejak';

  @override
  String get typingTrailFade => 'Pudar jejak';

  @override
  String get typingLivePreview => 'Pratinjau langsung';

  @override
  String get typingLivePreviewBody =>
      'Menampilkan kata yang mungkin saat meluncur';

  @override
  String get typingSpaceMovesCursor => 'Bilah spasi memindahkan kursor';

  @override
  String get typingSpaceMovesCursorBody =>
      'Seret di bilah spasi untuk memindahkan kursor';

  @override
  String get typingSwipeBackspace => 'Geser hapus untuk menghapus kata';

  @override
  String get typingSwipeBackspaceBody =>
      'Geser ke kiri pada hapus untuk memilih dan menghapus kata';

  @override
  String get voiceTyping => 'Mengetik dengan suara';

  @override
  String get voiceTypingBody =>
      'Bicara dalam bahasa Inggris untuk mengetik. Pengenalan berjalan di ponsel ini.';

  @override
  String get voiceRecognition => 'Pengenalan';

  @override
  String get voiceModelPacksBody =>
      'Pasang atau hapus paket suara dan terjemahan';

  @override
  String get voiceAudioStays =>
      'Audio tetap di ponsel ini dan tidak pernah disimpan.';

  @override
  String get voicePackAutomatic => 'Otomatis';

  @override
  String get voicePackAutomaticSelected => 'Otomatis (dipilih)';

  @override
  String get voicePack => 'Paket suara';

  @override
  String get voiceNoPack =>
      'Tidak ada paket suara terpasang. Pasang satu di Paket model.';

  @override
  String get voiceLooking => 'Mencari paket yang terpasang';

  @override
  String voicePackItem(String name, String size) {
    return '$name · $size';
  }

  @override
  String voicePackItemSelected(String name, String size) {
    return '$name · $size (dipilih)';
  }

  @override
  String megabytes(num count) {
    return '$count MB';
  }

  @override
  String milliseconds(num count) {
    return '$count ms';
  }

  @override
  String dpValue(num count) {
    return '$count dp';
  }

  @override
  String get packsOpenFailed => 'BooBoard tidak dapat membuka pemilih file.';

  @override
  String packsInstalled(String name) {
    return '$name dipasang.';
  }

  @override
  String packsDeleteTitle(String name) {
    return 'Hapus $name?';
  }

  @override
  String get packsDeleteBody =>
      'Berkasnya dihapus dari ponsel ini. Anda dapat mengimpor paket itu lagi nanti dari berkasnya.';

  @override
  String packsDeleted(String name) {
    return '$name dihapus.';
  }

  @override
  String packsDeleteFailed(String name) {
    return 'BooBoard tidak dapat menghapus $name. Coba lagi.';
  }

  @override
  String get packsIntro =>
      'Paket diperiksa sebelum dipasang. Isinya hanya data, tidak pernah kode.';

  @override
  String get packsImport => 'Impor';

  @override
  String get packsImportTitle => 'Impor file paket';

  @override
  String get packsChecking => 'Memeriksa dan memasang…';

  @override
  String get packsImportBody => 'File .boopack, misalnya dari Unduhan';

  @override
  String get packsNoVoice => 'Tidak ada paket suara terpasang';

  @override
  String get packsNoVoiceBody =>
      'Mengetik dengan suara memerlukan paket suara.';

  @override
  String get packsNoTranslation => 'Tidak ada paket terjemahan terpasang';

  @override
  String get packsNoTranslationBody =>
      'Terjemahan memerlukan satu paket untuk setiap arah.';

  @override
  String get packsDictionaries => 'Kamus';

  @override
  String get packsNoDictionary => 'Tidak ada paket kamus terpasang';

  @override
  String get packsNoDictionaryBody =>
      'Mengetik bahasa Mandarin dan Jepang memerlukan paket kamus.';

  @override
  String get packsGetTitle => 'Dapatkan paket';

  @override
  String get packsExplainTitle =>
      'Paket adalah berkas yang Anda tambahkan sendiri.';

  @override
  String get packsExplainBody =>
      'Unduh dari halaman rilis proyek di perangkat lain, salin ke ponsel ini, lalu impor.';

  @override
  String get packsCopyLink => 'Salin tautan halaman rilis';

  @override
  String get packsPrivateTitle => 'Cara unduhan tetap pribadi';

  @override
  String get packsPrivateBody =>
      'BooBoard tidak punya izin internet dan tidak pernah terhubung. Unduh membuka browser Anda, yang mengambil paket dari rilis GitHub proyek. Lalu BooBoard memeriksa tanda tangan paket di ponsel ini sebelum memasang apa pun.';

  @override
  String get packsAvailableTitle => 'Paket yang bisa ditambahkan';

  @override
  String get packsDownload => 'Unduh';

  @override
  String packsDownloadMeta(String size) {
    return '$size · membuka browser Anda';
  }

  @override
  String packsDownloadStarted(String name) {
    return 'Browser Anda sedang mengunduh $name. Setelah selesai, ketuk Impor file paket.';
  }

  @override
  String get packsNoBrowser =>
      'Tidak ada browser yang bisa membuka tautan. Salin tautan halaman rilis sebagai gantinya.';

  @override
  String get packsImportCheckedBody =>
      'Pilih file .boopack yang diunduh. File diperiksa di ponsel ini, lalu dipasang.';

  @override
  String get packsAllInstalled =>
      'Semua paket yang diterbitkan sudah terpasang.';

  @override
  String get packsLinkCopied => 'Tautan disalin. Buka di perangkat lain.';

  @override
  String get packsPlayTitle => 'Dapatkan lewat Google Play';

  @override
  String get packsPlayNote =>
      'Google Play yang mengunduh paket ini, bukan BooBoard. BooBoard sendiri tidak pernah memakai jaringan.';

  @override
  String get packsGet => 'Dapatkan';

  @override
  String get packsStatusNotRequested => 'Belum diunduh';

  @override
  String get packsStatusWaiting => 'Menunggu Wi-Fi atau data seluler';

  @override
  String get packsStatusDownloading => 'Mengunduh lewat Google Play';

  @override
  String get packsStatusInstalling => 'Memeriksa dan memasang';

  @override
  String get packsStatusFailed =>
      'Google Play tidak dapat mengirimkannya. Coba lagi.';

  @override
  String packsOfferMeta(Object size, Object status) {
    return '$size · $status';
  }

  @override
  String get packsVerifyTitle => 'Periksa paket terpasang';

  @override
  String get packsVerifyBody =>
      'Memeriksa setiap berkas dari setiap paket terpasang dengan daftar yang ditandatangani. Tidak ada yang diubah.';

  @override
  String packsVerifyOk(Object count) {
    return '$count paket terpasang diperiksa. Semua berkas cocok.';
  }

  @override
  String packsVerifyDamaged(Object count) {
    return '$count paket terpasang memiliki berkas rusak atau hilang. Hapus lalu impor lagi.';
  }

  @override
  String get packsVerifyUnavailable =>
      'Pemeriksaan paket belum tersedia di versi BooBoard ini.';

  @override
  String get packsVerifyFailed =>
      'BooBoard tidak dapat memeriksa paket. Tidak ada yang diubah.';

  @override
  String packsFreeSpace(Object size) {
    return '$size kosong di ponsel ini.';
  }

  @override
  String get packsNothingStored => 'Belum ada yang disimpan.';

  @override
  String packsInstalledUse(String size) {
    return 'Paket terpasang memakai $size di ponsel ini.';
  }

  @override
  String get packErrorBadSignature =>
      'Paket ini tidak ditandatangani untuk BooBoard, jadi tidak ada yang dipasang.';

  @override
  String get packErrorBadFormat =>
      'File ini bukan paket BooBoard. Tidak ada yang dipasang.';

  @override
  String get packErrorTooLarge =>
      'Paket ini terlalu besar untuk dipasang di ponsel ini.';

  @override
  String get packErrorVersion =>
      'Paket ini memerlukan versi BooBoard yang lebih baru.';

  @override
  String get packErrorNoSpace =>
      'Ruang kosong tidak cukup untuk memasang paket ini.';

  @override
  String get packErrorGeneric =>
      'Paket tidak dapat dipasang. Tidak ada yang diubah.';

  @override
  String get translateDefaultPair => 'Pasangan bahasa default';

  @override
  String translatePairName(String from, String to) {
    return '$from → $to';
  }

  @override
  String get translateOffline => 'Terjemahan luring';

  @override
  String get translateOfflineBody =>
      'Menerjemahkan saat mengetik di keyboard, dan teks yang dipilih di aplikasi mana pun.';

  @override
  String get translateDefaultPairTile => 'Pasangan default';

  @override
  String get translatePackInstalled => 'Paket terpasang';

  @override
  String get translatePackNotInstalled =>
      'Paket belum terpasang. Dapatkan di Paket model.';

  @override
  String get translateInstalled => 'Arah yang terpasang';

  @override
  String get translateInstalledBody =>
      'Setiap arah adalah satu paket, misalnya Inggris → Spanyol.';

  @override
  String translatePackMeta(String license, String size) {
    return '$size · $license';
  }

  @override
  String get translateModelPacksBody => 'Pasang atau hapus paket terjemahan';

  @override
  String get translateRunsOnPhone =>
      'Terjemahan berjalan di ponsel ini. Tidak ada yang Anda terjemahkan yang disimpan.';

  @override
  String get privacyUnlockReason =>
      'Buka kunci BooBoard untuk melihat pengaturan dan data Anda';

  @override
  String get privacyLockUnavailable =>
      'Kunci perangkat tidak tersedia sekarang. Coba lagi sebentar lagi.';

  @override
  String get privacyLockedTitle => 'BooBoard terkunci';

  @override
  String get privacyLockedBody =>
      'Buka dengan sidik jari atau PIN perangkat Anda untuk melanjutkan.';

  @override
  String get privacyUnlock => 'Buka';

  @override
  String backupSaved(String size) {
    return 'Cadangan disimpan ($size). Simpan frasa sandi Anda dengan aman.';
  }

  @override
  String get backupUnlockRetrySaved =>
      'Buka kunci ponsel, lalu coba lagi. Tidak ada yang disimpan.';

  @override
  String get backupSaveFailed =>
      'Cadangan tidak dapat disimpan. Tidak ada yang diubah.';

  @override
  String get backupCheckFailed =>
      'File yang disimpan tidak dapat diperiksa, jadi mungkin rusak. Simpan cadangan lagi sebagai file baru.';

  @override
  String get backupWrongPassphrase =>
      'Frasa sandi salah, atau file rusak. Tidak ada yang diubah.';

  @override
  String get backupInvalidFile =>
      'File ini bukan cadangan BooBoard yang valid. Tidak ada yang diubah.';

  @override
  String get backupTooLarge =>
      'File ini terlalu besar untuk menjadi cadangan BooBoard.';

  @override
  String get backupNewerVersion =>
      'Cadangan ini dibuat oleh versi BooBoard yang lebih baru. Perbarui BooBoard untuk memulihkannya.';

  @override
  String get backupBusy => 'Tutup dulu jendela file yang lain, lalu coba lagi.';

  @override
  String get backupOpenFailed =>
      'Cadangan tidak dapat dibuka. Tidak ada yang diubah.';

  @override
  String get backupEmpty => 'Cadangan ini kosong.';

  @override
  String get backupRestoreTitle => 'Pulihkan cadangan';

  @override
  String backupMadeBy(String date, String version) {
    return 'Dibuat $date oleh BooBoard $version.';
  }

  @override
  String get backupMerge => 'Gabung';

  @override
  String get backupMergeBody =>
      'Simpan yang ada di ponsel ini dan tambahkan isi cadangan.';

  @override
  String get backupReplace => 'Ganti';

  @override
  String get backupReplaceBody =>
      'Samakan bagian yang dipilih dengan cadangan. Data di sini dihapus lebih dulu.';

  @override
  String get commonContinue => 'Lanjut';

  @override
  String get backupReplaceTitle => 'Ganti data di ponsel ini?';

  @override
  String get backupReplaceConfirm =>
      'Bagian yang dipilih di ponsel ini akan dihapus dan diganti. Tidak bisa dibatalkan.';

  @override
  String get backupPrivacyChangesTitle =>
      'Cadangan ini mengubah pengaturan privasi Anda';

  @override
  String get backupPrivacyChangesBody =>
      'Memulihkan pengaturan akan mengubah pengaturan privasi ini di ponsel ini. Periksa dulu sebelum melanjutkan.';

  @override
  String backupPrivacyChangeLine(String setting, String from, String to) {
    return '$setting: $from → $to';
  }

  @override
  String get backupStateOn => 'Aktif';

  @override
  String backupAppsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aplikasi',
      one: '1 aplikasi',
    );
    return '$_temp0';
  }

  @override
  String get backupRestoreAndChange => 'Pulihkan dan ubah';

  @override
  String get backupUnlockRetryChanged =>
      'Buka kunci ponsel, lalu coba lagi. Tidak ada yang diubah.';

  @override
  String get backupRestoreFailed =>
      'BooBoard tidak dapat menyelesaikan pemulihan. Sebagian data mungkin belum tertulis.';

  @override
  String get restoreNothingNew => 'Tidak ada yang baru dipulihkan.';

  @override
  String restoreSummary(String items) {
    return 'Dipulihkan: $items.';
  }

  @override
  String restoreSummarySkipped(String added, String skipped) {
    return '$added Dilewati: $skipped.';
  }

  @override
  String restoreLearnedFor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bahasa',
    );
    return 'kata yang dipelajari untuk $_temp0';
  }

  @override
  String countFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file',
    );
    return '$_temp0';
  }

  @override
  String countWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kata',
    );
    return '$_temp0';
  }

  @override
  String countLanguages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bahasa',
    );
    return '$_temp0';
  }

  @override
  String countShortcuts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pintasan',
    );
    return '$_temp0';
  }

  @override
  String countClipboardItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count item papan klip',
    );
    return '$_temp0';
  }

  @override
  String countThemeFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file tema',
    );
    return '$_temp0';
  }

  @override
  String countPinnedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count item tersemat',
    );
    return '$_temp0';
  }

  @override
  String countPacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paket',
    );
    return '$_temp0';
  }

  @override
  String countBlockedWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kata diblokir',
    );
    return '$_temp0';
  }

  @override
  String countTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kali',
    );
    return '$_temp0';
  }

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count menit lalu',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jam lalu',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hari lalu',
    );
    return '$_temp0';
  }

  @override
  String get timeJustNow => 'baru saja';

  @override
  String get languagePortuguese => 'Portugis';

  @override
  String packMeta(String languages, String license, String size) {
    return '$languages · $size · $license';
  }

  @override
  String privacyLearnedWordsTitle(String language) {
    return 'Kata yang dipelajari ($language)';
  }

  @override
  String privacyClearLanguageTitle(String language) {
    return 'Hapus kata $language?';
  }

  @override
  String get privacyClearLanguageBody =>
      'Ini menghapus semua kata yang dipelajari dalam bahasa ini, dan kata yang diblokir. Tidak bisa dibatalkan.';

  @override
  String get privacyClear => 'Hapus';

  @override
  String get privacySaveFailed => 'Perubahan tidak dapat disimpan. Coba lagi.';

  @override
  String get privacyCouldNotReadWords =>
      'BooBoard tidak dapat membaca kata-kata ini.';

  @override
  String get privacyCannotReadWordsNow =>
      'BooBoard tidak dapat membaca kata-kata ini sekarang. Buka kunci ponsel, lalu coba lagi.';

  @override
  String get privacyNoWordsLanguage =>
      'Belum ada kata yang dipelajari dalam bahasa ini. BooBoard mempelajari kata setelah Anda mengetiknya beberapa kali.';

  @override
  String privacyBlockedWordsTooltip(num count) {
    return 'Kata diblokir ($count)';
  }

  @override
  String get privacySortTooltip => 'Urutkan';

  @override
  String get privacySortMostUsed => 'Paling sering dulu';

  @override
  String get privacySortAZ => 'A sampai Z';

  @override
  String get privacyMoreTooltip => 'Lainnya';

  @override
  String get privacyClearThisLanguage => 'Hapus bahasa ini';

  @override
  String get privacySearchWords => 'Cari kata';

  @override
  String privacyWordsSummary(String blocked, String words) {
    return '$words · $blocked';
  }

  @override
  String get privacyNoWordsYet => 'Belum ada kata.';

  @override
  String privacyNoWordsMatch(String query) {
    return 'Tidak ada kata yang cocok dengan \"$query\".';
  }

  @override
  String get privacyNeverSuggested => 'Tidak pernah disarankan';

  @override
  String get privacyBlockedExplain =>
      'BooBoard tidak akan menyarankan atau mengoreksi ke kata-kata ini.';

  @override
  String get privacyNoBlockedWords => 'Tidak ada kata yang diblokir.';

  @override
  String get privacyAllowAgain => 'Izinkan lagi';

  @override
  String privacyWordLastUsed(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kali',
    );
    return 'Diketik $_temp0 · terakhir $when';
  }

  @override
  String privacyWordNotYetSuggested(String when) {
    return 'Baru diketik sekali, belum disarankan · terakhir $when';
  }

  @override
  String get privacyToday => 'hari ini';

  @override
  String get privacyYesterday => 'kemarin';

  @override
  String privacyActionsFor(String word) {
    return 'Tindakan untuk $word';
  }

  @override
  String get privacyForgetWord => 'Lupakan kata ini';

  @override
  String get privacyNeverSuggestWord => 'Jangan pernah sarankan kata ini';

  @override
  String get privacyTryAgain => 'Coba lagi';

  @override
  String get privacyCenterLoadFailed =>
      'BooBoard tidak dapat membaca data privasinya. Coba lagi nanti.';

  @override
  String get privacyDevBuildNetwork =>
      'Build ini meminta akses internet. BooBoard seharusnya tidak pernah melakukannya. Mohon laporkan.';

  @override
  String get privacyNoInternetPermission =>
      'BooBoard tidak memiliki izin internet. Tidak ada yang bisa dikirim.';

  @override
  String get privacyDevBuildNote =>
      'Ini adalah build pengembangan. Izin jaringannya hanya untuk alat pengembangan.';

  @override
  String get privacyDevBuildShort =>
      'Build pengembangan. BooBoard tetap tidak memiliki izin internet.';

  @override
  String privacyStorageSize(String size, String when) {
    return '$size · diubah $when';
  }

  @override
  String get privacyCustomThemes => 'Tema kustom';

  @override
  String get privacyNoPacks =>
      'Tidak ada yang terpasang. Paket suara dan terjemahan muncul di sini.';

  @override
  String privacyPacksSize(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paket',
    );
    return '$_temp0 · $size';
  }

  @override
  String get privacyWhatBooBoardStores => 'Yang disimpan BooBoard';

  @override
  String get privacyShowsSizesOnly =>
      'BooBoard hanya menampilkan ukuran di sini, tidak pernah isinya. Ukuran menyertakan salinan terakhir yang disimpan, yang menjaga data Anda jika penyimpanan terputus.';

  @override
  String get privacyTypingPrivacy => 'Privasi saat mengetik';

  @override
  String get privacyLearnNewWords => 'Pelajari kata baru';

  @override
  String get privacyLearnNewWordsBody =>
      'Mempelajari kata dan frasa dari yang Anda ketik. Tidak pernah di kolom sandi atau mode penyamaran.';

  @override
  String get privacyIncognito => 'Penyamaran';

  @override
  String get privacyIncognitoBody =>
      'Tidak mempelajari atau mengingat apa pun saat aktif. Tab penyamaran peramban mengaktifkannya sendiri.';

  @override
  String get privacyHideScreenshots => 'Sembunyikan dari tangkapan layar';

  @override
  String get privacyHideScreenshotsBody =>
      'Mencegah tangkapan layar dan rekaman layar keyboard di setiap aplikasi. Kolom sandi selalu disembunyikan.';

  @override
  String get privacyAutoOffApps => 'Otomatis dimatikan di aplikasi ini';

  @override
  String get privacyAutoOffAppsBody =>
      'BooBoard hanya menyimpan nama aplikasi untuk mengisi daftar ini. Nama itu terenkripsi, tidak pernah dicatat saat penyamaran, dan dapat dihapus di bawah.';

  @override
  String get privacyNoAppsYet => 'Belum ada aplikasi';

  @override
  String get privacyNoAppsYetBody =>
      'Aplikasi tempat Anda mengetik akan muncul di sini.';

  @override
  String get privacyAlwaysIncognitoApps => 'Aplikasi selalu dalam penyamaran';

  @override
  String get privacyPersonalShortcuts => 'Pintasan pribadi';

  @override
  String get privacyOfferShortcuts => 'Tawarkan pintasan';

  @override
  String get privacyOfferShortcutsBody =>
      'Tampilkan singkatan Anda, seperti \"omw\", sebagai saran pertama.';

  @override
  String get privacyEditShortcuts => 'Edit pintasan';

  @override
  String get privacyNoShortcutsYet => 'Belum ada';

  @override
  String get privacyLearnedAndClipboard =>
      'Kata yang dipelajari dan papan klip';

  @override
  String get privacyNoWordsLearnedYet => 'Belum ada kata yang dipelajari';

  @override
  String get privacyWordsLearnedBody =>
      'Kata yang Anda ketik dipelajari di sini setelah BooBoard melihatnya beberapa kali.';

  @override
  String privacyReviewWords(String when) {
    return 'Tinjau, hapus, atau blokir kata · $when';
  }

  @override
  String get privacyClipboardHistoryEmpty =>
      'Riwayat kosong. Ubah pengaturan papan klip di Panel.';

  @override
  String privacyClipboardInHistory(String size) {
    return '$size dalam riwayat. Ubah pengaturan papan klip di Panel.';
  }

  @override
  String get privacyAppLock => 'Kunci aplikasi';

  @override
  String get privacyLockBooBoard => 'Kunci BooBoard';

  @override
  String get privacyLockBooBoardBody =>
      'Meminta sidik jari atau PIN perangkat saat aplikasi dibuka, atau setelah berada di latar belakang.';

  @override
  String get privacyLockAfter => 'Kunci setelah';

  @override
  String get privacySetScreenLockFirst => 'Atur kunci layar terlebih dahulu';

  @override
  String get privacySetScreenLockBody =>
      'Kunci aplikasi menggunakan sidik jari atau PIN perangkat. Atur PIN, pola, atau sandi di pengaturan keamanan Android, lalu kembali.';

  @override
  String get privacyTurnOnAppLockReason =>
      'Nyalakan kunci aplikasi untuk BooBoard';

  @override
  String get privacyNotAvailable => 'Tidak tersedia sekarang';

  @override
  String get privacyNotAvailableBody =>
      'Kunci perangkat tidak dapat digunakan. Kunci aplikasi tetap mati.';

  @override
  String get privacyBackupTitle => 'Cadangan';

  @override
  String get privacyBackupRestore => 'Cadangan dan pemulihan';

  @override
  String get privacyBackupRestoreBody =>
      'Berkas .boobackup terenkripsi yang Anda simpan. Anda memilih isinya.';

  @override
  String get privacyDeleteData => 'Hapus data';

  @override
  String get privacyEraseEverything => 'Hapus semuanya';

  @override
  String get privacyEraseEverythingBody =>
      'Semua kategori di atas, tema kustom Anda, dan kunci yang melindunginya.';

  @override
  String privacyDeleteTitle(String category) {
    return 'Hapus $category?';
  }

  @override
  String get privacyEraseTitle => 'Hapus semuanya?';

  @override
  String get privacyWillDelete => 'Ini akan menghapus secara permanen:';

  @override
  String get privacyResetSettings =>
      'Juga atur ulang semua pengaturan ke default';

  @override
  String get privacyCannotBeUndone => 'Tidak bisa dibatalkan.';

  @override
  String get privacyDeleted => 'Dihapus.';

  @override
  String get privacyDeleteFailed =>
      'BooBoard tidak dapat menghapus semuanya. Coba lagi.';

  @override
  String get privacyOk => 'OK';

  @override
  String get backupMakeTitle => 'Buat cadangan';

  @override
  String get backupIncludeImages => 'Sertakan gambar latar';

  @override
  String get backupPhotosLarger => 'Foto membuat file jauh lebih besar.';

  @override
  String get backupCreateButton => 'Buat cadangan terenkripsi';

  @override
  String get backupRestoreSection => 'Pulihkan';

  @override
  String get backupRestoreFromFile => 'Pulihkan dari file cadangan';

  @override
  String get backupRestoreFromFileBody =>
      'Buka file .boobackup, periksa isinya, lalu gabungkan atau ganti.';

  @override
  String get backupChoosePassphrase => 'Pilih frasa sandi';

  @override
  String get backupEnterPassphrase => 'Masukkan frasa sandi';

  @override
  String get backupWriteItDown =>
      'Tulis di tempat yang aman. Frasa sandi yang hilang tidak bisa dipulihkan.';

  @override
  String get backupPassphrase => 'Frasa sandi';

  @override
  String get backupTypeAgain => 'Ketik ulang';

  @override
  String get backupMismatch => 'Frasa sandi tidak cocok';

  @override
  String backupStrength(String strength) {
    return 'Kekuatan frasa sandi: $strength';
  }

  @override
  String get strengthTooShort => 'Kurang dari 8 karakter, gunakan minimal 8';

  @override
  String get strengthWeak => 'Lemah';

  @override
  String get strengthFair => 'Cukup';

  @override
  String get strengthGood => 'Baik';

  @override
  String get strengthStrong => 'Kuat';

  @override
  String get backupOpen => 'Buka';

  @override
  String get backupNothingYet => 'Belum ada';

  @override
  String get backupSettingsSummary =>
      'Tema, bahasa, pengetikan, dan pilihan privasi';

  @override
  String backupLearnedSummary(String languages, String words) {
    return '$words dalam $languages';
  }

  @override
  String backupPinnedOff(String items) {
    return '$items. Mati kecuali Anda menyalakannya.';
  }

  @override
  String backupAlreadyHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pintasan sudah ada',
    );
    return '$_temp0';
  }

  @override
  String backupThemesAlreadyHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file tema sudah ada',
    );
    return '$_temp0';
  }

  @override
  String get backupClipboardKept =>
      'papan klip dibiarkan (tata letak tidak dikenal)';

  @override
  String get backupEmojiKept => 'emoji terbaru dipertahankan';

  @override
  String get backupSettingsApplied => 'pengaturan';

  @override
  String backupLearnedAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bahasa',
    );
    return 'kata yang dipelajari untuk $_temp0';
  }

  @override
  String shortcutDeleteTitle(String trigger) {
    return 'Hapus \"$trigger\"?';
  }

  @override
  String get shortcutDeleteBody =>
      'Ini menghapus pintasan. Tidak bisa dibatalkan.';

  @override
  String get shortcutAdd => 'Tambah pintasan';

  @override
  String get shortcutSearch => 'Cari pintasan';

  @override
  String get shortcutNoMatch =>
      'Tidak ada pintasan yang cocok dengan pencarian Anda.';

  @override
  String shortcutDeleteTooltip(String trigger) {
    return 'Hapus $trigger';
  }

  @override
  String get shortcutNoneYet => 'Belum ada pintasan';

  @override
  String get shortcutExplain =>
      'Pintasan mengubah singkatan menjadi teks yang lebih panjang. Contoh:';

  @override
  String shortcutExamples(String first, String second) {
    return '$first\n$second';
  }

  @override
  String get shortcutEncrypted =>
      'Pintasan terenkripsi di ponsel ini, seperti kata yang dipelajari.';

  @override
  String get shortcutNew => 'Pintasan baru';

  @override
  String get shortcutEdit => 'Edit pintasan';

  @override
  String get shortcutShortForm => 'Singkatan';

  @override
  String get shortcutExpandsTo => 'Diperluas menjadi';

  @override
  String get privacyMascotLabel => 'Maskot privasi BooBoard';

  @override
  String get privacyStoredEmoji => 'Emoji terbaru';

  @override
  String get privacyStoredApps => 'Daftar aplikasi';

  @override
  String get privacyStoredOther => 'Data tersimpan lainnya';

  @override
  String privacyUnitBytes(num count) {
    return '$count B';
  }

  @override
  String privacyUnitKilobytes(num count) {
    return '$count KB';
  }

  @override
  String privacyUnitMegabytes(num count) {
    return '$count MB';
  }

  @override
  String get shortcutProblemEmptyTrigger =>
      'Ketik singkatan yang ingin diperluas.';

  @override
  String shortcutProblemTriggerTooLong(num count) {
    return 'Singkatan boleh paling banyak $count karakter.';
  }

  @override
  String get shortcutProblemTriggerCharacters =>
      'singkatan hanya boleh berisi huruf, angka, dan tanda kutip satu.';

  @override
  String get shortcutProblemEmptyExpansion =>
      'Ketik apa yang harus diperluas dari singkatan ini.';

  @override
  String shortcutProblemExpansionTooLong(num count) {
    return 'Perluasan boleh paling banyak $count karakter.';
  }

  @override
  String get shortcutProblemDuplicate =>
      'Anda sudah punya pintasan dengan singkatan ini.';

  @override
  String shortcutProblemTooMany(num count) {
    return 'Anda boleh menyimpan paling banyak $count pintasan.';
  }

  @override
  String get onboardingWelcomeTitle => 'Hai, aku *Boo.*';

  @override
  String get onboardingWelcomeBody =>
      'Aku keyboard yang tidak pernah online. Yang kamu ketik tetap di ponsel ini, terkunci rapat.';

  @override
  String get onboardingWelcomeStart => 'Ayo mulai';

  @override
  String get onboardingMascotLabel => 'Boo, hantu BooBoard';

  @override
  String get onboardingFactNoInternet => 'Tanpa izin internet';

  @override
  String get onboardingFactOpenSource => 'Sumber terbuka';

  @override
  String get onboardingFactOpenSourceBody =>
      'Siapa pun bisa membaca kodenya dan memeriksa.';

  @override
  String get onboardingDemoKeyboards => 'Aplikasi keyboard';

  @override
  String get onboardingDemoOtherKeyboard => 'Keyboard lain';

  @override
  String get onboardingDemoAttention => 'Perhatian';

  @override
  String get onboardingDemoAttentionBody =>
      'Keyboard ini mungkin dapat mengumpulkan semua teks yang kamu ketik…';

  @override
  String get onboardingDemoOk => 'OK';

  @override
  String get onboardingDemoChooseInput => 'Pilih metode masukan';

  @override
  String get onboardingDemoSwitchOn => 'Aktifkan';

  @override
  String get onboardingDemoTapOk => 'OK, lalu OK';

  @override
  String get onboardingDemoComeBack => 'Kembali';

  @override
  String get onboardingDemoPick => 'Pilih BooBoard';

  @override
  String get onboardingDemoStartTyping => 'Mulai mengetik';

  @override
  String get onboardingDemoRebootNote =>
      'Catatan: Setelah dimulai ulang, aplikasi ini tidak dapat dimulai hingga Anda membuka kunci ponsel';

  @override
  String get onboardingDemoChatIn => 'Ketemu jam 7?';

  @override
  String get onboardingDemoChatOut => 'Otw';

  @override
  String get onboardingDemoMessage => 'Pesan';

  @override
  String get onboardingShh => 'sst';

  @override
  String get onboardingTryMe => 'Coba aku';

  @override
  String get onboardingTurnOnTitle => 'Aktifkan *BooBoard*';

  @override
  String get onboardingTurnOnBody =>
      'Aktifkan di daftar keyboard Android, lalu kembali. Halaman ini akan tahu sendiri.';

  @override
  String get onboardingKeyboardOn => 'BooBoard sudah aktif';

  @override
  String get onboardingKeyboardOff => 'Belum aktif';

  @override
  String get onboardingOpenKeyboardSettings => 'Buka pengaturan keyboard';

  @override
  String get onboardingSwitchTitle => 'Jadikan *milikmu*';

  @override
  String get onboardingSwitchBody =>
      'Pilih BooBoard dari daftar singkat Android. Kamu bisa beralih lagi kapan saja.';

  @override
  String get onboardingKeyboardIsYours => 'BooBoard keyboard kamu';

  @override
  String get onboardingKeyboardNotYours => 'Belum jadi keyboard kamu';

  @override
  String get onboardingTurnOnFirst => 'Aktifkan dulu';

  @override
  String get onboardingChooseKeyboard => 'Pilih keyboard';

  @override
  String get onboardingCheckingPermissions => 'Memeriksa izin aplikasi…';

  @override
  String get onboardingDebugInternet =>
      'Build debug ini bisa mengakses internet. Build debug memiliki izin itu hanya untuk pengembangan.';

  @override
  String get onboardingReleaseInternet => 'Build ini bisa mengakses internet.';

  @override
  String get onboardingNoInternet =>
      'BooBoard tidak punya izin internet, jadi tidak bisa mengirim apa pun ke mana pun.';

  @override
  String get onboardingWarningTitle => 'Soal *peringatan* itu';

  @override
  String get onboardingWarningBody =>
      'Android menampilkannya untuk semua keyboard, karena keyboard bisa mengirim ketikanmu ke internet. BooBoard tidak bisa.';

  @override
  String get onboardingInternetAccess => 'Akses internet';

  @override
  String get onboardingEverythingHere => 'Tetap di ponsel ini';

  @override
  String get onboardingEverythingHereBody =>
      'Kata yang dipelajari, papan klip, dan pengaturan dienkripsi dengan kunci di Android Keystore.';

  @override
  String get onboardingLanguagesTitle => '*Bahasa* kamu';

  @override
  String get onboardingThemeTitle => 'Tema';

  @override
  String get onboardingTryTyping => 'Ketik satu kalimat';

  @override
  String get onboardingTrySwipe => 'Geser satu kata, huruf ke huruf';

  @override
  String get onboardingTryAccents => 'Tekan lama huruf untuk aksen';

  @override
  String get onboardingTryTitle => 'Coba *sekarang*';

  @override
  String get onboardingTryField => 'Ketik sesuatu di sini';

  @override
  String get onboardingAllSetTitle => 'Semua *siap.*';

  @override
  String get onboardingAllSetBody =>
      'Bahasa, pengetikan, tema, dan lainnya ada di Setelan kapan pun kamu mau.';

  @override
  String onboardingStepOf(String step, String total) {
    return 'Langkah $step dari $total';
  }

  @override
  String get onboardingBack => 'Kembali';

  @override
  String get onboardingNext => 'Berikutnya';

  @override
  String get onboardingDone => 'Selesai';

  @override
  String get onboardingSearchLanguages => 'Cari bahasa';

  @override
  String onboardingSelected(String languages) {
    return 'Dipilih: $languages';
  }

  @override
  String get onboardingNoLanguageMatch =>
      'Tidak ada bahasa yang cocok dengan pencarian itu.';

  @override
  String get themeCreate => 'Buat tema';

  @override
  String themeSelectedLabel(String name) {
    return '$name, dipilih';
  }

  @override
  String themeCardOptions(String name) {
    return 'Opsi untuk $name';
  }

  @override
  String get themeEdit => 'Edit';

  @override
  String get themeDuplicate => 'Duplikat';

  @override
  String get themeRename => 'Ganti nama';

  @override
  String get themeDeleteAction => 'Hapus';

  @override
  String get themeTryTyping => 'Coba mengetik';

  @override
  String get themeTryLabel => 'Ketik di sini untuk mencoba tema';

  @override
  String get themeTryHelper => 'Keyboard muncul di sini saat BooBoard dipilih.';

  @override
  String get themeRenameTitle => 'Ganti nama tema';

  @override
  String get themeNameField => 'Nama';

  @override
  String get themeEditTitle => 'Edit tema';

  @override
  String get themeNewTitle => 'Tema baru';

  @override
  String get themeEditorTitle => 'Tema';

  @override
  String get themeOpenFailed => 'Tema ini tidak dapat dibuka.';

  @override
  String get themeSaveFailed => 'Tema tidak dapat disimpan.';

  @override
  String get themePhotoPickerFailed => 'Pemilih foto tidak dapat dibuka.';

  @override
  String get themeDiscardTitle => 'Buang perubahan?';

  @override
  String get themeDiscardBody => 'Perubahan pada tema ini akan hilang.';

  @override
  String get themeKeepEditing => 'Lanjutkan mengedit';

  @override
  String get themeDiscard => 'Buang';

  @override
  String get themeSave => 'Simpan';

  @override
  String get themeNameRequired => 'Nama diperlukan';

  @override
  String get themeNameLabel => 'Nama tema';

  @override
  String get themeDefaultName => 'Tema saya';

  @override
  String get themeSectionName => 'Nama';

  @override
  String get themeSectionLook => 'Tampilan';

  @override
  String get themeDarkMode => 'Mode gelap';

  @override
  String get themeChoiceSystem => 'Sistem';

  @override
  String get themeChoiceLight => 'Terang';

  @override
  String get themeChoiceDark => 'Gelap';

  @override
  String get themePureBlack => 'Hitam pekat';

  @override
  String get themePureBlackBody => 'Latar hitam';

  @override
  String get themePureBlackOnlyDark => 'Hanya di mode gelap';

  @override
  String get themeGalleryPureBlackDark => 'Latar hitam di mode gelap';

  @override
  String get themeContrast => 'Kontras';

  @override
  String get themeChoiceStandard => 'Standar';

  @override
  String get themeChoiceMedium => 'Sedang';

  @override
  String get themeChoiceHigh => 'Tinggi';

  @override
  String get themeKeyboardHeight => 'Tinggi keyboard';

  @override
  String get themeSectionColours => 'Warna';

  @override
  String get themeSource => 'Sumber';

  @override
  String get themeSourceWallpaper => 'Wallpaper';

  @override
  String get themeSourceSeed => 'Warna dasar';

  @override
  String get themeSourcePerRole => 'Per peran';

  @override
  String get themeWallpaperNeedsAndroid12 =>
      'Warna wallpaper memerlukan Android 12 atau yang lebih baru.';

  @override
  String get themeSeedColour => 'Warna dasar';

  @override
  String get themeScheme => 'Skema';

  @override
  String get themeColourRoles => 'Peran warna';

  @override
  String themeEditingColours(String mode) {
    String _temp0 = intl.Intl.selectLogic(mode, {
      'dark': 'Mengedit warna gelap',
      'other': 'Mengedit warna terang',
    });
    return '$_temp0';
  }

  @override
  String get themeResetRoles => 'Atur ulang semua peran';

  @override
  String get themeKeys => 'Tombol';

  @override
  String get themeShape => 'Bentuk';

  @override
  String get themeShapePill => 'Kapsul';

  @override
  String get themeShapeRounded => 'Membulat';

  @override
  String get themeShapeSquare => 'Persegi';

  @override
  String get themeKeyBorders => 'Batas tombol';

  @override
  String get themeBorderWidth => 'Lebar batas';

  @override
  String get themeKeyGap => 'Jarak antar tombol';

  @override
  String get themeFontWeight => 'Ketebalan huruf';

  @override
  String get themeFontSize => 'Ukuran huruf';

  @override
  String get themeHintCharacters => 'Karakter petunjuk';

  @override
  String get themeHintCharactersBody => 'Karakter kecil saat ditekan lama';

  @override
  String get themeBackground => 'Latar belakang';

  @override
  String get themeBackgroundType => 'Jenis';

  @override
  String get themeTypeSolid => 'Solid';

  @override
  String get themeTypeGradient => 'Gradien';

  @override
  String get themeTypePhoto => 'Foto';

  @override
  String get themeNoPhotoYet =>
      'Belum ada foto. Pilih satu untuk dipotong ke ukuran keyboard.';

  @override
  String get themeChoosePhoto => 'Pilih foto';

  @override
  String get themeEditCrop => 'Edit potongan dan blur';

  @override
  String get themeDim => 'Redupkan';

  @override
  String get themeSectionPopups => 'Popup dan jejak';

  @override
  String get themeSolidPopups => 'Popup solid';

  @override
  String get themeSolidPopupsBodyWallpaper => 'Tidak dengan warna wallpaper';

  @override
  String get themeSolidPopupsBodyPrimary => 'Popup dalam warna utama';

  @override
  String get themeSwipeTrail => 'Jejak geser';

  @override
  String get themeTrailWidth => 'Lebar jejak';

  @override
  String get themeTrailFade => 'Pudar jejak';

  @override
  String get themeTrailInstant => 'Seketika';

  @override
  String get themeTrailColours => 'Warna jejak';

  @override
  String get themeTrailStart => 'Awal';

  @override
  String get themeTrailEnd => 'Akhir';

  @override
  String get themeTrailStartTitle => 'Awal jejak';

  @override
  String get themeTrailEndTitle => 'Akhir jejak';

  @override
  String get themeAutomatic => 'Otomatis';

  @override
  String get themeSectionMotion => 'Gerak';

  @override
  String get themeKeyPressAnimation => 'Animasi saat tombol ditekan';

  @override
  String get themeReduceMotion =>
      '«Hapus animasi» aktif di pengaturan sistem, sehingga tombol tidak dianimasikan.';

  @override
  String get themeMotionOff => 'Nonaktif';

  @override
  String get themeMotionSubtle => 'Halus';

  @override
  String get themeMotionStandard => 'Standar';

  @override
  String get themeMotionBouncy => 'Memantul';

  @override
  String get themeSchemeTonalSpot => 'Titik tonal';

  @override
  String get themeSchemeVibrant => 'Cerah';

  @override
  String get themeSchemeExpressive => 'Ekspresif';

  @override
  String get themeSchemeFidelity => 'Kesetiaan';

  @override
  String get themeSchemeContent => 'Konten';

  @override
  String get themeSchemeMonochrome => 'Monokrom';

  @override
  String get themeSchemeNeutral => 'Netral';

  @override
  String get themeSchemeRainbow => 'Pelangi';

  @override
  String get themeSchemeFruitSalad => 'Salad buah';

  @override
  String themeCustomColourHex(String hex) {
    return 'Warna kustom #$hex';
  }

  @override
  String get themeCustomColour => 'Warna kustom';

  @override
  String themeSwatchLabel(String hex, String label) {
    return 'Warna $label, #$hex';
  }

  @override
  String themeUseSchemeColour(String label) {
    return 'Gunakan warna skema untuk $label';
  }

  @override
  String get themeFromScheme => 'Dari skema';

  @override
  String get themeOverridden => 'Diatur';

  @override
  String themeStopLabel(String n) {
    return 'Titik $n';
  }

  @override
  String themePickStopTitle(String n) {
    return 'Titik $n';
  }

  @override
  String get themeAddStop => 'Tambah titik';

  @override
  String get themeRemoveStop => 'Hapus titik';

  @override
  String get themeAngle => 'Sudut';

  @override
  String get themeUseSchemeTooltipLabel => 'Gunakan warna skema';

  @override
  String get themeCropTitle => 'Potong foto';

  @override
  String get themeUsePhoto => 'Gunakan foto';

  @override
  String get themeCropSaveFailed => 'Foto tidak dapat disimpan.';

  @override
  String get themeCropSemantics =>
      'Potong foto. Seret untuk memindahkan foto dan cubit atau gunakan penggeser zoom untuk memperbesar.';

  @override
  String get themeCropZoom => 'Zoom';

  @override
  String get themeCropBlur => 'Blur';

  @override
  String get themeCropBlurOff => 'Nonaktif';

  @override
  String get themeCropNote =>
      'Blur disimpan ke dalam gambar. Redup diatur di editor dan langsung diterapkan.';

  @override
  String get themeHexLabel => 'Hex';

  @override
  String get themeHexError => 'Gunakan enam digit hex, misalnya F5B700';

  @override
  String get themeHue => 'Rona';

  @override
  String get themeSaturation => 'Saturasi';

  @override
  String get themeBrightness => 'Kecerahan';

  @override
  String get themePickShadeHint => 'Pilih warna, lalu ketuk Gunakan.';

  @override
  String get themePickColourUse => 'Gunakan';

  @override
  String get themeCopySuffix => 'salinan';

  @override
  String themeCopyName(String name) {
    return 'Salinan $name';
  }

  @override
  String themeDeleteTitle(String name) {
    return 'Hapus \"$name\"?';
  }

  @override
  String get themeDeleteSelectedBody =>
      'Tema ini sedang dipilih. BooBoard Dynamic akan dipakai sebagai gantinya. Tidak bisa dibatalkan.';

  @override
  String get themeDeleteBody => 'Tidak bisa dibatalkan.';

  @override
  String get themeDeleteFailed => 'Tema tidak dapat dihapus.';

  @override
  String get themeRenameFailed => 'Tema tidak dapat diganti namanya.';

  @override
  String get themeDuplicateFailed => 'Tema tidak dapat disalin.';

  @override
  String get themeSettingFailed => 'Pengaturan tidak dapat disimpan.';

  @override
  String get themeSystemColoursUnavailable => 'Warna sistem tidak tersedia.';

  @override
  String get themeBooBoardDynamicFollows =>
      'BooBoard Dynamic mengikuti wallpaper Anda';

  @override
  String get themeBooBoardDynamicBody =>
      'Warnanya diperbarui saat wallpaper berubah';

  @override
  String get themeSectionPresets => 'Preset';

  @override
  String get themeSectionMyThemes => 'Tema saya';

  @override
  String get themeSectionTry => 'Coba mengetik';

  @override
  String get themeAppearance => 'Tampilan';

  @override
  String get themesTitle => 'Tema';

  @override
  String privacyThemesSize(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file tema',
    );
    return '$_temp0 · $size';
  }

  @override
  String get backupUnlockToSeeCount =>
      'Buka kunci ponsel untuk melihat jumlahnya';

  @override
  String get shortcutHelp =>
      'Pintasan mengubah singkatan menjadi teks yang lebih panjang. Contoh:\nomw → on my way\naddr → your address';

  @override
  String privacyStoredLearned(String language) {
    return 'Kata yang dipelajari ($language)';
  }

  @override
  String get settingsComingLater => 'Hadir di pembaruan berikutnya';

  @override
  String get backupExplainer =>
      'Cadangan adalah satu file yang dienkripsi dengan frasa sandi pilihan Anda. Hanya frasa sandi itu yang bisa membukanya. Jika Anda lupa frasa sandinya, tidak ada yang bisa memulihkan cadangan, termasuk BooBoard.';

  @override
  String privacyCategoryLine(String detail, String title) {
    return '$title: $detail';
  }

  @override
  String get shortcutShortFormHint => 'omw';

  @override
  String get shortcutExpansionHint => 'on my way';

  @override
  String get durationMinutes15 => '15 menit';

  @override
  String get durationHour => '1 jam';

  @override
  String get durationDay => '1 hari';

  @override
  String get durationWeek => '1 minggu';

  @override
  String get onboardingCloseSetup => 'Tutup pengaturan';

  @override
  String get packsCouldNotRead => 'BooBoard tidak dapat membaca paketnya';

  @override
  String packsDeleteTooltip(String name) {
    return 'Hapus $name';
  }

  @override
  String get privacyNothingStored => 'Belum ada yang disimpan';

  @override
  String privacyRemoveAppTooltip(String app) {
    return 'Hapus $app dari daftar';
  }

  @override
  String get chineseTitle => 'Mandarin';

  @override
  String get chineseTraditional => 'Aksara tradisional';

  @override
  String get chineseTraditionalBody =>
      'Tampilkan kandidat dalam aksara tradisional (standar Taiwan).';

  @override
  String get chineseFuzzy => 'Pinyin longgar';

  @override
  String get chineseFuzzyBody =>
      'Juga menerima z dan zh, c dan ch, s dan sh, n dan l, an dan ang, en dan eng, in dan ing.';

  @override
  String get cjkDictionary => 'Kamus';

  @override
  String get chineseClearPhrases => 'Hapus frasa yang dipelajari';

  @override
  String get chineseClearPhrasesBody =>
      'Melupakan kata yang Anda pilih. Kamus tetap ada.';

  @override
  String get chineseFooter =>
      'Bahasa Mandarin diketik di ponsel ini. Frasa yang dipelajari dienkripsi dan tidak pernah keluar dari ponsel.';

  @override
  String get chineseClearTitle => 'Hapus frasa yang dipelajari?';

  @override
  String get chineseClearBody =>
      'Kata yang Anda pilih untuk bahasa Mandarin dihapus. Tindakan ini tidak dapat dibatalkan.';

  @override
  String get cjkClear => 'Hapus';

  @override
  String get chinesePhrasesCleared => 'Frasa yang dipelajari dihapus';

  @override
  String get chineseLooking => 'Mencari kamus';

  @override
  String get chineseDictName => 'Kamus Mandarin';

  @override
  String get chinesePackMissing =>
      'Belum dipasang. Mengetik Mandarin memerlukannya; pasang di Paket model.';

  @override
  String chinesePackInstalled(String license) {
    return 'Terpasang. $license';
  }

  @override
  String get japaneseTitle => 'Jepang';

  @override
  String get japaneseLayout => 'Tata letak';

  @override
  String get japaneseLayout12 => '12 tombol (geser)';

  @override
  String get japaneseLayoutRomaji => 'Romaji (QWERTY)';

  @override
  String get japaneseTyping => 'Mengetik';

  @override
  String get japaneseFlickOnly => 'Hanya geser';

  @override
  String get japaneseFlickOnlyBody =>
      'Tanpa ketuk berulang: mengetuk あ dua kali mengetik ああ, bukan い';

  @override
  String get japaneseHalfWidth => 'Spasi lebar normal';

  @override
  String get japaneseHalfWidthBody =>
      'Spasi mengetik spasi biasa saat tidak ada yang sedang diketik. Jika mati, mengetik spasi lebar penuh.';

  @override
  String get japaneseDictPack => 'Paket kamus';

  @override
  String get japaneseChecking => 'Memeriksa...';

  @override
  String japaneseInstalled(String name) {
    return '$name terpasang. Konversi kanji aktif.';
  }

  @override
  String get japaneseNotInstalled =>
      'Belum dipasang. Kana tetap bisa diketik; kanji memerlukan paket.';

  @override
  String get japaneseClearWords => 'Hapus kata yang dipelajari';

  @override
  String get japaneseClearWordsBody =>
      'Melupakan kata Jepang yang Anda pilih. Disimpan terenkripsi di ponsel ini.';

  @override
  String get japaneseClearTitle => 'Hapus kata Jepang yang dipelajari?';

  @override
  String get japaneseClearBody =>
      'Semua kata Jepang yang Anda pilih dihapus. Tindakan ini tidak dapat dibatalkan.';

  @override
  String get privacyStoredChinesePhrases => 'Frasa Mandarin';

  @override
  String get privacyStoredJapaneseWords => 'Kata Jepang';
}
