import 'package:flutter/material.dart';
import '../../services/group.dart';
import '../../services/credit_score.dart';
import '../../models/group.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _goalAmountController = TextEditingController();
  final _goalDescriptionController = TextEditingController();
  final _contributionController = TextEditingController();
  final _frequencyValueController = TextEditingController(text: '1');
  String _selectedType = 'public'; // dropdown default
  String _selectedFrequencyUnit = 'months';
  bool _isSubmitting = false;

  final GroupService _groupService = GroupService(
    creditScoreService: MockCreditScoreService(),
  );

  // TODO: replace with FirebaseAuth.instance.currentUser!.uid once auth is wired in
  final String _currentUserId = 'test_admin_123';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _goalAmountController.dispose();
    _goalDescriptionController.dispose();
    _contributionController.dispose();
    _frequencyValueController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    // Validate all fields first
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      Group newGroup = Group.create(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        adminId: _currentUserId,
        treasurerId: _currentUserId, // admin is treasurer until reassigned later
        goalAmount: double.parse(_goalAmountController.text.trim()),
        goalDescription: _goalDescriptionController.text.trim(),
        contribution: double.parse(_contributionController.text.trim()),
        contributionFrequencyValue: int.parse(_frequencyValueController.text.trim()),
        contributionFrequencyUnit: _selectedFrequencyUnit,
      );

      String newGroupId = await _groupService.createGroup(newGroup);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group created! ID: $newGroupId')),
      );

      Navigator.pop(context); // go back to wherever Group List will live
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Group Name'),
                validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Enter a group name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Enter a description' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Group Type'),
                items: const [
                  DropdownMenuItem(value: 'public', child: Text('Public')),
                  DropdownMenuItem(value: 'private', child: Text('Private')),
                ],
                onChanged: (value) {
                  setState(() => _selectedType = value!);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _goalAmountController,
                decoration: const InputDecoration(labelText: 'Goal Amount (UGX)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Enter a goal amount';
                  if (double.tryParse(value.trim()) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _goalDescriptionController,
                decoration: const InputDecoration(labelText: 'Goal Description'),
                validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Enter a goal description' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contributionController,
                decoration: const InputDecoration(labelText: 'Contribution Amount (UGX)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Enter an amount';
                  if (double.tryParse(value.trim()) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _frequencyValueController,
                      decoration: const InputDecoration(labelText: 'Every'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Required';
                        if (int.tryParse(value.trim()) == null) return 'Enter a number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedFrequencyUnit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: const [
                        DropdownMenuItem(value: 'days', child: Text('Days')),
                        DropdownMenuItem(value: 'weeks', child: Text('Weeks')),
                        DropdownMenuItem(value: 'months', child: Text('Months')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedFrequencyUnit = value!);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Create Group'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}