import 'package:flutter/material.dart';
import '../services/services.dart';

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
  BigInt? _prize;
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
      final prize = await checkPrice(widget.instanceId, _userAddress!);
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
      await payPrice(widget.instanceId, _userAddress!);
      setState(() => _isPayingPrize = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prize received!')),
      );
    } catch (e) {
      setState(() => _isPayingPrize = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error receiving prize: $e')),
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
                        child: _isCheckingPrize
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Check Prize'),
                      ),
                      if (_prize != null && _prize! > BigInt.zero)
                        Column(
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              '🎉 Congratulations! You have a prize of $_prize!',
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _isPayingPrize ? null : _payPrize,
                              child: _isPayingPrize
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Text('Receive Prize'),
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
