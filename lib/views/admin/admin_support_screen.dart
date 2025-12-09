import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/admin/admin_view_model.dart';
import 'package:helphub/widgets/user_avatar_with_frame.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/utils/constants.dart';
import '../../data/models/support_ticket_model.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_text_field.dart';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _responseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appThemeColors.blueAccent,
      appBar: AppBar(
        backgroundColor: appThemeColors.appBarBg,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back,
            size: 40,
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
        title: Text(
          'Центр підтримки',
          style: TextStyleHelper.instance.headline24SemiBold.copyWith(
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(0.9, -0.4),
            end: const Alignment(-0.9, 0.4),
            colors: [appThemeColors.blueAccent, appThemeColors.cyanAccent],
          ),
        ),
        child: Consumer<AdminViewModel>(
          builder: (context, viewModel, child) {
            return Column(
              children: [
                // Вкладки
                Container(
                  color: appThemeColors.appBarBg,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: appThemeColors.backgroundLightGrey,
                    unselectedLabelColor: appThemeColors.backgroundLightGrey
                        .withAlpha(150),
                    indicatorColor: appThemeColors.lightGreenColor,
                    tabs: [
                      Tab(text: 'Відкриті (${viewModel.openTickets.length})'),
                      Tab(
                        text:
                            'В роботі (${viewModel.inProgressTickets.length})',
                      ),
                      Tab(
                        text: 'Вирішені (${viewModel.resolvedTickets.length})',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: viewModel.isLoadingSupport
                      ? Center(
                          child: CircularProgressIndicator(
                            color: appThemeColors.backgroundLightGrey,
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildTicketsList(viewModel.openTickets, viewModel),
                            _buildTicketsList(
                              viewModel.inProgressTickets,
                              viewModel,
                            ),
                            _buildTicketsList(
                              viewModel.resolvedTickets,
                              viewModel,
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTicketsList(
    List<SupportTicketModel> tickets,
    AdminViewModel viewModel,
  ) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: appThemeColors.backgroundLightGrey.withAlpha(150),
            ),
            const SizedBox(height: 16),
            Text(
              'Немає звернень',
              style: TextStyleHelper.instance.title18Bold.copyWith(
                color: appThemeColors.backgroundLightGrey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return _buildTicketCard(ticket, viewModel);
      },
    );
  }

  Widget _buildTicketCard(SupportTicketModel ticket, AdminViewModel viewModel) {
    Color statusColor;
    IconData statusIcon;

    switch (ticket.status) {
      case SupportTicketStatus.open:
        statusColor = appThemeColors.errorRed;
        statusIcon = Icons.error_outline;
        break;
      case SupportTicketStatus.inProgress:
        statusColor = appThemeColors.orangeAccent;
        statusIcon = Icons.pending;
        break;
      case SupportTicketStatus.resolved:
        statusColor = appThemeColors.successGreen;
        statusIcon = Icons.check_circle;
        break;
      case SupportTicketStatus.closed:
        statusColor = appThemeColors.textMediumGrey;
        statusIcon = Icons.archive;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: appThemeColors.primaryBlack.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                UserAvatarWithFrame(
                  size: 24,
                  photoUrl: ticket.userPhotoUrl,
                  uid: ticket.userId,
                  role: null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.userName,
                        style: TextStyleHelper.instance.title16Bold.copyWith(
                          color: appThemeColors.primaryBlack,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeago.format(ticket.createdAt, locale: 'uk'),
                        style: TextStyleHelper.instance.title13Regular.copyWith(
                          color: appThemeColors.textMediumGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusText(ticket.status),
                        style: TextStyleHelper.instance.title13Regular.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(color: appThemeColors.grey200, height: 1),

          // Тема
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.subject,
                  style: TextStyleHelper.instance.title16Bold.copyWith(
                    color: appThemeColors.primaryBlack,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ticket.message,
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.textMediumGrey,
                  ),
                ),
              ],
            ),
          ),

          // Відповідь адміністратора (якщо є)
          if (ticket.adminResponse != null) ...[
            Divider(color: appThemeColors.grey200, height: 1),
            Container(
              padding: const EdgeInsets.all(16),
              color: appThemeColors.blueMixedColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        size: 16,
                        color: appThemeColors.blueAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Відповідь адміністратора:',
                        style: TextStyleHelper.instance.title14Regular.copyWith(
                          fontWeight: FontWeight.w700,
                          color: appThemeColors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ticket.adminResponse!,
                    style: TextStyleHelper.instance.title14Regular.copyWith(
                      color: appThemeColors.primaryBlack,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Кнопки дій
          if (ticket.status != SupportTicketStatus.resolved &&
              ticket.status != SupportTicketStatus.closed) ...[
            Divider(color: appThemeColors.grey200, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (ticket.status == SupportTicketStatus.open)
                    Expanded(
                      child: CustomElevatedButton(
                        text: 'Взяти в роботу',
                        onPressed: () => _updateTicketStatus(
                          ticket,
                          SupportTicketStatus.inProgress,
                          viewModel,
                        ),
                        backgroundColor: appThemeColors.orangeAccent,
                        textStyle: TextStyleHelper.instance.title14Regular
                            .copyWith(
                              color: appThemeColors.primaryWhite,
                              fontWeight: FontWeight.w700,
                            ),
                        borderRadius: 12,
                        height: 44,
                      ),
                    ),
                  if (ticket.status == SupportTicketStatus.open)
                    const SizedBox(width: 12),
                  Expanded(
                    child: CustomElevatedButton(
                      text: 'Відповісти',
                      onPressed: () =>
                          _showResponseDialog(context, ticket, viewModel),
                      backgroundColor: appThemeColors.successGreen,
                      textStyle: TextStyleHelper.instance.title14Regular
                          .copyWith(
                            color: appThemeColors.primaryWhite,
                            fontWeight: FontWeight.w700,
                          ),
                      borderRadius: 12,
                      height: 44,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getStatusText(SupportTicketStatus status) {
    switch (status) {
      case SupportTicketStatus.open:
        return 'Відкрито';
      case SupportTicketStatus.inProgress:
        return 'В роботі';
      case SupportTicketStatus.resolved:
        return 'Вирішено';
      case SupportTicketStatus.closed:
        return 'Закрито';
    }
  }

  void _updateTicketStatus(
    SupportTicketModel ticket,
    SupportTicketStatus newStatus,
    AdminViewModel viewModel,
  ) async {
    final success = await viewModel.updateTicketStatus(ticket.id, newStatus);

    if (success) {
      Constants.showSuccessMessage(context, 'Статус оновлено');
    } else {
      Constants.showErrorMessage(context, 'Помилка оновлення статусу');
    }
  }

  void _showResponseDialog(
    BuildContext context,
    SupportTicketModel ticket,
    AdminViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appThemeColors.primaryWhite,
        title: Text(
          'Відповісти користувачу',
          style: TextStyleHelper.instance.title18Bold,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Тема: ${ticket.subject}',
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.primaryBlack,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _responseController,
              label: 'Ваша відповідь',
              hintText: 'Введіть відповідь...',
              maxLines: 5,
              inputType: TextInputType.text,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Будь ласка, введіть відповідь';
                }
                return null;
              },
              height: 48,
              labelColor: appThemeColors.primaryBlack,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _responseController.clear();
              Navigator.of(context).pop();
            },
            child: Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_responseController.text.trim().isEmpty) {
                return;
              }

              final adminId = FirebaseAuth.instance.currentUser?.uid;
              if (adminId == null) {
                Constants.showErrorMessage(context, 'Помилка авторизації');
                return;
              }

              final success = await viewModel.respondToTicket(
                ticket.id,
                _responseController.text.trim(),
                adminId,
              );

              Navigator.of(context).pop();
              _responseController.clear();

              if (success) {
                Constants.showSuccessMessage(context, 'Відповідь надіслано!');
              } else {
                Constants.showErrorMessage(
                  context,
                  'Помилка надсилання відповіді',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: appThemeColors.successGreen,
            ),
            child: Text(
              'Надіслати',
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.primaryWhite,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
