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
