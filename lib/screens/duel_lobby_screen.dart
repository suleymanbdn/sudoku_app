import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../duel/duel_room_code.dart';
import '../firebase_bootstrap.dart';
import '../game_logic/sudoku_engine.dart';
import '../providers/duel_provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_colors.dart';
import 'game_screen.dart';

class DuelLobbyScreen extends ConsumerStatefulWidget {
  const DuelLobbyScreen({super.key});

  @override
  ConsumerState<DuelLobbyScreen> createState() => _DuelLobbyScreenState();
}

class _DuelLobbyScreenState extends ConsumerState<DuelLobbyScreen> {
  Difficulty _difficulty = Difficulty.medium;
  bool _useOnline = false;

  String? _roomCode;
  int? _seed;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  bool _navigated = false;

  final _joinController = TextEditingController();

  @override
  void dispose() {
    _sub?.cancel();
    _joinController.dispose();
    super.dispose();
  }

  void _cancelWatch() {
    _sub?.cancel();
    _sub = null;
  }

  Future<void> _goToGame({
    required Difficulty difficulty,
    required int seed,
    required String roomCode,
    required bool isHost,
  }) async {
    if (_navigated) return;
    _navigated = true;
    await ref.read(gameProvider.notifier).startDuelGame(
          difficulty: difficulty,
          seed: seed,
          roomCode: roomCode,
          duelIsHost: isHost,
        );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(GameScreen.route());
  }

  void _listenForPlaying({
    required String roomCode,
    required Difficulty difficulty,
    required int seed,
    required bool isHost,
  }) {
    _cancelWatch();
    final stream = ref.read(duelFirestoreServiceProvider).watchRoom(roomCode);
    if (stream == null) return;
    _sub = stream.listen((snap) {
      final p = snap.data()?['phase'];
      if (p == 'playing' && mounted && !_navigated) {
        unawaited(_goToGame(
          difficulty: difficulty,
          seed: seed,
          roomCode: roomCode,
          isHost: isHost,
        ));
      }
    });
  }

  Future<void> _createRoom() async {
    final seed = Random().nextInt(0x7fffffff);
    final code = DuelRoomCode.encode(_difficulty, seed);
    final online = _useOnline && ref.read(duelFirebaseReadyProvider);
    final playerId = ref.read(duelPlayerIdProvider);
    final fs = ref.read(duelFirestoreServiceProvider);

    setState(() {
      _roomCode = code;
      _seed = seed;
      _navigated = false;
    });

    if (online) {
      try {
        await fs.createOnlineRoom(
          roomCode: code,
          seed: seed,
          difficultyIndex: _difficulty.index,
          hostId: playerId,
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sunucuya bağlanılamadı. İnternet / Firestore kontrol edin.'),
            ),
          );
        }
        _cancelWatch();
        return;
      }
      _listenForPlaying(
        roomCode: code,
        difficulty: _difficulty,
        seed: seed,
        isHost: true,
      );
    } else {
      _cancelWatch();
    }
  }

  Future<void> _hostStartOffline() async {
    final code = _roomCode;
    final seed = _seed;
    if (code == null || seed == null) return;
    await _goToGame(
      difficulty: _difficulty,
      seed: seed,
      roomCode: code,
      isHost: true,
    );
  }

  Future<void> _hostStartOnlineRace() async {
    final code = _roomCode;
    if (code == null) return;
    try {
      await ref.read(duelFirestoreServiceProvider).startOnlineRace(code);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yarış başlatılamadı. Bağlantıyı kontrol edin.'),
          ),
        );
      }
    }
  }

  Future<void> _joinOffline() async {
    final parsed = DuelRoomCode.decode(_joinController.text);
    if (parsed == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid room code')),
        );
      }
      return;
    }
    final (difficulty, seed) = parsed;
    final code = DuelRoomCode.encode(difficulty, seed);
    await _goToGame(
      difficulty: difficulty,
      seed: seed,
      roomCode: code,
      isHost: false,
    );
  }

  Future<void> _joinOnline() async {
    final parsed = DuelRoomCode.decode(_joinController.text);
    if (parsed == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid room code')),
        );
      }
      return;
    }
    final (difficulty, seed) = parsed;
    final code = DuelRoomCode.encode(difficulty, seed);
    final guestId = ref.read(duelPlayerIdProvider);
    final bool ok;
    try {
      ok = await ref.read(duelFirestoreServiceProvider).joinOnlineRoom(
            roomCode: code,
            guestId: guestId,
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sunucuya bağlanılamadı. İnternet / Firestore kontrol edin.'),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room not found or offline')),
      );
      return;
    }
    setState(() {
      _roomCode = code;
      _seed = seed;
      _difficulty = difficulty;
      _navigated = false;
    });
    _listenForPlaying(
      roomCode: code,
      difficulty: difficulty,
      seed: seed,
      isHost: false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Joined — wait for host to start the race')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final firebaseOk = ref.watch(duelFirebaseReadyProvider);

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        title: Text(
          'Duel race',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Same room code = same puzzle. First correct finish wins (online uses server time).',
            style: GoogleFonts.nunito(
              fontSize: 14,
              height: 1.4,
              color: c.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          if (!firebaseOk)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                kDuelFirestoreEmulator
                    ? 'Emulator not running or Firebase failed to start. Run tool/run_online_duel_dev.ps1 (or start the Firestore emulator on port 8080).'
                    : 'Online race: run tool/run_online_duel_dev.ps1 for zero-setup dev, or add keys in lib/firebase_options.dart for production.',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: c.tertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (firebaseOk)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Online synced start', style: GoogleFonts.nunito()),
              subtitle: Text(
                'Host starts the race for both players',
                style: GoogleFonts.nunito(fontSize: 12, color: c.onSurfaceVariant),
              ),
              value: _useOnline,
              onChanged: (v) => setState(() => _useOnline = v),
            ),
          const SizedBox(height: 8),
          Text('Difficulty', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          SegmentedButton<Difficulty>(
            segments: const [
              ButtonSegment(value: Difficulty.easy, label: Text('Easy')),
              ButtonSegment(value: Difficulty.medium, label: Text('Med')),
              ButtonSegment(value: Difficulty.hard, label: Text('Hard')),
              ButtonSegment(value: Difficulty.expert, label: Text('Exp')),
            ],
            selected: {_difficulty},
            onSelectionChanged: (s) {
              if (_roomCode != null) return;
              setState(() => _difficulty = s.first);
            },
          ),
          const SizedBox(height: 28),
          Text(
            'Host',
            style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _roomCode != null ? null : _createRoom,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Create room'),
          ),
          if (_roomCode != null) ...[
            const SizedBox(height: 16),
            SelectableText(
              _roomCode!,
              style: GoogleFonts.robotoMono(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: c.primary,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _roomCode!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code copied')),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy code'),
            ),
            if (_useOnline && firebaseOk) ...[
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _hostStartOnlineRace,
                child: const Text('Start race (both devices)'),
              ),
            ] else ...[
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: _hostStartOffline,
                child: const Text('Start puzzle (offline)'),
              ),
            ],
          ],
          const SizedBox(height: 36),
          Text(
            'Join',
            style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _joinController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'E1A4F9C0',
              labelText: 'Room code',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    if (_useOnline && firebaseOk) {
                      unawaited(_joinOnline());
                    } else {
                      unawaited(_joinOffline());
                    }
                  },
                  child: Text(
                    _useOnline && firebaseOk ? 'Join online' : 'Join (offline)',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
