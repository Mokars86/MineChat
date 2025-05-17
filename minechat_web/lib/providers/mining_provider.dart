import 'dart:async';
import 'package:flutter/material.dart';
import '../models/mining_models.dart';
import '../services/mining_service.dart';
import '../services/wallet_service.dart';

class MiningProvider extends ChangeNotifier {
  final MiningService _miningService = MiningService();

  List<MiningSession> _miningSessions = [];
  MiningSession? _activeMiningSession;
  bool _isLoading = false;
  String? _error;
  int _selectedMiningRateLevel = 1;

  StreamSubscription? _miningSessionsSubscription;
  StreamSubscription? _activeMiningSessionSubscription;

  List<MiningSession> get miningSessions => _miningSessions;
  MiningSession? get activeMiningSession => _activeMiningSession;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isMining => _activeMiningSession != null && _activeMiningSession!.status == MiningStatus.mining;
  bool get canClaimReward => _activeMiningSession != null && _activeMiningSession!.status == MiningStatus.completed;
  int get selectedMiningRateLevel => _selectedMiningRateLevel;
  MiningRate get selectedMiningRate => MiningRate.getByLevel(_selectedMiningRateLevel);

  MiningProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _miningService.init();

      // Listen for mining sessions updates
      _miningSessionsSubscription = _miningService.miningSessionsStream.listen((sessions) {
        _miningSessions = sessions;
        notifyListeners();
      });

      // Listen for active mining session updates
      _activeMiningSessionSubscription = _miningService.activeMiningSessionStream.listen((session) {
        _activeMiningSession = session;
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

  Future<void> startMining() async {
    if (isMining) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _miningService.startMining(miningRateLevel: _selectedMiningRateLevel);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void setMiningRateLevel(int level) {
    if (level < 1 || level > MiningRate.rates.length) return;
    if (isMining) return; // Can't change mining rate while mining

    _selectedMiningRateLevel = level;
    notifyListeners();
  }

  Future<bool> purchaseMiningRate(int level) async {
    if (level <= _selectedMiningRateLevel) return true; // Already purchased

    final walletService = WalletService();
    final miningRate = MiningRate.getByLevel(level);

    // Check if user has enough balance
    if (walletService.balance < miningRate.price) {
      _error = 'Insufficient balance to purchase this mining rate';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Deduct the price from wallet
      await walletService.addTransaction(
        amount: miningRate.price,
        description: 'Purchase ${miningRate.name} Mining Rate',
        isDeposit: false,
      );

      // Update the mining rate level
      _selectedMiningRateLevel = level;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> stopMining() async {
    if (!isMining) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _miningService.stopMining();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> claimReward() async {
    if (!canClaimReward) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _miningService.claimReward();

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
    _miningSessionsSubscription?.cancel();
    _activeMiningSessionSubscription?.cancel();
    super.dispose();
  }
}
