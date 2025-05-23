import 'package:flutter/material.dart';
import 'package:starknet/starknet.dart';
import '../services/services.dart';
import '../models/game.dart';
import '../utils/utils.dart';

class PlayTournamentScreen extends StatefulWidget {
  const PlayTournamentScreen({Key? key}) : super(key: key);

  @override
  _PlayTournamentScreenState createState() => _PlayTournamentScreenState();
}

class _PlayTournamentScreenState extends State<PlayTournamentScreen> {
  List<Map<String, dynamic>> _tournamentInstances = [];
  List<Game> _games = [];
  // Map of game_id to list of predictions (0=draw, 1=home, 2=away)
  Map<int, List<int>> _predictions = {};
  bool _isLoading = true;
  String? _error;
  int? _selectedInstanceId;

  @override
  void initState() {
    super.initState();
    _loadTournamentInstances();
  }

  Future<void> _loadTournamentInstances() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final instances = await getTournamentInstances();
      setState(() {
        _tournamentInstances = instances;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadGames(Felt tournamentTemplateId) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _selectedInstanceId = tournamentTemplateId.toInt();
      });

      final games = await getTournamentTemplateGames(tournamentTemplateId);
      setState(() {
        _games = games;
        _predictions = {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _togglePrediction(int gameId, int prediction) {
    setState(() {
      if (!_predictions.containsKey(gameId)) {
        _predictions[gameId] = [];
      }

      final predictions = _predictions[gameId]!;
      if (predictions.contains(prediction)) {
        predictions.remove(prediction);
      } else {
        // Clear other predictions for this game
        predictions.clear();
        predictions.add(prediction);
      }
    });
  }

  bool _areAllGamesPredicted() {
    if (_games.isEmpty) return false;

    // Check if each game has exactly one prediction
    for (var game in _games) {
      final gameId = game.id.toInt();
      final predictions = _predictions[gameId] ?? [];
      if (predictions.length != 1) return false;
    }
    return true;
  }

  Future<void> _savePredictions() async {
    if (_selectedInstanceId == null) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Convert predictions to the format expected by the contract
      List<Map<String, dynamic>> allPredictions = [];
      _predictions.forEach((gameId, predictions) {
        for (var prediction in predictions) {
          allPredictions.add({
            'game_id': gameId,
            'prediction': prediction,
          });
        }
      });

      final txHash = await saveUserInstancePrediction(
          _selectedInstanceId!, allPredictions);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Predictions saved! Transaction: $txHash')),
      );

      // Clear predictions after successful save
      setState(() {
        _predictions = {};
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Play Tournament'),
        backgroundColor: const Color(0xFF6750A4),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _selectedInstanceId == null
                  ? _buildTournamentList()
                  : _buildGamesList(),
    );
  }

  Widget _buildTournamentList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tournamentInstances.length,
      itemBuilder: (context, index) {
        final instance = _tournamentInstances[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            title: Text(instance['name']),
            subtitle: Text(instance['description']),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _loadGames(instance['tournament_template_id']),
          ),
        );
      },
    );
  }

  Widget _buildGamesList() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _games.length,
            itemBuilder: (context, index) {
              final game = _games[index];
              final gamePredictions = _predictions[game.id.toInt()] ?? [];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${game.team1} vs ${game.team2}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        gamePredictions.isEmpty
                            ? 'No prediction selected'
                            : 'Selected: ${gamePredictions.map((p) => p == 1 ? "Home Win" : p == 2 ? "Away Win" : "Draw").join(", ")}',
                        style: TextStyle(
                          color: gamePredictions.isEmpty
                              ? Colors.red
                              : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildPredictionButton(
                            game.id.toInt(),
                            1,
                            'Home Win',
                            Icons.home,
                            gamePredictions.contains(1),
                          ),
                          _buildPredictionButton(
                            game.id.toInt(),
                            0,
                            'Draw',
                            Icons.sports_soccer,
                            gamePredictions.contains(0),
                          ),
                          _buildPredictionButton(
                            game.id.toInt(),
                            2,
                            'Away Win',
                            Icons.airplanemode_active,
                            gamePredictions.contains(2),
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
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _areAllGamesPredicted() ? _savePredictions : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6750A4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 0),
            ),
            child: Text(
              'Save Predictions (${_predictions.length}/${_games.length} games predicted)',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionButton(int gameId, int prediction, String label,
      IconData icon, bool isSelected) {
    return ElevatedButton(
      onPressed: () => _togglePrediction(gameId, prediction),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected ? const Color(0xFF6750A4) : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Column(
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}
