# Task 07: Voice Input Integration

**Status**: DONE
**Priority**: MEDIUM
**Estimated Time**: 3 hours
**Assigned To**: Claude
**Dependencies**: Task 06 (Today's Log Screen)
**Completed**: 2025-11-05

---

## Objective

Implement voice-to-text functionality for quick activity logging, making habit capture effortless and natural.

## Acceptance Criteria

- [ ] Voice input button appears on Add Log sheet
- [ ] Speech-to-text captures user's spoken notes
- [ ] Captured text populates the notes field
- [ ] Works on both iOS and Android
- [ ] Proper permissions handling (microphone access)
- [ ] Visual feedback while listening
- [ ] Error handling for no permission/failed recognition
- [ ] Option to re-record if needed

---

## Step-by-Step Instructions

### 1. Update Permissions

#### For iOS - `ios/Runner/Info.plist`

Add this inside `<dict>`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access to capture your voice notes for habit logging</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>We need speech recognition to convert your voice notes to text</string>
```

#### For Android - `android/app/src/main/AndroidManifest.xml`

Add these permissions before `<application>`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

Also add this inside `<manifest>`:

```xml
<queries>
    <intent>
        <action android:name="android.speech.RecognitionService" />
    </intent>
</queries>
```

### 2. Create Voice Input Service

#### `lib/services/voice_input_service.dart`

```dart
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceInputService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  /// Initialize the speech recognition service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onError: (error) => print('Speech recognition error: $error'),
        onStatus: (status) => print('Speech recognition status: $status'),
      );
      return _isInitialized;
    } catch (e) {
      print('Failed to initialize speech recognition: $e');
      return false;
    }
  }

  /// Check if speech recognition is available
  Future<bool> isAvailable() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _isInitialized;
  }

  /// Start listening for speech input
  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onPartialResult,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        throw Exception('Speech recognition not initialized');
      }
    }

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
        } else if (onPartialResult != null) {
          onPartialResult(result.recognizedWords);
        }
      },
      listenFor: Duration(seconds: 30),
      pauseFor: Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    if (_speech.isListening) {
      await _speech.cancel();
    }
  }

  /// Check if currently listening
  bool get isListening => _speech.isListening;

  /// Get available locales
  Future<List<stt.LocaleName>> getLocales() async {
    return await _speech.locales();
  }

  /// Dispose resources
  void dispose() {
    _speech.stop();
  }
}
```

### 3. Create Voice Input Provider

#### `lib/providers/voice_input_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/voice_input_service.dart';

// Voice Input Service Provider
final voiceInputServiceProvider = Provider<VoiceInputService>((ref) {
  final service = VoiceInputService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Voice Input State
class VoiceInputState {
  final bool isListening;
  final bool isAvailable;
  final String recognizedText;
  final String partialText;
  final String? error;

  VoiceInputState({
    this.isListening = false,
    this.isAvailable = false,
    this.recognizedText = '',
    this.partialText = '',
    this.error,
  });

  VoiceInputState copyWith({
    bool? isListening,
    bool? isAvailable,
    String? recognizedText,
    String? partialText,
    String? error,
  }) {
    return VoiceInputState(
      isListening: isListening ?? this.isListening,
      isAvailable: isAvailable ?? this.isAvailable,
      recognizedText: recognizedText ?? this.recognizedText,
      partialText: partialText ?? this.partialText,
      error: error,
    );
  }
}

// Voice Input Notifier
class VoiceInputNotifier extends StateNotifier<VoiceInputState> {
  final VoiceInputService _service;

  VoiceInputNotifier(this._service) : super(VoiceInputState()) {
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final available = await _service.isAvailable();
    state = state.copyWith(isAvailable: available);
  }

  Future<void> startListening() async {
    try {
      state = state.copyWith(
        isListening: true,
        error: null,
        recognizedText: '',
        partialText: '',
      );

      await _service.startListening(
        onResult: (text) {
          state = state.copyWith(
            recognizedText: text,
            isListening: false,
            partialText: '',
          );
        },
        onPartialResult: (text) {
          state = state.copyWith(partialText: text);
        },
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isListening: false,
      );
    }
  }

  Future<void> stopListening() async {
    await _service.stopListening();
    state = state.copyWith(isListening: false);
  }

  Future<void> cancelListening() async {
    await _service.cancelListening();
    state = state.copyWith(
      isListening: false,
      recognizedText: '',
      partialText: '',
    );
  }

  void clearText() {
    state = state.copyWith(
      recognizedText: '',
      partialText: '',
      error: null,
    );
  }
}

// Voice Input State Provider
final voiceInputNotifierProvider =
    StateNotifierProvider<VoiceInputNotifier, VoiceInputState>((ref) {
  final service = ref.watch(voiceInputServiceProvider);
  return VoiceInputNotifier(service);
});
```

### 4. Create Voice Input Button Widget

#### `lib/widgets/buttons/voice_input_button.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/voice_input_provider.dart';
import '../../theme/app_colors.dart';

class VoiceInputButton extends ConsumerWidget {
  final Function(String) onTextRecognized;
  final bool showPartialResults;

  const VoiceInputButton({
    super.key,
    required this.onTextRecognized,
    this.showPartialResults = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceInputNotifierProvider);

    if (!voiceState.isAvailable) {
      return SizedBox.shrink();
    }

    return IconButton(
      icon: Icon(
        voiceState.isListening ? Icons.mic : Icons.mic_none,
        color: voiceState.isListening
            ? AppColors.warmCoral
            : AppColors.primaryText,
      ),
      onPressed: () {
        if (voiceState.isListening) {
          ref.read(voiceInputNotifierProvider.notifier).stopListening();
        } else {
          _startVoiceInput(context, ref);
        }
      },
    );
  }

  void _startVoiceInput(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(voiceInputNotifierProvider.notifier);

    try {
      await notifier.startListening();

      // Listen for recognized text
      ref.listen(
        voiceInputNotifierProvider,
        (previous, current) {
          if (current.recognizedText.isNotEmpty &&
              previous?.recognizedText != current.recognizedText) {
            onTextRecognized(current.recognizedText);
            notifier.clearText();
          }

          if (current.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Voice input error: ${current.error}'),
                backgroundColor: AppColors.softRed,
              ),
            );
          }
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not start voice input: $e'),
          backgroundColor: AppColors.softRed,
        ),
      );
    }
  }
}
```

### 5. Create Voice Input Dialog

#### `lib/widgets/common/voice_input_dialog.dart`

```dart
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
      duration: Duration(seconds: 1),
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
        padding: EdgeInsets.all(24),
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
                  child: Icon(
                    Icons.mic,
                    size: 50,
                    color: AppColors.warmCoral,
                  ),
                );
              },
            ),

            SizedBox(height: 24),

            // Status Text
            Text(
              voiceState.isListening ? 'Listening...' : 'Processing...',
              style: AppTextStyles.title,
            ),

            SizedBox(height: 12),

            // Partial Results
            if (voiceState.partialText.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  voiceState.partialText,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondaryText,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            SizedBox(height: 24),

            // Cancel Button
            TextButton(
              onPressed: () {
                ref.read(voiceInputNotifierProvider.notifier).cancelListening();
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 6. Update Add Log Sheet

Update [lib/screens/home/add_log_sheet.dart](lib/screens/home/add_log_sheet.dart) to include voice input:

```dart
// Add import
import '../../widgets/common/voice_input_dialog.dart';

// In the notes TextField, add this as suffixIcon in InputDecoration:
suffixIcon: IconButton(
  icon: Icon(Icons.mic, color: AppColors.warmCoral),
  onPressed: () => _showVoiceInputDialog(),
),

// Add this method to _AddLogSheetState:
void _showVoiceInputDialog() {
  showDialog(
    context: context,
    builder: (context) => VoiceInputDialog(
      onComplete: (text) {
        setState(() {
          if (_notesController.text.isNotEmpty) {
            _notesController.text += ' $text';
          } else {
            _notesController.text = text;
          }
        });
      },
    ),
  );
}
```

---

## Verification Checklist

- [ ] Microphone permission requested on first use
- [ ] Voice input button appears in Add Log sheet
- [ ] Tapping mic icon opens voice input dialog
- [ ] Animated listening indicator displays
- [ ] Partial results show while speaking
- [ ] Final text populates notes field correctly
- [ ] Cancel button stops listening
- [ ] Works on both iOS and Android
- [ ] Error handling for denied permissions
- [ ] No crashes or memory leaks

---

## Testing Scenarios

1. **First Use**: Launch voice input, verify permission prompt appears
2. **Happy Path**: Tap mic, speak clearly, verify text appears in notes
3. **Partial Results**: Speak slowly, watch partial text update
4. **Cancel**: Start voice input, tap cancel, verify dialog closes
5. **Denied Permission**: Deny microphone access, verify error message
6. **Background**: Start voice input, minimize app, verify it stops
7. **Multiple Uses**: Use voice input multiple times in a row

---

## Common Issues & Solutions

### Issue: Permission denied on iOS
**Solution**: Check Info.plist has correct usage descriptions

### Issue: Speech recognition not working on Android
**Solution**: Ensure device has Google app installed and updated

### Issue: No partial results showing
**Solution**: Check `partialResults: true` is set in `listen()` call

### Issue: Voice input doesn't stop automatically
**Solution**: Adjust `pauseFor` duration in `startListening()`

---

## Privacy & Best Practices

1. **Permissions**: Always explain why microphone access is needed
2. **Privacy**: Voice data is processed on-device (no cloud storage)
3. **User Control**: Always show visual indicator when listening
4. **Timeout**: Auto-stop after 30 seconds to save battery
5. **Cleanup**: Dispose service properly to prevent memory leaks

---

## Next Task

After completion, proceed to: [08_habit_model.md](./08_habit_model.md)

---

**Last Updated**: 2025-10-29
