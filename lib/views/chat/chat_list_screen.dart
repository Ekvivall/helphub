import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helphub/routes/app_router.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/widgets/custom_tournament_icon_button.dart';
import 'package:provider/provider.dart';

import '../../data/models/base_profile_model.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/volunteer_model.dart';
import '../../theme/theme_helper.dart';
import '../../view_models/chat/chat_view_model.dart';
import '../../widgets/chat/chat_list_item.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';
import '../../widgets/custom_notification_icon_button.dart';
import '../../widgets/user_avatar_with_frame.dart';
import 'chat_project_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentUserId != null) {
        context.read<ChatViewModel>().loadUserChats(_currentUserId!);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: appThemeColors.blueAccent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(0.9, -0.4),
              end: Alignment(-0.9, 0.4),
              colors: [appThemeColors.blueAccent, appThemeColors.cyanAccent],
            ),
          ),
          child: Consumer<ChatViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.user == null) return SizedBox.shrink();
              final BaseProfileModel user = viewModel.user!;
              return Column(
                children: [
                  _buildHeader(context, viewModel, user),
                  const SizedBox(height: 9),
                  TabBar(
                    tabAlignment: TabAlignment.start,
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: appThemeColors.backgroundLightGrey,
                    unselectedLabelColor: appThemeColors.backgroundLightGrey
                        .withAlpha(150),
                    indicatorColor: appThemeColors.lightGreenColor,
                    labelStyle: TextStyleHelper.instance.title14Regular
                        .copyWith(fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(text: 'Усі чати'),
                      Tab(text: 'Події'),
                      Tab(text: 'Проєкти'),
                      Tab(text: 'Друзі'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildChatList(viewModel, filter: 'all'),
                        _buildChatList(viewModel, filter: 'events'),
                        _buildChatList(viewModel, filter: 'projects'),
                        _buildChatList(viewModel, filter: 'friends'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: buildBottomNavigationBar(context, 4),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ChatViewModel viewModel,
    BaseProfileModel user,
  ) {
    final VolunteerModel? volunteer = user is VolunteerModel ? user : null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 12),
      color: appThemeColors.appBarBg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          UserAvatarWithFrame(
            size: 22,
            role: user.role,
            photoUrl: user.photoUrl,
            frame: volunteer?.frame,
            uid: user.uid!,
          ),
          Row(
            children: [
              CustomTournamentIconButton(),
              CustomNotificationIconButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(ChatViewModel viewModel, {required String filter}) {
    if (viewModel.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: appThemeColors.primaryWhite),
      );
    }
    if (viewModel.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: appThemeColors.backgroundLightGrey.withAlpha(150),
              ),
              const SizedBox(height: 16),
              Text(
                viewModel.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyleHelper.instance.title16Regular.copyWith(
                  color: appThemeColors.backgroundLightGrey.withAlpha(150),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  viewModel.clearError();
                  if (_currentUserId != null) {
                    viewModel.loadUserChats(_currentUserId!);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: appThemeColors.lightGreenColor,
                ),
                child: Text(
                  'Спробувати знову',
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final filteredChats = _getFilteredChats(viewModel.userChats, filter);

    if (filteredChats.isEmpty) {
      return _buildEmptyListMessage(filter);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredChats.length,
      itemBuilder: (context, index) {
        final chat = filteredChats[index];
        return ChatListItem(
          chat: chat,
          currentUserId: _currentUserId!,
          onTap: () {
            if (chat.type == ChatType.project) {
              Navigator.of(context).pushNamed(
                AppRoutes.chatProjectScreen,
                arguments: {'chatId': chat.id, 'displayMode': DisplayMode.chat},
              );
            } else if (chat.type == ChatType.friend) {
              Navigator.of(
                context,
              ).pushNamed(AppRoutes.chatFriendScreen, arguments: chat.id);
            } else {
              Navigator.of(
                context,
              ).pushNamed(AppRoutes.chatEventScreen, arguments: chat.id);
            }
          },
          unreadCount: chat.unreadCount,
        );
      },
    );
  }

  List<ChatModel> _getFilteredChats(List<ChatModel> allChats, String filter) {
    switch (filter) {
      case 'events':
        return allChats.where((chat) => chat.type == ChatType.event).toList();
      case 'projects':
        return allChats.where((chat) => chat.type == ChatType.project).toList();
      case 'friends':
        return allChats.where((chat) => chat.type == ChatType.friend).toList();
      case 'all':
      default:
        return allChats;
    }
  }

  Widget _buildEmptyListMessage(String filter) {
    String message;
    String subtitle;
    IconData icon;

    switch (filter) {
      case 'events':
        message = 'Немає чатів подій';
        subtitle = 'Чати подій з\'являться після долучення до подій';
        icon = Icons.event;
        break;
      case 'projects':
        message = 'Немає чатів проєктів';
        subtitle = 'Чати проєктів з\'являться після участі у проєктах';
        icon = Icons.work;
        break;
      case 'friends':
        message = 'Немає чатів з друзями';
        subtitle = 'Почніть розмову з друзями через їх профіль';
        icon = Icons.people;
        break;
      default:
        message = 'Немає чатів';
        subtitle = 'Ваші розмови з\'являться тут';
        icon = Icons.chat;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: appThemeColors.backgroundLightGrey.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyleHelper.instance.title20Regular.copyWith(
                color: appThemeColors.backgroundLightGrey.withAlpha(150),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.backgroundLightGrey.withAlpha(100),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
