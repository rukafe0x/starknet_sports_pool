import 'package:flutter/material.dart';
import '../services/services.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _instances = [];
  List<Map<String, dynamic>> _leaderboard = [];
  Map<String, dynamic>? _selectedInstance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInstances();
  }

  Future<void> _loadInstances() async {
    setState(() => _isLoading = true);
    try {
      final instances = await getTournamentInstances();
      setState(() {
        _instances = instances;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading instances: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLeaderboard(Map<String, dynamic> instance) async {
    setState(() => _isLoading = true);
    try {
      final leaderboard =
          await getInstanceLeaderboard(instance['instance_id'].toInt());
      setState(() {
        _leaderboard = leaderboard;
        _selectedInstance = instance;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading leaderboard: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament Leaderboard'),
        backgroundColor: const Color(0xFF6750A4),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Tournament Instance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedInstance,
                            items: _instances.map((instance) {
                              return DropdownMenuItem(
                                value: instance,
                                child: Text(instance['name'].toString()),
                              );
                            }).toList(),
                            onChanged: (instance) {
                              if (instance != null) {
                                _loadLeaderboard(instance);
                              }
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Tournament Instance',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedInstance != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_selectedInstance!['name']} Leaderboard',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_leaderboard.isEmpty)
                              const Center(
                                child: Text('No participants yet'),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _leaderboard.length,
                                itemBuilder: (context, index) {
                                  final entry = _leaderboard[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFF6750A4),
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      '0x${entry['address'].toString().substring(2, 6)}..${entry['address'].toString().substring(entry['address'].toString().length - 4)}',
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    trailing: Text(
                                      '${entry['points']} pts',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
