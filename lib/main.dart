import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/group.dart';
import 'services/credit_score.dart';
import 'models/group.dart';
import 'screens/group_mgt/group_create.dart';
import 'screens/group_mgt/group_list.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Make sure Firebase is set up
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6FA8DC), // muted soft blue
          secondary: const Color(0xFF8FD6BD), // soft sage green
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7FAFC), // barely-there blue-white
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6FA8DC),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8FD6BD),
            foregroundColor: const Color(0xFF1F2937), // dark grey, not pure black
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const GroupListScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final GroupService _groupService = GroupService(
    creditScoreService: MockCreditScoreService(),
  );

  String _result = 'Press the button to create a group';

  Future<void> _createTestGroup() async {
    try {
      //dummy group data
      Group testGroup = Group.create(
        name: 'Test Group ${DateTime.now().minute}',
        description: 'This is a test group created from the app',
        type: 'public',
        adminId: 'test_admin_123', // Replace with a real user ID if you have auth
        treasurerId: 'test_admin_123',
        goalAmount: 1000000,
        goalDescription: 'Buy a van',
        contribution: 100000,
        contributionFrequencyValue: 1,
        contributionFrequencyUnit: 'months',
      );

      String newGroupId = await _groupService.createGroup(testGroup);

      setState(() {
        _result = 'Group created! ID: $newGroupId';
      });

      print('Group created with ID: $newGroupId');
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
      print('Error creating group: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Create Group')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_result, textAlign: TextAlign.center),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _createTestGroup,
                child: Text('Create Test Group'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}