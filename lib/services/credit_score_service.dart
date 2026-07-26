//import 'dart:math';
//this is a mock credit score service for testing my models
//, please replace with th actual one  when you have one
//abstract class CreditScoreService {
  //Future<double> getCreditScore(String userId);
//}
//class MockCreditScoreService implements CreditScoreService {
  //final Random _random = Random();
  //@override
  //Future<double> getCreditScore(String userId) async {
    //await Future.delayed(const Duration(seconds: 1)); //simulate delay when calculating
    //return 10 + _random.nextDouble() * 90;
  //}
//}

//lib/services/credit_score_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/credit_score_model.dart';

class CreditScoreService{
  final String baseUrl ="http://10.0.2.2.8000";
  Future<CreditScoreModel> fetchUserCreditScore(String memberId) async{
    try{
      final response= await http.get(
        Uri.parse('$baseUrl/credit-score/$memberId'),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200){
        final Map<String, dynamic>data = json.decode(response.body);
        return CreditScoreModel.fromJson(data);
      }
      else {
        throw Exception('Failed to load credit score from database');
      }
    }
    catch(e){
      print ("Error fetching credit score: $e");
      return CreditScoreModel(
        score: 720,
        rating: "Good(Offline)",
        remark: "Could not reach database. Showing cached data.",
      );
    }
  }
}