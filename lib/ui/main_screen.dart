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
import 'withdraw_screen.dart';

class FunButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  const FunButton({required this.onPressed, required this.child, Key? key})
      : super(key: key);

  @override
  State<FunButton> createState() => _FunButtonState();
}

class _FunButtonState extends State<FunButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 6,
              textStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            onPressed: widget.onPressed,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

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
        title: const Text(
          'Starknet Sports Pool',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFFF76300),
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
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.55,
                          child: Text(
                            widget.accountAddress,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.white),
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
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'lib/assets/backg.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Players Section
                          Text('For Players',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          const SizedBox(height: 8),
                          FunButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PlayTournamentScreen(),
                                  ));
                            },
                            child: const Text('Play a League'),
                          ),
                          FunButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MyTournamentsScreen(
                                        userAddress: widget.accountAddress),
                                  ));
                            },
                            child: const Text('Check my Results'),
                          ),
                          const SizedBox(height: 24),

                          // Managers Section
                          Text('For Managers',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          const SizedBox(height: 8),
                          FunButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CreateTournamentInstance(
                                            accountAddress:
                                                widget.accountAddress),
                                  ));
                            },
                            child: const Text('Create a New league'),
                          ),
                          const SizedBox(height: 24),

                          // Admins Section
                          if (widget.owner ==
                              Felt.fromHexString(widget.accountAddress)) ...[
                            Text('For Admins',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            const SizedBox(height: 8),
                            FunButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CreateTournamentTemplate(),
                                    ));
                              },
                              child: const Text('Create a tournament template'),
                            ),
                            FunButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const EditTournamentScreen(),
                                    ));
                              },
                              child: const Text('Edit tournament results'),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Wallet Section
                          Text('Wallet',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          const SizedBox(height: 8),
                          Column(
                            children: [
                              FunButton(
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => WithdrawScreen(
                                            accountAddress:
                                                widget.accountAddress),
                                      ));
                                },
                                child: const Text('Check/Withdraw balance'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
