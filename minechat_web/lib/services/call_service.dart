import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/call_models.dart';
import 'auth_service.dart';

class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  final List<Call> _callHistory = [];
  Call? _currentCall;
  final _callHistoryController = StreamController<List<Call>>.broadcast();
  final _currentCallController = StreamController<Call?>.broadcast();

  Stream<List<Call>> get callHistoryStream => _callHistoryController.stream;
  Stream<Call?> get currentCallStream => _currentCallController.stream;

  List<Call> get callHistory => _callHistory;
  Call? get currentCall => _currentCall;

  // Initialize the call service
  Future<void> init() async {
    await _loadData();
    _notifyCallHistoryListeners();
  }

  // Load data from shared preferences
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load call history
    final callHistoryJson = prefs.getString('callHistory');
    if (callHistoryJson != null) {
      final List<dynamic> callHistoryData = jsonDecode(callHistoryJson);
      _callHistory.clear();
      _callHistory.addAll(
        callHistoryData.map((data) => Call.fromJson(data)).toList()
      );
      
      // Sort call history by start time (newest first)
      _callHistory.sort((a, b) => b.startTime.compareTo(a.startTime));
    }
  }

  // Save data to shared preferences
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save call history
    final callHistoryJson = jsonEncode(_callHistory.map((c) => c.toJson()).toList());
    await prefs.setString('callHistory', callHistoryJson);
  }

  // Start a call
  Future<Call> startCall({
    required String receiverId,
    required String receiverName,
    String? receiverAvatar,
    required CallType type,
    String? conversationId,
  }) async {
    final authService = AuthService();
    final currentUser = authService.currentUser;
    
    if (currentUser == null) {
      throw Exception('User not logged in');
    }
    
    if (_currentCall != null) {
      throw Exception('Another call is in progress');
    }
    
    final call = Call(
      callerId: currentUser.id,
      callerName: currentUser.name,
      callerAvatar: currentUser.photoUrl,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverAvatar: receiverAvatar,
      type: type,
      status: CallStatus.ringing,
      isOutgoing: true,
      conversationId: conversationId,
    );
    
    _currentCall = call;
    _notifyCurrentCallListeners();
    
    // Simulate call connection delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Randomly decide if call is answered or missed (for demo purposes)
    final random = DateTime.now().millisecondsSinceEpoch % 3;
    
    if (random == 0) {
      // Call missed
      return await endCall(CallStatus.missed);
    } else {
      // Call answered
      _currentCall = _currentCall!.copyWith(status: CallStatus.ongoing);
      _notifyCurrentCallListeners();
      return _currentCall!;
    }
  }

  // Answer an incoming call
  Future<Call> answerCall() async {
    if (_currentCall == null) {
      throw Exception('No incoming call to answer');
    }
    
    if (_currentCall!.status != CallStatus.ringing) {
      throw Exception('Call is not ringing');
    }
    
    _currentCall = _currentCall!.copyWith(status: CallStatus.ongoing);
    _notifyCurrentCallListeners();
    
    return _currentCall!;
  }

  // End a call
  Future<Call> endCall([CallStatus status = CallStatus.ended]) async {
    if (_currentCall == null) {
      throw Exception('No call to end');
    }
    
    final endTime = DateTime.now();
    final duration = endTime.difference(_currentCall!.startTime);
    
    final endedCall = _currentCall!.copyWith(
      status: status,
      endTime: endTime,
      duration: status == CallStatus.ongoing || status == CallStatus.ended 
          ? duration 
          : null,
    );
    
    _callHistory.insert(0, endedCall);
    _currentCall = null;
    
    await _saveData();
    _notifyCallHistoryListeners();
    _notifyCurrentCallListeners();
    
    return endedCall;
  }

  // Reject an incoming call
  Future<Call> rejectCall() async {
    if (_currentCall == null) {
      throw Exception('No incoming call to reject');
    }
    
    if (_currentCall!.status != CallStatus.ringing) {
      throw Exception('Call is not ringing');
    }
    
    return await endCall(CallStatus.rejected);
  }

  // Simulate an incoming call
  Future<Call> simulateIncomingCall({
    required String callerId,
    required String callerName,
    String? callerAvatar,
    required CallType type,
    String? conversationId,
  }) async {
    final authService = AuthService();
    final currentUser = authService.currentUser;
    
    if (currentUser == null) {
      throw Exception('User not logged in');
    }
    
    if (_currentCall != null) {
      throw Exception('Another call is in progress');
    }
    
    final call = Call(
      callerId: callerId,
      callerName: callerName,
      callerAvatar: callerAvatar,
      receiverId: currentUser.id,
      receiverName: currentUser.name,
      receiverAvatar: currentUser.photoUrl,
      type: type,
      status: CallStatus.ringing,
      isOutgoing: false,
      conversationId: conversationId,
    );
    
    _currentCall = call;
    _notifyCurrentCallListeners();
    
    return call;
  }

  // Clear call history
  Future<void> clearCallHistory() async {
    _callHistory.clear();
    await _saveData();
    _notifyCallHistoryListeners();
  }

  // Delete a call from history
  Future<void> deleteCallFromHistory(String callId) async {
    _callHistory.removeWhere((call) => call.id == callId);
    await _saveData();
    _notifyCallHistoryListeners();
  }

  void _notifyCallHistoryListeners() {
    _callHistoryController.add(_callHistory);
  }

  void _notifyCurrentCallListeners() {
    _currentCallController.add(_currentCall);
  }

  void dispose() {
    _callHistoryController.close();
    _currentCallController.close();
  }
}
