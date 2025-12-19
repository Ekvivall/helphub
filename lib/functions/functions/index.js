const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");

admin.initializeApp();

/**
 * Cloud Function to send push notifications to a list of user IDs.
 */
exports.sendPushNotification = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated",
    );
  }

  const {userIds, title, body, type, additionalData} = data;

  if (!userIds || !title || !body || !type) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required fields",
    );
  }

  try {
    await sendNotificationToUsers({
      userIds,
      title,
      body,
      type,
      additionalData,
    });

    return {
      success: true,
      message: "Notifications sent successfully",
    };
  } catch (error) {
    console.error("Error sending notifications:", error);
    throw new functions.https.HttpsError(
        "internal",
        "Error sending notifications",
    );
  }
});


/**
 * Cloud Function to handle new chat messages
 */
exports.onNewChatMessage = onDocumentCreated(
    "chats/{chatId}/messages/{messageId}",
    async (event) => {
      const messageData = event.data.data();
      const chatId = event.params.chatId;

      try {
        const chatDoc = await admin.firestore().collection("chats")
            .doc(chatId).get();
        if (!chatDoc.exists) return;

        const chatData = chatDoc.data();
        const participants = chatData.participants || [];
        const recipientIds = participants.filter(
            (id) => id !== messageData.senderId,
        );

        if (recipientIds.length === 0) return;

        const senderDoc = await admin.firestore().collection("users")
            .doc(messageData.senderId).get();

        let senderName = "Користувач";
        if (senderDoc.exists) {
          const senderData = senderDoc.data();
          senderName = senderData.fullName ||
                      senderData.displayName ||
                      senderData.organizationName || "Користувач";
        }

        let title = "Нове повідомлення від " + senderName;
        const body = `${senderName}: ${messageData.text || "Нове повідомлення"}`;

        if (chatData.type === "event" && chatData.entityId) {
          const eventDoc = await admin.firestore()
              .collection("events")
              .doc(chatData.entityId)
              .get();
          if (eventDoc.exists) {
            const eventData = eventDoc.data();
            title = eventData.name || "Подія";
          }
        } else if (chatData.type === "project" && chatData.entityId) {
          const projectDoc = await admin.firestore()
              .collection("projects")
              .doc(chatData.entityId)
              .get();
          if (projectDoc.exists) {
            const projectData = projectDoc.data();
            title = projectData.title || "Проєкт";
          }
        }

        await sendNotificationToUsers({
          userIds: recipientIds,
          title: title,
          body: body,
          type: "chat",
          additionalData: {
            chatId: chatId,
            chatType: chatData.type || "general",
            senderId: messageData.senderId,
          },
        });
      } catch (error) {
        console.error("Error sending chat notification:", error);
      }
    },
);

/**
 * Applications notifications
 */
exports.onFundraisingApplication = onDocumentCreated(
    "fundraiserApplications/{applicationId}",
    async (event) => {
      const applicationData = event.data.data();
      const applicationId = event.params.applicationId;

      try {
        const fundraisingDoc = await admin.firestore()
            .collection("fundraiserApplications")
            .doc(applicationId)
            .get();

        if (!fundraisingDoc.exists) return;

        const fundraisingData = fundraisingDoc.data();
        const organizerId = fundraisingData.organizationId;
        if (!organizerId) return;

        const applicantDoc = await admin.firestore()
            .collection("users")
            .doc(applicationData.volunteerId)
            .get();

        let applicantName = "Користувач";
        if (applicantDoc.exists) {
          const applicantData = applicantDoc.data();
          applicantName = applicantData.fullName ||
                        applicantData.displayName ||
                        "Користувач";
        }

        await sendNotificationToUsers({
          userIds: [organizerId],
          title: "Нова заявка на збір",
          body: `${applicantName} подав заявку на участь у "${fundraisingData.title || "збору"}"`,
          type: "fundraisingApplication",
          additionalData: {
            applicationId: applicationId,
            applicantId: applicationData.volunteerId,
          },
        });
      } catch (error) {
        console.error("Error sending fundraising application notification:", error);
      }
    },
);

exports.onProjectApplication = onDocumentCreated(
    "projectApplications/{applicationId}",
    async (event) => {
      const applicationData = event.data.data();
      const projectId = applicationData.projectId;

      try {
        const projectDoc = await admin.firestore()
            .collection("projects")
            .doc(projectId)
            .get();

        if (!projectDoc.exists) return;

        const projectData = projectDoc.data();
        const organizerId = projectData.organizerId;
        if (!organizerId) return;

        const applicantDoc = await admin.firestore()
            .collection("users")
            .doc(applicationData.volunteerId)
            .get();

        let applicantName = "Користувач";
        if (applicantDoc.exists) {
          const applicantData = applicantDoc.data();
          applicantName = applicantData.fullName ||
                        applicantData.displayName ||
                        "Користувач";
        }

        await sendNotificationToUsers({
          userIds: [organizerId],
          title: "Нова заявка на проєкт",
          body: `${applicantName} подав заявку на участь у проєкті "${projectData.title || "проєкті"}"`,
          type: "projectApplication",
          additionalData: {
            projectId: projectId,
            applicationId: event.params.applicationId,
            applicantId: applicationData.volunteerId,
          },
        });
      } catch (error) {
        console.error("Error sending project application notification:", error);
      }
    },
);

/**
 * Friend requests notifications
 */
exports.onFriendRequest = onDocumentCreated(
    "friendRequests/{requestId}",
    async (event) => {
      const requestData = event.data.data();
      const recipientId = requestData.receiverId;

      try {
        const senderDoc = await admin.firestore()
            .collection("users")
            .doc(requestData.senderId)
            .get();

        if (!senderDoc.exists) return;

        const senderData = senderDoc.data();
        const senderName = senderData.fullName ||
                          senderData.displayName ||
                          "Користувач";

        await sendNotificationToUsers({
          userIds: [recipientId],
          title: "Новий запит на дружбу",
          body: `${senderName} надіслав вам запит на дружбу`,
          type: "friendRequest",
          additionalData: {
            senderId: requestData.senderId,
            requestId: event.params.requestId,
          },
        });
      } catch (error) {
        console.error("Error sending friend request notification:", error);
      }
    },
);

/**
 * Friend request acceptance
 */
exports.onFriendRequestAccepted = onDocumentUpdated(
    "friendRequests/{requestId}",
    async (event) => {
      const change = event.data;
      if (!change.before.exists || !change.after.exists) return;
      const before = change.before.data();
      const after = change.after.data();

      try {
        // Check if status changed to accepted
        if (before.status === "pending" && after.status === "accepted") {
          const accepterDoc = await admin.firestore()
              .collection("users")
              .doc(after.receiverId)
              .get();

          if (!accepterDoc.exists) return;

          const accepterData = accepterDoc.data();
          const accepterName = accepterData.fullName ||
                              accepterData.displayName ||
                              "Користувач";

          await sendNotificationToUsers({
            userIds: [after.senderId],
            title: "Запит дружби прийнято!",
            body: `${accepterName} прийняв ваш запит дружби`,
            type: "friendRequestEdit",
            additionalData: {
              senderId: after.senderId,
              accepterId: after.receiverId,
              accepterName: accepterName,
              action: "accepted",
            },
          });
        }
      } catch (error) {
        console.error("Error sending friend request acceptance notification:", error);
      }
    },
);


exports.onFundraisingApplicationStatusChange = onDocumentUpdated(
    "fundraiserApplications/{applicationId}",
    async (event) => {
      const change = event.data;
      if (!change.after.exists || !change.before.exists) return;
      const before = change.before.data();
      const after = change.after.data();

      try {
        if (before.status !== after.status) {
          let title = "";
          let body = "";

          if (after.status === "approved") {
            title = "Заявку прийнято!";
            body = `Вашу заявку на участь на створення збору "${after.title}" було прийнято`;
          } else if (after.status === "rejected") {
            title = "Заявку відхилено";
            body = `Вашу заявку на участь на створення збору "${after.title}" було відхилено`;
          } else if (after.status === "active") {
            title = "Створено збір";
            body = `За вашою заявкою "${after.title}" було створено збір`;
          } else if (after.status === "completed") {
            title = "Збір завершено";
            body = `За вашою заявкою "${after.title}" було завершено збір`;
          }

          if (title && body) {
            await sendNotificationToUsers({
              userIds: [after.volunteerId],
              title: title,
              body: body,
              type: "fundraisingApplicationEdit",
              additionalData: {
                status: after.status,
                applicationId: event.params.applicationId,
              },
            });
          }
        }
      } catch (error) {
        console.error("Error sending fundraising application status notification:", error);
      }
    },
);

/**
 * Raffle winner notifications
 */
exports.onRaffleWinner = onDocumentUpdated(
    "fundraisings/{fundraisingId}",
    async (event) => {
      const change = event.data;
      if (!change.before.exists || !change.after.exists) {
        return;
      }
      const newData = change.after.data();
      const oldData = change.before.data();
      const fundraisingId = event.params.fundraisingId;
      const newWinners = newData.raffleWinners || [];
      const oldWinners = oldData.raffleWinners || [];
      if (newWinners.length <= oldWinners.length) {
        return null;
      }
      const oldWinnerIds = oldWinners.map( (winner) => winner.donorId );
      const latestWinners = newWinners.filter( (winner) => !oldWinnerIds.includes(winner.donorId) );
      if (latestWinners.length === 0) {
        return null;
      }
      try {
        for (const winner of latestWinners) {
          if (!winner || !winner.donorId) {
            continue;
          }

          await sendNotificationToUsers({
            userIds: [winner.donorId],
            title: "Вітаємо! Ви виграли!",
            body: `Ви виграли приз в розіграші "${newData.title}"! Приз: ${winner.prize}`,
            type: "raffleWinner",
            additionalData: {
              fundraisingId: fundraisingId,
              winnerId: winner.donorId,
              prize: winner.prize || "",
            },
          });
        }
      } catch (error) {
        console.error("Error sending raffle winner notification:", error);
      }
    },
);

/**
 * Event update notifications
 */
exports.onEventUpdate = onDocumentUpdated(
    "events/{eventId}",
    async (event) => {
      const change = event.data;
      if (!change.before.exists || !change.after.exists) return;
      const before = change.before.data();
      const after = change.after.data();
      const eventId = event.params.eventId;

      try {
        const importantFields = ["name", "date", "locationText", "city", "description", "duration"];
        const hasFieldChanged = (key) => {
          const b = before[key];
          const a = after[key];
          if (b && typeof b.isEqual === "function" && a) {
            return !b.isEqual(a);
          }
          return b !== a;
        };
        const changedFields = importantFields.filter((field) => hasFieldChanged(field));

        if (changedFields.length === 0) return;

        const participants = after.participantIds || [];
        if (participants.length === 0) return;

        let updateMessage = "Інформацію про подію було оновлено";

        if (changedFields.includes("date")) {
          updateMessage = "Дату проведення було змінено";
        } else if (changedFields.includes("locationText") || changedFields.includes("city")) {
          updateMessage = "Місце проведення було змінено";
        } else if (changedFields.includes("name")) {
          updateMessage = "Назву події було змінено";
        } else if (changedFields.includes("duration")) {
          updateMessage = "Тривалість події було змінено";
        }

        await sendNotificationToUsers({
          userIds: participants,
          title: "Оновлення події",
          body: `Подія "${after.name}": ${updateMessage}`,
          type: "eventUpdate",
          additionalData: {
            eventId: eventId,
            updateType: "eventUpdate",
          },
        });
      } catch (error) {
        console.error("Error sending event update notification:", error);
      }
    },
);

/**
 * New fundraising created - notify followers
 */
exports.onNewFundraisingCreated = onDocumentCreated(
    "fundraisings/{fundraisingId}",
    async (event) => {
      const fundraisingData = event.data.data();
      const fundraisingId = event.params.fundraisingId;

      try {
        const organizationId = fundraisingData.organizationId || fundraisingData.organizerId;
        if (!organizationId) return;

        // Get all followers of this organization
        const followersSnapshot = await admin.firestore()
            .collection("follows")
            .where("followedId", "==", organizationId)
            .get();

        if (followersSnapshot.empty) {
          console.log("No followers found for organization:", organizationId);
          return;
        }

        const followerIds = followersSnapshot.docs.map((doc) => {
          const followData = doc.data();
          return followData.followerId;
        });

        // Get organization name
        const organizationDoc = await admin.firestore()
            .collection("users")
            .doc(organizationId)
            .get();

        let organizationName = "Організація";
        if (organizationDoc.exists) {
          const orgData = organizationDoc.data();
          organizationName = orgData.organizationName ||
                            orgData.fullName ||
                            orgData.displayName ||
                            "Організація";
        }

        await sendNotificationToUsers({
          userIds: followerIds,
          title: "Новий збір коштів!",
          body: `${organizationName} створила новий збір коштів: "${fundraisingData.title}"`,
          type: "newFundraising",
          additionalData: {
            fundraisingId: fundraisingId,
            organizationId: organizationId,
            organizationName: organizationName,
          },
        });

        console.log(`Sent new fundraising notification to ${followerIds.length} followers`);
      } catch (error) {
        console.error("Error sending new fundraising notification:", error);
      }
    },
);

/**
 * Fundraising completion notifications
 */
exports.onFundraisingCompleted = onDocumentUpdated(
    "fundraisings/{fundraisingId}",
    async (event) => {
      const change = event.data;
      if (!change.before.exists || !change.after.exists) return;
      const before = change.before.data();
      const after = change.after.data();
      const fundraisingId = event.params.fundraisingId;

      try {
        // Check if fundraising was just completed
        if (before.status !== "completed" && after.status === "completed") {
          await sendNotificationToUsers({
            userIds: after.donorIds,
            title: "Збір коштів завершено!",
            body: `Збір "${after.title}" успішно завершено! Зібрано ${after.currentAmount || 0} грн`,
            type: "fundraisingCompleted",
            additionalData: {
              fundraisingId: fundraisingId,
              finalAmount: (after.currentAmount || 0).toString(),
            },
          });
        }
      } catch (error) {
        console.error("Error sending fundraising completion notification:", error);
      }
    },
);

/**
 * User registration notifications for admins
 */
exports.onUserRegistered = onDocumentCreated(
    "users/{userId}",
    async (event) => {
      const userData = event.data.data();
      const userId = event.params.userId;

      try {
        const userType = userData.role || "користувач";
        if (userType !== "organization") return;

        // Get admin users
        const adminSnapshot = await admin.firestore()
            .collection("users")
            .where("role", "==", "admin")
            .get();

        if (adminSnapshot.empty) return;

        const adminIds = adminSnapshot.docs.map((doc) => doc.id);
        const userName = userData.fullName ||
                        userData.displayName ||
                        userData.organizationName || "Новий користувач";

        await sendNotificationToUsers({
          userIds: adminIds,
          title: "Новий користувач",
          body: `Зареєструвався новий ${userType}: ${userName}`,
          type: "adminNotification",
          additionalData: {
            type: "admin_new_user",
            userType: userType,
            userName: userName,
            userId: userId,
          },
        });
      } catch (error) {
        console.error("Error sending admin registration notification:", error);
      }
    },
);

/**
 * User reports/complaints notifications for admins
 */
exports.onUserReportSubmitted = onDocumentCreated(
    "reports/{reportId}",
    async (event) => {
      const reportData = event.data.data();
      const reportId = event.params.reportId;

      try {
        // Only handle user complaints, not activity reports
        if (reportData.type !== "user_complaint" && !reportData.reportedEntityId) return;

        const adminSnapshot = await admin.firestore()
            .collection("users")
            .where("role", "==", "admin")
            .get();

        if (adminSnapshot.empty) return;

        const adminIds = adminSnapshot.docs.map((doc) => doc.id);
        const reportType = reportData.reportType || "контент";

        await sendNotificationToUsers({
          userIds: adminIds,
          title: "Нова скарга",
          body: `Надійшла скарга на ${reportType}`,
          type: "adminNotification",
          additionalData: {
            type: "admin_report",
            reportType: reportType,
            reportedEntityId: reportData.reportedEntityId || "",
            reporterId: reportData.reporterId || reportData.authorId || "",
            reportId: reportId,
          },
        });
      } catch (error) {
        console.error("Error sending admin report notification:", error);
      }
    },
);

/**
 * Event reminder notifications (scheduled)
 */
exports.sendEventReminders = onSchedule("every day 06:00", async (context) => {
  try {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(0, 0, 0, 0);

    const dayAfter = new Date(tomorrow);
    dayAfter.setDate(dayAfter.getDate() + 1);

    // Get events happening tomorrow
    const eventsSnapshot = await admin.firestore()
        .collection("events")
        .where("date", ">=", admin.firestore.Timestamp.fromDate(tomorrow))
        .where("date", "<", admin.firestore.Timestamp.fromDate(dayAfter))
        .get();

    if (eventsSnapshot.empty) {
      console.log("No events tomorrow to remind about");
      return null;
    }

    for (const eventDoc of eventsSnapshot.docs) {
      const eventData = eventDoc.data();
      const participants = eventData.participantIds || [];

      if (participants.length > 0) {
        const eventTime = eventData.date.toDate();

        await sendNotificationToUsers({
          userIds: participants,
          title: "Нагадування про подію",
          body: `Подія "${eventData.name}" відбудеться завтра`,
          type: "eventReminder",
          additionalData: {
            reminderType: "upcoming",
            eventTime: eventTime.toISOString(),
          },
        });
      }
    }

    return null;
  } catch (error) {
    console.error("Error sending event reminders:", error);
    return null;
  }
});

/**
 * Project deadline reminder notifications (scheduled)
 */
exports.sendProjectDeadlineReminders = onSchedule("every day 06:00", async (context) => {
  try {
    const now = new Date();
    const threeDaysFromNow = new Date();
    threeDaysFromNow.setDate(now.getDate() + 3);
    threeDaysFromNow.setHours(23, 59, 59, 999);

    const projectsSnapshot = await admin.firestore()
        .collection("projects")
        .get();

    if (projectsSnapshot.empty) {
      return null;
    }

    const notificationPromises = [];

    for (const projectDoc of projectsSnapshot.docs) {
      const projectData = projectDoc.data();
      const tasks = projectData.tasks || [];

      for (const task of tasks) {
        if (task.deadline && task.assignedVolunteerIds && task.assignedVolunteerIds.length > 0 && task.status !== "completed" && task.status !== "confirmed") {
          const deadline = task.deadline.toDate();

          if (deadline >= now && deadline <= threeDaysFromNow) {
            const deadlineString = formatDate(deadline);

            const promise = sendNotificationToUsers({
              userIds: task.assignedVolunteerIds,
              title: "Нагадування про дедлайн завдання!",
              body: `Завдання "${task.title}" у проєкті "${projectData.title}" має бути завершене до ${deadlineString}`,
              type: "projectDeadline",
              additionalData: {
                projectId: projectDoc.id,
                taskId: task.id,
                deadline: deadline.toISOString(),
              },
            });
            notificationPromises.push(promise);
          }
        }
      }
    }

    await Promise.all(notificationPromises);

    return null;
  } catch (error) {
    console.error("Error sending task deadline reminders:", error);
    return null;
  }
});

/**
 * Тригер при створенні тікета підтримки.
 * Сповіщає всіх адміністраторів про нове звернення.
 */
exports.onSupportTicketCreated = onDocumentCreated(
    "supportTickets/{ticketId}",
    async (event) => {
      const ticketData = event.data.data();
      const ticketId = event.params.ticketId;
      try {
        const adminsSnapshot = await admin.firestore()
            .collection("users")
            .where("role", "==", "admin")
            .get();

        if (adminsSnapshot.empty) {
          console.log("No admins found to notify.");
          return null;
        }
        const adminIds = adminsSnapshot.docs.map((doc) => doc.id);
        await sendNotificationToUsers({
          userIds: adminIds,
          title: "Новий запит у підтримку",
          body: `Користувач ${ticketData.userName} створив звернення: "${ticketData.subject}"`,
          type: "adminNotification",
          additionalData: {
            ticketId: ticketId,
            userId: ticketData.userId,
          },
        });
      } catch (error) {
        console.error("Error sending support notification to admins:", error);
      }
      return null;
    },
);

/**
 * Тригер при оновленні тікета підтримки.
 * Сповіщає користувача про відповідь адміна або зміну статусу.
 */
exports.onSupportTicketUpdated = onDocumentUpdated(
    "supportTickets/{ticketId}",
    async (event) => {
      const change = event.data;
      const before = change.before.data();
      const after = change.after.data();
      const ticketId = event.params.ticketId;
      const userId = after.userId;
      if (before.status === after.status && before.adminResponse === after.adminResponse) {
        return null;
      }
      try {
        let title = "Оновлення заявки в підтримку";
        let body = "";
        if (!before.adminResponse && after.adminResponse) {
          title = "Нова відповідь від підтримки";
          body = `Адміністратор відповів на ваше звернення: "${after.subject}"`;
        } else if (before.status !== after.status) {
          let statusText = "";
          switch (after.status) {
            case "inProgress": statusText = "взято в роботу"; break;
            case "resolved": statusText = "вирішено"; break;
            case "closed": statusText = "закрито"; break;
            default: statusText = "оновлено";
          }
          body = `Статус вашого звернення "${after.subject}" змінено на "${statusText}".`;
        }
        if (body) {
          await sendNotificationToUsers({
            userIds: [userId],
            title: title,
            body: body,
            type: "supportReply",
            additionalData: {
              ticketId: ticketId,
              status: after.status,
            },
          });
        }
      } catch (error) {
        console.error("Error sending support update notification:", error);
      }
      return null;
    },
);

/**
 * Helper function to format date time in Ukrainian
 * @param {Date} dateTime The date and time object to format.
 * @return {string} The formatted date string.
 */
function formatDate(dateTime) {
  const months = [
    "січня", "лютого", "березня", "квітня", "травня", "червня",
    "липня", "серпня", "вересня", "жовтня", "листопада", "грудня",
  ];

  const day = dateTime.getDate();
  const month = months[dateTime.getMonth()];

  return `${day} ${month}`;
}

/**
 * Helper function to send FCM messages
 */
async function sendNotificationToUsers({
  userIds,
  title,
  body,
  type,
  additionalData = {},
}) {
  try {
    const userDocsPromises = userIds.map(
        (userId) => admin.firestore().collection("users").doc(userId).get(),
    );

    const userDocs = await Promise.all(userDocsPromises);
    const validUsers = [];

    // Collect tokens and save notifications to Firestore
    const batch = admin.firestore().batch();

    userDocs.forEach((doc) => {
      if (doc.exists) {
        const userData = doc.data();
        const settings = userData.notificationSettings || {};
        const typeEnabled = settings[type] !== false;

        if (typeEnabled) {
          // Add to FCM list if has token
          if (userData.fcmToken) {
            validUsers.push({
              id: doc.id,
              token: userData.fcmToken,
            });
          }

          // Save notification to user's collection
          if (type !== "chat" && type !== "fundraisingDonation") {
            const notificationId = Date.now().toString() + "_" + doc.id;
            const notificationRef = admin.firestore()
                .collection("users")
                .doc(doc.id)
                .collection("notifications")
                .doc(notificationId);

            batch.set(notificationRef, {
              id: notificationId,
              title: title,
              body: body,
              type: type,
              data: additionalData,
              isRead: false,
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
            });
          }
        }
      }
    });

    // Commit notifications to Firestore
    await batch.commit();

    if (validUsers.length === 0) {
      console.log("No valid users for FCM");
      return;
    }

    // Send FCM messages
    const messages = validUsers.map((user) => ({
      token: user.token,
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: type,
        ...Object.fromEntries(
            Object.entries(additionalData).map(([k, v]) => [k, String(v)]),
        ),
      },
      android: {
        priority: "high",
        notification: {
          channelId: "helphub_channel",
          priority: "high",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            sound: "default",
            badge: 1,
          },
        },
      },
    }));

    const results = await Promise.allSettled(
        messages.map((message) => admin.messaging().send(message)),
    );

    let successCount = 0;
    let errorCount = 0;

    results.forEach((result, index) => {
      if (result.status === "fulfilled") {
        successCount++;
      } else {
        errorCount++;
        console.error(`Error sending to user ${validUsers[index].id}:`, result.reason);
      }
    });

    console.log(
        `Notifications sent: ${successCount} success, ${errorCount} errors`,
    );
  } catch (error) {
    console.error("Error in sendNotificationToUsers:", error);
  }
}


/**
   * Щоденна перевірка завершених подій
   */
exports.checkCompletedEventsDaily = onSchedule("every day 06:00", async (context) => {
  try {
    // const now = admin.firestore.Timestamp.now();
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    yesterday.setHours(0, 0, 0, 0);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const completedEvents = await admin.firestore()
        .collection("events")
        .where("date", ">=", admin.firestore.Timestamp.fromDate(yesterday))
        .where("date", "<", admin.firestore.Timestamp.fromDate(today))
        .get();
      // Для кожної завершеної події
    for (const eventDoc of completedEvents.docs) {
      const event = eventDoc.data();
      const participantIds = event.participantIds || [];
      // Для кожного учасника
      for (const userId of participantIds) {
        await processCompletedEventForUser(userId, eventDoc.id);
      }
    }
    return null;
  } catch (error) {
    console.error("Error in daily check:", error);
    throw error;
  }
});

/**
   * Обробляє завершену подію для користувача, оновлює лічильник та перевіряє досягнення.
   * @param {string} userId - ID користувача, для якого обробляється подія.
   * @param {string} eventId - ID завершеної події.
   */
async function processCompletedEventForUser(userId, eventId) {
  try {
    const userRef = admin.firestore().collection("users").doc(userId);
    const processedEventRef = userRef
        .collection("processedEvents")
        .doc(eventId);
    const processedEventDoc = await processedEventRef.get();
    if (processedEventDoc.exists) {
      return;
    }
    await processedEventRef.set({
      eventId: eventId,
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Нарахування балів за участь у події
    await updateUserPoints(userId, 10, "Участь у події");
    const processedEventsSnapshot = await userRef
        .collection("processedEvents")
        .get();
    const completedEventsCount = processedEventsSnapshot.size;
    await checkEventAchievementsForUser(userId, completedEventsCount);
  } catch (error) {
    console.error(`Error processing event ${eventId} for user ${userId}:`, error);
  }
}

/**
   * Перевіряє та розблоковує досягнення, пов'язані з кількістю відвіданих подій.
   * @param {string} userId - ID користувача.
   * @param {number} completedEventsCount - Загальна кількість подій, які відвідав користувач.
   */
async function checkEventAchievementsForUser(userId, completedEventsCount) {
  try {
    const achievements = [
      {id: "newcomer", threshold: 1, title: "Новачок"},
      {id: "activist", threshold: 5, title: "Активіст"},
      {id: "event_veteran", threshold: 20, title: "Ветеран подій"},
    ];
    for (const achievement of achievements) {
      if (completedEventsCount >= achievement.threshold) {
        await unlockAchievement(userId, achievement.id, achievement.title);
      }
    }
    // Перевірка марафонця
    await checkMarathonerAchievement(userId);
    // Перевірка секретного досягнення
    await checkSecretAchievement(userId);
  } catch (error) {
    console.error(`Error checking event achievements for user ${userId}:`, error);
  }
}
/**
   * Перевіряє, чи відвідував користувач події щотижня протягом останнього місяця.
   * @param {string} userId - ID користувача.
   */
async function checkMarathonerAchievement(userId) {
  try {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const processedEvents = await admin.firestore()
        .collection("users")
        .doc(userId)
        .collection("processedEvents")
        .where("processedAt", ">=", admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
        .get();
    const eventsByWeek = {};
    processedEvents.forEach((doc) => {
      const processedAt = doc.data().processedAt.toDate();
      const weekNumber = getWeekNumber(processedAt);
      eventsByWeek[weekNumber] = (eventsByWeek[weekNumber] || 0) + 1;
    });

    // Якщо є події в 4 різних тижнях
    if (Object.keys(eventsByWeek).length >= 4) {
      await unlockAchievement(userId, "marathoner", "Марафонець");
    }
  } catch (error) {
    console.error("Error checking marathoner achievement:", error);
  }
}
/**
   * Розраховує номер тижня в році для заданої дати.
   * @param {Date} date - Об'єкт Date.
   * @return {number} Номер тижня в році.
   */
function getWeekNumber(date) {
  const firstDayOfYear = new Date(date.getFullYear(), 0, 1);
  const daysSinceFirstDay = Math.floor((date - firstDayOfYear) / (24 * 60 * 60 * 1000));
  return Math.floor(daysSinceFirstDay / 7);
}

/**
   * Додає нове досягнення для користувача, якщо воно ще не розблоковане.
   * @param {string} userId - ID користувача.
   * @param {string} achievementId - ID досягнення.
   * @param {string} achievementTitle - Назва досягнення.
   */
async function unlockAchievement(userId, achievementId, achievementTitle) {
  try {
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    if (!userDoc.exists) {
      return;
    }
    const userData = userDoc.data();
    if (userData.role !== "volunteer") {
      return;
    }
    const achievementRef = admin.firestore()
        .collection("users")
        .doc(userId)
        .collection("achievements")
        .doc(achievementId);
    const achievementDoc = await achievementRef.get();
    if (!achievementDoc.exists) {
      await achievementRef.set({
        achievementId: achievementId,
        unlockedAt: admin.firestore.FieldValue.serverTimestamp(),
        dialogShown: false,
      });
      const achievementsSnapshot = await admin.firestore()
          .collection("users")
          .doc(userId)
          .collection("achievements")
          .get();
      await admin.firestore().collection("users").doc(userId).update({
        achievementsCount: achievementsSnapshot.size,
      });
      await sendAchievementNotification(userId, achievementId, achievementTitle);
    }
  } catch (error) {
    console.error(`Error unlocking achievement ${achievementId}:`, error);
  }
}

/**
   * Перевіряє, чи користувач зібрав достатньо досягнень для розблокування секретного.
   * @param {string} userId - ID користувача.
   */
async function checkSecretAchievement(userId) {
  try {
    const userAchievements = await admin.firestore()
        .collection("users")
        .doc(userId)
        .collection("achievements")
        .get();
      // Якщо є всі досягнення крім секретного (10 з 11)
    if (userAchievements.size >= 10) {
      const hasSecret = userAchievements.docs.some(
          (doc) => doc.id === "secret_master",
      );
      if (!hasSecret) {
        await unlockAchievement(userId, "secret_master", "Майстер досягнень");
      }
    }
  } catch (error) {
    console.error("Error checking secret achievement:", error);
  }
}

/**
 * Надсилає push-сповіщення користувачу про розблокування нового досягнення.
 * @param {string} userId - ID користувача, який отримує сповіщення.
 * @param {string} achievementId - ID розблокованого досягнення.
 * @param {string} achievementTitle - Назва розблокованого досягнення.
 */
async function sendAchievementNotification(userId, achievementId, achievementTitle) {
  try {
    const achievementDescriptions = {
      "newcomer": "Візьми участь у першій події",
      "activist": "Візьми участь у 5 подіях",
      "event_veteran": "Візьми участь у 20 подіях",
      "team_player": "Приєднайся до 3 різних проєктів",
      "project_leader": "Заверши проєкт як організатор",
      "donator": "Зроби перший донат у збір",
      "philanthropist": "Задонать понад 1000 грн",
      "community_fan": "Додай 5 друзів",
      "marathoner": "Бери участь у подіях щотижня протягом місяця",
      "photographer": "Додай фото до звіту",
      "secret_master": "Отримай всі інші досягнення",
    };

    const description = achievementDescriptions[achievementId] || "Вітаємо!";

    await sendNotificationToUsers({
      userIds: [userId],
      title: "Нове досягнення розблоковано!",
      body: `${achievementTitle}: ${description}`,
      type: "achievement",
      additionalData: {
        achievementId: achievementId,
        achievementTitle: achievementTitle,
      },
    });
  } catch (error) {
    console.error("Error sending achievement notification:", error);
  }
}

/**
 * Тригер, що спрацьовує при будь-якій зміні статусу заявки на проєкт.
 * Надсилає сповіщення та перевіряє досягнення.
 */
exports.onProjectApplicationUpdate = onDocumentUpdated(
    "projectApplications/{applicationId}",
    async (event) => {
      const change = event.data;
      if (!change.before.exists || !change.after.exists) {
        return null;
      }
      const before = change.before.data();
      const after = change.after.data();
      const volunteerId = after.volunteerId;
      const projectId = after.projectId;
      if (before.status === after.status) {
        return null;
      }
      try {
        if (after.status === "approved") {
          // Нарахування балів за схвалену заявку
          await updateUserPoints(volunteerId, 3, "Схвалена заявка на проєкт");
          const projectDoc = await admin.firestore().collection("projects").doc(projectId).get();
          if (projectDoc.exists) {
            const projectData = projectDoc.data();
            await sendNotificationToUsers({
              userIds: [volunteerId],
              title: "Заявку прийнято!",
              body: `Вашу заявку на участь в проєкті "${projectData.title || "без назви"}" було прийнято`,
              type: "projectApplication",
              additionalData: {
                projectId: projectId,
                status: after.status,
                applicationId: event.params.applicationId,
              },
            });
          }
          const approvedApplications = await admin.firestore()
              .collection("projectApplications")
              .where("volunteerId", "==", volunteerId)
              .where("status", "==", "approved")
              .get();
          const uniqueProjects = new Set(approvedApplications.docs.map((doc) => doc.data().projectId));
          const projectsCount = uniqueProjects.size;
          if (projectsCount >= 3) {
            await unlockAchievement(volunteerId, "team_player", "Командний гравець");
          }
          await checkSecretAchievement(volunteerId);
        } else if (after.status === "rejected") {
          console.log(`Application ${event.params.applicationId} was rejected.`);
          const projectDoc = await admin.firestore().collection("projects").doc(projectId).get();
          if (projectDoc.exists) {
            const projectData = projectDoc.data();
            await sendNotificationToUsers({
              userIds: [volunteerId],
              title: "Заявку відхилено",
              body: `Вашу заявку на участь в проєкті "${projectData.title || "без назви"}" було відхилено`,
              type: "projectApplicationEdit",
              additionalData: {
                projectId: projectId,
                status: after.status,
                applicationId: event.params.applicationId,
              },
            });
          }
        }
        return null;
      } catch (error) {
        console.error(`Error processing application update for ${event.params.applicationId}:`, error);
        return null;
      }
    },
);

/**
 * Тригер, що спрацьовує при оновленні документа проєкту.
 * 1. Перевіряє завершення всього проєкту для розблокування досягнень організатора.
 * 2. Перевіряє зміну статусів завдань для надсилання сповіщень.
 */
exports.onProjectUpdate = onDocumentUpdated(
    "projects/{projectId}",
    async (event) => {
      const change = event.data;
      if (!change.before.exists || !change.after.exists) return null;
      const before = change.before.data();
      const after = change.after.data();
      const projectId = event.params.projectId;
      const wasFinishedBefore = isProjectFinished(before);
      const isFinishedAfter = isProjectFinished(after);
      if (!wasFinishedBefore && isFinishedAfter) {
        const organizerId = after.organizerId;
        try {
          await unlockAchievement(organizerId, "project_leader", "Лідер проєктів");
          await checkSecretAchievement(organizerId);
        } catch (error) {
          console.error(`Error checking achievements for project ${projectId}:`, error);
        }
      }
      const oldTasks = before.tasks || [];
      const newTasks = after.tasks || [];
      const oldTasksMap = new Map(oldTasks.map((task) => [task.id, task]));
      for (const newTask of newTasks) {
        const oldTask = oldTasksMap.get(newTask.id);
        if (!oldTask || oldTask.status === newTask.status) {
          continue;
        }
        try {
          // Завдання виконано волонтером і очікує підтвердження
          if (newTask.status === "completed") {
            await sendNotificationToUsers({
              userIds: [after.organizerId], // Сповіщення тільки організатору
              title: "Завдання очікує підтвердження",
              body: `Завдання "${newTask.title}" у проєкті "${after.title}" виконано і потребує вашої перевірки.`,
              type: "taskCompleted",
              additionalData: {projectId: projectId, taskId: newTask.id},
            });
          } else if (newTask.status === "confirmed") { // Завдання підтверджено організатором
            const participants = new Set(newTask.assignedVolunteerIds || []);
            for (const volunteerId of participants) {
              await updateUserPoints(volunteerId, 10, "Виконання завдання у проєкті");
            }
            await sendNotificationToUsers({
              userIds: Array.from(participants),
              title: "Завдання підтверджено!",
              body: `Завдання "${newTask.title}" у проєкті "${after.title}" було успішно підтверджено.`,
              type: "taskConfirmed",
              additionalData: {projectId: projectId, taskId: newTask.id},
            });
          }
        } catch (error) {
          console.error(`Error sending notification for task ${newTask.id}:`, error);
        }
      }
      return null;
    },
);

/**
 * Допоміжна функція для визначення, чи проєкт завершено
 * @param {object} projectData - Дані документа проєкту.
 * @return {boolean} True, якщо проєкт вважається завершеним, false в іншому випадку.
 */
function isProjectFinished(projectData) {
  if (!projectData) return false;
  if (projectData.endDate) {
    const endDate = projectData.endDate.toDate ? projectData.endDate.toDate() : new Date(projectData.endDate);
    if (endDate < new Date()) {
      return true;
    }
  }
  const tasks = projectData.tasks || [];
  if (tasks.length > 0) {
    const allTasksConfirmed = tasks.every((task) => task.status === "confirmed");
    if (allTasksConfirmed) {
      return true;
    }
  }
  return false;
}

/**
 * Тригер, що спрацьовує при створенні нового донату.
 * 1. Надсилає сповіщення організатору збору.
 * 2. Перевіряє та розблоковує досягнення для донатора.
 */
exports.onNewDonation = onDocumentCreated(
    "donations/{donationId}",
    async (event) => {
      const donationData = event.data.data();
      const donationId = event.params.donationId;
      const fundraisingId = donationData.fundraisingId;
      const donorId = donationData.donorId;
      const amount = donationData.amount || 0;
      if (donorId) {
        // 1 бал за кожні 100 грн
        const points = Math.floor(amount / 100);
        if (points > 0) {
          await updateUserPoints(donorId, points, `Донат ${amount} грн`);
        }
      }
      // Надсилання сповіщення організатору
      try {
        if (fundraisingId) {
          const fundraisingDoc = await admin.firestore()
              .collection("fundraisings")
              .doc(fundraisingId)
              .get();
          if (fundraisingDoc.exists) {
            const fundraisingData = fundraisingDoc.data();
            const organizerId = fundraisingData.organizationId;
            if (organizerId) {
              const donorName = donationData.donorName;
              const bodyText = `${donorName} зробив донат на суму ${amount} грн для "${fundraisingData.title || "Збору"}"`;
              await sendNotificationToUsers({
                userIds: [organizerId],
                title: "Новий донат!",
                body: bodyText,
                type: "fundraisingDonation",
                additionalData: {
                  fundraisingId: fundraisingId,
                  donationId: donationId,
                  donorId: donorId || "",
                  amount: amount.toString(),
                },
              });
            } else {
              console.warn(`Fundraising ${fundraisingId} has no organizerId.`);
            }
          } else {
            console.warn(`Fundraising document ${fundraisingId} not found.`);
          }
        } else {
          console.warn(`Donation ${donationId} has no fundraisingId.`);
        }
      } catch (error) {
        console.error(`Error sending donation notification for ${donationId}:`, error);
      }
      // Перевірка досягнень донатора
      if (donorId) {
        try {
          const donationsSnapshot = await admin.firestore()
              .collection("donations")
              .where("donorId", "==", donorId)
              .get();
          let totalDonated = 0;
          let donationsCount = 0;
          donationsSnapshot.forEach((doc) => {
            const data = doc.data();
            totalDonated += data.amount || 0;
            donationsCount++;
          });
          // Перший донат
          if (donationsCount >= 1) {
            await unlockAchievement(donorId, "donator", "Донатор");
          }
          // Більше 1000 грн
          if (totalDonated >= 1000) {
            await unlockAchievement(donorId, "philanthropist", "Благодійник");
          }
          await checkSecretAchievement(donorId);
        } catch (error) {
          console.error(`Error checking donation achievements for donor ${donorId}:`, error);
        }
      } else {
        console.log(`Donation ${donationId} is anonymous or has no donorId, skipping achievement check.`);
      }
      return null;
    },
);

/**
 * Тригер при додаванні друга - перевірка досягнень
 */
exports.onFriendAdded = onDocumentCreated(
    "users/{userId}/friends/{friendId}",
    async (event) => {
      const userId = event.params.userId;
      // Нарахування балів за додавання друга
      await updateUserPoints(userId, 2, "Додавання друга");
      try {
        const friendsSnapshot = await admin.firestore()
            .collection("users")
            .doc(userId)
            .collection("friends")
            .get();
        const friendsCount = friendsSnapshot.size;
        if (friendsCount >= 5) {
          await unlockAchievement(userId, "community_fan", "Фанат спільноти");
        }
        await checkSecretAchievement(userId);
        return null;
      } catch (error) {
        console.error("Error checking friend achievements:", error);
        return null;
      }
    },
);

/**
 * Тригер, що спрацьовує при створенні нового звіту.
 * 1. Надсилає сповіщення всім учасникам/донаторам.
 * 2. Перевіряє досягнення "Фотограф" для автора звіту.
 */
exports.onNewReportCreated = onDocumentCreated(
    "reports/{reportId}",
    async (event) => {
      const reportData = event.data.data();
      const reportId = event.params.reportId;
      const organizerId = reportData.organizerId;
      if (organizerId) {
        // Нарахування балів за публікацію звіту
        await updateUserPoints(organizerId, 10, "Публікація звіту");
        // Додаткові бали за фото у звіті
        const photoUrls = reportData.photoUrls || [];
        if (photoUrls.length > 0) {
          await updateUserPoints(organizerId, 5, "Звіт з фотографіями");
        }
      }
      // Логіка сповіщень
      try {
        let recipientIds = [];
        const entityId = reportData.entityId;
        const activityType = reportData.activityType;
        if (activityType === "project" && entityId) {
          const projectDoc = await admin.firestore().collection("projects").doc(entityId).get();
          if (projectDoc.exists) {
            const projectData = projectDoc.data();
            const tasks = projectData.tasks || [];
            const uniqueParticipants = new Set();
            tasks.forEach((task) => {
              if (task.assignedVolunteerIds && Array.isArray(task.assignedVolunteerIds)) {
                task.assignedVolunteerIds.forEach((volunteerId) => {
                  uniqueParticipants.add(volunteerId);
                });
              }
            });
            recipientIds = Array.from(uniqueParticipants);
          }
        } else if (activityType === "fundraising" && entityId) {
          const fundraisingDoc = await admin.firestore().collection("fundraisings").doc(entityId).get();
          if (fundraisingDoc.exists) {
            recipientIds = fundraisingDoc.data().donorIds || [];
          }
        } else if (activityType === "event" && entityId) {
          const eventDoc = await admin.firestore().collection("events").doc(entityId).get();
          if (eventDoc.exists) {
            recipientIds = eventDoc.data().participantIds || [];
          }
        }
        const authorId = reportData.organizerId;
        if (recipientIds.length > 0 && authorId) {
          const authorDoc = await admin.firestore().collection("users").doc(authorId).get();
          let authorName = "Користувач";
          if (authorDoc.exists) {
            const authorData = authorDoc.data();
            authorName = authorData.fullName || authorData.displayName || "Користувач";
          }
          await sendNotificationToUsers({
            userIds: recipientIds,
            title: "Новий звіт",
            body: `${authorName} опублікував(ла) новий звіт`,
            type: "reportCreated",
            additionalData: {
              reportId: reportId,
              entityType: activityType || "",
              entityId: entityId || "",
              authorId: authorId,
            },
          });
        }
      } catch (error) {
        console.error("Error sending report notification:", error);
      }
      // Логіка досягнень
      try {
        const userId = reportData.organizerId;
        if (!userId) {
          console.log("No user ID found, skipping achievement check.");
          return null;
        }
        const photoUrls = reportData.photoUrls || [];
        if (photoUrls.length > 0) {
          await unlockAchievement(userId, "photographer", "Фотограф");
          await checkSecretAchievement(userId);
        }
      } catch (error) {
        console.error("Error checking photographer achievement:", error);
      }
      return null;
    },
);

/**
 * Універсальна функція для нарахування балів користувачу
 * @param {string} userId - ID користувача
 * @param {number} points - Кількість балів для нарахування
 * @param {string} reason - Причина нарахування балів
 */
async function updateUserPoints(userId, points, reason) {
  try {
    const userRef = admin.firestore().collection("users").doc(userId);
    const userDoc = await userRef.get();
    if (!userDoc.exists) {
      return;
    }
    const userData = userDoc.data();
    if (userData.role !== "volunteer") {
      return;
    }
    const currentPoints = userData.points || 0;
    const currentSeasonPoints = userData.seasonPoints || 0;
    const currentLevel = userData.currentLevel || 1;
    const newPoints = currentPoints + points;
    const newSeasonPoints = currentSeasonPoints + points;
    const newLevel = calculateLevel(newPoints);
    const levelChanged = newLevel > currentLevel;
    const updateData = {
      points: newPoints,
      seasonPoints: newSeasonPoints,
      currentLevel: newLevel,
    };
    // Якщо рівень підвищився
    if (levelChanged) {
      const levelInfo = getLevelInfo(newLevel);
      updateData.frame = levelInfo.framePath;
      await userRef.update(updateData);
      await sendLevelUpNotification(userId, levelInfo);
    } else {
      await userRef.update(updateData);
    }
    await logPointsTransaction(userId, points, reason, newPoints);
  } catch (error) {
    console.error(`Error updating points for user ${userId}:`, error);
  }
}

/**
 * Розраховує рівень на основі балів
 * @param {number} points - Кількість балів
 * @return {number} Номер рівня (1-8)
 */
function calculateLevel(points) {
  const levels = [
    {level: 1, min: 0, max: 9},
    {level: 2, min: 10, max: 29},
    {level: 3, min: 30, max: 59},
    {level: 4, min: 60, max: 99},
    {level: 5, min: 100, max: 159},
    {level: 6, min: 160, max: 239},
    {level: 7, min: 240, max: 319},
    {level: 8, min: 320, max: 999999},
  ];
  for (const levelData of levels.reverse()) {
    if (points >= levelData.min) {
      return levelData.level;
    }
  }
  return 1;
}

/**
 * Отримує інформацію про рівень
 * @param {number} level - Номер рівня
 * @return {object} Інформація про рівень
 */
function getLevelInfo(level) {
  const levelInfos = {
    1: {
      title: "Лама-новачок",
      description: "Тільки почала, але вже з ентузіазмом!",
      framePath: "assets/images/frames/frame_level_1.png",
      avatarPath: "assets/images/avatars/avatar_level_1.gif",
    },
    2: {
      title: "Старанна лама",
      description: "Приходить на кожну подію і завжди готова допомогти.",
      framePath: "assets/images/frames/frame_level_2.png",
      avatarPath: "assets/images/avatars/avatar_level_2.gif",
    },
    3: {
      title: "Лама-організатор",
      description: "Планує краще, ніж Google Calendar.",
      framePath: "assets/images/frames/frame_level_3.png",
      avatarPath: "assets/images/avatars/avatar_level_3.gif",
    },
    4: {
      title: "Лама-двигун",
      description: "Енергії вистачить на всю Україну.",
      framePath: "assets/images/frames/frame_level_4.gif",
      avatarPath: "assets/images/avatars/avatar_level_4.gif",
    },
    5: {
      title: "Лама-натхнення",
      description: "Може зібрати людей навіть на суботник у понеділок о 6 ранку.",
      framePath: "assets/images/frames/frame_level_5.gif",
      avatarPath: "assets/images/avatars/avatar_level_5.gif",
    },
    6: {
      title: "Лама-приклад",
      description: "Її цитують організатори інших подій.",
      framePath: "assets/images/frames/frame_level_6.gif",
      avatarPath: "assets/images/avatars/avatar_level_6.gif",
    },
    7: {
      title: "Лама-світло",
      description: "Може організувати концерт навіть під час відключення світла.",
      framePath: "assets/images/frames/frame_level_7.gif",
      avatarPath: "assets/images/avatars/avatar_level_7.gif",
    },
    8: {
      title: "Лама-легенда",
      description: "Її портрет повинен висіти в кожному волонтерському центрі.",
      framePath: "assets/images/frames/frame_level_8.gif",
      avatarPath: "assets/images/avatars/avatar_level_8.gif",
    },
  };
  return levelInfos[level] || levelInfos[1];
}

/**
 * Надсилає сповіщення про підвищення рівня
 * @param {string} userId - ID користувача
 * @param {object} levelInfo - Інформація про новий рівень
 */
async function sendLevelUpNotification(userId, levelInfo) {
  try {
    await sendNotificationToUsers({
      userIds: [userId],
      title: "Вітаємо! Новий рівень!",
      body: `Тепер ти ${levelInfo.title}!`,
      type: "levelUp",
      additionalData: {
        levelTitle: levelInfo.title,
        levelDescription: levelInfo.description,
      },
    });
  } catch (error) {
    console.error("Error sending level up notification:", error);
  }
}

/**
 * Логує транзакцію балів
 * @param {string} userId - ID користувача
 * @param {number} points - Кількість балів
 * @param {string} reason - Причина
 * @param {number} totalPoints - Загальна кількість балів після операції
 */
async function logPointsTransaction(userId, points, reason, totalPoints) {
  try {
    await admin.firestore()
        .collection("users")
        .doc(userId)
        .collection("pointsHistory")
        .add({
          points: points,
          reason: reason,
          totalPoints: totalPoints,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
  } catch (error) {
    console.error("Error logging points transaction:", error);
  }
}

exports.onProjectCreatedWithPoints = onDocumentCreated(
    "projects/{projectId}",
    async (event) => {
      const projectData = event.data.data();
      const organizerId = projectData.organizerId;
      if (organizerId) {
        // Нарахування балів за створення проєкту
        await updateUserPoints(organizerId, 25, "Створення проєкту");
      }
    },
);

exports.onEventCreatedWithPoints = onDocumentCreated(
    "events/{eventId}",
    async (event) => {
      const eventData = event.data.data();
      const organizerId = eventData.organizerId;
      if (organizerId) {
        // Нарахування балів за створення події
        await updateUserPoints(organizerId, 20, "Організація події");
      }
    },
);

exports.onOrganizerFeedbackWithPoints = onDocumentUpdated(
    "reports/{reportId}",
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();
      const oldFeedbacks = before.organizerFeedback || [];
      const newFeedbacks = after.organizerFeedback || [];
      if (newFeedbacks.length > oldFeedbacks.length) {
        const newFeedback = newFeedbacks[newFeedbacks.length - 1];
        const participantId = newFeedback.participantId;
        if (participantId) {
          // Нарахування балів за написання відгуку
          await updateUserPoints(participantId, 5, "Відгук організатору");
        }
      }
    },
);

exports.onAchievementUnlockedWithPoints = onDocumentCreated(
    "users/{userId}/achievements/{achievementId}",
    async (event) => {
      const userId = event.params.userId;
      const achievementId = event.params.achievementId;
      // Нарахування балів за досягнення
      const achievementPoints = getAchievementPoints(achievementId);
      await updateUserPoints(userId, achievementPoints, `Досягнення: ${achievementId}`);
    },
);

/**
 * Повертає кількість балів за конкретне досягнення
 * @param {string} achievementId - ID досягнення
 * @return {number} Кількість балів
 */
function getAchievementPoints(achievementId) {
  const pointsMap = {
    "newcomer": 5,
    "activist": 10,
    "event_veteran": 15,
    "team_player": 10,
    "project_leader": 15,
    "donator": 5,
    "philanthropist": 20,
    "community_fan": 10,
    "marathoner": 15,
    "photographer": 5,
    "secret_master": 20,
  };
  return pointsMap[achievementId] || 5;
}


/**
 * Створює турнірні групи на початку нового сезону
 * Запускається автоматично 1 числа кожного місяця о 00:00
 */
exports.createTournamentGroups = onSchedule({
  schedule: "0 4 1 * *",
  timeZone: "Europe/Kyiv",
}, async (context) => {
  try {
    const now = new Date();
    const seasonId = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
    const volunteersSnapshot = await admin.firestore()
        .collection("users")
        .where("role", "==", "volunteer")
        .get();
    if (volunteersSnapshot.empty) {
      return null;
    }
    const volunteers = volunteersSnapshot.docs.map((doc) => ({
      uid: doc.id,
      seasonPoints: 0,
    }));
    shuffleArray(volunteers);
    const groupSize = 4; // для тесту
    // буде const groupSize = 100;
    const minGroupSize = Math.floor(groupSize / 2);
    const groups = [];
    for (let i = 0; i < volunteers.length; i += groupSize) {
      groups.push(volunteers.slice(i, i + groupSize));
    }
    if (groups.length > 1) {
      const lastGroupIndex = groups.length - 1;
      const lastGroup = groups[lastGroupIndex];
      // Якщо в останній групі менше людей, ніж мінімальний поріг
      if (lastGroup.length <= minGroupSize) {
        groups.pop();
        groups[groups.length - 1].push(...lastGroup);
      }
    }
    for (let i = 0; i < groups.length; i++) {
      const batch = admin.firestore().batch();
      const groupId = `group_${i + 1}`;
      const groupRef = admin.firestore()
          .collection("tournamentSeasons")
          .doc(seasonId)
          .collection("groups")
          .doc(groupId);
      batch.set(groupRef, {
        groupNumber: i + 1,
        userIds: groups[i].map((u) => u.uid),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        seasonId: seasonId,
      });
      for (const volunteer of groups[i]) {
        const userRef = admin.firestore()
            .collection("users")
            .doc(volunteer.uid);
        batch.update(userRef, {
          currentGroupId: groupId,
          currentSeasonId: seasonId,
          seasonPoints: 0,
        });
      }
      await batch.commit();
    }
    await notifySeasonStart(seasonId, groups.length);
    return null;
  } catch (error) {
    console.error("Error creating tournament groups:", error);
    return null;
  }
});

/**
 * Допоміжна функція для перемішування масиву
 * @param {T[]} array - Масив, який потрібно перемішати.
 * @return {T[]} Той самий масив із перемішаними елементами.
 */
function shuffleArray(array) {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
  return array;
}

/**
 * Повідомляє всіх волонтерів про початок нового сезону
 * @param {string} seasonId - Унікальний ідентифікатор нового сезону .
 * @param {number} groupCount - Загальна кількість сформованих груп у цьому сезоні.
 */
async function notifySeasonStart(seasonId, groupCount) {
  try {
    const volunteersSnapshot = await admin.firestore()
        .collection("users")
        .where("role", "==", "volunteer")
        .get();
    const userIds = volunteersSnapshot.docs.map((doc) => doc.id);
    await sendNotificationToUsers({
      userIds: userIds,
      title: "Новий турнірний сезон!",
      body: `Почався новий сезон ${seasonId}! Вас розподілено у групи. Борися за топ-10 та отримуй ексклюзивні медалі!`,
      type: "tournamentSeasonStart",
      additionalData: {
        seasonId: seasonId,
        groupCount: groupCount.toString(),
      },
    });
  } catch (error) {
    console.error("Error notifying season start:", error);
  }
}

/**
 * Визначає переможців та присвоює медалі
 * Запускається в останній день місяця о 23:00
 */
exports.awardSeasonMedals = onSchedule({
  schedule: "0 23 28-31 * *",
  timeZone: "Europe/Kyiv",
}, async (context) => {
  try {
    const now = new Date();
    const tomorrow = new Date(now);
    tomorrow.setDate(tomorrow.getDate() + 1);
    if (tomorrow.getMonth() === now.getMonth()) {
      return null;
    }
    const seasonId = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
    const groupsSnapshot = await admin.firestore()
        .collection("tournamentSeasons")
        .doc(seasonId)
        .collection("groups")
        .get();
    if (groupsSnapshot.empty) {
      return null;
    }
    for (const groupDoc of groupsSnapshot.docs) {
      const groupData = groupDoc.data();
      const groupId = groupDoc.id;
      const usersSnapshot = await admin.firestore()
          .collection("users")
          .where("currentGroupId", "==", groupId)
          .get();
      if (usersSnapshot.empty) continue;
      const usersWithPoints = usersSnapshot.docs.map((doc) => {
        const data = doc.data();
        return {
          uid: doc.id,
          seasonPoints: data.seasonPoints || 0,
          displayName: data.displayName || data.fullName || "Волонтер",
        };
      });
      usersWithPoints.sort((a, b) => b.seasonPoints - a.seasonPoints);
      const top10 = usersWithPoints.slice(0, 3); // для тесту
      // буде const top10 = usersWithPoints.slice(0, 10);
      const batch = admin.firestore().batch();
      const notificationPromises = [];
      for (let i = 0; i < top10.length; i++) {
        const place = i + 1;
        const user = top10[i];
        let medalType;
        if (place === 1) {
          medalType = "gold";
        } else if (place == 2) { // для тесту
        // буде } else if (place >= 2 && place <= 3) {
          medalType = "silver";
        } else {
          medalType = "bronze";
        }
        const iconPath = await getSeasonMedalIcon(seasonId, medalType);
        const medalId = `${seasonId}_${groupId}_${place}`;
        const medal = {
          id: medalId,
          seasonId: seasonId,
          type: medalType,
          place: place,
          iconPath: iconPath,
          awardedAt: admin.firestore.Timestamp.now(),
          groupNumber: groupData.groupNumber,
          totalParticipants: usersWithPoints.length,
          seasonPoints: user.seasonPoints,
        };
        const userRef = admin.firestore().collection("users").doc(user.uid);
        batch.update(userRef, {
          medals: admin.firestore.FieldValue.arrayUnion(medal),
        });
        notificationPromises.push(
            sendMedalNotification(user.uid, medal, user.displayName)
                .catch((err) => console.error(`Failed to send notification to ${user.uid}:`, err)),
        );
      }
      await batch.commit();
      await Promise.all(notificationPromises);
    }
    return null;
  } catch (error) {
    console.error("Error awarding season medals:", error);
    return null;
  }
});

/**
 * Повертає URL медалі з Firebase Storage
 * Кожен місяць має унікальні медалі
 * @param {string} seasonId - Ідентифікатор сезону.
 * @param {string} medalType - Тип медалі ("gold", "silver", "bronze").
 * @return {Promise<string|undefined>} URL зображення або undefined (якщо файлу немає).
  */
async function getSeasonMedalIcon(seasonId, medalType) {
  try {
    const filePath = `medals/${seasonId}/${medalType}.png`;
    const bucket = admin.storage().bucket();
    const file = bucket.file(filePath);
    const [exists] = await file.exists();
    if (exists) {
      return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(filePath)}?alt=media`;
    }
  } catch (error) {
    console.error(`Error getting medal URL for ${seasonId}/${medalType}:`, error);
    return "";
  }
}

/**
 * Відправляє повідомлення про отримання медалі
 * @param {string} userId - UID користувача, який отримує нагороду.
 * @param {Object} medal - Об'єкт з даними про медаль.
 * @param {string} displayName - Ім'я користувача.
 */
async function sendMedalNotification(userId, medal, displayName) {
  try {
    let medalName;
    if (medal.type === "gold") {
      medalName = "золоту";
    } else if (medal.type === "silver") {
      medalName = "срібну";
    } else {
      medalName = "бронзову";
    }
    await sendNotificationToUsers({
      userIds: [userId],
      title: `Вітаємо! Ви в топ-10!`,
      body: `Ви зайняли ${medal.place} місце в турнірі та отримали ${medalName} медаль сезону ${medal.seasonId}!`,
      type: "tournamentMedal",
      additionalData: {
        seasonId: medal.seasonId,
        place: medal.place.toString(),
        medalType: medal.type,
        groupNumber: medal.groupNumber.toString(),
      },
    });
  } catch (error) {
    console.error(`Error sending medal notification to ${userId}:`, error);
  }
}
