import 'package:flutter/material.dart';
import 'package:starknet/starknet.dart';
import 'package:intl/intl.dart';
import '../services/services.dart';
import '../models/game.dart';
import '../models/tournament_template.dart';
import '../utils/utils.dart';

class CreateTournamentInstance extends StatefulWidget {
  final String accountAddress;

  const CreateTournamentInstance({Key? key, required this.accountAddress})
      : super(key: key);

  @override
  _CreateTournamentInstanceState createState() =>
      _CreateTournamentInstanceState();
}

class _CreateTournamentInstanceState extends State<CreateTournamentInstance> {
  final _formKey = GlobalKey<FormState>();
  List<TournamentTemplate> _tournamentTemplates = [];
  TournamentTemplate? _selectedTemplate;
  bool _isLoading = true;
  bool _isLoadingGames = false;
  List<Game> _games = [];
  String _name = '';
  String _description = '';
  Uint256 _entryFee = Uint256.fromInt(0);
  Felt _prizeFirstPlace = Felt.fromInt(0);
  Felt _prizeSecondPlace = Felt.fromInt(0);
  Felt _prizeThirdPlace = Felt.fromInt(0);

  @override
  void initState() {
    super.initState();
    _loadTournamentTemplates();
  }

  Future<void> _loadTournamentTemplates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch tournament templates from the blockchain
      final templates = await getTournamentTemplates();

      setState(() {
        _tournamentTemplates = templates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading templates: $e')),
      );
    }
  }

  Future<void> _loadGames(Felt templateId) async {
    setState(() {
      _isLoadingGames = true;
      _games = [];
    });

    try {
      final games = await getTournamentTemplateGames(templateId);
      setState(() {
        _games = games;
        _isLoadingGames = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingGames = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading games: $e')),
      );
    }
  }

  Future<void> _createTournamentInstance() async {
    if (_formKey.currentState!.validate() && _selectedTemplate != null) {
      try {
        final txHash = await createTournamentInstance(
          _selectedTemplate!.id.toInt(),
          _name,
          _description,
          _selectedTemplate!.imageUrl,
          _entryFee,
          _prizeFirstPlace,
          _prizeSecondPlace,
          _prizeThirdPlace,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Tournament instance created! TX: ${txHash.substring(0, 10)}...')),
        );

        // Navigate back to the previous screen
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating tournament instance: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New League'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  const Text(
                    'Select a Tournament Template',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TournamentTemplate>(
                    decoration: const InputDecoration(
                      labelText: 'Tournament Template',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Select a template'),
                    value: _selectedTemplate,
                    items: _tournamentTemplates.map((template) {
                      return DropdownMenuItem(
                        value: template,
                        child: Text(template.name),
                      );
                    }).toList(),
                    onChanged: (template) {
                      setState(() {
                        _selectedTemplate = template;
                        if (template != null) {
                          _name = template.name;
                          _description = template.description;
                          _entryFee = template.entryFee;
                          _prizeFirstPlace = template.prizeFirstPlace;
                          _prizeSecondPlace = template.prizeSecondPlace;
                          _prizeThirdPlace = template.prizeThirdPlace;

                          // Load games for this template
                          _loadGames(template.id);
                        }
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a template' : null,
                  ),
                  const SizedBox(height: 24),
                  if (_selectedTemplate != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        //TODO: Display image
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectedTemplate!.imageUrl.isNotEmpty)
                            Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: double.infinity,
                                    height: 180,
                                    color: Colors.grey.shade200,
                                    child: Image.network(
                                      _selectedTemplate!.imageUrl,
                                      fit: BoxFit.contain,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                            child: CircularProgressIndicator());
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Center(
                                            child: Icon(Icons.error_outline,
                                                color: Colors.grey, size: 48));
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: _name,
                            decoration: const InputDecoration(
                              labelText: 'New League Name',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _name = value;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: _description,
                            decoration: const InputDecoration(
                              labelText: 'New League Description',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _description = value;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: uint256ToStrkString(_entryFee),
                            decoration: const InputDecoration(
                              labelText: 'Entry Fee (STRK)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              try {
                                final entryFee = strkToUint256(value);
                                setState(() {
                                  _entryFee = entryFee;
                                });
                              } catch (e) {
                                // Handle invalid input
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: _prizeFirstPlace.toString(),
                                  decoration: const InputDecoration(
                                    labelText: '1st Place (%)',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    setState(() {
                                      _prizeFirstPlace = Felt.fromInt(
                                          int.tryParse(value) ?? 0);
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: _prizeSecondPlace.toString(),
                                  decoration: const InputDecoration(
                                    labelText: '2nd Place (%)',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    setState(() {
                                      _prizeSecondPlace = Felt.fromInt(
                                          int.tryParse(value) ?? 0);
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: _prizeThirdPlace.toString(),
                                  decoration: const InputDecoration(
                                    labelText: '3rd Place (%)',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    setState(() {
                                      _prizeThirdPlace = Felt.fromInt(
                                          int.tryParse(value) ?? 0);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Games List
                    const Text(
                      'New League Games',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    if (_isLoadingGames)
                      const Center(child: CircularProgressIndicator())
                    else if (_games.isEmpty)
                      const Text('No games found for this tournament template.')
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _games.length,
                        itemBuilder: (context, index) {
                          final game = _games[index];
                          final gameDate = DateTime.fromMillisecondsSinceEpoch(
                              game.datetime.toInt());

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          game.team1,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const Text(
                                        'vs',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          game.team2,
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(gameDate)}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _createTournamentInstance,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Create League',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
