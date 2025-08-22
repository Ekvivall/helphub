import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/services/chat_service.dart';
import '../../models/chat_model.dart';
import '../../models/message_model.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ChatModel> _userChats = [];
  ChatModel? _currentChat;
  List<MessageModel> _currentMessages = [];
  bool _isLoading = false;
  bool _isSendingMessage = false;
  String? _errorMessage;
  String? _currentUserId;

  StreamSubscription<List<ChatModel>>? _userChatsSubscription;
  StreamSubscription<List<MessageModel>>? _messagesSubscription;
  StreamSubscription<ChatModel>? _currentChatSubscription;

  List<ChatModel> get userChats => _userChats;
  ChatModel? get currentChat => _currentChat;
  List<MessageModel> get currentMessages => _currentMessages;
  bool get isLoading => _isLoading;
  bool get isSendingMessage => _isSendingMessage;
  String? get errorMessage => _errorMessage;
  String? get currentUserId => _currentUserId;

  ChatViewModel() {
    _init();
  }

  void _init() {
    _currentUserId = _auth.currentUser?.uid;
    if (_currentUserId != null) {
      loadUserChats(_currentUserId!);
    }
  }

  void loadUserChats(String userId) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _userChatsSubscription?.cancel();
    _userChatsSubscription = _chatService.getUserChats(userId).listen(
          (chats) {
        _userChats = chats;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Помилка завантаження чатів: $error';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> openChat(String chatId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _messagesSubscription?.cancel();
      _currentChatSubscription?.cancel();

      _currentChat = await _chatService.getChatById(chatId);

      if (_currentChat == null) {
        _errorMessage = 'Чат не знайдено';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _currentChatSubscription = _chatService.getChatStream(chatId).listen(
            (chat) {
          _currentChat = chat;
          notifyListeners();
        },
        onError: (error) {
          print('Error listening to chat updates: $error');
        },
      );

      _messagesSubscription = _chatService.listenMessages(chatId).listen(
            (messages) {
          _currentMessages = messages;
          _isLoading = false;
          notifyListeners();

          if (_currentUserId != null) {
            _chatService.markMessagesAsRead(chatId, _currentUserId!);
          }
        },
        onError: (error) {
          _errorMessage = 'Помилка завантаження повідомлень: $error';
          _isLoading = false;
          notifyListeners();
        },
      );

    } catch (e) {
      _errorMessage = 'Помилка відкриття чату: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(String chatId, String text) async {
    if (text.trim().isEmpty) return false;

    _isSendingMessage = true;
    notifyListeners();

    try {
      final success = await _chatService.sendMessage(
        chatId: chatId,
        text: text.trim(),
        type: MessageType.text,
      );

      _isSendingMessage = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Помилка відправки повідомлення: $e';
      _isSendingMessage = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendMessageWithAttachments({
    required String chatId,
    required String text,
    required MessageType type,
    List<String> attachments = const [],
  }) async {
    _isSendingMessage = true;
    notifyListeners();

    try {
      final success = await _chatService.sendMessage(
        chatId: chatId,
        text: text,
        type: type,
        attachments: attachments,
      );

      _isSendingMessage = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Помилка відправки повідомлення: $e';
      _isSendingMessage = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> createEventChat(String eventId, List<String> participantIds) async {
    _isLoading = true;
    notifyListeners();

    try {
      final chatId = await _chatService.createEventChat(eventId, participantIds);
      _isLoading = false;
      notifyListeners();
      return chatId;
    } catch (e) {
      _errorMessage = 'Помилка створення чату події: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<String?> createProjectChat(String projectId, List<String> participantIds) async {
    _isLoading = true;
    notifyListeners();

    try {
      final chatId = await _chatService.createProjectChat(projectId, participantIds);
      _isLoading = false;
      notifyListeners();
      return chatId;
    } catch (e) {
      _errorMessage = 'Помилка створення чату проєкту: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<String?> createFriendChat(String friendUserId) async {
    if (_currentUserId == null) return null;

    _isLoading = true;
    notifyListeners();

    try {
      final chatId = await _chatService.createFriendChat(_currentUserId!, friendUserId);
      _isLoading = false;
      notifyListeners();
      return chatId;
    } catch (e) {
      _errorMessage = 'Помилка створення чату з другом: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> addParticipantToChat(String chatId, String userId) async {
    try {
      return await _chatService.addParticipant(chatId, userId);
    } catch (e) {
      _errorMessage = 'Помилка додавання учасника: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeParticipantFromChat(String chatId, String userId) async {
    try {
      return await _chatService.removeParticipant(chatId, userId);
    } catch (e) {
      _errorMessage = 'Помилка видалення учасника: $e';
      notifyListeners();
      return false;
    }
  }

  void closeCurrentChat() {
    _currentChat = null;
    _currentMessages = [];
    _messagesSubscription?.cancel();
    _currentChatSubscription?.cancel();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  ChatModel? getChatByEntity(ChatType type, String? entityId) {
    if (type == ChatType.friend) {
      return _userChats.where((chat) =>
      chat.type == type &&
          chat.participants.length == 2
      ).firstOrNull;
    }

    return _userChats.where((chat) =>
    chat.type == type &&
        chat.entityId == entityId
    ).firstOrNull;
  }

  bool chatExistsForEntity(ChatType type, String? entityId, [String? friendUserId]) {
    if (type == ChatType.friend && friendUserId != null && _currentUserId != null) {
      final chatId = ChatModel.generateFriendChatId(_currentUserId!, friendUserId);
      return _userChats.any((chat) => chat.id == chatId);
    }

    return _userChats.any((chat) =>
    chat.type == type &&
        chat.entityId == entityId
    );
  }

  @override
  void dispose() {
    _userChatsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _currentChatSubscription?.cancel();
    super.dispose();
  }


}