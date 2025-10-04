import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/widgets/user_avatar_with_frame.dart';
import 'package:provider/provider.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/base_profile_model.dart';
import '../../data/models/event_model.dart';
import '../../data/models/project_model.dart';
import '../../data/models/volunteer_model.dart';
import '../../data/models/organization_model.dart';
import '../../view_models/chat/chat_view_model.dart';

class ChatListItem extends StatefulWidget {
  final ChatModel chat;
  final String currentUserId;
  final VoidCallback onTap;
  final int unreadCount;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.onTap,
    required this.unreadCount,
  });

  @override
  State<ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<ChatListItem> {
  String _chatTitle = '';
  String _avatarText = '';
  Color _avatarColor = appThemeColors.grey200;
  IconData? _typeIcon;
  BaseProfileModel? _friendProfile;
  EventModel? _eventData;
  ProjectModel? _projectData;

  @override
  void initState() {
    super.initState();
    _loadChatData();
  }

  Future<void> _loadChatData() async {
    try {
      switch (widget.chat.type) {
        case ChatType.friend:
          await _loadFriendData();
          break;
        case ChatType.event:
          await _loadEventData();
          break;
        case ChatType.project:
          await _loadProjectData();
          break;
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error loading chat data: $e');
    }
  }

  Future<void> _loadFriendData() async {
    // Get friend's ID (the other participant)
    final friendId = widget.chat.participants.firstWhere(
      (id) => id != widget.currentUserId,
      orElse: () => '',
    );

    if (friendId.isEmpty) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(friendId)
        .get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      if (data['role'] == 'volunteer') {
        _friendProfile = VolunteerModel.fromMap(data);
        final volunteer = _friendProfile as VolunteerModel;
        _chatTitle = volunteer.fullName ?? volunteer.displayName ?? 'Волонтер';
      } else if (data['role'] == 'organization') {
        _friendProfile = OrganizationModel.fromMap(data);
        final org = _friendProfile as OrganizationModel;
        _chatTitle = org.organizationName ?? 'Організація';
      }
    }
  }

  Future<void> _loadEventData() async {
    if (widget.chat.entityId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.chat.entityId!)
        .get();

    if (doc.exists && doc.data() != null) {
      _eventData = EventModel.fromMap(doc.data()!, doc.id);
      _chatTitle = _eventData!.name;
      _typeIcon = Icons.event;
      _avatarColor = appThemeColors.lightGreenColor;
      _avatarText = _getInitials(_chatTitle);
    }
  }

  Future<void> _loadProjectData() async {
    if (widget.chat.entityId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.chat.entityId!)
        .get();

    if (doc.exists && doc.data() != null) {
      _projectData = ProjectModel.fromMap(doc.data()!);
      _chatTitle = _projectData!.title ?? 'Проєкт';
      _typeIcon = Icons.assignment;
      _avatarColor = appThemeColors.cyanAccent;
      _avatarText = _getInitials(_chatTitle);
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'
          .toUpperCase();
    }
  }

  String _formatLastMessageTime() {
    if (widget.chat.lastMessageAt == null) return '';

    final now = DateTime.now();
    final messageTime = widget.chat.lastMessageAt!;
    final difference = now.difference(messageTime);

    if (difference.inMinutes < 1) {
      return 'щойно';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} хв';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} год';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн';
    } else {
      return '${messageTime.day}.${messageTime.month.toString().padLeft(2, '0')}';
    }
  }

  String _getLastMessagePreview() {
    if (widget.chat.lastMessage == null || widget.chat.lastMessage!.isEmpty) {
      switch (widget.chat.type) {
        case ChatType.event:
          return 'Чат події створено';
        case ChatType.project:
          return 'Чат проєкту створено';
        case ChatType.friend:
          return 'Розпочати розмову';
      }
    }

    final message = widget.chat.lastMessage!;
    return message.length > 60 ? '${message.substring(0, 60)}...' : message;
  }

  Widget _buildAvatar() {
    switch (widget.chat.type) {
      case ChatType.friend:
        if (_friendProfile == null) {
          return CircleAvatar(
            radius: 28,
            backgroundColor: appThemeColors.grey200,
            child: Icon(
              Icons.person,
              color: appThemeColors.primaryWhite,
              size: 24,
            ),
          );
        }

        // Використовуємо UserAvatarWithFrame для друзів
        return UserAvatarWithFrame(
          photoUrl: _friendProfile is VolunteerModel
              ? (_friendProfile as VolunteerModel).photoUrl
              : _friendProfile is OrganizationModel
              ? (_friendProfile as OrganizationModel).photoUrl
              : null,
          frame: _friendProfile is VolunteerModel
              ? (_friendProfile as VolunteerModel).frame
              : null,
          role: _friendProfile is VolunteerModel
              ? UserRole.volunteer
              : UserRole.organization,
          size: 28,
          uid: widget.chat.participants.firstWhere(
            (id) => id != widget.currentUserId,
            orElse: () => '',
          ),
        );

      case ChatType.event:
      case ChatType.project:
        // Для подій та проєктів показуємо кастомне фото або іконку
        if (widget.chat.chatImageUrl != null &&
            widget.chat.chatImageUrl!.isNotEmpty) {
          return CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(widget.chat.chatImageUrl!),
          );
        } else {
          return Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: _avatarColor,
                child: _typeIcon != null
                    ? Icon(
                        _typeIcon,
                        color: appThemeColors.primaryWhite,
                        size: 24,
                      )
                    : Text(
                        _avatarText,
                        style: TextStyleHelper.instance.title18Bold.copyWith(
                          color: appThemeColors.primaryWhite,
                        ),
                      ),
              ),
            ],
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: appThemeColors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: appThemeColors.backgroundLightGrey.withAlpha(15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: appThemeColors.backgroundLightGrey.withAlpha(30),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Avatar
                _buildAvatar(),

                const SizedBox(width: 16),

                // Chat info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chat title and time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _chatTitle.isNotEmpty
                                  ? _chatTitle
                                  : 'Завантаження...',
                              style: TextStyleHelper.instance.title16Bold
                                  .copyWith(
                                    color: appThemeColors.backgroundLightGrey,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatLastMessageTime(),
                            style: TextStyleHelper.instance.title13Regular
                                .copyWith(
                                  color: appThemeColors.backgroundLightGrey
                                      .withAlpha(150),
                                ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Last message and participants count
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _getLastMessagePreview(),
                              style: TextStyleHelper.instance.title14Regular
                                  .copyWith(
                                    color: appThemeColors.backgroundLightGrey
                                        .withAlpha(180),
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Participants count for events/projects
                          if (widget.chat.type != ChatType.friend)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: appThemeColors.backgroundLightGrey
                                    .withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 12,
                                    color: appThemeColors.backgroundLightGrey
                                        .withAlpha(150),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${widget.chat.participants.length}',
                                    style: TextStyleHelper
                                        .instance
                                        .title10Regular
                                        .copyWith(
                                          color: appThemeColors
                                              .backgroundLightGrey
                                              .withAlpha(150),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          _buildUnreadBadge(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnreadBadge() {
    return Consumer<ChatViewModel>(
      builder: (context, viewModel, child) {
        if (widget.unreadCount > 0) {
          return Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: appThemeColors.cyanAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            child: Text(
              widget.unreadCount.toString(),
              style: TextStyleHelper.instance.title13Regular.copyWith(
                color: appThemeColors.primaryWhite,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        return SizedBox.shrink();
      },
    );
  }
}
