// Text-to-speech services for the Kind Banking app
//
// Provides an abstraction layer over TTS implementations,
// making it easy to swap providers (flutter_tts, Google Cloud TTS, AWS Polly, etc.)

export 'flutter_tts_service.dart';
export 'mock_tts_service.dart';
export 'tts_manager.dart';
export 'tts_service.dart';
