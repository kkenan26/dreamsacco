//lib/models/credit_score_model.dart

class CreditScoreModel{
  final int score;
  final String rating;
  final String remark;

  CreditScoreModel({
    required this.score,
    required this.rating,
    required this.remark,
});

  factory CreditScoreModel.fromJson(Map<String, dynamic> json){
    return CreditScoreModel(
      score: json['score']??0,
      rating: json['rating']??'Unknown',
      remark: json['remark']??'No remarks available',
    );
  }
}