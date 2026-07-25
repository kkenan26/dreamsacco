//lib/screens/credit_scoring_screen.dart
import 'package:flutter/material.dart';

class CreditScoreScreen extends StatefulWidget{
  const CreditScoreScreen({super.key});

  @override
  State<CreditScoreScreen> createState() => _CreditScoreScreenState();
}

class _CreditScoreScreenState extends State<CreditScoreScreen>{
  //Mock data which represents evaluation factors
  final int totalMonthsContributed = 10;
  final int onTimeRepayments=5;
  final int lateRepayments=1;
  final double currentSavings=850000;

  double calculateCreditScore(){
    double contributionWeight = (totalMonthsContributed/12)*40;

    double repaymentRatio = onTimeRepayments + lateRepayments ==0 ?1.0 : onTimeRepayments/ (onTimeRepayments + lateRepayments);
    double repaymentWeight = repaymentRatio *40;
    double activityWeight = currentSavings >= 500000 ?20 :10;
    double finalScore = contributionWeight + repaymentWeight + activityWeight;
    return finalScore.clamp(0.0,100.0);
  }

  @override
  Widget build(BuildContext context){
    double score =calculateCreditScore();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar :AppBar(
        title: const Text("Credit Worthiness Engine"),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D47A1),Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow:[
                  BoxShadow(
                    color: const Color(0xFF0D47A1).withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0,4),

                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "Your Credit Score",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${score.toStringAsFixed(1)}/100",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label:Text(
                      score >= 70 ? "Status: Excellent":"Status: Moderate",
                      style: const TextStyle(
                        color: Color(0xFF0D47A1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Score Breakdown Factors",style: TextStyle(fontSize: 18, fontWeight:FontWeight.bold, color: Colors.black87),
            ),

            const SizedBox(height: 12),

            _factorCard(
              "Contribution History(40%)",
              "$totalMonthsContributed/12 Months Consistency",
              Icons.payments,
              Colors.green,
            ),

            const SizedBox(height: 12),
            _factorCard(
              "Repayment Record(40%)",
              "$onTimeRepayments On-Time | $lateRepayments Late",
              Icons.history,
              Colors.blue,

            ),

            const SizedBox(height: 12),
            _factorCard(
              "Activity & Savings (20%)",
              "Current Savings: UGX ${currentSavings.toStringAsFixed(0)}",
              Icons.account_balance_wallet,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _factorCard(String title, String subtitle, IconData icon, Color color){
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius:4 ,offset:Offset(0,2)),
        ],
      ),
      child: Row(
        children:[
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height:4),
                Text(subtitle, style:TextStyle(color: Colors.grey.shade600, fontSize:12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

}