import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/group.dart';
import '../../services/adapter.dart';
import '../../models/group.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final _treasurerUsernameController = TextEditingController();
  final _treasurerMobileMoneyController = TextEditingController();
  final _totalSharesController = TextEditingController();
  final _contributionPerShareController = TextEditingController();

  String _selectedType = 'public';
  String _selectedFrequencyUnit = 'months';
  bool _isShareBased = false;
  bool _isSubmitting = false;

  final GroupService _groupService = GroupService(
    creditScoreService: RealCreditScoreAdapter(),
  );

  String get _currentUserId => FirebaseAuth.instance.currentUser!.uid;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _goalAmountController.dispose();
    _goalDescriptionController.dispose();
    _contributionController.dispose();
    _frequencyValueController.dispose();
    _treasurerUsernameController.dispose();
    _treasurerMobileMoneyController.dispose();
    _totalSharesController.dispose();
    _contributionPerShareController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // ====== NEW: Look up treasurer by username ======
      String treasurerUsername = _treasurerUsernameController.text.trim();
      String treasurerId = _currentUserId; // default to yourself

      if (treasurerUsername.isNotEmpty && treasurerUsername != _nameController.text.trim()) {
        QuerySnapshot userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('name', isEqualTo: treasurerUsername)
            .limit(1)
            .get();

        if (userQuery.docs.isEmpty) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No user found with username: $treasurerUsername')),
          );
          return;
        }
        treasurerId = userQuery.docs.first.id;
      }
      // ====== END NEW ======

      Group newGroup = Group.create(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        adminId: _currentUserId,
        treasurerId: treasurerId, // <-- now uses the resolved ID, not the controller
        treasurerMobileMoney: _treasurerMobileMoneyController.text.trim(),
        goalAmount: double.parse(_goalAmountController.text.trim()),
        goalDescription: _goalDescriptionController.text.trim(),
        contribution: _isShareBased
            ? 0.0
            : double.parse(_contributionController.text.trim()),
        contributionFrequencyValue: int.parse(_frequencyValueController.text.trim()),
        contributionFrequencyUnit: _selectedFrequencyUnit,
        isShareBased: _isShareBased,
        totalShares: _isShareBased ? int.parse(_totalSharesController.text.trim()) : 0,
        contributionPerShare: _isShareBased
            ? double.parse(_contributionPerShareController.text.trim())
            : 0.0,
      );

      String newGroupId = await _groupService.createGroup(newGroup);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group created! ID: $newGroupId')),
      );
      Navigator.pop(context);
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          title: const Text('Create Group', style: TextStyle(fontWeight: FontWeight.w600))),
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
                initialValue: _selectedType,
                decoration: const InputDecoration(labelText: 'Group Type'),
                items: const [
                  DropdownMenuItem(value: 'public', child: Text('Public')),
                  DropdownMenuItem(value: 'private', child: Text('Private')),
                ],
                onChanged: (value) => setState(() => _selectedType = value!),
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
              const SizedBox(height: 20),
              const Divider(),
              const Text('Treasurer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _treasurerUsernameController,
                decoration: const InputDecoration(
                  labelText: 'Treasurer Username',
                  helperText: 'Enter the exact name they registered with',
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter the treasurer\'s username' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _treasurerMobileMoneyController,
                decoration: const InputDecoration(labelText: 'Treasurer Mobile Money Number'),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Enter a mobile money number' : null,
              ),
              const SizedBox(height: 20),
              const Divider(),
              SwitchListTile(
                title: const Text('Share-Based Group?'),
                subtitle: const Text('Members join by requesting a percentage of shares'),
                value: _isShareBased,
                onChanged: (value) => setState(() => _isShareBased = value),
              ),
              const SizedBox(height: 12),
              if (_isShareBased) ...[
                TextFormField(
                  controller: _totalSharesController,
                  decoration: const InputDecoration(labelText: 'Total Shares'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (!_isShareBased) return null;
                    if (value == null || value.trim().isEmpty) return 'Enter total shares';
                    if (int.tryParse(value.trim()) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contributionPerShareController,
                  decoration: const InputDecoration(labelText: 'Contribution Per Share (UGX)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (!_isShareBased) return null;
                    if (value == null || value.trim().isEmpty) return 'Enter amount per share';
                    if (double.tryParse(value.trim()) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
              ] else
                TextFormField(
                  controller: _contributionController,
                  decoration: const InputDecoration(labelText: 'Contribution Amount (UGX)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_isShareBased) return null;
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
                      initialValue: _selectedFrequencyUnit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: const [
                        DropdownMenuItem(value: 'days', child: Text('Days')),
                        DropdownMenuItem(value: 'weeks', child: Text('Weeks')),
                        DropdownMenuItem(value: 'months', child: Text('Months')),
                      ],
                      onChanged: (value) => setState(() => _selectedFrequencyUnit = value!),
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