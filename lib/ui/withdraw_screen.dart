import 'package:flutter/material.dart';
import 'package:starknet/starknet.dart';
import 'package:starknet_sports_pool/utils/utils.dart';
import '../services/services.dart';

class WithdrawScreen extends StatefulWidget {
  final String accountAddress;
  const WithdrawScreen({Key? key, required this.accountAddress})
      : super(key: key);

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  Uint256? strkBalance;
  Uint256? ethBalance;
  String _selectedToken = 'STRK';
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  Future<void> _loadBalances() async {
    setState(() => _isLoading = true);
    strkBalance = await getStrkBalance(widget.accountAddress);
    ethBalance = await getEthBalance(widget.accountAddress);
    setState(() => _isLoading = false);
  }

  Future<void> _withdraw() async {
    final recipient = _recipientController.text.trim();
    final amount = parseTokenAmount(_amountController.text.trim());
    if (recipient.isEmpty || amount <= BigInt.from(0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid recipient and amount')),
      );
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Withdrawal'),
        content: Text(
          'You are about to send '
          '${formatTokenBalance(Uint256.fromBigInt(amount), decimals: 18)} $_selectedToken to:\n$recipient\n\n'
          '⚠️ Ensure the recipient address is correct. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      if (_selectedToken == 'STRK') {
        await withdrawStrk(
            widget.accountAddress, recipient, Uint256.fromBigInt(amount));
      } else {
        await withdrawEth(
            widget.accountAddress, recipient, Uint256.fromBigInt(amount));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Withdrawal successful!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Withdraw Balance')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButton<String>(
                    value: _selectedToken,
                    items: const [
                      DropdownMenuItem(value: 'STRK', child: Text('STRK')),
                      DropdownMenuItem(value: 'ETH', child: Text('ETH')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedToken = value;
                        });
                      }
                    },
                  ),
                  Text('${_selectedToken} Balance: '
                      '${_selectedToken == 'STRK' ? (formatTokenBalance(strkBalance ?? Uint256.fromInt(0), decimals: 18)) : (formatTokenBalance(ethBalance ?? Uint256.fromInt(0), decimals: 18))}'),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _recipientController,
                    decoration: const InputDecoration(
                      labelText: 'Recipient Address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount ($_selectedToken)',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _withdraw,
                    child: const Text('Withdraw'),
                  ),
                ],
              ),
            ),
    );
  }
}
