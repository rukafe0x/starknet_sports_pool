import 'package:flutter/material.dart';
import '../services/services.dart';
import '../models/game.dart';
import 'package:starknet/starknet.dart';

class MyTournamentsScreen extends StatefulWidget {
  final String userAddress;

  const MyTournamentsScreen({Key? key, required this.userAddress})
      : super(key: key);

  @override
  _MyTournamentsScreenState createState() => _MyTournamentsScreenState();
}

class _MyTournamentsScreenState extends State<MyTournamentsScreen> {
  List<int> _userInstanceIds = [];
  List<Map<String, dynamic>> _allInstances = [];
  List<Game> _games = [];
  List<int> _predictions = [];
  Map<String, dynamic>? _selectedInstance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // First, get the list of instance IDs where the user has predictions
      final userInstanceIds =
          await getUserInstancePredictionsList(widget.userAddress);

      // Then, get all tournament instances
      final allInstances = await getTournamentInstances();

      // Filter instances to only show those where user has predictions
      final filteredInstances = allInstances.where((instance) {
        return userInstanceIds.contains(instance['instance_id'].toInt());
      }).toList();

      setState(() {
        _userInstanceIds = userInstanceIds;
        _allInstances = filteredInstances;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadInstanceData(Map<String, dynamic> instance) async {
    setState(() => _isLoading = true);
    try {
      // Get games for the selected instance's template
      final games =
          await getTournamentTemplateGames(instance['tournament_template_id']);

      // Get predictions for the selected instance
      final predictions = await getUserInstancePredictions(
          Felt.fromHexString(widget.userAddress),
          instance['instance_id'].toInt());

      setState(() {
        _games = games;
        _predictions = predictions;
        _selectedInstance = instance;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading instance data: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  String _getPredictionText(int gameIndex) {
    if (gameIndex >= _predictions.length) return 'No prediction';
    final prediction = _predictions[gameIndex];
    switch (prediction) {
      case 0:
        return 'Home Win';
      case 1:
        return 'Draw';
      case 2:
        return 'Away Win';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tournaments'),
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
                            'Select Tournament',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedInstance,
                            items: _allInstances.map((instance) {
                              return DropdownMenuItem(
                                value: instance,
                                child: Text(instance['name'].toString()),
                              );
                            }).toList(),
                            onChanged: (instance) {
                              if (instance != null) {
                                _loadInstanceData(instance);
                              }
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Tournament',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedInstance != null && _games.isNotEmpty) ...[
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_selectedInstance!['name']} Games',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _games.length,
                                  itemBuilder: (context, index) {
                                    final game = _games[index];
                                    return Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    game.team1,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    game.team2,
                                                    textAlign: TextAlign.end,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Your prediction:',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                Text(
                                                  _getPredictionText(index),
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
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
