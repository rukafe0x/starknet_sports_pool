import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:starknet/starknet.dart';
import 'create_tournament_template.dart';
import 'create_tournament_instance.dart';
import 'play_tournament_screen.dart';
import 'edit_tournament_screen.dart';
import 'leaderboard_screen.dart';
import 'my_tournaments_screen.dart';
import 'package:flutter/rendering.dart';

class MainScreen extends StatefulWidget {
  final String accountAddress;
  final Felt owner;
  final String accountNickname;

  const MainScreen(
      {Key? key,
      required this.accountAddress,
      required this.owner,
      required this.accountNickname})
      : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Starknet Sports Pool'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(38),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Account: ${widget.accountNickname}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.55,
                          child: Text(
                            widget.accountAddress,
                            style: const TextStyle(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: widget.accountAddress));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Account address copied to clipboard')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyTournamentsScreen(
                      userAddress: widget.accountAddress,
                    ),
                  ),
                );
              },
              child: const Text('Check my tournaments'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LeaderboardScreen(),
                  ),
                );
              },
              child: const Text('View Leaderboard'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PlayTournamentScreen(),
                  ),
                );
              },
              child: const Text('Play a tournament'),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to create tournament instance screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateTournamentInstance(
                      accountAddress: widget.accountAddress,
                    ),
                  ),
                );
              },
              child: Text('Create new tournament'),
            ),
            ElevatedButton(
              onPressed: () {
                // Add your logic for edit tournament
              },
              child: Text('Edit tournament'),
            ),
            if (widget.owner.toHexString() == widget.accountAddress)
              ElevatedButton(
                onPressed: () {
                  // navigate to create tournament template screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateTournamentTemplate(),
                    ),
                  );
                },
                child: Text('Create new tournament template'),
              ),
            if (widget.owner.toHexString() == widget.accountAddress)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditTournamentScreen(),
                    ),
                  );
                },
                child: Text('Edit tournament template'),
              ),
          ],
        ),
      ),
    );
  }
}
