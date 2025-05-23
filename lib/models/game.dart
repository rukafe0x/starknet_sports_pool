import 'package:starknet/starknet.dart';
import '../utils/utils.dart';

class Game {
  final Felt id;
  final String team1;
  final String team2;
  final Felt goals1;
  final Felt goals2;
  final Felt datetime;
  final bool played;

  Game({
    required this.id,
    required this.team1,
    required this.team2,
    required this.goals1,
    required this.goals2,
    required this.datetime,
    required this.played,
  });

  factory Game.fromFelt(Map<String, dynamic> data) {
    return Game(
      id: data['id'] as Felt,
      team1: data['team1'].toString(),
      team2: data['team2'].toString(),
      goals1: data['goals1'] as Felt,
      goals2: data['goals2'] as Felt,
      datetime: data['datetime'] as Felt,
      played: (data['played'] as Felt).toInt() == 1,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Game &&
        other.id == id &&
        other.team1 == team1 &&
        other.team2 == team2 &&
        other.goals1 == goals1 &&
        other.goals2 == goals2 &&
        other.datetime == datetime &&
        other.played == played;
  }

  @override
  int get hashCode {
    return Object.hash(id, team1, team2, goals1, goals2, datetime, played);
  }
}
