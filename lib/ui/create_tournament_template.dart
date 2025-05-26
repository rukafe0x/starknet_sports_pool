import 'package:flutter/material.dart';
import '../services/services.dart';
import '../utils/utils.dart';
import './create_tournament_template_games.dart';

class CreateTournamentTemplate extends StatefulWidget {
  const CreateTournamentTemplate({Key? key}) : super(key: key);

  @override
  _CreateTournamentTemplateState createState() =>
      _CreateTournamentTemplateState();
}

class _CreateTournamentTemplateState extends State<CreateTournamentTemplate> {
  final _formKey = GlobalKey<FormState>();
  int _tournamentTemplateId = 0;
  String _tournamentName = '';
  String _tournamentDescription = '';
  String _tournamentImage = '';
  String _entryFee = '';
  int _prizeFirstPlace = 0;
  int _prizeSecondPlace = 0;
  int _prizeThirdPlace = 0;
  bool _isLoading = false;

  bool _showImagePreview = false;

  bool _areAllFieldsFilled() {
    return _tournamentName.isNotEmpty &&
        _tournamentDescription.isNotEmpty &&
        _tournamentImage.isNotEmpty &&
        _entryFee.isNotEmpty &&
        _prizeFirstPlace > 0 &&
        _prizeSecondPlace > 0 &&
        _prizeThirdPlace > 0;
  }

  @override
  Widget build(BuildContext context) {
    Future<void> _saveTournamentTemplate(
        int tournamentTemplateId,
        String tournamentName,
        String tournamentDescription,
        String tournamentImage,
        BigInt entryFee,
        BigInt prizeFirstPlace,
        BigInt prizeSecondPlace,
        BigInt prizeThirdPlace) async {
      await saveTournamentTemplate(
          tournamentTemplateId,
          tournamentName,
          tournamentDescription,
          tournamentImage,
          entryFee,
          prizeFirstPlace,
          prizeSecondPlace,
          prizeThirdPlace);
      setState(() {});
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Tournament Template'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (value) => setState(() => _tournamentName = value),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter a name' : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (value) =>
                  setState(() => _tournamentDescription = value),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Image URL'),
              onChanged: (value) => setState(() {
                _tournamentImage = value;
                _showImagePreview = false;
              }),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter an image URL' : null,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                if (_tournamentImage.isNotEmpty) {
                  setState(() {
                    _showImagePreview = true;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Show Image Preview'),
            ),
            if (_showImagePreview && _tournamentImage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Image.network(
                  _tournamentImage,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Text('Error loading image: $error');
                  },
                ),
              ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Entry Fee'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() => _entryFee = value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an entry fee';
                }
                try {
                  // Validate that it's a valid number
                  final amount = double.tryParse(value);
                  if (amount == null || amount < 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                } catch (e) {
                  return 'Please enter a valid number';
                }
              },
            ),
            TextFormField(
              decoration:
                  const InputDecoration(labelText: 'Prize First Place (%)'),
              keyboardType: TextInputType.number,
              onChanged: (value) =>
                  setState(() => _prizeFirstPlace = int.tryParse(value) ?? 0),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter first place prize' : null,
            ),
            TextFormField(
              decoration:
                  const InputDecoration(labelText: 'Prize Second Place (%)'),
              keyboardType: TextInputType.number,
              onChanged: (value) =>
                  setState(() => _prizeSecondPlace = int.tryParse(value) ?? 0),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter second place prize' : null,
            ),
            TextFormField(
              decoration:
                  const InputDecoration(labelText: 'Prize Third Place (%)'),
              keyboardType: TextInputType.number,
              onChanged: (value) =>
                  setState(() => _prizeThirdPlace = int.tryParse(value) ?? 0),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter third place prize' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _areAllFieldsFilled()
                  ? () async {
                      final tournamentTemplateId =
                          await getTournamentTemplateId();
                      if (_formKey.currentState!.validate()) {
                        // Print values to console
                        print('Name: $_tournamentName');
                        print('Description: $_tournamentDescription');
                        print('Image URL: $_tournamentImage');
                        print('Entry Fee: $_entryFee');
                        print('Prize First Place: $_prizeFirstPlace%');
                        print('Prize Second Place: $_prizeSecondPlace%');
                        print('Prize Third Place: $_prizeThirdPlace%');
                        await _saveTournamentTemplate(
                            tournamentTemplateId,
                            _tournamentName,
                            _tournamentDescription,
                            _tournamentImage,
                            (strkToUint256(_entryFee).high.toBigInt() << 128) |
                                strkToUint256(_entryFee).low.toBigInt(),
                            BigInt.from(_prizeFirstPlace),
                            BigInt.from(_prizeSecondPlace),
                            BigInt.from(_prizeThirdPlace));
                      }
                      // Navigate to the next screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CreateTournamentTemplateGames(
                                tournamentName: _tournamentName,
                                tournamentId: tournamentTemplateId)),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create Tournament Template'),
            ),
          ],
        ),
      ),
    );
  }
}
