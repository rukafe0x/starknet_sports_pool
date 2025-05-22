// ignore_for_file: prefer_const_declarations, avoid_print

import 'package:starknet/starknet.dart';
import 'package:starknet_provider/starknet_provider.dart';
import '../models/game.dart';
import '../models/tournament_template.dart';

final provider = JsonRpcProvider(
    nodeUri: Uri.parse(
        'https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_7/DSuGip93IA2Lr6nNhaCN4oS0Je2n1xCF'));
final contractAddress =
    '0x0441590e4e9406182057670298319b3c38d4322c1ce2a5147ead92b2d566081c';
final secretAccountAddress =
    "0x073a4176e97c29044dd1717727aa752ec56af04113e0c9277b798ee7a317163b";
final secretAccountPrivateKey =
    "0x059b1a1e0b1ec4e5f69ef80ab281b12a5509fe67a4f2fb0c40964d30f50e798f";
final signeraccount = getAccount(
  accountAddress: Felt.fromHexString(secretAccountAddress),
  privateKey: Felt.fromHexString(secretAccountPrivateKey),
  nodeUri: Uri.parse(
      'https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_7/DSuGip93IA2Lr6nNhaCN4oS0Je2n1xCF'),
);

Future<Felt> getOwner() async {
  final result = await provider.call(
    request: FunctionCall(
        contractAddress: Felt.fromHexString(contractAddress),
        entryPointSelector: getSelectorByName("get_owner"),
        calldata: []),
    blockId: BlockId.latest,
  );
  return result.when(
    result: (result) => result[0],
    error: (error) => throw Exception("Failed to get counter value"),
  );
}

Future<int> getTournamentTemplateId() async {
  final result = await provider.call(
    request: FunctionCall(
        contractAddress: Felt.fromHexString(contractAddress),
        entryPointSelector: getSelectorByName("get_tournament_template_count"),
        calldata: []),
    blockId: BlockId.latest,
  );
  return result.when(
    result: (result) => result[0].toInt(),
    error: (error) => throw Exception("Failed to get tournament template id"),
  );
}

Future<List<TournamentTemplate>> getTournamentTemplates() async {
  final result = await provider.call(
    request: FunctionCall(
        contractAddress: Felt.fromHexString(contractAddress),
        entryPointSelector: getSelectorByName("get_tournament_templates"),
        calldata: []),
    blockId: BlockId.latest,
  );

  return result.when(
    result: (result) {
      // Parse the result into tournament templates
      // first field is array length
      List<TournamentTemplate> templates = [];
      final arrayLength = result[0].toInt();

      // Parse real blockchain data
      print("Parsing blockchain response: ${result.length} templates found");

      for (var i = 0; i < arrayLength; i++) {
        // Create a Map from the Felt data structure
        final Map<String, dynamic> templateData = {
          'name': result[i * 9 +
              1], // Example - adjust indexes based on your contract's response structure
          'description': result[i * 9 + 2],
          'image_url': result[i * 9 + 3],
          'entry_fee_low': result[i * 9 + 4], //low 64 bits
          'entry_fee_high': result[i * 9 + 5], //high 64 bits
          'prize_first_place': result[i * 9 + 6],
          'prize_second_place': result[i * 9 + 7],
          'prize_third_place': result[i * 9 + 8],
          'games_count': result[i * 9 + 9],
        };

        // Use the fromFelt constructor to create a TournamentTemplate
        templates
            .add(TournamentTemplate.fromFelt(templateData, Felt.fromInt(i)));
      }

      // If no templates were found or there was an error parsing, use mock data
      if (templates.isEmpty) {
        print("No templates found, using mock data");
        templates = [
          TournamentTemplate(
            id: Felt.fromInt(0),
            name: "World Cup 2022",
            description: "FIFA World Cup tournament",
            imageUrl: "https://example.com/worldcup.jpg",
            entryFee: Uint256.fromBigInt(BigInt.from(1000000000000000000)),
            prizeFirstPlace: Felt(BigInt.from(70)),
            prizeSecondPlace: Felt(BigInt.from(20)),
            prizeThirdPlace: Felt(BigInt.from(10)),
            gamesCount: Felt.fromInt(64),
          ),
          TournamentTemplate(
            id: Felt.fromInt(1),
            name: "Euro 2024",
            description: "European Championship tournament",
            imageUrl: "https://example.com/euro.jpg",
            entryFee: Uint256.fromBigInt(BigInt.from(1500000000000000000)),
            prizeFirstPlace: Felt(BigInt.from(60)),
            prizeSecondPlace: Felt(BigInt.from(30)),
            prizeThirdPlace: Felt(BigInt.from(10)),
            gamesCount: Felt.fromInt(51),
          ),
        ];
      }

      return templates;
    },
    error: (error) => throw Exception("Failed to get tournament templates"),
  );
}

Future<String> createTournamentInstance(
    int instanceId,
    int templateId,
    String name,
    String description,
    String imageUrl,
    Uint256 entryFee,
    Felt prizeFirstPlace,
    Felt prizeSecondPlace,
    Felt prizeThirdPlace) async {
  // in cairo:
  //   fn save_tournament_instance(ref self: ContractState, tournament_instance_id: u8, tournament_instance: tournament_instance) {
  //   where:
  //       struct tournament_instance {
  //     instance_id: u8,
  //     tournament_template_id: u8,
  //     name: felt252,
  //     description: felt252,
  //     image_url: felt252,
  //     entry_fee: u256,
  //     prize_first_place: u256,
  //     prize_second_place: u256,
  //     prize_third_place: u256,
  // }
  final response = await signeraccount.execute(functionCalls: [
    FunctionCall(
      contractAddress: Felt.fromHexString(contractAddress),
      entryPointSelector: getSelectorByName("save_tournament_instance"),
      calldata: [
        Felt.fromInt(templateId),
        Felt.fromInt(instanceId),
        Felt.fromInt(templateId),
        Felt.fromString(name),
        Felt.fromString(description),
        Felt.fromString(imageUrl),
        entryFee.low, //low 64 bits just for entry fee
        entryFee.high, //high 64 bits just for entry fee
        prizeFirstPlace,
        prizeSecondPlace,
        prizeThirdPlace,
      ],
    ),
  ]);

  final txHash = response.when(
    result: (result) => result.transaction_hash,
    error: (err) => throw Exception("Failed to create tournament instance"),
  );

  print('Creating tournament instance TX : $txHash');
  return txHash;
}

Future<String> saveTournamentTemplate(
    int tournamentTemplateId,
    String tournamentName,
    String tournamentDescription,
    String tournamentImage,
    BigInt entryFee,
    BigInt prizeFirstPlace,
    BigInt prizeSecondPlace,
    BigInt prizeThirdPlace) async {
  final gamesCount = 0;
  //AQU VOY PARECE QUE FALTA UN ID
  final response = await signeraccount.execute(functionCalls: [
    FunctionCall(
      contractAddress: Felt.fromHexString(contractAddress),
      entryPointSelector: getSelectorByName("save_tournament_template"),
      calldata: [
        Felt.fromInt(tournamentTemplateId),
        Felt.fromString(tournamentName),
        Felt.fromString(tournamentDescription),
        Felt.fromString(tournamentImage),
        Felt(entryFee & BigInt.from(0xFFFFFFFFFFFFFFFF)),
        Felt(entryFee >> 64),
        Felt(prizeFirstPlace),
        Felt(prizeSecondPlace),
        Felt(prizeThirdPlace),
        Felt.fromInt(gamesCount),
      ],
    ),
  ]);

  final txHash = response.when(
    result: (result) => result.transaction_hash,
    error: (err) => throw Exception("Failed to execute"),
  );

  print('printing save tournament template TX : $txHash');
  return txHash;
}

Future<String> saveTournamentTemplateGames(
    int tournamentId, List<Game> games) async {
  final gamesCount = games.length;
  //define calldata as array of felt
  List<Felt> calldata = [];
  // set calldata with Game values
  calldata.add(Felt.fromInt(tournamentId));
  calldata.add(Felt.fromInt(gamesCount));
  for (var game in games) {
    calldata.addAll([
      Felt.fromString(game.team1),
      Felt.fromString(game.team2),
      game.goals1,
      game.goals2,
      game.datetime,
      Felt.fromInt(game.played ? 1 : 0)
    ]);
  }
  final response = await signeraccount.execute(functionCalls: [
    FunctionCall(
      contractAddress: Felt.fromHexString(contractAddress),
      entryPointSelector: getSelectorByName("save_tournament_template_games"),
      calldata: calldata,
    ),
  ]);

  final txHash = response.when(
    result: (result) => result.transaction_hash,
    error: (err) => throw Exception("Failed to execute"),
  );

  print('printing save tournament template games TX : $txHash');
  return txHash;
}

// Get games for a specific tournament template
Future<List<Game>> getTournamentTemplateGames(Felt tournamentTemplateId) async {
  final result = await provider.call(
    request: FunctionCall(
        contractAddress: Felt.fromHexString(contractAddress),
        entryPointSelector: getSelectorByName("get_tournament_template_games"),
        calldata: [tournamentTemplateId]),
    blockId: BlockId.latest,
  );

  return result.when(
    result: (result) {
      // Parse the result into games
      List<Game> games = [];

      // First element is array length
      if (result.isEmpty) {
        return games;
      }

      final arrayLength = result[0].toInt();
      print("Parsing games, found $arrayLength games");

      // Each game has 6 fields: team1, team2, goals1, goals2, datetime, played
      for (var i = 0; i < arrayLength; i++) {
        final Map<String, dynamic> gameData = {
          'team1': result[i * 6 + 1],
          'team2': result[i * 6 + 2],
          'goals1': result[i * 6 + 3],
          'goals2': result[i * 6 + 4],
          'datetime': result[i * 6 + 5],
          'played': result[i * 6 + 6],
        };

        games.add(Game.fromFelt(gameData));
      }

      // If no games were found, return empty list
      if (games.isEmpty && arrayLength > 0) {
        print("Error parsing games, using mock data");
        // You could add mock games here if needed
      }

      return games;
    },
    error: (error) {
      print("Error getting games: $error");
      return [];
    },
  );
}
