import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:helphub/data/services/event_service.dart';
import 'package:helphub/data/services/user_service.dart';
import 'package:helphub/data/models/event_model.dart';

import '../../data/services/chat_service.dart';
import '../../data/models/base_profile_model.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/message_model.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  final EventService _eventService = EventService();
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
  BaseProfileModel? _user;

  BaseProfileModel? get user => _user;

  BaseProfileModel? _friendProfile;

  BaseProfileModel? get friendProfile => _friendProfile;
  int _totalUnreadCount = 0;
  StreamSubscription<int>? _totalUnreadCountSubscription;

  int get totalUnreadCount => _totalUnreadCount;

  final Map<String, StreamSubscription<int>> _unreadSubscriptions = {};

  EventModel? _currentEvent;

  EventModel? get currentEvent => _currentEvent;

  ChatViewModel() {
    _init();
  }

  Future<void> _init() async {
    _currentUserId = _auth.currentUser?.uid;
    if (_currentUserId != null) {
      _user = await _userService.fetchUserProfile(_currentUserId);
      loadUserChats(_currentUserId!);
    }
  }

  void loadUserChats(String userId) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _userChatsSubscription?.cancel();
    _userChatsSubscription = _chatService
        .getUserChats(userId)
        .listen(
          (chats) async {
            _userChats = chats;
            _isLoading = false;
            notifyListeners();
            _startUnreadCountListeners();
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

      _currentChatSubscription = _chatService
          .getChatStream(chatId)
          .listen(
            (chat) {
              _currentChat = chat;
              notifyListeners();
            },
            onError: (error) {
              print('Error listening to chat updates: $error');
            },
          );
      if (currentChat!.type == ChatType.friend) {
        final friendId = _currentChat!.participants.firstWhere(
          (id) => id != currentUserId,
        );
        try {
          _friendProfile = await _userService.fetchUserProfile(friendId);
          notifyListeners();
        } catch (e) {
          print('Error loading friend profile: $e');
        }
      } else if (currentChat!.type == ChatType.event) {
        if (currentChat?.entityId != null) {
          _currentEvent = await _eventService.getEventById(
            currentChat!.entityId!,
          );
          notifyListeners();
        }
      }
      _messagesSubscription = _chatService
          .listenMessages(chatId)
          .listen(
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
/*
  void _startListeningToTotalUnreadCount(String userId) {
    _totalUnreadCountSubscription?.cancel();
    _totalUnreadCountSubscription = _chatService
        .getTotalUnreadMessagesCount(userId)
        .listen(
          (totalCount) {
            _totalUnreadCount = totalCount;
            notifyListeners();
          },
          onError: (error) {
            print('Error listening to total unread count: $error');
          },
        );
  }*/

  Future<bool> sendMessage(String chatId, String text) async {
    if (text.trim().isEmpty) {
      return false;
    }

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

  Future<String?> createEventChat(
    String eventId,
    List<String> participantIds, {
    String? chatImageUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final chatId = await _chatService.createEventChat(
        eventId,
        participantIds,
        chatImageUrl: chatImageUrl,
      );
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

  Future<String?> createProjectChat(
    String projectId,
    List<String> participantIds, {
    String? chatImageUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final chatId = await _chatService.createProjectChat(
        projectId,
        participantIds,
        chatImageUrl: chatImageUrl,
      );
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
      final chatId = await _chatService.createFriendChat(
        _currentUserId!,
        friendUserId,
      );
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

  Future<bool> updateChatImage(String chatId, String? imageUrl) async {
    try {
      final success = await _chatService.updateChatImage(chatId, imageUrl);
      if (success) {
        // Оновлюємо локальну модель чату
        if (_currentChat?.id == chatId) {
          _currentChat = _currentChat!.copyWith(chatImageUrl: imageUrl);
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      _errorMessage = 'Помилка оновлення фото чату: $e';
      notifyListeners();
      return false;
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
      return _userChats
          .where((chat) => chat.type == type && chat.participants.length == 2)
          .firstOrNull;
    }

    return _userChats
        .where((chat) => chat.type == type && chat.entityId == entityId)
        .firstOrNull;
  }

  bool chatExistsForEntity(
    ChatType type,
    String? entityId, [
    String? friendUserId,
  ]) {
    if (type == ChatType.friend &&
        friendUserId != null &&
        _currentUserId != null) {
      final chatId = ChatModel.generateFriendChatId(
        _currentUserId!,
        friendUserId,
      );
      return _userChats.any((chat) => chat.id == chatId);
    }

    return _userChats.any(
      (chat) => chat.type == type && chat.entityId == entityId,
    );
  }

  @override
  void dispose() {
    _userChatsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _currentChatSubscription?.cancel();
    _totalUnreadCountSubscription?.cancel();
    for (var sub in _unreadSubscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }

  void _startUnreadCountListeners() {
    for (var sub in _unreadSubscriptions.values) {
      sub.cancel();
    }
    _unreadSubscriptions.clear();

    if (_currentUserId == null) return;

    for (var chat in _userChats) {
      if (chat.id == null) continue;
      final subscription = _chatService
          .getUnreadMessagesCountStream(chat.id!, _currentUserId!)
          .listen((count) {
            final index = _userChats.indexWhere((c) => c.id == chat.id);
            if (index != -1) {
              _userChats[index] = _userChats[index].copyWith(
                unreadCount: count,
              );
              _calculateTotalUnreadCount();
              notifyListeners();
            }
          });
      _unreadSubscriptions[chat.id!] = subscription;
    }
  }
  void _calculateTotalUnreadCount() {
    _totalUnreadCount = _userChats.fold(
      0,
          (sum, chat) => sum + (chat.unreadCount),
    );
  }
}
