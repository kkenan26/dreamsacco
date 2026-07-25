import 'dart:math';
//this is a mock credit score service for testing my models
//, please replace with th actual one  when you have one
abstract class CreditScoreService {
  Future<double> getCreditScore(String userId);
}
class MockCreditScoreService implements CreditScoreService {
  final Random _random = Random();
  @override
  Future<double> getCreditScore(String userId) async {
    await Future.delayed(const Duration(seconds: 1)); //simulate delay when calculating
    return 10 + _random.nextDouble() * 90;
  }
}