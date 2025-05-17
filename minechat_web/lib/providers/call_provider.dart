import 'dart:async';
import 'package:flutter/material.dart';
import '../models/call_models.dart';
import '../services/call_service.dart';

class CallProvider extends ChangeNotifier {
  final CallService _callService = CallService();
  
  List<Call> _callHistory = [];
  Call? _currentCall;
  bool _isLoading = false;
  String? _error;
  
  StreamSubscription? _callHistorySubscription;
  StreamSubscription? _currentCallSubscription;

  List<Call> get callHistory => _callHistory;
  Call? get currentCall => _currentCall;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInCall => _currentCall != null;

  CallProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _callService.init();
      
      // Listen for call history updates
      _callHistorySubscription = _callService.callHistoryStream.listen((calls) {
        _callHistory = calls;
        notifyListeners();
      });
      
      // Listen for current call updates
      _currentCallSubscription = _callService.currentCallStream.listen((call) {
        _currentCall = call;
        notifyListeners();
      });
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startCall({
    required String receiverId,
    required String receiverName,
    String? receiverAvatar,
    required CallType type,
    String? conversationId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _callService.startCall(
        receiverId: receiverId,
        receiverName: receiverName,
        receiverAvatar: receiverAvatar,
        type: type,
        conversationId: conversationId,
      );
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> answerCall() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _callService.answerCall();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> endCall() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _callService.endCall();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> rejectCall() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _callService.rejectCall();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> simulateIncomingCall({
    required String callerId,
    required String callerName,
    String? callerAvatar,
    required CallType type,
    String? conversationId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _callService.simulateIncomingCall(
        callerId: callerId,
        callerName: callerName,
        callerAvatar: callerAvatar,
        type: type,
        conversationId: conversationId,
      );
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearCallHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _callService.clearCallHistory();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCallFromHistory(String callId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _callService.deleteCallFromHistory(callId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _callHistorySubscription?.cancel();
    _currentCallSubscription?.cancel();
    super.dispose();
  }
}
