import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/chat_message.dart';

/// Service for persisting chat history locally
class ChatStorageService {
  static const String _chatHistoryKey = 'chat_history';
  static const int _maxMessagesToStore = 100;

  final SharedPreferences _prefs;

  ChatStorageService(this._prefs);

  /// Save chat messages to local storage
  Future<void> saveMessages(List<ChatMessage> messages) async {
    try {
      // Limit the number of messages to store
      final messagesToStore =
          messages.length > _maxMessagesToStore ? messages.sublist(messages.length - _maxMessagesToStore) : messages;

      // Convert messages to JSON
      final jsonList = messagesToStore.map((m) => m.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      // Save to shared preferences
      await _prefs.setString(_chatHistoryKey, jsonString);
    } catch (e) {
      // Silent fail - don't interrupt user experience
      print('Error saving chat history: $e');
    }
  }

  /// Load chat messages from local storage
  Future<List<ChatMessage>> loadMessages() async {
    try {
      final jsonString = _prefs.getString(_chatHistoryKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.map((json) => ChatMessage.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      // Silent fail - return empty list
      print('Error loading chat history: $e');
      return [];
    }
  }

  /// Clear all chat history from storage
  Future<void> clearMessages() async {
    try {
      await _prefs.remove(_chatHistoryKey);
    } catch (e) {
      print('Error clearing chat history: $e');
    }
  }

  /// Check if chat history exists
  bool hasHistory() {
    return _prefs.containsKey(_chatHistoryKey);
  }
}
