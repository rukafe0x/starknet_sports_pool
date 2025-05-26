import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:starknet_sports_pool/models/game.dart';
import '../services/services.dart';
import 'package:starknet/starknet.dart';

class CreateTournamentTemplateGames extends StatefulWidget {
  final String tournamentName;
  final int tournamentId;

  const CreateTournamentTemplateGames(
      {Key? key, required this.tournamentName, required this.tournamentId})
      : super(key: key);

  @override
  _CreateTournamentTemplateGamesState createState() =>
      _CreateTournamentTemplateGamesState();
}

class _CreateTournamentTemplateGamesState
    extends State<CreateTournamentTemplateGames> {
  List<Game> games = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tournamentName} - Add Games'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: games.length,
              itemBuilder: (context, index) {
                return GameListItem(
                  game: games[index],
                  onUpdate: (game) => _updateGame(index, game),
                  onDelete: () => _removeGame(index),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addNewGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Add New Game'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: games.isNotEmpty ? _saveTournament : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Save Tournament'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addNewGame() {
    setState(() {
      games.add(Game(
        id: Felt.fromInt(0),
        team1: '',
        team2: '',
        goals1: Felt.fromInt(0),
        goals2: Felt.fromInt(0),
        datetime: Felt.fromInt(DateTime.now().millisecondsSinceEpoch),
        played: false,
      ));
    });
  }

  void _removeGame(int index) {
    setState(() {
      games.removeAt(index);
    });
  }

  void _updateGame(int index, Game game) {
    setState(() {
      games[index] = game;
    });
  }

  Future<void> _saveTournament() async {
    try {
      await saveTournamentTemplateGames(widget.tournamentId, games);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tournament games saved successfully!')),
        );
        // Pop twice to go back two screens
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving tournament games: $e')),
        );
      }
    }
  }
}

class GameListItem extends StatelessWidget {
  final Game game;
  final Function(Game) onUpdate;
  final VoidCallback onDelete;

  GameListItem({
    Key? key,
    required this.game,
    required this.onUpdate,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: game.team1,
                    decoration: InputDecoration(labelText: 'Home Team'),
                    onChanged: (value) => onUpdate(Game(
                      id: game.id,
                      team1: value,
                      team2: game.team2,
                      goals1: game.goals1,
                      goals2: game.goals2,
                      datetime: game.datetime,
                      played: game.played,
                    )),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: game.team2,
                    decoration: InputDecoration(labelText: 'Away Team'),
                    onChanged: (value) => onUpdate(Game(
                      id: game.id,
                      team1: game.team1,
                      team2: value,
                      goals1: game.goals1,
                      goals2: game.goals2,
                      datetime: game.datetime,
                      played: game.played,
                    )),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDateTime(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date and Time',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(
                      DateTime.fromMillisecondsSinceEpoch(
                          game.datetime.toInt())),
                ),
              ),
            ),
            SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(Icons.delete),
                onPressed: onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.fromMillisecondsSinceEpoch(game.datetime.toInt()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
            DateTime.fromMillisecondsSinceEpoch(game.datetime.toInt())),
      );
      if (pickedTime != null) {
        final newDateTime = Felt.fromInt(DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        ).millisecondsSinceEpoch);

        onUpdate(Game(
          id: game.id,
          team1: game.team1,
          team2: game.team2,
          goals1: game.goals1,
          goals2: game.goals2,
          datetime: newDateTime,
          played: game.played,
        ));
      }
    }
  }
}
