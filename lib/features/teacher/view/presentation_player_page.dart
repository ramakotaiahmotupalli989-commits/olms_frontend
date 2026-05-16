/// EduCinema LMS — Presentation Player
/// Full-screen cinematic video player optimized for classroom presentation.
/// Uses youtube_player_flutter for YouTube links, video_player + chewie for HLS/MP4 fallback.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../core/theme/app_theme.dart';

class PresentationPlayerPage extends StatefulWidget {
  final int videoId;
  final String title;
  final String videoUrl;
  final String thumbnailUrl;
  final int durationSecs;

  const PresentationPlayerPage({
    super.key,
    required this.videoId,
    required this.title,
    required this.videoUrl,
    this.thumbnailUrl = '',
    this.durationSecs = 0,
  });

  @override
  State<PresentationPlayerPage> createState() => _PresentationPlayerPageState();
}

class _PresentationPlayerPageState extends State<PresentationPlayerPage>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  YoutubePlayerController? _youtubeController;
  bool _hasValidUrl = false;
  bool _isYoutube = false;
  bool _isInitializing = true;
  bool _initError = false;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Force landscape for presentation mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);

    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final url = widget.videoUrl.trim();
    _hasValidUrl = url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'));

    if (!_hasValidUrl) {
      setState(() {
        _isInitializing = false;
        _initError = true;
      });
      _fadeController.forward();
      return;
    }

    final ytId = YoutubePlayer.convertUrlToId(url);
    if (ytId != null) {
      _isYoutube = true;
      _youtubeController = YoutubePlayerController(
        initialVideoId: ytId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: true,
          hideControls: false,
          controlsVisibleAtStart: true,
          // ── Lock playback inside the app ──
          disableDragSeek: false,
          forceHD: false,
          loop: false,
          isLive: false,
          // Hide YouTube logo from controls bar
          showLiveFullscreenButton: false,
        ),
      );
      setState(() {
        _isInitializing = false;
        _initError = false;
      });
      _fadeController.forward();
      return;
    }

    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        showOptions: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          bufferedColor: AppColors.primary.withValues(alpha: 0.3),
          backgroundColor: Colors.white24,
        ),
        placeholder: _buildThumbnailPlaceholder(),
        errorBuilder: (context, errorMessage) => _buildErrorState(errorMessage),
      );

      setState(() {
        _isInitializing = false;
        _initError = false;
      });
      _fadeController.forward();
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _initError = true;
      });
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _youtubeController?.dispose();
    _fadeController.dispose();
    // Restore orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: _isInitializing
            ? _buildLoadingState()
            : _initError || !_hasValidUrl
                ? _buildFallbackPlayer()
                : _buildVideoPlayer(),
      ),
    );
  }

  // ─────────────────────────────────────
  // REAL VIDEO PLAYBACK
  // ─────────────────────────────────────
  Widget _buildVideoPlayer() {
    return FadeTransition(
      opacity: _fadeController,
      child: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: _isYoutube
                ? _buildYoutubePlayer()
                : Chewie(controller: _chewieController!),
          ),
          _buildInfoBar(),
        ],
      ),
    );
  }

  /// Embedded YouTube player with overlays that block the YouTube logo
  /// and watermark links, keeping playback 100% inside the app.
  Widget _buildYoutubePlayer() {
    return Stack(
      children: [
        // The actual YouTube player — renders inside a WebView, never opens externally
        YoutubePlayerBuilder(
          player: YoutubePlayer(
            controller: _youtubeController!,
            showVideoProgressIndicator: true,
            progressIndicatorColor: AppColors.primary,
            bottomActions: [
              CurrentPosition(),
              const SizedBox(width: 8),
              ProgressBar(
                isExpanded: true,
                colors: ProgressBarColors(
                  playedColor: AppColors.primary,
                  handleColor: AppColors.primary,
                  bufferedColor: AppColors.primary.withValues(alpha: 0.3),
                  backgroundColor: Colors.white24,
                ),
              ),
              const SizedBox(width: 8),
              RemainingDuration(),
              const SizedBox(width: 8),
              PlaybackSpeedButton(),
            ],
          ),
          builder: (context, player) => player,
        ),

        // ── Block YouTube logo (top-left corner) ──
        Positioned(
          top: 0,
          left: 0,
          child: GestureDetector(
            onTap: () {}, // swallow tap — prevents opening YouTube
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(width: 100, height: 40),
          ),
        ),

        // ── Block YouTube watermark (bottom-right, above controls) ──
        Positioned(
          bottom: 48,
          right: 0,
          child: GestureDetector(
            onTap: () {},
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(width: 60, height: 36),
          ),
        ),

        // ── Block "Watch on YouTube" link (top-right) ──
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {},
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(width: 140, height: 40),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────
  // FALLBACK: RICH MOCK PLAYER
  // When no valid URL is available, show
  // a full-featured simulated player UI.
  // ─────────────────────────────────────
  Widget _buildFallbackPlayer() {
    return FadeTransition(
      opacity: _fadeController,
      child: Column(
        children: [
          _buildTopBar(),
          Expanded(child: _FallbackVideoPlayer(
            title: widget.title,
            thumbnailUrl: widget.thumbnailUrl,
            durationSecs: widget.durationSecs,
          )),
          _buildInfoBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRESENTING',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  widget.title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'LIVE',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBar() {
    final mins = widget.durationSecs ~/ 60;
    final secs = widget.durationSecs % 60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          const Icon(Icons.school_rounded, size: 16, color: Colors.white38),
          const SizedBox(width: 8),
          Text(
            'EduCinema Classroom',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
          ),
          const Spacer(),
          const Icon(Icons.timer_outlined, size: 14, color: Colors.white38),
          const SizedBox(width: 4),
          Text(
            '${mins}m ${secs.toString().padLeft(2, '0')}s',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 20),
          Text(
            'Preparing presentation...',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailPlaceholder() {
    if (widget.thumbnailUrl.isEmpty) {
      return Container(
        color: const Color(0xFF1A1A2E),
        child: const Center(
          child: Icon(Icons.play_circle_outline_rounded, size: 80, color: Colors.white24),
        ),
      );
    }
    return Image.network(
      widget.thumbnailUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFF1A1A2E),
        child: const Center(
          child: Icon(Icons.play_circle_outline_rounded, size: 80, color: Colors.white24),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(message, style: GoogleFonts.inter(color: Colors.white54)),
        ],
      ),
    );
  }
}

/// ───────────────────────────────────────────────
/// FALLBACK VIDEO PLAYER (Rich Simulated UI)
/// When no real video URL is available.
/// ───────────────────────────────────────────────
class _FallbackVideoPlayer extends StatefulWidget {
  final String title;
  final String thumbnailUrl;
  final int durationSecs;

  const _FallbackVideoPlayer({
    required this.title,
    required this.thumbnailUrl,
    required this.durationSecs,
  });

  @override
  State<_FallbackVideoPlayer> createState() => _FallbackVideoPlayerState();
}

class _FallbackVideoPlayerState extends State<_FallbackVideoPlayer>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  double _progress = 0.0;
  bool _showControls = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _simulatePlayback();
    }
  }

  void _simulatePlayback() async {
    while (_isPlaying && _progress < 1.0 && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted && _isPlaying) {
        setState(() {
          _progress += 0.001;
          if (_progress >= 1.0) {
            _progress = 1.0;
            _isPlaying = false;
          }
        });
      }
    }
  }

  String _formatTime(int totalSecs) {
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currentSecs = (_progress * widget.durationSecs).toInt();

    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background (thumbnail or gradient)
          if (widget.thumbnailUrl.isNotEmpty)
            Image.network(
              widget.thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildGradientBg(),
            )
          else
            _buildGradientBg(),

          // Dark overlay
          Container(color: Colors.black.withValues(alpha: _showControls ? 0.5 : 0.2)),

          // Center play/pause
          if (_showControls)
            Center(
              child: GestureDetector(
                onTap: _togglePlay,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, child) {
                    final scale = _isPlaying ? 1.0 : 1.0 + _pulseController.value * 0.08;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.9),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Bottom controls
          if (_showControls)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress slider
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: AppColors.primary,
                        overlayColor: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: _progress.clamp(0.0, 1.0),
                        onChanged: (v) => setState(() => _progress = v),
                      ),
                    ),
                    // Time + controls row
                    Row(
                      children: [
                        Text(
                          _formatTime(currentSecs),
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                        ),
                        Text(
                          ' / ${_formatTime(widget.durationSecs)}',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => setState(() => _progress = (_progress - 0.05).clamp(0.0, 1.0)),
                          icon: const Icon(Icons.replay_10_rounded, color: Colors.white70, size: 22),
                        ),
                        IconButton(
                          onPressed: _togglePlay,
                          icon: Icon(
                            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white, size: 28,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _progress = (_progress + 0.05).clamp(0.0, 1.0)),
                          icon: const Icon(Icons.forward_10_rounded, color: Colors.white70, size: 22),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.volume_up_rounded, color: Colors.white70, size: 22),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.fullscreen_rounded, color: Colors.white70, size: 22),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // "Demo Mode" watermark
          if (!_isPlaying && _showControls)
            Positioned(
              top: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Presentation Preview',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white54),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGradientBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
      ),
    );
  }
}
