//lib/screens/loan_request_screen.dart
import 'package:flutter/material.dart';

class LoanRequestScreen extends StatefulWidget{
  const LoanRequestScreen({super.key});

  @override
  State<LoanRequestScreen> createState() => _LoanRequestScreenState();
}

class _LoanRequestScreenState extends State<LoanRequestScreen>{
  final TextEditingController _amountController = TextEditingController();
  int _selectedMonths = 6; //default repayment duration in months
  final double _interestRate = 0.10; //10% flat interest rate for the loan

  List<Map<String, dynamic>> _repaymentSchedule =[];
  void _generatedSchedule(){
    double requestedAmount = double.tryParse(_amountController.text) ?? 0.0;

    if (requestedAmount <= 0){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount for your loan")),
      );
      return;
    }

    double totalInterest = requestedAmount * _interestRate;
    double totalRepayment = requestedAmount + totalInterest;

    double monthlyInstallment = totalRepayment / _selectedMonths;

    List<Map<String, dynamic>> temporaryList =[];
    DateTime currentDate =DateTime.now();

    for (int i=1; i <= _selectedMonths; i++){
      currentDate = DateTime(currentDate.year, currentDate.month +1, currentDate.day);

      temporaryList.add({
        "month": "Month $i",
        "dueDate": "${currentDate.day}/${currentDate.month}/${currentDate.year}",
        "amount":"UGX ${monthlyInstallment.toStringAsFixed(0)}",
      });
    }

    setState((){
      _repaymentSchedule = temporaryList;
    });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("LoanRequest & Schedule"),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),

              child: const Text(
                "Request a loan below. Our system shall automatically compute your monthly installments and repayment timeline.",
                style: TextStyle(color: Color(0xFF0D47A1), fontSize:13),
              ),
            ),

            const SizedBox(height:20),

            const Text("Requested Amount(UGX)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height:8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "e.g. 500000",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Repayment Duration", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height:8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),

              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedMonths,
                  isExpanded: true,
                  items: const[
                    DropdownMenuItem(value:3, child: Text("3 Months")),
                    DropdownMenuItem(value:6, child: Text("6 Months")),
                    DropdownMenuItem(value:12, child: Text("12 Months"))
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedMonths = value!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _generatedSchedule,
                child: const Text("Generate Repayment Schedule", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),

            if (_repaymentSchedule.isNotEmpty)...[
              const Text(
                "Auto-Generated Repayment Schedule",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),

              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _repaymentSchedule.length,
                itemBuilder: (context, index){
                  final item = _repaymentSchedule[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom:8),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF0D47A1).withValues(alpha: 0.1),
                        child: Text("${index + 1}", style:const TextStyle(color:Color(0xFF0D47A1),fontWeight: FontWeight.bold)),
                      ),
                      title: Text(item["month"], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Due Date: ${item["dueDate"]}"),
                      trailing: Text(
                        item["amount"],
                        style: const TextStyle(fontWeight: FontWeight.bold, color:Colors.green, fontSize: 14),
                      ),
                    ),
                  );
                },
              ),
            ],

          ],
        ),
      ),
    );
  }
}