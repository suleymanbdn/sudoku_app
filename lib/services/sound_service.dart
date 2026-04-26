import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Rich synthesized game sounds.
///
/// WAV files are generated via additive synthesis (marimba + bell timbres)
/// and written to the app's temp directory on first [initAsync] call.
/// [DeviceFileSource] is used instead of BytesSource for reliable Android
/// audio playback.
class SoundService {
  SoundService._();

  static bool enabled = true;

  static String? _placeFile;
  static String? _errorFile;
  static String? _lineFile;
  static String? _boxFile;
  static String? _winFile;

  static bool _ready = false;

  // Pool of players for low-latency concurrent playback
  static final List<AudioPlayer> _pool =
      List.generate(6, (_) => AudioPlayer());
  static int _idx = 0;

  // -------------------------------------------------------------------------
  // Note frequencies (Hz)
  // -------------------------------------------------------------------------
  static const double _c5 = 523.25;
  static const double _e5 = 659.25;
  static const double _g5 = 783.99;
  static const double _c6 = 1046.50;
  static const double _e6 = 1318.51;

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Async init: generates WAV bytes and writes them to the temp directory.
  /// Call once from main() or the first screen's initState.
  static Future<void> initAsync() async {
    if (_ready) return;
    try {
      final dir = await getTemporaryDirectory();

      _placeFile = await _write(
        dir,
        'snd_place.wav',
        _marimba(587.33, 0.25, 0.28),
      );
      _errorFile = await _write(
        dir,
        'snd_error.wav',
        _mixNotes([(150.0, 0, 0.09, 0.30), (115.0, 60, 0.12, 0.25)],
            type: _NoteType.bass),
      );
      _lineFile = await _write(
        dir,
        'snd_line.wav',
        _mixNotes(
            [(_e5, 0, 0.30, 0.26), (_g5, 130, 0.38, 0.30)],
            type: _NoteType.marimba),
      );
      _boxFile = await _write(
        dir,
        'snd_box.wav',
        _mixNotes([
          (_c5, 0, 0.45, 0.24),
          (_e5, 110, 0.45, 0.26),
          (_g5, 220, 0.52, 0.28),
        ], type: _NoteType.bell),
      );
      _winFile = await _write(
        dir,
        'snd_win.wav',
        _mixNotes([
          (_c5, 0, 0.45, 0.22),
          (_e5, 120, 0.45, 0.23),
          (_g5, 240, 0.45, 0.24),
          (_c6, 360, 0.50, 0.25),
          (_e6, 480, 0.55, 0.27),
          (_c5, 640, 0.90, 0.18),
          (_e5, 640, 0.90, 0.18),
          (_g5, 640, 0.90, 0.19),
          (_c6, 640, 0.90, 0.17),
        ], type: _NoteType.bell),
      );

      _ready = true;
      if (kDebugMode) debugPrint('SoundService: ready');
    } catch (e) {
      if (kDebugMode) debugPrint('SoundService init error: $e');
    }
  }

  static void playPlace() => _play(_placeFile);
  static void playError() => _play(_errorFile);
  static void playLine() => _play(_lineFile);
  static void playBox() => _play(_boxFile);
  static void playWin() => _play(_winFile);

  // -------------------------------------------------------------------------
  // Playback
  // -------------------------------------------------------------------------

  static void _play(String? path) {
    if (!enabled || path == null) return;
    try {
      final p = _pool[_idx % _pool.length];
      _idx++;
      // ignore: discarded_futures
      p.play(DeviceFileSource(path));
    } catch (e) {
      if (kDebugMode) debugPrint('SoundService: $e');
    }
  }

  // -------------------------------------------------------------------------
  // File helper
  // -------------------------------------------------------------------------

  static Future<String> _write(
      Directory dir, String name, Uint8List bytes) async {
    final f = File('${dir.path}/$name');
    await f.writeAsBytes(bytes, flush: true);
    return f.path;
  }

  // -------------------------------------------------------------------------
  // Synthesis helpers
  // -------------------------------------------------------------------------

  static Uint8List _mixNotes(
    List<(double, double, double, double)> notes, {
    required _NoteType type,
    int sr = 22050,
  }) {
    double totalDur = 0;
    for (final (_, startMs, dur, _) in notes) {
      totalDur = max(totalDur, startMs / 1000.0 + dur);
    }

    final totalN = (sr * totalDur).ceil();
    final buf = List<double>.filled(totalN, 0.0);

    for (final (freq, startMs, dur, amp) in notes) {
      final raw = switch (type) {
        _NoteType.marimba => _marimbaRaw(freq, dur, amp, sr),
        _NoteType.bell => _bellRaw(freq, dur, amp, sr),
        _NoteType.bass => _bassRaw(freq, dur, amp, sr),
      };
      final offset = (sr * startMs / 1000).round();
      for (int i = 0; i < raw.length; i++) {
        final j = i + offset;
        if (j < totalN) buf[j] += raw[i];
      }
    }

    return _normalize(buf, sr);
  }

  static Uint8List _marimba(double freq, double dur, double amp,
      {int sr = 22050}) =>
      _normalize(_marimbaRaw(freq, dur, amp, sr), sr);

  // -------------------------------------------------------------------------
  // Per-timbre raw generators
  // -------------------------------------------------------------------------

  static List<double> _marimbaRaw(
      double freq, double dur, double amp, int sr) {
    const partials = [
      [1.000, 1.00, 7.0],
      [3.932, 0.28, 22.0],
      [9.538, 0.08, 55.0],
    ];
    return _additive(freq, dur, amp, partials, attackSec: 0.002, sr: sr);
  }

  static List<double> _bellRaw(double freq, double dur, double amp, int sr) {
    const partials = [
      [1.000, 1.00, 2.5],
      [2.756, 0.60, 5.0],
      [5.404, 0.28, 10.0],
      [8.933, 0.10, 18.0],
    ];
    return _additive(freq, dur, amp, partials, attackSec: 0.003, sr: sr);
  }

  static List<double> _bassRaw(double freq, double dur, double amp, int sr) {
    const partials = [
      [1.0, 1.00, 14.0],
      [2.0, 0.35, 30.0],
    ];
    return _additive(freq, dur, amp, partials, attackSec: 0.001, sr: sr);
  }

  static List<double> _additive(
    double baseFreq,
    double dur,
    double amp,
    List<List<double>> partials, {
    required double attackSec,
    int sr = 22050,
  }) {
    final n = (sr * dur).round();
    final buf = List<double>.filled(n, 0.0);
    for (final p in partials) {
      final f = baseFreq * p[0];
      final relAmp = p[1];
      final decay = p[2];
      for (int i = 0; i < n; i++) {
        final t = i / sr;
        final attack = (t < attackSec) ? t / attackSec : 1.0;
        final env = attack * exp(-t * decay) * relAmp * amp;
        buf[i] += sin(2 * pi * f * t) * env;
      }
    }
    return buf;
  }

  // -------------------------------------------------------------------------
  // WAV building
  // -------------------------------------------------------------------------

  static Uint8List _normalize(List<double> buf, int sr) {
    final peak = buf.fold(0.0, (m, v) => max(m, v.abs()));
    final scale = peak > 1e-9 ? (0.88 / peak) * 32767.0 : 0.0;
    final samples = buf
        .map((v) => (v * scale).round().clamp(-32768, 32767))
        .toList();
    return _buildWav(samples, sr);
  }

  static Uint8List _buildWav(List<int> samples, int sr) {
    final dataBytes = samples.length * 2;
    final d = ByteData(44 + dataBytes);

    void str(int off, String s) {
      for (int i = 0; i < s.length; i++) {
        d.setUint8(off + i, s.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    d.setUint32(4, 36 + dataBytes, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    d.setUint32(16, 16, Endian.little);
    d.setUint16(20, 1, Endian.little);
    d.setUint16(22, 1, Endian.little);
    d.setUint32(24, sr, Endian.little);
    d.setUint32(28, sr * 2, Endian.little);
    d.setUint16(32, 2, Endian.little);
    d.setUint16(34, 16, Endian.little);
    str(36, 'data');
    d.setUint32(40, dataBytes, Endian.little);
    for (int i = 0; i < samples.length; i++) {
      d.setInt16(44 + i * 2, samples[i], Endian.little);
    }
    return d.buffer.asUint8List();
  }

  static void dispose() {
    for (final p in _pool) {
      p.dispose();
    }
  }
}

enum _NoteType { marimba, bell, bass }
