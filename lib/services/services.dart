// ignore_for_file: prefer_const_declarations, avoid_print

import 'package:starknet/starknet.dart';
import 'package:starknet_provider/starknet_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:starknet_sports_pool/utils/utils.dart';
import '../models/game.dart';
import '../models/tournament_template.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

final _storage = const FlutterSecureStorage();

Future<String> getSecretAccountAddress() async {
  final accountData = await _storage.read(key: 'selected_account');
  if (accountData == null) return '';
  final data = jsonDecode(accountData);
  return data['address'] ?? '';
}

Future<String> getSecretAccountPrivateKey() async {
  final accountData = await _storage.read(key: 'selected_account');
  if (accountData == null) return '';
  final data = jsonDecode(accountData);
  return data['privateKey'] ?? '';
}

final secretAccountAddress = getSecretAccountAddress();
final secretAccountPrivateKey = getSecretAccountPrivateKey();

final provider =
    JsonRpcProvider(nodeUri: Uri.parse(dotenv.env['STARKNET_NODE_URI'] ?? ''));
final contractAddress = dotenv.env['CONTRACT_ADDRESS'] ?? '';

Future<Account> getSignerAccount() async {
  final address = await getSecretAccountAddress();
  final privateKey = await getSecretAccountPrivateKey();
  return getAccount(
    accountAddress: Felt.fromHexString(address),
    privateKey: Felt.fromHexString(privateKey),
    nodeUri: Uri.parse(dotenv.env['STARKNET_NODE_URI'] ?? ''),
  );
}

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
    error: (error) => throw Exception("Failed to get owner value"),
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
    int templateId,
    String name,
    String description,
    String imageUrl,
    Uint256 entryFee,
    Felt prizeFirstPlace,
    Felt prizeSecondPlace,
    Felt prizeThirdPlace) async {
  final account = await getSignerAccount();
  final response = await account.execute(functionCalls: [
    FunctionCall(
      contractAddress: Felt.fromHexString(contractAddress),
      entryPointSelector: getSelectorByName("save_tournament_instance"),
      calldata: [
        Felt.fromInt(0),
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
  final account = await getSignerAccount();
  final gamesCount = 0;
  final response = await account.execute(functionCalls: [
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
  final account = await getSignerAccount();
  final gamesCount = games.length;
  List<Felt> calldata = [];
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
  final response = await account.execute(functionCalls: [
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
          'id': Felt.fromInt(i), // Use the index as the game ID
          'team1': feltToAsciiString(result[i * 6 + 1]),
          'team2': feltToAsciiString(result[i * 6 + 2]),
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

Future<List<Map<String, dynamic>>> getTournamentInstances() async {
  final result = await provider.call(
    request: FunctionCall(
        contractAddress: Felt.fromHexString(contractAddress),
        entryPointSelector: getSelectorByName("get_tournament_instances"),
        calldata: []),
    blockId: BlockId.latest,
  );

  return result.when(
    result: (result) {
      List<Map<String, dynamic>> instances = [];
      final arrayLength = result[0].toInt();

      for (var i = 0; i < arrayLength; i++) {
        final Map<String, dynamic> instanceData = {
          'instance_id': result[i * 10 + 1],
          'tournament_template_id': result[i * 10 + 2],
          'name': result[i * 10 + 3] != Felt.fromInt(0)
              ? feltToAsciiString(result[i * 10 + 3])
              : '_',
          'description': result[i * 10 + 4] != Felt.fromInt(0)
              ? feltToAsciiString(result[i * 10 + 4])
              : '_',
          'image_url': result[i * 10 + 5] != Felt.fromInt(0)
              ? feltToAsciiString(result[i * 10 + 5])
              : '_',
          'entry_fee':
              Uint256.fromFeltList([result[i * 10 + 6], result[i * 10 + 7]]),
          'prize_first_place': result[i * 10 + 8],
          'prize_second_place': result[i * 10 + 9],
          'prize_third_place': result[i * 10 + 10],
        };
        instances.add(instanceData);
      }
      return instances;
    },
    error: (error) => throw Exception("Failed to get tournament instances"),
  );
}

Future<String> saveUserInstancePrediction(
    int instanceId, List<Map<String, dynamic>> predictions) async {
  final account = await getSignerAccount();
  List<Felt> calldata = [];
  calldata.add(Felt.fromInt(instanceId));
  calldata.add(Felt.fromInt(predictions.length));
  for (var prediction in predictions) {
    calldata.add(Felt.fromInt(prediction['prediction']));
  }
  final response = await account.execute(functionCalls: [
    FunctionCall(
      contractAddress: Felt.fromHexString(contractAddress),
      entryPointSelector: getSelectorByName("save_user_instance_prediction"),
      calldata: calldata,
    ),
  ]);

  final txHash = response.when(
    result: (result) => result.transaction_hash,
    error: (err) => throw Exception("Failed to save predictions"),
  );

  await waitForAcceptance(transactionHash: txHash, provider: provider);

  print('Saving predictions TX: $txHash');
  return txHash;
}

Future<String> editGameResult(
    int tournamentId, int gameId, Felt goals1, Felt goals2, bool played) async {
  final account = await getSignerAccount();
  final response = await account.execute(functionCalls: [
    FunctionCall(
      contractAddress: Felt.fromHexString(contractAddress),
      entryPointSelector: getSelectorByName("edit_game_result"),
      calldata: [
        Felt.fromInt(tournamentId),
        Felt.fromInt(gameId),
        goals1,
        goals2,
        Felt.fromInt(played
            ? 1
            : 0), // Convert boolean to Felt (1 for true, 0 for false)
      ],
    ),
  ]);

  final txHash = response.when(
    result: (result) => result.transaction_hash,
    error: (err) => throw Exception("Failed to edit game result"),
  );

  print('Editing game result TX: $txHash');
  return txHash;
}

Future<List<Map<String, dynamic>>> getInstanceLeaderboard(
    int instanceId) async {
  final result = await provider.call(
    request: FunctionCall(
      contractAddress: Felt.fromHexString(contractAddress),
      entryPointSelector: getSelectorByName("get_instance_leaderboard"),
      calldata: [Felt.fromInt(instanceId)],
    ),
    blockId: BlockId.latest,
  );

  return result.when(
    result: (result) {
      List<Map<String, dynamic>> leaderboard = [];
      final arrayLength = result[0].toInt();

      for (var i = 0; i < arrayLength; i++) {
        leaderboard.add({
          'address': result[i * 2 + 1].toHexString(),
          'points': result[i * 2 + 2].toInt(),
        });
      }

      // Sort by points in descending order
      leaderboard.sort((a, b) => b['points'].compareTo(a['points']));
      return leaderboard;
    },
    error: (error) => throw Exception("Failed to get leaderboard"),
  );
}

Future<List<Map<String, dynamic>>> getUserInstances(String userAddress) async {
  final result = await provider.call(
    request: FunctionCall(
      contractAddress: Felt.fromHexString(contractAddress),
      entryPointSelector: getSelectorByName("get_user_instances"),
      calldata: [Felt.fromHexString(userAddress)],
    ),
    blockId: BlockId.latest,
  );

  return result.when(
    result: (result) {
      List<Map<String, dynamic>> instances = [];
      final arrayLength = result[0].toInt();

      for (var i = 0; i < arrayLength; i++) {
        instances.add({
          'instance_id': result[i + 1].toInt(),
        });
      }
      return instances;
    },
    error: (error) => throw Exception("Failed to get user instances"),
  );
}

Future<List<int>> getUserInstancePredictions(
    Felt userAddress, int instanceId) async {
  final result = await provider.call(
    request: FunctionCall(
      contractAddress: Felt.fromHexString(contractAddress),
      entryPointSelector: getSelectorByName("get_user_instance_predictions"),
      calldata: [userAddress, Felt.fromInt(instanceId)],
    ),
    blockId: BlockId.latest,
  );

  return result.when(
    result: (result) {
      List<int> predictions = [];
      final arrayLength = result[0].toInt();

      for (var i = 0; i < arrayLength; i++) {
        predictions.add(result[i + 1].toInt());
      }
      return predictions;
    },
    error: (error) => throw Exception("Failed to get user predictions"),
  );
}

Future<List<int>> getUserInstancePredictionsList(String userAddress) async {
  final result = await provider.call(
    request: FunctionCall(
      contractAddress: Felt.fromHexString(contractAddress),
      entryPointSelector:
          getSelectorByName("get_user_instance_predictions_list"),
      calldata: [Felt.fromHexString(userAddress)],
    ),
    blockId: BlockId.latest,
  );

  return result.when(
    result: (result) {
      List<int> instanceIds = [];
      final arrayLength = result[0].toInt();

      for (var i = 0; i < arrayLength; i++) {
        instanceIds.add(result[i + 1].toInt());
      }
      return instanceIds;
    },
    error: (error) =>
        throw Exception("Failed to get user instance predictions list"),
  );
}

Future<String> approveEntryFee(int instanceId, Uint256 entryFee) async {
  final account = await getSignerAccount();
  final strkTokenAddress = dotenv.env['STRK_TOKEN_ADDRESS'] ?? '';
  final calldata = [
    Felt.fromHexString(contractAddress), // spender (contract address)
    entryFee.low, // amount low
    entryFee.high, // amount high
  ];
  final response = await account.execute(functionCalls: [
    FunctionCall(
      contractAddress: Felt.fromHexString(strkTokenAddress),
      entryPointSelector: getSelectorByName("approve"),
      calldata: calldata,
    ),
  ]);

  final txHash = response.when(
    result: (result) => result.transaction_hash,
    error: (err) => throw Exception("Failed to approve entry fee"),
  );

  await waitForAcceptance(transactionHash: txHash, provider: provider);

  print('Approving entry fee TX: $txHash');
  return txHash;
}

// Placeholder: Get STRK balance for an address
Future<Uint256> getStrkBalance(String address) async {
  final strkTokenAddress = dotenv.env['STRK_TOKEN_ADDRESS'].toString() ?? '';
  final account = await getSignerAccount();
  final strk =
      ERC20(account: account, address: Felt.fromHexString(strkTokenAddress));
  final balance = await strk.balanceOf(Felt.fromHexString(address));
  return balance;
}

// Placeholder: Get ETH balance for an address
Future<Uint256> getEthBalance(String address) async {
  final ethTokenAddress = dotenv.env['ETH_TOKEN_ADDRESS'].toString() ?? '';
  final account = await getSignerAccount();
  final eth =
      ERC20(account: account, address: Felt.fromHexString(ethTokenAddress));
  final balance = await eth.balanceOf(Felt.fromHexString(address));
  return balance;
}

// Placeholder: Withdraw STRK to another address
Future<void> withdrawStrk(String from, String to, Uint256 amount) async {
  final account = await getSignerAccount();
  final strkTokenAddress = dotenv.env['STRK_TOKEN_ADDRESS'].toString() ?? '';
  final erc20 =
      ERC20(account: account, address: Felt.fromHexString(strkTokenAddress));
  var trx = await erc20.transfer(
    Felt.fromHexString(to),
    amount,
  );
  print('Transfer Transaction: $trx');
  await waitForAcceptance(
    transactionHash: trx,
    provider: provider,
  );
}

// Placeholder: Withdraw ETH to another address
Future<void> withdrawEth(String from, String to, Uint256 amount) async {
  final account = await getSignerAccount();
  final ethTokenAddress = dotenv.env['ETH_TOKEN_ADDRESS'].toString() ?? '';
  final eth =
      ERC20(account: account, address: Felt.fromHexString(ethTokenAddress));
  var trx = await eth.transfer(
    Felt.fromHexString(to),
    amount,
  );
  print('Transfer Transaction: $trx');
  await waitForAcceptance(
    transactionHash: trx,
    provider: provider,
  );
}

// Check prize for a user in a tournament instance
Future<BigInt> checkPrice(int instanceId, String userAddress) async {
  // TODO: Replace with actual contract call
  // Simulate a prize for demonstration
  await Future.delayed(const Duration(seconds: 1));
  return BigInt.from(1000000000000000000); // 1 token as example
}

// Pay prize to a user in a tournament instance
Future<void> payPrice(int instanceId, String userAddress) async {
  // TODO: Replace with actual contract call
  await Future.delayed(const Duration(seconds: 2));
}
