import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:helphub/data/models/support_ticket_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:timeago/timeago.dart' as timeago;

class UserSupportHistoryScreen extends StatelessWidget {
  const UserSupportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: appThemeColors.blueAccent,
      appBar: AppBar(
        title: Text(
          'Історія звернень',
          style: TextStyleHelper.instance.headline24SemiBold,
        ),
        backgroundColor: appThemeColors.appBarBg,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(
            Icons.arrow_back,
            size: 40,
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [appThemeColors.blueAccent, appThemeColors.cyanAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('supportTickets')
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return Center(
                child: Text(
                  'У вас поки немає звернень',
                  style: TextStyleHelper.instance.title16Regular.copyWith(
                    color: Colors.white,
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final ticket = SupportTicketModel.fromMap(data, docs[index].id);
                return _buildUserTicketCard(ticket);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserTicketCard(SupportTicketModel ticket) {
    Color statusColor;
    String statusText;

    switch (ticket.status) {
      case SupportTicketStatus.open:
        statusColor = Colors.orange;
        statusText = 'Відкрито';
        break;
      case SupportTicketStatus.inProgress:
        statusColor = Colors.blue;
        statusText = 'В роботі';
        break;
      case SupportTicketStatus.resolved:
        statusColor = Colors.green;
        statusText = 'Вирішено';
        break;
      case SupportTicketStatus.closed:
        statusColor = Colors.grey;
        statusText = 'Закрито';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    ticket.subject,
                    style: TextStyleHelper.instance.title16Bold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(49),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ticket.message,
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              timeago.format(ticket.createdAt, locale: 'uk'),
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),

            // --- ОСЬ ТУТ ВІДПОВІДЬ АДМІНА ---
            if (ticket.adminResponse != null &&
                ticket.adminResponse!.isNotEmpty) ...[
              const Divider(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.support_agent, size: 20, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Відповідь підтримки:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(ticket.adminResponse!),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
