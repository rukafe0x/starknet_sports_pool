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
  Map<String, dynamic>? _selectedInstance;

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

  Future<void> _loadGames(
      Felt selectedInstanceId, Felt tournamentTemplateId) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final games = await getTournamentTemplateGames(tournamentTemplateId);

      // Find the selected instance from _tournamentInstances
      final selectedInstance = _tournamentInstances.firstWhere(
        (instance) => instance['instance_id'] == selectedInstanceId,
      );

      setState(() {
        _games = games;
        _predictions = {};
        _selectedInstance = selectedInstance;
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
    if (!_areAllGamesPredicted()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please predict all games before saving')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // First, approve the entry fee
      await approveEntryFee(
        _selectedInstance!['instance_id'].toInt(),
        _selectedInstance!['entry_fee'],
      );

      // Show confirmation dialog
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Charge'),
          content: const Text(
              'Entry fee has been approved. The charge will now be effective and discounted from your account. Do you want to continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ok'),
            ),
          ],
        ),
      );

      if (proceed != true) {
        return; // User cancelled, do not proceed
      }

      // Then save the predictions
      final predictions = _games.map((game) {
        final gameId = game.id.toInt();
        final gamePredictions = _predictions[gameId] ?? [];
        return {
          'prediction':
              gamePredictions.isNotEmpty ? gamePredictions.first : null,
        };
      }).toList();

      final txHash = await saveUserInstancePrediction(
        _selectedInstance!['instance_id'].toInt(),
        predictions,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Predictions saved! TX: $txHash')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving predictions: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Play League'),
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
                            'Select League',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedInstance,
                            items: _tournamentInstances.map((instance) {
                              return DropdownMenuItem(
                                value: instance,
                                child: Text(instance['name'].toString()),
                              );
                            }).toList(),
                            onChanged: (instance) {
                              if (instance != null) {
                                _loadGames(instance['instance_id'],
                                    instance['tournament_template_id']);
                              }
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Tournament',
                            ),
                          ),
                          if (_selectedInstance != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Entry Fee: ${uint256ToStrkString(_selectedInstance!['entry_fee'])} STRK',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_selectedInstance != null &&
                      (_selectedInstance!['image_url']?.isNotEmpty ?? false))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _selectedInstance!['image_url'],
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            height: 160,
                            color: Colors.grey[200],
                            child: const Center(
                                child: Icon(Icons.broken_image, size: 48)),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return SizedBox(
                              height: 160,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          },
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _games.length,
                      itemBuilder: (context, index) {
                        final game = _games[index];
                        final gamePredictions =
                            _predictions[game.id.toInt()] ?? [];
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
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
                      onPressed:
                          _areAllGamesPredicted() ? _savePredictions : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
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
              ),
            ),
    );
  }

  Widget _buildPredictionButton(int gameId, int prediction, String label,
      IconData icon, bool isSelected) {
    return ElevatedButton(
      onPressed: () => _togglePrediction(gameId, prediction),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.orange : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Column(
        children: [
          Icon(icon, color: isSelected ? Colors.white : Color(0xFFF78A05)),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}
