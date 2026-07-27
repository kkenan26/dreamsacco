import 'package:flutter/material.dart';
import '../services/contribution_service.dart';

class RecordContributionScreen extends StatefulWidget {
  final String groupId;
  final String userId; // the member paying (treasurer records on their behalf, or self-service)
  final double suggestedAmount;

  const RecordContributionScreen({
    Key? key,
    required this.groupId,
    required this.userId,
    required this.suggestedAmount,
  }) : super(key: key);

  @override
  State<RecordContributionScreen> createState() => _RecordContributionScreenState();
}

class _RecordContributionScreenState extends State<RecordContributionScreen> {
  final ContributionService _service = ContributionService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.suggestedAmount.toStringAsFixed(0));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      await _service.recordPayment(
        userId: widget.userId,
        groupId: widget.groupId,
        amount: double.parse(_amountController.text),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contribution recorded successfully')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to record payment: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Contribution')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Confirm the amount contributed for this month.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (UGX)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter an amount';
                  if (double.tryParse(value) == null) return 'Enter a valid number';
                  if (double.parse(value) <= 0) return 'Amount must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirm Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
