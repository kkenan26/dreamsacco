//lib/models/credit_score_model.dart

class CreditScoreModel {
  final int score;
  final String rating;
  final String remark;
  final int loanLimit;
  final double interestRate;

  CreditScoreModel({
    required this.score,
    required this.rating,
    required this.remark,
    required this.loanLimit,
    required this.interestRate,
  });

  // Computes credit score from user activity data
  factory CreditScoreModel.compute({
    required int totalContributions,
    required int missedContributions,
    required int loansRepaid,
    required int activeLoanCount,
    required int contributionStreak,
  }) {
    // PRIORITY QUEUE SCORING ALGORITHM
    // Each factor is weighted and combined into a final score

    // Factor 1: Contribution consistency (40 points max)
    int totalExpected = totalContributions + missedContributions;
    double consistencyRate = totalExpected == 0
        ? 0
        : totalContributions / totalExpected;
    int consistencyScore = (consistencyRate * 40).toInt();

    // Factor 2: Loan repayment history (30 points max)
    int repaymentScore = (loansRepaid * 10).clamp(0, 30);

    // Factor 3: Contribution streak (20 points max)
    int streakScore = (contributionStreak * 4).clamp(0, 20);

    // Factor 4: Penalize active loans (10 points max deduction)
    int loanPenalty = (activeLoanCount * 5).clamp(0, 10);

    // Final score out of 100
    int finalScore = (consistencyScore + repaymentScore + streakScore - loanPenalty).clamp(0, 100);

    // Determine rating and loan limit based on score
    String rating;
    String remark;
    int loanLimit;
    double interestRate;

    if (finalScore >= 80) {
      rating = "Excellent";
      remark = "Outstanding financial behaviour. Maximum loan access granted.";
      loanLimit = 5000000;
      interestRate = 0.05; // 5%
    } else if (finalScore >= 60) {
      rating = "Good";
      remark = "Reliable contributor. Standard loan access granted.";
      loanLimit = 3000000;
      interestRate = 0.08; // 8%
    } else if (finalScore >= 40) {
      rating = "Fair";
      remark = "Some missed contributions detected. Limited loan access.";
      loanLimit = 1000000;
      interestRate = 0.12; // 12%
    } else {
      rating = "Poor";
      remark = "Significant missed contributions or unpaid loans. Loan access restricted.";
      loanLimit = 0;
      interestRate = 0.15; // 15%
    }

    return CreditScoreModel(
      score: finalScore,
      rating: rating,
      remark: remark,
      loanLimit: loanLimit,
      interestRate: interestRate,
    );
  }
}