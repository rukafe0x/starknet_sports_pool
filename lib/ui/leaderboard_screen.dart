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
  bool _isCheckingPrize = false;
  bool _isPayingPrize = false;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadUserAddress() async {
    _userAddress = await getSecretAccountAddress();
  }

  Future<void> _checkPrize() async {
    setState(() => _isCheckingPrize = true);
    try {
      await _loadUserAddress();
      final prize = await checkPrice(widget.instanceId);
      setState(() {
        _prize = prize;
        _isCheckingPrize = false;
      });
    } catch (e) {
      setState(() => _isCheckingPrize = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking prize: $e')),
      );
    }
  }

  Future<void> _payPrize() async {
    setState(() => _isPayingPrize = true);
    try {
      final txHash = await claimPrice(widget.instanceId);
      setState(() => _isPayingPrize = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prize claimed!')),
      );
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
                      ElevatedButton(
                        onPressed: _isCheckingPrize ? null : _checkPrize,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: _isCheckingPrize
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Check Prize'),
                      ),
                      if (_prize != null)
                        Column(
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              _prize!.toBigInt() > BigInt.zero
                                  ? '🎉 Great! You have a prize of ${formatTokenBalance(_prize!, decimals: 18)} STRK.'
                                  : '😔 Sorry, no prize this time. Keep playing and good luck next time!',
                              style: TextStyle(
                                  color: _prize!.toBigInt() > BigInt.zero
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            if (_prize!.toBigInt() > BigInt.zero)
                              ElevatedButton(
                                onPressed: _isPayingPrize ? null : _payPrize,
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
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _leaderboard.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final entry = _leaderboard[index];
                      return ListTile(
                        leading: Text('#${index + 1}'),
                        title: Text(entry['address'] ?? ''),
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
