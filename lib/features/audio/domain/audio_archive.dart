enum AudioArchiveType { word, sentence }

extension AudioArchiveTypeMetadata on AudioArchiveType {
  String get archiveFileName => switch (this) {
    AudioArchiveType.word => 'sutiau-mp3.zip',
    AudioArchiveType.sentence => 'leku-mp3.zip',
  };

  String get displayLabel => switch (this) {
    AudioArchiveType.word => '詞目音檔',
    AudioArchiveType.sentence => '例句音檔',
  };

  String get sourceUrl => switch (this) {
    AudioArchiveType.word =>
      'https://sutian.moe.edu.tw/media/senn/sutiau-mp3.zip',
    AudioArchiveType.sentence =>
      'https://sutian.moe.edu.tw/media/senn/leku-mp3.zip',
  };

  int get archiveBytes => switch (this) {
    AudioArchiveType.word => 298531008,
    AudioArchiveType.sentence => 514423301,
  };

  String get sampleClipId => switch (this) {
    AudioArchiveType.word => '1(1)',
    AudioArchiveType.sentence => '1-1-1',
  };

  String get cacheFolderName => switch (this) {
    AudioArchiveType.word => 'word_clips',
    AudioArchiveType.sentence => 'sentence_clips',
  };

  String get storageStem => switch (this) {
    AudioArchiveType.word => 'sutiau_mp3',
    AudioArchiveType.sentence => 'leku_mp3',
  };
}

class AudioActionResult {
  const AudioActionResult({this.message, this.isError = false});

  final String? message;
  final bool isError;
}

String formatBytes(int bytes) {
  if (bytes <= 0) {
    return '0 B';
  }

  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }

  final fixed = value >= 100 || unitIndex == 0 ? 0 : 1;
  return '${value.toStringAsFixed(fixed)} ${units[unitIndex]}';
}

String formatBytesPerSecond(double bytesPerSecond) {
  if (bytesPerSecond <= 0) {
    return '0 B/s';
  }
  return '${formatBytes(bytesPerSecond.round())}/s';
}
