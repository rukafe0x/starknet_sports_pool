import 'package:starknet/starknet.dart';
import '../utils/utils.dart';

class Game {
  String team1;
  String team2;
  Felt goals1;
  Felt goals2;
  Felt datetime;
  bool played;

  Game({
    required this.team1,
    required this.team2,
    required this.goals1,
    required this.goals2,
    required this.datetime,
    required this.played,
  });

  factory Game.fromFelt(Map<String, dynamic> data) {
    return Game(
      team1: feltToAsciiString(data['team1']),
      team2: feltToAsciiString(data['team2']),
      goals1: data['goals1'],
      goals2: data['goals2'],
      datetime: data['datetime'],
      played: data['played'] == 1,
    );
  }
}
