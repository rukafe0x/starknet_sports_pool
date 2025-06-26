import 'package:flutter/material.dart';
import '../services/services.dart';
import 'package:starknet/starknet.dart';
import '../utils/utils.dart';

class LeaderboardScreen extends StatefulWidget {
  final int instanceId;
  const LeaderboardScreen({Key? key, required this.instanceId})
      : super(key: key);

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;
  String? _userAddress;
  Uint256? _prize;
  bool _isPrizeClaimed = false;
  bool _isPayingPrize = false;
  bool _isUserInTop3 = false;
  int _userPosition = -1;
  bool _isTournamentFinished = false;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadUserAddress() async {
    _userAddress = await getSecretAccountAddress();
    // convert after 0x and pad with 64 zeros left
    if (_userAddress != null && _userAddress!.startsWith('0x')) {
      _userAddress = '0x${_userAddress!.substring(2).padLeft(64, '0')}';
    }
  }

  Future<void> _checkUserPosition() async {
    if (_userAddress == null) {
      await _loadUserAddress();
    }

    if (_userAddress != null && _leaderboard.isNotEmpty) {
      // Check if tournament is finished
      setState(() {
        _isTournamentFinished = _leaderboard[0]['is_finished'] ?? false;
      });

      // Check if user is in top 3
      if (_userAddress == _leaderboard[0]['leader1']) {
        setState(() {
          _isUserInTop3 = true;
          _userPosition = 1;
          _prize = _leaderboard[0]['final_prize1'];
          _isPrizeClaimed = _leaderboard[0]['prize1_claimed'];
        });
      } else if (_userAddress == _leaderboard[0]['leader2']) {
        setState(() {
          _isUserInTop3 = true;
          _userPosition = 2;
          _prize = _leaderboard[0]['final_prize2'];
          _isPrizeClaimed = _leaderboard[0]['prize2_claimed'];
        });
      } else if (_userAddress == _leaderboard[0]['leader3']) {
        setState(() {
          _isUserInTop3 = true;
          _userPosition = 3;
          _prize = _leaderboard[0]['final_prize3'];
          _isPrizeClaimed = _leaderboard[0]['prize3_claimed'];
        });
      }
    }
  }

  Future<void> _claimPrize() async {
    setState(() => _isPayingPrize = true);
    try {
      await claimPrize(widget.instanceId);
      setState(() => _isPayingPrize = false);

      // Show success dialog
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Prize Claimed!'),
          content: const Text(
              'Congratulations! Your prize has been successfully claimed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      // Return to previous screen
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isPayingPrize = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error claiming prize: $e')),
      );
    }
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final leaderboard = await getInstanceLeaderboard(widget.instanceId);
      setState(() {
        _leaderboard = leaderboard;
        _isLoading = false;
      });
      await _checkUserPosition();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading leaderboard: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (_isUserInTop3)
                        Column(
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              _prize != null && _prize!.toBigInt() > BigInt.zero
                                  ? _isPrizeClaimed
                                      ? '🎉 Congratulations! You finished in ${_userPosition == 1 ? '1st' : _userPosition == 2 ? '2nd' : '3rd'} place and have already claimed your prize of ${formatTokenBalance(_prize!, decimals: 18)} STRK!'
                                      : _isTournamentFinished
                                          ? '🎉 Congratulations! You are in ${_userPosition == 1 ? '1st' : _userPosition == 2 ? '2nd' : '3rd'} place and have a prize of ${formatTokenBalance(_prize!, decimals: 18)} STRK.'
                                          : '🎉 Congratulations! You are in ${_userPosition == 1 ? '1st' : _userPosition == 2 ? '2nd' : '3rd'} place! Keep waiting for tournament finalization.'
                                  : '🎉 Congratulations! You are in ${_userPosition == 1 ? '1st' : _userPosition == 2 ? '2nd' : '3rd'} place! Keep waiting for tournament finalization.',
                              style: TextStyle(
                                  color: _prize != null &&
                                          _prize!.toBigInt() > BigInt.zero
                                      ? _isPrizeClaimed
                                          ? Colors.grey
                                          : (_isTournamentFinished
                                              ? Colors.green
                                              : Colors.blue)
                                      : Colors.blue,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            if (_prize != null &&
                                _prize!.toBigInt() > BigInt.zero &&
                                !_isPrizeClaimed &&
                                _isTournamentFinished)
                              ElevatedButton(
                                onPressed: _isPayingPrize ? null : _claimPrize,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                                child: _isPayingPrize
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Text('Claim Prize'),
                              ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              _isTournamentFinished
                                  ? '😔 Sorry, tournament has finished. You didnt make it into the top 3.'
                                  : '😔 Sorry, you are not in the top 3 at this moment. Keep waiting for tournament finalization.',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _leaderboard.length - 1,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final entry = _leaderboard[index + 1];
                      final nickname = entry['nickname'] ?? '';
                      final address = entry['address'] ?? '';
                      final formattedAddress = formatAddressDisplay(address);

                      String displayName;
                      if (nickname.isNotEmpty && nickname != '0') {
                        displayName = '$nickname ($formattedAddress)';
                      } else {
                        displayName = formattedAddress;
                      }

                      return ListTile(
                        leading: Text('#${index + 1}'),
                        title: Text(displayName),
                        trailing: Text('${entry['points']} pts'),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
