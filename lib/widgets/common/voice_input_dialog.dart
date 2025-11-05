import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/voice_input_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class VoiceInputDialog extends ConsumerStatefulWidget {
  final Function(String) onComplete;

  const VoiceInputDialog({
    super.key,
    required this.onComplete,
  });

  @override
  ConsumerState<VoiceInputDialog> createState() => _VoiceInputDialogState();
}

class _VoiceInputDialogState extends ConsumerState<VoiceInputDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    // Start listening immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceInputNotifierProvider.notifier).startListening();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    ref.read(voiceInputNotifierProvider.notifier).cancelListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceInputNotifierProvider);

    ref.listen(
      voiceInputNotifierProvider,
      (previous, current) {
        if (current.recognizedText.isNotEmpty &&
            previous?.recognizedText != current.recognizedText) {
          Navigator.pop(context);
          widget.onComplete(current.recognizedText);
        }
      },
    );

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Mic Icon
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.warmCoral.withOpacity(
                      0.1 + (_animationController.value * 0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.mic,
                    size: 50,
                    color: AppColors.warmCoral,
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Status Text
            Text(
              voiceState.isListening ? 'Listening...' : 'Processing...',
              style: AppTextStyles.title(),
            ),

            const SizedBox(height: 12),

            // Partial Results
            if (voiceState.partialText.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  voiceState.partialText,
                  style: AppTextStyles.body().copyWith(
                    color: AppColors.secondaryText,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 24),

            // Cancel Button
            TextButton(
              onPressed: () {
                ref.read(voiceInputNotifierProvider.notifier).cancelListening();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
