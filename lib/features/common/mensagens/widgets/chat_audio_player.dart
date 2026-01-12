import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'package:chegaja_v2/l10n/app_localizations.dart';

class ChatAudioPlayer extends StatefulWidget {
  const ChatAudioPlayer({
    super.key,
    required this.url,
    this.title,
    this.compact = false,
    this.accentColor,
  });

  final String url;
  final String? title;
  final bool compact;
  final Color? accentColor;

  @override
  State<ChatAudioPlayer> createState() => _ChatAudioPlayerState();
}

class _ChatAudioPlayerState extends State<ChatAudioPlayer> {
  static AudioPlayer? _activePlayer;

  late final AudioPlayer _player;
  StreamSubscription<PlayerState>? _stateSub;
  bool _loading = true;
  bool _loadFailed = false;
  double _speed = 1.0;
  Duration? _duration;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _load();
    _stateSub = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ChatAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _loading = true;
      _loadFailed = false;
      _duration = null;
      _player.stop();
      if (mounted) {
        setState(() {});
      }
      _load();
    }
  }

  Future<void> _load() async {
    try {
      if (kIsWeb) {
        await _player.setWebCrossOrigin(WebCrossOrigin.anonymous);
      }
      final duration = await _player.setUrl(widget.url);
      _duration = duration;
      _loadFailed = false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ChatAudioPlayer: falha ao carregar audio: $e');
      }
      _loadFailed = true;
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    if (_activePlayer == _player) {
      _activePlayer = null;
    }
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_loading || _loadFailed) return;

    if (_player.playing) {
      await _player.pause();
      return;
    }

    final active = _activePlayer;
    if (active != null && active != _player) {
      await active.pause();
    }

    _activePlayer = _player;
    await _player.play();
  }

  Future<void> _cycleSpeed() async {
    const speeds = [1.0, 1.5, 2.0];
    final idx = speeds.indexOf(_speed);
    final next = speeds[(idx + 1) % speeds.length];
    _speed = next;
    await _player.setSpeed(next);
    if (mounted) setState(() {});
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  String _speedLabel(double speed) {
    if (speed == speed.roundToDouble()) {
      return '${speed.toInt()}x';
    }
    return '${speed.toStringAsFixed(1)}x';
  }

  Widget _buildPlayButton(Color accent, double size) {
    if (_loading) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: accent,
        ),
      );
    }

    if (_loadFailed) {
      return Icon(Icons.error_outline, size: size, color: Colors.redAccent);
    }

    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data?.playing ?? false;
        return IconButton(
          onPressed: _togglePlay,
          icon: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
            size: size,
            color: accent,
          ),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints.tightFor(width: size + 8, height: size + 8),
          splashRadius: size,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accent = widget.accentColor ?? theme.colorScheme.primary;
    final isCompact = widget.compact;
    final title = (widget.title ?? '').trim();
    final iconSize = isCompact ? 20.0 : 24.0;
    final trackHeight = isCompact ? 2.0 : 3.0;
    final timeStyle = TextStyle(
      fontSize: isCompact ? 10 : 11,
      color: Colors.grey.shade700,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isCompact ? 12 : 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Row(
          children: [
            _buildPlayButton(accent, iconSize),
            const SizedBox(width: 6),
            Expanded(
              child: StreamBuilder<Duration>(
                stream: _player.positionStream,
                builder: (context, posSnap) {
                  final position = posSnap.data ?? Duration.zero;
                  return StreamBuilder<Duration?>(
                    stream: _player.durationStream,
                    builder: (context, durSnap) {
                      final duration = durSnap.data ?? _duration;
                      final maxMs = duration?.inMilliseconds ?? 0;
                      final posMs = position.inMilliseconds;
                      final clampedMs =
                          maxMs > 0 ? posMs.clamp(0, maxMs) : 0;
                      final timeLabel = duration == null
                          ? _formatDuration(position)
                          : '${_formatDuration(position)} / ${_formatDuration(duration)}';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: trackHeight,
                              activeTrackColor: accent,
                              inactiveTrackColor: Colors.grey.shade300,
                              thumbColor: accent,
                              thumbShape: RoundSliderThumbShape(
                                enabledThumbRadius: isCompact ? 6 : 7,
                              ),
                              overlayShape: RoundSliderOverlayShape(
                                overlayRadius: isCompact ? 12 : 14,
                              ),
                            ),
                            child: Slider(
                              min: 0,
                              max: maxMs > 0 ? maxMs.toDouble() : 1,
                              value: maxMs > 0 ? clampedMs.toDouble() : 0,
                              onChanged: maxMs > 0
                                  ? (value) {
                                      _player.seek(
                                        Duration(milliseconds: value.round()),
                                      );
                                    }
                                  : null,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(timeLabel, style: timeStyle),
                              TextButton(
                                onPressed:
                                    _loading || _loadFailed ? null : _cycleSpeed,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  _speedLabel(_speed),
                                  style: timeStyle.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        if (_loadFailed)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.chatAudioReadError,
              style: timeStyle.copyWith(color: Colors.redAccent),
            ),
          ),
      ],
    );
  }
}
