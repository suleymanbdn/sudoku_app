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
  bool _guestWaiting = false;

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

  void _resetRoom() {
    _cancelWatch();
    setState(() {
      _roomCode = null;
      _seed = null;
      _navigated = false;
      _guestWaiting = false;
    });
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
      _guestWaiting = true;
    });
    _listenForPlaying(
      roomCode: code,
      difficulty: difficulty,
      seed: seed,
      isHost: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final firebaseOk = ref.watch(duelFirebaseReadyProvider);
    final onlineActive = _useOnline && firebaseOk;

    return Scaffold(
      backgroundColor: c.surface,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Hero Banner ──────────────────────────────────────────
          _DuelHeroBanner(primary: c.primary, dark: c.dark),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Feature badges ────────────────────────────────
                _FeatureBadgesRow(liveSync: onlineActive),
                const SizedBox(height: 28),

                // ── Difficulty ────────────────────────────────────
                _SectionLabel(
                  icon: Icons.tune_rounded,
                  label: 'Difficulty',
                  c: c,
                ),
                const SizedBox(height: 10),
                _DifficultyPicker(
                  selected: _difficulty,
                  locked: _roomCode != null,
                  onSelect: (d) => setState(() => _difficulty = d),
                  c: c,
                ),
                const SizedBox(height: 20),

                // ── Online toggle ─────────────────────────────────
                if (firebaseOk) ...[
                  _OnlineToggleCard(
                    value: _useOnline,
                    onChanged: (v) => setState(() => _useOnline = v),
                    c: c,
                  ),
                  const SizedBox(height: 28),
                ] else
                  const SizedBox(height: 8),

                // ── HOST ──────────────────────────────────────────
                _SectionLabel(
                  icon: Icons.emoji_events_rounded,
                  label: 'Host',
                  c: c,
                ),
                const SizedBox(height: 10),
                _HostCard(
                  roomCode: _roomCode,
                  onlineActive: onlineActive,
                  onCreateRoom: _roomCode == null ? _createRoom : null,
                  onCopy: () {
                    Clipboard.setData(ClipboardData(text: _roomCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied')),
                    );
                  },
                  onCancel: _resetRoom,
                  onStartOffline: _hostStartOffline,
                  onStartOnline: _hostStartOnlineRace,
                  c: c,
                ),

                // ── VS divider ────────────────────────────────────
                const SizedBox(height: 28),
                _VsDivider(c: c),
                const SizedBox(height: 28),

                // ── JOIN ──────────────────────────────────────────
                _SectionLabel(
                  icon: Icons.login_rounded,
                  label: 'Join',
                  c: c,
                ),
                const SizedBox(height: 10),
                _JoinCard(
                  guestWaiting: _guestWaiting,
                  roomCode: _roomCode,
                  controller: _joinController,
                  onlineActive: onlineActive,
                  onJoin: () {
                    if (onlineActive) {
                      unawaited(_joinOnline());
                    } else {
                      unawaited(_joinOffline());
                    }
                  },
                  onLeave: _resetRoom,
                  c: c,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero banner
// ─────────────────────────────────────────────────────────────────────────────

class _DuelHeroBanner extends StatefulWidget {
  final Color primary;
  final Color dark;
  const _DuelHeroBanner({required this.primary, required this.dark});

  @override
  State<_DuelHeroBanner> createState() => _DuelHeroBannerState();
}

class _DuelHeroBannerState extends State<_DuelHeroBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      height: 200 + topPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.dark, widget.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Back button
          Positioned(
            top: topPadding + 8,
            left: 4,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          // Main content
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.flash_on_rounded,
                        color: Colors.white.withValues(alpha: 0.85),
                        size: 38,
                      ),
                      const SizedBox(width: 12),
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, child) => Transform.scale(
                          scale: _pulse.value,
                          child: child,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            'VS',
                            style: GoogleFonts.nunito(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Transform.scale(
                        scaleX: -1,
                        child: Icon(
                          Icons.flash_on_rounded,
                          color: Colors.white.withValues(alpha: 0.85),
                          size: 38,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'DUEL RACE',
                    style: GoogleFonts.nunito(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Same puzzle • First correct finish wins',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature badges
// ─────────────────────────────────────────────────────────────────────────────

class _FeatureBadgesRow extends StatelessWidget {
  final bool liveSync;
  const _FeatureBadgesRow({required this.liveSync});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _FeatureBadge(
          icon: Icons.lightbulb_outline_rounded,
          label: 'No Hints',
          color: const Color(0xFFFFA000),
        ),
        const SizedBox(width: 8),
        _FeatureBadge(
          icon: Icons.grid_view_rounded,
          label: 'Same Puzzle',
          color: const Color(0xFF1976D2),
        ),
        const SizedBox(width: 8),
        _FeatureBadge(
          icon: liveSync ? Icons.wifi_rounded : Icons.wifi_off_rounded,
          label: liveSync ? 'Live Sync' : 'Offline',
          color: liveSync ? const Color(0xFF388E3C) : const Color(0xFF757575),
        ),
      ],
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _FeatureBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppColors c;
  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: c.primary),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: c.primary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Difficulty picker
// ─────────────────────────────────────────────────────────────────────────────

class _DifficultyPicker extends StatelessWidget {
  final Difficulty selected;
  final bool locked;
  final ValueChanged<Difficulty> onSelect;
  final AppColors c;
  const _DifficultyPicker({
    required this.selected,
    required this.locked,
    required this.onSelect,
    required this.c,
  });

  static const _data = [
    (Difficulty.easy, Icons.eco_rounded, Color(0xFF43A047), 'Easy'),
    (Difficulty.medium, Icons.bolt_rounded, Color(0xFFFB8C00), 'Medium'),
    (Difficulty.hard, Icons.local_fire_department_rounded, Color(0xFFE53935), 'Hard'),
    (Difficulty.expert, Icons.whatshot_rounded, Color(0xFF7B1FA2), 'Expert'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _data.map((entry) {
        final (diff, icon, color, name) = entry;
        final isSelected = selected == diff;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: locked ? null : () => onSelect(diff),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.12)
                      : c.pureWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : c.outline.withValues(alpha: 0.5),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: isSelected
                          ? color
                          : c.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: isSelected ? color : c.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Online toggle card
// ─────────────────────────────────────────────────────────────────────────────

class _OnlineToggleCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppColors c;
  const _OnlineToggleCard({
    required this.value,
    required this.onChanged,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: value
            ? c.primary.withValues(alpha: 0.07)
            : c.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? c.primary.withValues(alpha: 0.4)
              : c.outline.withValues(alpha: 0.5),
        ),
      ),
      child: SwitchListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        secondary: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: value
                ? c.primary.withValues(alpha: 0.12)
                : c.container,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.wifi_rounded,
            size: 20,
            color: value ? c.primary : c.onSurfaceVariant,
          ),
        ),
        title: Text(
          'Online Synced Start',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: c.onSurface,
          ),
        ),
        subtitle: Text(
          'Host launches the race for both players simultaneously',
          style: GoogleFonts.nunito(
            fontSize: 11,
            color: c.onSurfaceVariant,
          ),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Host card
// ─────────────────────────────────────────────────────────────────────────────

class _HostCard extends StatelessWidget {
  final String? roomCode;
  final bool onlineActive;
  final VoidCallback? onCreateRoom;
  final VoidCallback onCopy;
  final VoidCallback onCancel;
  final VoidCallback onStartOffline;
  final VoidCallback onStartOnline;
  final AppColors c;

  const _HostCard({
    required this.roomCode,
    required this.onlineActive,
    required this.onCreateRoom,
    required this.onCopy,
    required this.onCancel,
    required this.onStartOffline,
    required this.onStartOnline,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.outline.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (roomCode == null) ...[
            Text(
              'Create a room and share the code with your opponent.',
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: c.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onCreateRoom,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: Text(
                'Create Room',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
              ),
            ),
          ] else ...[
            _RoomCodeDisplay(
              code: roomCode!,
              onCopy: onCopy,
              onCancel: onCancel,
              c: c,
            ),
            const SizedBox(height: 14),
            if (onlineActive)
              FilledButton.icon(
                onPressed: onStartOnline,
                icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                label: Text(
                  'Start Race — Both Devices',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                ),
              )
            else
              FilledButton.tonalIcon(
                onPressed: onStartOffline,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(
                  'Start Puzzle (Offline)',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _RoomCodeDisplay extends StatelessWidget {
  final String code;
  final VoidCallback onCopy;
  final VoidCallback onCancel;
  final AppColors c;
  const _RoomCodeDisplay({
    required this.code,
    required this.onCopy,
    required this.onCancel,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            c.primary.withValues(alpha: 0.08),
            c.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: c.primary.withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ROOM CODE',
                  style: GoogleFonts.nunito(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: c.primary.withValues(alpha: 0.7),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  code,
                  style: GoogleFonts.robotoMono(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: c.primary,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.copy_rounded, size: 20, color: c.primary),
                tooltip: 'Copy code',
                onPressed: onCopy,
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: c.onSurfaceVariant,
                ),
                tooltip: 'Cancel room',
                onPressed: onCancel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VS divider
// ─────────────────────────────────────────────────────────────────────────────

class _VsDivider extends StatelessWidget {
  final AppColors c;
  const _VsDivider({required this.c});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  c.outline.withValues(alpha: 0.0),
                  c.outline.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: c.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events_rounded,
                    size: 14, color: c.primary.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Text(
                  'VS',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: c.primary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.person_rounded,
                    size: 14, color: c.primary.withValues(alpha: 0.7)),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  c.outline.withValues(alpha: 0.6),
                  c.outline.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Join card
// ─────────────────────────────────────────────────────────────────────────────

class _JoinCard extends StatelessWidget {
  final bool guestWaiting;
  final String? roomCode;
  final TextEditingController controller;
  final bool onlineActive;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final AppColors c;

  const _JoinCard({
    required this.guestWaiting,
    required this.roomCode,
    required this.controller,
    required this.onlineActive,
    required this.onJoin,
    required this.onLeave,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.outline.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: guestWaiting
          ? _GuestWaitingContent(roomCode: roomCode ?? '', onLeave: onLeave, c: c)
          : _JoinFormContent(
              controller: controller,
              onlineActive: onlineActive,
              onJoin: onJoin,
              c: c,
            ),
    );
  }
}

class _JoinFormContent extends StatelessWidget {
  final TextEditingController controller;
  final bool onlineActive;
  final VoidCallback onJoin;
  final AppColors c;

  const _JoinFormContent({
    required this.controller,
    required this.onlineActive,
    required this.onJoin,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter the room code shared by the host.',
          style: GoogleFonts.nunito(
            fontSize: 13,
            color: c.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          style: GoogleFonts.robotoMono(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 2,
          ),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'M1A4F9C0',
            hintStyle: GoogleFonts.robotoMono(
              letterSpacing: 2,
              color: Colors.grey.shade400,
            ),
            labelText: 'Room code',
            prefixIcon: const Icon(Icons.vpn_key_rounded),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onJoin,
          icon: const Icon(Icons.login_rounded, size: 18),
          label: Text(
            onlineActive ? 'Join Race — Online' : 'Join Race',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _GuestWaitingContent extends StatefulWidget {
  final String roomCode;
  final VoidCallback onLeave;
  final AppColors c;

  const _GuestWaitingContent({
    required this.roomCode,
    required this.onLeave,
    required this.c,
  });

  @override
  State<_GuestWaitingContent> createState() => _GuestWaitingContentState();
}

class _GuestWaitingContentState extends State<_GuestWaitingContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _fade = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.hourglass_top_rounded,
                color: c.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Joined successfully!',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: c.onSurface,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _fade,
                    builder: (_, child) => Opacity(
                      opacity: _fade.value,
                      child: child,
                    ),
                    child: Text(
                      'Waiting for host to start the race…',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: c.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.tag_rounded, size: 14, color: c.primary),
              const SizedBox(width: 6),
              Text(
                widget.roomCode,
                style: GoogleFonts.robotoMono(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: c.primary,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: widget.onLeave,
          icon: Icon(Icons.exit_to_app_rounded, size: 16, color: c.onSurfaceVariant),
          label: Text(
            'Leave Room',
            style: GoogleFonts.nunito(
              color: c.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
