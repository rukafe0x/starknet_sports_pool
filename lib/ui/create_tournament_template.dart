import 'package:flutter/material.dart';
import '../services/services.dart';
import './create_tournament_template_games.dart';

class CreateTournamentTemplate extends StatefulWidget {
  const CreateTournamentTemplate({Key? key}) : super(key: key);

  @override
  _CreateTournamentTemplateState createState() =>
      _CreateTournamentTemplateState();
}

class _CreateTournamentTemplateState extends State<CreateTournamentTemplate> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _description = '';
  String _imageUrl = '';
  double _entryFee = 0.0;
  double _prizeFirstPlace = 0.0;
  double _prizeSecondPlace = 0.0;
  double _prizeThirdPlace = 0.0;

  bool _showImagePreview = false;

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
              onChanged: (value) => setState(() => _name = value),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter a name' : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (value) => setState(() => _description = value),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Image URL'),
              onChanged: (value) => setState(() {
                _imageUrl = value;
                _showImagePreview = false;
              }),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter an image URL' : null,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                if (_imageUrl.isNotEmpty) {
                  setState(() {
                    _showImagePreview = true;
                  });
                }
              },
              child: const Text('Show Image Preview'),
            ),
            if (_showImagePreview && _imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Image.network(
                  _imageUrl,
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
              onChanged: (value) =>
                  setState(() => _entryFee = double.tryParse(value) ?? 0.0),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter an entry fee' : null,
            ),
            TextFormField(
              decoration:
                  const InputDecoration(labelText: 'Prize First Place (%)'),
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(
                  () => _prizeFirstPlace = double.tryParse(value) ?? 0.0),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter first place prize' : null,
            ),
            TextFormField(
              decoration:
                  const InputDecoration(labelText: 'Prize Second Place (%)'),
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(
                  () => _prizeSecondPlace = double.tryParse(value) ?? 0.0),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter second place prize' : null,
            ),
            TextFormField(
              decoration:
                  const InputDecoration(labelText: 'Prize Third Place (%)'),
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(
                  () => _prizeThirdPlace = double.tryParse(value) ?? 0.0),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter third place prize' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final tournamentTemplateId = await getTournamentTemplateId();
                if (_formKey.currentState!.validate()) {
                  // Print values to console
                  print('Name: $_name');
                  print('Description: $_description');
                  print('Image URL: $_imageUrl');
                  print('Entry Fee: $_entryFee');
                  print('Prize First Place: $_prizeFirstPlace%');
                  print('Prize Second Place: $_prizeSecondPlace%');
                  print('Prize Third Place: $_prizeThirdPlace%');
                  await _saveTournamentTemplate(
                      tournamentTemplateId,
                      _name,
                      _description,
                      _imageUrl,
                      BigInt.from(_entryFee),
                      BigInt.from(_prizeFirstPlace),
                      BigInt.from(_prizeSecondPlace),
                      BigInt.from(_prizeThirdPlace));
                }
                // Navigate to the next screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CreateTournamentTemplateGames(
                          tournamentName: _name,
                          tournamentId: tournamentTemplateId)),
                );
              },
              child: const Text('Create Tournament Template'),
            ),
          ],
        ),
      ),
    );
  }
}
