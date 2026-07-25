//lib/screens/loan_status_screen.dart
import 'package:flutter/material.dart';

class LoanStatusScreen extends StatelessWidget{
  const LoanStatusScreen({super.key});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Loan Application Status"),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            Container(
              padding: const EdgeInsets.all(20),
              decoration:BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0,4),
                  ),
                ],
              ),
              child: Column(
                children:[
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.orangeAccent,
                    child: Icon(Icons.hourglass_top, size: 30, color:Colors.white),
                  ),
                  const SizedBox(height:6),
                  Text(
                    "your loan request is currently being evaluated against your credit score.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize:13),
                  ),
                  const Divider(height: 30),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:[
                      Text("Requested Amount:", style: TextStyle(color: Colors.grey)),
                      Text("UGX 500000", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Estimated Credit Score:", style:TextStyle(color:Colors.grey)),
                      Text("740(Good)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child:ElevatedButton(
                style:ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: (){
                  Navigator.pop(context);
                },
                child: const Text(" Back to the Dashboard", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}