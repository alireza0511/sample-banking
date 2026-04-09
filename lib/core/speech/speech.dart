// Speech recognition services for the Kind Banking app
//
// Provides an abstraction layer over speech-to-text implementations,
// making it easy to swap providers (speech_to_text, Google Cloud, AWS, etc.)

export 'mock_speech_service.dart';
export 'speech_manager.dart';
export 'speech_service.dart';
export 'speech_to_text_service.dart';
