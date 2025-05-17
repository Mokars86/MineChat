import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mining_models.dart';
import 'auth_service.dart';
import 'wallet_service.dart';

class MiningService {
  static final MiningService _instance = MiningService._internal();
  factory MiningService() => _instance;
  MiningService._internal();

  final List<MiningSession> _miningSessions = [];
  MiningSession? _activeMiningSession;
  Timer? _miningTimer;

  final _miningSessionsController = StreamController<List<MiningSession>>.broadcast();
  final _activeMiningSessionController = StreamController<MiningSession?>.broadcast();

  Stream<List<MiningSession>> get miningSessionsStream => _miningSessionsController.stream;
  Stream<MiningSession?> get activeMiningSessionStream => _activeMiningSessionController.stream;

  List<MiningSession> get miningSessions => _miningSessions;
  MiningSession? get activeMiningSession => _activeMiningSession;

  // Initialize the mining service
  Future<void> init() async {
    await _loadData();
    _checkActiveMiningSession();
    _notifyMiningSessionsListeners();
    _notifyActiveMiningSessionListener();
  }

  // Load data from shared preferences
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load mining sessions
    final miningSessionsJson = prefs.getString('miningSessions');
    if (miningSessionsJson != null) {
      final List<dynamic> miningSessionsData = jsonDecode(miningSessionsJson);
      _miningSessions.clear();
      _miningSessions.addAll(
        miningSessionsData.map((data) => MiningSession.fromJson(data)).toList()
      );

      // Sort mining sessions by start time (newest first)
      _miningSessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    }
  }

  // Save data to shared preferences
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    // Save mining sessions
    final miningSessionsJson = jsonEncode(_miningSessions.map((s) => s.toJson()).toList());
    await prefs.setString('miningSessions', miningSessionsJson);
  }

  // Check if there's an active mining session
  void _checkActiveMiningSession() {
    final authService = AuthService();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      _activeMiningSession = null;
      return;
    }

    // Find the active mining session for the current user
    try {
      _activeMiningSession = _miningSessions.firstWhere(
        (session) =>
          session.userId == currentUser.id &&
          session.status == MiningStatus.mining,
      );
      print('MiningService: Found active mining session: ${_activeMiningSession!.id}');
    } catch (e) {
      // No active mining session found
      _activeMiningSession = null;
      print('MiningService: No active mining session found for user');
    }

    // If there's an active mining session, check if it's complete
    if (_activeMiningSession != null && _activeMiningSession!.isMiningComplete) {
      _completeMiningSession();
    }

    // Start the mining timer if there's an active session
    if (_activeMiningSession != null) {
      _startMiningTimer();
    }
  }

  // Start a new mining session
  Future<MiningSession> startMining({int miningRateLevel = 1}) async {
    print('MiningService: Starting mining with rate level $miningRateLevel');
    final authService = AuthService();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      print('MiningService: Cannot start mining - User not logged in');
      throw Exception('User not logged in');
    }

    if (_activeMiningSession != null) {
      print('MiningService: Cannot start mining - Session already in progress');
      throw Exception('A mining session is already in progress');
    }

    print('MiningService: User authenticated, proceeding with mining');

    // Get the mining rate
    final miningRate = MiningRate.getByLevel(miningRateLevel);
    print('MiningService: Using mining rate: ${miningRate.name} with base hash rate ${miningRate.hashRate}');

    // Generate hash rate based on the mining rate with some randomness
    final random = Random();
    final hashRate = miningRate.hashRate * (0.9 + random.nextDouble() * 0.2);

    // Estimate reward based on hash rate (0.01 to 0.05 coins per MH/s)
    final estimatedReward = hashRate * (0.01 + random.nextDouble() * 0.04);

    print('MiningService: Creating mining session with hash rate $hashRate and estimated reward $estimatedReward');

    // Create a new mining session
    final miningSession = MiningSession(
      startTime: DateTime.now(),
      status: MiningStatus.mining,
      hashRate: hashRate,
      estimatedReward: estimatedReward,
      userId: currentUser.id,
      miningRateLevel: miningRateLevel,
    );

    _miningSessions.insert(0, miningSession);
    _activeMiningSession = miningSession;

    print('MiningService: Saving mining session data');
    await _saveData();

    print('MiningService: Notifying listeners about new mining session');
    _notifyMiningSessionsListeners();
    _notifyActiveMiningSessionListener();

    // Start the mining timer
    print('MiningService: Starting mining timer');
    _startMiningTimer();

    print('MiningService: Mining session started successfully');
    return miningSession;
  }

  // Stop the current mining session
  Future<MiningSession> stopMining() async {
    if (_activeMiningSession == null) {
      throw Exception('No active mining session');
    }

    // Stop the mining timer
    _miningTimer?.cancel();

    // Update the mining session
    final stoppedSession = _activeMiningSession!.copyWith(
      endTime: DateTime.now(),
      status: MiningStatus.idle,
    );

    // Update the mining session in the list
    final index = _miningSessions.indexWhere((s) => s.id == _activeMiningSession!.id);
    if (index != -1) {
      _miningSessions[index] = stoppedSession;
    }

    _activeMiningSession = null;

    await _saveData();
    _notifyMiningSessionsListeners();
    _notifyActiveMiningSessionListener();

    return stoppedSession;
  }

  // Complete the mining session (when 24 hours have passed)
  Future<MiningSession> _completeMiningSession() async {
    if (_activeMiningSession == null) {
      throw Exception('No active mining session');
    }

    // Stop the mining timer
    _miningTimer?.cancel();

    // Calculate actual reward (80-120% of estimated reward)
    final random = Random();
    final rewardMultiplier = 0.8 + random.nextDouble() * 0.4;
    final actualReward = _activeMiningSession!.estimatedReward * rewardMultiplier;

    // Update the mining session
    final completedSession = _activeMiningSession!.copyWith(
      endTime: _activeMiningSession!.startTime.add(const Duration(hours: 24)),
      status: MiningStatus.completed,
      actualReward: actualReward,
    );

    // Update the mining session in the list
    final index = _miningSessions.indexWhere((s) => s.id == _activeMiningSession!.id);
    if (index != -1) {
      _miningSessions[index] = completedSession;
    }

    _activeMiningSession = completedSession;

    await _saveData();
    _notifyMiningSessionsListeners();
    _notifyActiveMiningSessionListener();

    return completedSession;
  }

  // Claim the reward from a completed mining session
  Future<MiningSession> claimReward() async {
    if (_activeMiningSession == null) {
      throw Exception('No active mining session');
    }

    if (_activeMiningSession!.status != MiningStatus.completed) {
      throw Exception('Mining session is not completed');
    }

    // Update the mining session
    final claimedSession = _activeMiningSession!.copyWith(
      status: MiningStatus.claimed,
    );

    // Update the mining session in the list
    final index = _miningSessions.indexWhere((s) => s.id == _activeMiningSession!.id);
    if (index != -1) {
      _miningSessions[index] = claimedSession;
    }

    // Add the reward to the wallet
    final walletService = WalletService();
    await walletService.addTransaction(
      amount: claimedSession.actualReward!,
      description: 'Mining reward',
      miningSessionId: claimedSession.id,
      isDeposit: true,
    );

    _activeMiningSession = null;

    await _saveData();
    _notifyMiningSessionsListeners();
    _notifyActiveMiningSessionListener();

    return claimedSession;
  }

  // Start the mining timer to check for completion
  void _startMiningTimer() {
    print('MiningService: Setting up mining timer');

    if (_miningTimer != null) {
      print('MiningService: Cancelling existing timer');
      _miningTimer?.cancel();
    }

    print('MiningService: Starting new periodic timer to check mining completion');
    _miningTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeMiningSession == null) {
        print('MiningService: No active mining session, cancelling timer');
        timer.cancel();
        return;
      }

      if (_activeMiningSession!.isMiningComplete) {
        print('MiningService: Mining session complete, processing completion');
        timer.cancel();
        _completeMiningSession();
      } else {
        // Notify listeners about the active mining session (for UI updates)
        _notifyActiveMiningSessionListener();
      }
    });
    print('MiningService: Mining timer started successfully');
  }

  // Get mining sessions for a specific user
  List<MiningSession> getMiningSessionsForUser(String userId) {
    return _miningSessions.where((session) => session.userId == userId).toList();
  }

  void _notifyMiningSessionsListeners() {
    _miningSessionsController.add(_miningSessions);
  }

  void _notifyActiveMiningSessionListener() {
    _activeMiningSessionController.add(_activeMiningSession);
  }

  void dispose() {
    _miningTimer?.cancel();
    _miningSessionsController.close();
    _activeMiningSessionController.close();
  }
}
