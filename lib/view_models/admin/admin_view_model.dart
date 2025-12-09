import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:helphub/data/models/support_ticket_model.dart';
import 'package:helphub/data/models/volunteer_model.dart';
import 'package:helphub/data/services/admin_service.dart';

import '../../data/models/admin_statistics_model.dart';
import '../../data/models/feedback_model.dart';
import '../../data/models/organization_verification_model.dart';

class AdminViewModel extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  // Статистика
  AdminStatisticsModel? _statistics;
  bool _isLoadingStatistics = false;
  String? _statisticsError;

  AdminStatisticsModel? get statistics => _statistics;

  bool get isLoadingStatistics => _isLoadingStatistics;

  String? get statisticsError => _statisticsError;

  // Верифікація фондів
  List<OrganizationVerificationModel> _pendingVerifications = [];
  StreamSubscription<List<OrganizationVerificationModel>>?
  _verificationsSubscription;
  bool _isLoadingVerifications = false;

  List<OrganizationVerificationModel> get pendingVerifications =>
      _pendingVerifications;

  bool get isLoadingVerifications => _isLoadingVerifications;
  List<SupportTicketModel> _supportTickets = [];
  StreamSubscription<List<SupportTicketModel>>? _supportSubscription;
  bool _isLoadingSupport = false;

  List<SupportTicketModel> get supportTickets => _supportTickets;

  bool get isLoadingSupport => _isLoadingSupport;

  List<SupportTicketModel> get openTickets => _supportTickets
      .where((t) => t.status == SupportTicketStatus.open)
      .toList();

  List<SupportTicketModel> get inProgressTickets => _supportTickets
      .where((t) => t.status == SupportTicketStatus.inProgress)
      .toList();

  List<SupportTicketModel> get resolvedTickets => _supportTickets
      .where((t) => t.status == SupportTicketStatus.resolved)
      .toList();
  List<FeedbackModel> _feedback = [];
  StreamSubscription<List<FeedbackModel>>? _feedbackSubscription;
  bool _isLoadingFeedback = false;

  List<FeedbackModel> get feedback => _feedback;

  bool get isLoadingFeedback => _isLoadingFeedback;

  int get unreadFeedbackCount =>
      _feedback.where((f) => f.status == FeedbackStatus.unread).length;
  List<VolunteerModel> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;

  List<VolunteerModel> get searchResults => _searchResults;

  bool get isSearching => _isSearching;

  String? get searchError => _searchError;

  AdminViewModel() {
    _initialize();
  }

  void _initialize() {
    loadStatistics();
    _listenToVerifications();
    _listenToSupportTickets();
    _listenToFeedback();
  }

  Future<void> loadStatistics() async {
    _isLoadingStatistics = true;
    _statisticsError = null;
    notifyListeners();
    try {
      _statistics = await _adminService.getStatistics();
      _isLoadingStatistics = false;
      notifyListeners();
    } catch (e) {
      _statisticsError = 'Помилка завантаження статистики: $e';
      _isLoadingStatistics = false;
      notifyListeners();
    }
  }

  void _listenToVerifications() {
    _isLoadingVerifications = true;
    notifyListeners();
    _verificationsSubscription?.cancel();
    _verificationsSubscription = _adminService.getPendingVerifications().listen(
      (verifications) {
        _pendingVerifications = verifications;
        _isLoadingVerifications = false;
        notifyListeners();
      },
      onError: (error) {
        print('Error listening to verifications: $error');
        _isLoadingVerifications = false;
        notifyListeners();
      },
    );
  }

  Future<bool> approveOrganization(String organizationId) async {
    try {
      await _adminService.approveOrganization(organizationId);
      return true;
    } catch (e) {
      print('Error approving organization: $e');
      return false;
    }
  }

  Future<bool> rejectOrganization(String organizationId, String reason) async {
    try {
      await _adminService.rejectOrganization(organizationId, reason);
      return true;
    } catch (e) {
      print('Error rejecting organization: $e');
      return false;
    }
  }

  void _listenToSupportTickets() {
    _isLoadingSupport = true;
    notifyListeners();
    _supportSubscription?.cancel();
    _supportSubscription = _adminService.getSupportTickets().listen(
      (tickets) {
        _supportTickets = tickets;
        _isLoadingSupport = false;
        notifyListeners();
      },
      onError: (error) {
        print('Error listening to support tickets: $error');
        _isLoadingSupport = false;
        notifyListeners();
      },
    );
  }

  Future<bool> respondToTicket(
    String ticketId,
    String response,
    String adminId,
  ) async {
    try {
      await _adminService.respondToTicket(ticketId, response, adminId);
      return true;
    } catch (e) {
      print('Error responding to ticket: $e');
      return false;
    }
  }

  Future<bool> updateTicketStatus(
    String ticketId,
    SupportTicketStatus status,
  ) async {
    try {
      await _adminService.updateTicketStatus(ticketId, status);
      return true;
    } catch (e) {
      return false;
    }
  }

  void _listenToFeedback() {
    _isLoadingFeedback = true;
    notifyListeners();
    _feedbackSubscription?.cancel();
    _feedbackSubscription = _adminService.getFeedback().listen(
      (feedback) {
        _feedback = feedback;
        _isLoadingFeedback = false;
        notifyListeners();
      },
      onError: (error) {
        print('Error listening to feedback: $error');
        _isLoadingFeedback = false;
        notifyListeners();
      },
    );
  }

  Future<bool> markFeedbackAsRead(String feedbackId) async {
    try {
      await _adminService.markFeedbackAdRead(feedbackId);
      return true;
    } catch (e) {
      print('Error marking feedback as read: $e');
      return false;
    }
  }

  Future<bool> processFeedback(String feedbackId, String adminNote) async {
    try {
      await _adminService.processFeedback(feedbackId, adminNote);
      return true;
    } catch (e) {
      print('Error processing feedback: $e');
      return false;
    }
  }

  Future<void> searchVolunteers(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _searchError = null;
      notifyListeners();
      return;
    }
    _isSearching = true;
    _searchError = null;
    notifyListeners();
    try {
      _searchResults = await _adminService.searchVolunteers(query);
      _isSearching = false;
      if (_searchResults.isEmpty) {
        _searchError = 'Волонтерів не знайдено';
      }
      notifyListeners();
    } catch (e) {
      _searchError = 'Помилка входу: $e';
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    _searchError = null;
    notifyListeners();
  }

  Future<bool> addMedalToSeason(
    String seasonId,
    String medalType,
    String iconUrl,
  ) async {
    try {
      await _adminService.addMedalToSeason(seasonId, medalType, File(iconUrl));
      return true;
    } catch (e) {
      print('Error adding medal: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _verificationsSubscription?.cancel();
    _supportSubscription?.cancel();
    _feedbackSubscription?.cancel();
    super.dispose();
  }
}
