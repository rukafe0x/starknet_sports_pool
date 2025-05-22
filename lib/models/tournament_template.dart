import 'package:starknet/starknet.dart';
import '../utils/utils.dart';

class TournamentTemplate {
  final Felt id;
  final String name;
  final String description;
  final String imageUrl;
  final Uint256 entryFee;
  final Felt prizeFirstPlace;
  final Felt prizeSecondPlace;
  final Felt prizeThirdPlace;
  final Felt gamesCount;

  TournamentTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.entryFee,
    required this.prizeFirstPlace,
    required this.prizeSecondPlace,
    required this.prizeThirdPlace,
    required this.gamesCount,
  });

  // Constructor to parse Felt data from blockchain
  factory TournamentTemplate.fromFelt(Map<String, dynamic> data, Felt id) {
    return TournamentTemplate(
      id: id,
      name: feltToAsciiString(data['name']),
      description: feltToAsciiString(data['description']),
      imageUrl: feltToAsciiString(data['image_url']),
      entryFee:
          Uint256.fromFeltList([data['entry_fee_low'], data['entry_fee_high']]),
      prizeFirstPlace: data['prize_first_place'],
      prizeSecondPlace: data['prize_second_place'],
      prizeThirdPlace: data['prize_third_place'],
      gamesCount: data['games_count'],
    );
  }
}
