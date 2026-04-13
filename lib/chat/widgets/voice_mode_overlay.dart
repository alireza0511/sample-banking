import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Full-screen voice mode overlay
class VoiceModeOverlay extends StatefulWidget {
  final bool isListening;
  final bool isSpeaking;
  final String transcriptionText;
  final VoidCallback onClose;
  final VoidCallback onToggleListening;

  const VoiceModeOverlay({
    super.key,
    required this.isListening,
    required this.isSpeaking,
    required this.transcriptionText,
    required this.onClose,
    required this.onToggleListening,
  });

  @override
  State<VoiceModeOverlay> createState() => _VoiceModeOverlayState();
}

class _VoiceModeOverlayState extends State<VoiceModeOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryBlue.withValues(alpha: 0.95),
      child: SafeArea(
        child: Column(
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Voice Mode',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Close voice mode',
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Waveform visualization
            SizedBox(
              height: 200,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: WaveformPainter(
                      animationValue: _animationController.value,
                      isActive: widget.isListening || widget.isSpeaking,
                      color: Colors.white,
                    ),
                    size: Size(MediaQuery.of(context).size.width, 200),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Status indicator
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                _getStatusText(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Transcription text
            if (widget.transcriptionText.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(
                  widget.transcriptionText,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            const Spacer(),

            // Microphone button
            GestureDetector(
              onTap: widget.onToggleListening,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isListening
                      ? Colors.red.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.2),
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
                child: Icon(
                  widget.isListening ? Icons.mic_off : Icons.mic,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              widget.isListening ? 'Tap to stop' : 'Tap to speak',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),

            const SizedBox(height: AppSpacing.xl * 2),
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    if (widget.isListening) {
      return 'Listening...';
    } else if (widget.isSpeaking) {
      return 'Speaking...';
    } else {
      return 'Ready';
    }
  }
}

/// Waveform painter for voice visualization
class WaveformPainter extends CustomPainter {
  final double animationValue;
  final bool isActive;
  final Color color;

  WaveformPainter({
    required this.animationValue,
    required this.isActive,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive) {
      // Draw flat line when inactive
      final paint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final path = Path()
        ..moveTo(0, size.height / 2)
        ..lineTo(size.width, size.height / 2);

      canvas.drawPath(path, paint);
      return;
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final waveCount = 3;
    final amplitude = size.height * 0.3;
    final frequency = 2 * math.pi / size.width;

    // Draw animated waveform
    for (var x = 0.0; x < size.width; x += 2) {
      final y = size.height / 2 +
          amplitude *
              math.sin(frequency * x * waveCount + animationValue * 2 * math.pi) *
              math.sin(x / size.width * math.pi); // Envelope

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw additional waves for richer effect
    final paint2 = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path2 = Path();
    for (var x = 0.0; x < size.width; x += 2) {
      final y = size.height / 2 +
          amplitude *
              0.7 *
              math.sin(frequency * x * waveCount * 1.5 - animationValue * 2 * math.pi) *
              math.sin(x / size.width * math.pi);

      if (x == 0) {
        path2.moveTo(x, y);
      } else {
        path2.lineTo(x, y);
      }
    }

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.isActive != isActive;
  }
}
