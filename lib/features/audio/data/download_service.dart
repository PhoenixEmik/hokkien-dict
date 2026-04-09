import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

enum DownloadState { idle, downloading, paused, completed, error }

class DownloadSnapshot {
  const DownloadSnapshot({
    required this.state,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.speedBytesPerSecond,
    this.errorMessage,
  });

  const DownloadSnapshot.idle({required int totalBytes})
    : this(
        state: DownloadState.idle,
        downloadedBytes: 0,
        totalBytes: totalBytes,
        speedBytesPerSecond: 0,
      );

  final DownloadState state;
  final int downloadedBytes;
  final int totalBytes;
  final double speedBytesPerSecond;
  final String? errorMessage;

  double? get progress {
    if (totalBytes <= 0) {
      return null;
    }
    final ratio = downloadedBytes / totalBytes;
    return ratio.clamp(0.0, 1.0);
  }

  DownloadSnapshot copyWith({
    DownloadState? state,
    int? downloadedBytes,
    int? totalBytes,
    double? speedBytesPerSecond,
    Object? errorMessage = _noValue,
  }) {
    return DownloadSnapshot(
      state: state ?? this.state,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      speedBytesPerSecond: speedBytesPerSecond ?? this.speedBytesPerSecond,
      errorMessage: errorMessage == _noValue
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  static const Object _noValue = Object();
}

class DownloadService {
  DownloadService({Dio? dio}) : _dio = dio ?? Dio() {
    snapshot = ValueNotifier<DownloadSnapshot>(
      const DownloadSnapshot.idle(totalBytes: 0),
    );
  }

  final Dio _dio;
  late final ValueNotifier<DownloadSnapshot> snapshot;

  CancelToken? _cancelToken;
  int _sessionId = 0;

  bool get isDownloading => snapshot.value.state == DownloadState.downloading;

  void seed(DownloadSnapshot value) {
    snapshot.value = value;
  }

  Future<void> download({
    required String url,
    required File targetFile,
    required int fallbackTotalBytes,
    bool restart = false,
  }) async {
    if (isDownloading) {
      return;
    }

    if (restart && targetFile.existsSync()) {
      targetFile.deleteSync();
    }

    final sessionId = ++_sessionId;
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    final existingLength = targetFile.existsSync()
        ? targetFile.lengthSync()
        : 0;
    _emit(
      DownloadSnapshot(
        state: DownloadState.downloading,
        downloadedBytes: existingLength,
        totalBytes: _resolvedSeedTotal(fallbackTotalBytes, existingLength),
        speedBytesPerSecond: 0,
      ),
      sessionId: sessionId,
    );

    IOSink? sink;

    try {
      await targetFile.parent.create(recursive: true);

      final response = await _dio.get<ResponseBody>(
        url,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: existingLength > 0
              ? <String, Object>{
                  HttpHeaders.rangeHeader: 'bytes=$existingLength-',
                }
              : null,
          validateStatus: (status) =>
              status == HttpStatus.ok ||
              status == HttpStatus.partialContent ||
              status == HttpStatus.requestedRangeNotSatisfiable,
        ),
      );

      final statusCode = response.statusCode ?? 0;
      var downloadedLength = existingLength;
      var append = downloadedLength > 0;
      final totalBytes = _resolveTotalBytes(
        response: response,
        existingLength: downloadedLength,
        fallbackTotalBytes: fallbackTotalBytes,
      );

      if (statusCode == HttpStatus.requestedRangeNotSatisfiable &&
          downloadedLength > 0) {
        _emit(
          DownloadSnapshot(
            state: DownloadState.completed,
            downloadedBytes: totalBytes,
            totalBytes: totalBytes,
            speedBytesPerSecond: 0,
          ),
          sessionId: sessionId,
        );
        return;
      }

      if (statusCode == HttpStatus.ok && downloadedLength > 0) {
        await targetFile.delete();
        downloadedLength = 0;
        append = false;
      }

      sink = targetFile.openWrite(
        mode: append ? FileMode.append : FileMode.write,
      );

      var resumedBytes = downloadedLength;
      var receivedBytes = 0;
      var speedBytesPerSecond = 0.0;
      var lastSampleBytes = 0;
      var lastSampleAt = Duration.zero;
      final stopwatch = Stopwatch()..start();

      await for (final chunk in response.data!.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;

        final elapsed = stopwatch.elapsed;
        final sampleWindow = elapsed - lastSampleAt;
        if (sampleWindow >= const Duration(milliseconds: 400)) {
          final bytesDelta = receivedBytes - lastSampleBytes;
          final seconds =
              sampleWindow.inMicroseconds / Duration.microsecondsPerSecond;
          if (seconds > 0) {
            speedBytesPerSecond = bytesDelta / seconds;
          }
          lastSampleBytes = receivedBytes;
          lastSampleAt = elapsed;
        }

        final trueDownloaded = resumedBytes + receivedBytes;
        _emit(
          DownloadSnapshot(
            state: DownloadState.downloading,
            downloadedBytes: trueDownloaded,
            totalBytes: totalBytes,
            speedBytesPerSecond: speedBytesPerSecond,
          ),
          sessionId: sessionId,
        );
      }

      await sink.flush();
      await sink.close();
      sink = null;

      final completedBytes = resumedBytes + receivedBytes;
      _emit(
        DownloadSnapshot(
          state: DownloadState.completed,
          downloadedBytes: completedBytes,
          totalBytes: totalBytes,
          speedBytesPerSecond: 0,
        ),
        sessionId: sessionId,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        _emit(
          snapshot.value.copyWith(
            state: DownloadState.paused,
            speedBytesPerSecond: 0,
            errorMessage: null,
          ),
          sessionId: sessionId,
        );
        return;
      }

      _emit(
        snapshot.value.copyWith(
          state: DownloadState.error,
          speedBytesPerSecond: 0,
          errorMessage: _describeDioError(error),
        ),
        sessionId: sessionId,
      );
      rethrow;
    } catch (error) {
      _emit(
        snapshot.value.copyWith(
          state: DownloadState.error,
          speedBytesPerSecond: 0,
          errorMessage: error.toString(),
        ),
        sessionId: sessionId,
      );
      rethrow;
    } finally {
      await sink?.close();
      if (identical(_cancelToken, cancelToken)) {
        _cancelToken = null;
      }
    }
  }

  void pause() {
    final cancelToken = _cancelToken;
    if (cancelToken == null || cancelToken.isCancelled) {
      return;
    }
    cancelToken.cancel('paused');
  }

  void dispose() {
    _cancelToken?.cancel('disposed');
    snapshot.dispose();
  }

  void _emit(DownloadSnapshot value, {required int sessionId}) {
    if (sessionId != _sessionId) {
      return;
    }
    snapshot.value = value;
  }

  int _resolvedSeedTotal(int fallbackTotalBytes, int existingLength) {
    if (existingLength > fallbackTotalBytes) {
      return existingLength;
    }
    return fallbackTotalBytes;
  }

  int _resolveTotalBytes({
    required Response<ResponseBody> response,
    required int existingLength,
    required int fallbackTotalBytes,
  }) {
    final statusCode = response.statusCode ?? 0;
    final contentRange = response.headers.value(HttpHeaders.contentRangeHeader);
    final contentLength = response.data?.contentLength ?? -1;

    final contentRangeTotal = _parseTotalBytesFromContentRange(contentRange);
    if (contentRangeTotal != null) {
      return contentRangeTotal;
    }

    if (statusCode == HttpStatus.partialContent && contentLength > 0) {
      return existingLength + contentLength;
    }

    if (contentLength > 0) {
      return contentLength;
    }

    return fallbackTotalBytes > 0 ? fallbackTotalBytes : existingLength;
  }

  int? _parseTotalBytesFromContentRange(String? contentRange) {
    if (contentRange == null) {
      return null;
    }

    final match = RegExp(r'bytes\s+\d+-\d+/(\d+)').firstMatch(contentRange);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1)!);
  }

  String _describeDioError(DioException error) {
    final message = error.message;
    if (message != null && message.isNotEmpty) {
      return message;
    }
    return error.error?.toString() ?? '下載失敗';
  }
}
