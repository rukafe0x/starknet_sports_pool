import 'package:flutter/material.dart';
import 'package:starknet/starknet.dart';
import '../models/tournament_template.dart';
import '../models/game.dart';
import '../services/services.dart';

class EditTournamentScreen extends StatefulWidget {
  const EditTournamentScreen({Key? key}) : super(key: key);

  @override
  _EditTournamentScreenState createState() => _EditTournamentScreenState();
}

class _EditTournamentScreenState extends State<EditTournamentScreen> {
  List<TournamentTemplate> _templates = [];
  List<Game> _games = [];
  TournamentTemplate? _selectedTemplate;
  Game? _selectedGame;
  final TextEditingController _goals1Controller = TextEditingController();
  final TextEditingController _goals2Controller = TextEditingController();
  bool _isLoading = false;
  bool _isPlayed = false;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  @override
  void dispose() {
    _goals1Controller.dispose();
    _goals2Controller.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      final templates = await getTournamentTemplates();
      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading templates: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadGames(TournamentTemplate template) async {
    setState(() => _isLoading = true);
    try {
      final games = await getTournamentTemplateGames(template.id);
      setState(() {
        _games = games;
        _selectedTemplate = template;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading games: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveGameResult() async {
    if (_selectedTemplate == null || _selectedGame == null) return;

    final goals1 = int.tryParse(_goals1Controller.text);
    final goals2 = int.tryParse(_goals2Controller.text);

    if (goals1 == null || goals2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid goal numbers')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await editGameResult(
        _selectedTemplate!.id.toInt(),
        _selectedGame!.id.toInt(),
        Felt.fromInt(goals1),
        Felt.fromInt(goals2),
        _isPlayed,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game result updated successfully')),
      );

      // Reload games to show updated results
      await _loadGames(_selectedTemplate!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating game result: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Tournament'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tournament Template Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Tournament Template',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<TournamentTemplate>(
                            value: _selectedTemplate,
                            items: _templates.map((template) {
                              return DropdownMenuItem(
                                value: template,
                                child: Text(template.name),
                              );
                            }).toList(),
                            onChanged: (template) {
                              if (template != null) {
                                _loadGames(template);
                              }
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Tournament Template',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Game Selection and Result Editing
                  if (_selectedTemplate != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Game and Edit Result',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<Game>(
                              value: _selectedGame,
                              items: _games.map((game) {
                                return DropdownMenuItem(
                                  value: game,
                                  child: Text('${game.team1} vs ${game.team2}'),
                                );
                              }).toList(),
                              onChanged: (game) {
                                setState(() {
                                  _selectedGame = game;
                                  if (game != null) {
                                    _goals1Controller.text =
                                        game.goals1.toInt().toString();
                                    _goals2Controller.text =
                                        game.goals2.toInt().toString();
                                    _isPlayed = game.played;
                                  }
                                });
                              },
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Game',
                                filled: true,
                                fillColor: Color(0xFFFFF3E0),
                              ),
                              dropdownColor: Color(0xFFFFF3E0),
                            ),
                            if (_selectedGame != null) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _goals1Controller,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        border: const OutlineInputBorder(),
                                        labelText: _selectedGame!.team1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    'vs',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextField(
                                      controller: _goals2Controller,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        border: const OutlineInputBorder(),
                                        labelText: _selectedGame!.team2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _isPlayed,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _isPlayed = value ?? false;
                                      });
                                    },
                                  ),
                                  const Text('Mark as played'),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _saveGameResult,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                  ),
                                  child: const Text('Save Result'),
                                ),
                              ),
                            ],
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
