import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class MomoService {
  static const String _primaryKey = 'e56598360c5040cc9496b40505d67c50';
  static const String _userId = '2d256dd5-2761-4a8e-89b0-1f8d7069e6aa';
  static const String _userApiKey = '5a83b23063104b2e8e7ce08bb78677eb';
  static const String _baseUrl = 'https://sandbox.momodeveloper.mtn.com';
  static const String _targetEnvironment = 'sandbox';
  static const String _currency = 'EUR';

  Future<String?> getAccessToken() async {
    try {
      String credentials =
      base64Encode(utf8.encode('$_userId:$_userApiKey'));
      final response = await http.post(
        Uri.parse('$_baseUrl/collection/token/'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Ocp-Apim-Subscription-Key': _primaryKey,
        },
      );
      if (response.statusCode == 200) {
        return json.decode(response.body)['access_token'];
      }
      print('Token error ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      print('Token exception: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> requestToPay({
    required String payerPhone,
    required double amount,
    required String description,
  }) async {
    try {
      String? token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Failed to get access token'};
      }

      String referenceId = const Uuid().v4();
      String cleanPhone = _cleanPhone(payerPhone);

      final response = await http.post(
        Uri.parse('$_baseUrl/collection/v1_0/requesttopay'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Reference-Id': referenceId,
          'X-Target-Environment': _targetEnvironment,
          'Ocp-Apim-Subscription-Key': _primaryKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'amount': amount.toStringAsFixed(0),
          'currency': _currency,
          'externalId': referenceId,
          'payer': {
            'partyIdType': 'MSISDN',
            'partyId': cleanPhone,
          },
          'payerMessage': description,
          'payeeNote': 'DreamSacco Contribution',
        }),
      );

      if (response.statusCode == 202) {
        await Future.delayed(const Duration(seconds: 5));
        return await _checkStatus(token, referenceId);
      }

      print('RequestToPay error ${response.statusCode}: ${response.body}');
      return {
        'success': false,
        'message': 'Payment request failed: ${response.statusCode}'
      };
    } catch (e) {
      print('RequestToPay exception: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> _checkStatus(
      String token, String referenceId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/collection/v1_0/requesttopay/$referenceId'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Target-Environment': _targetEnvironment,
          'Ocp-Apim-Subscription-Key': _primaryKey,
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        String status = data['status'] ?? '';
        if (status == 'SUCCESSFUL') {
          return {
            'success': true,
            'referenceId': referenceId,
            'data': data
          };
        }
        return {
          'success': false,
          'message': 'Payment status: $status',
          'referenceId': referenceId
        };
      }
      return {
        'success': false,
        'message': 'Status check failed: ${response.statusCode}'
      };
    } catch (e) {
      return {'success': false, 'message': 'Status check error: $e'};
    }
  }

  String _cleanPhone(String phone) {
    String clean = phone.replaceAll('+', '').replaceAll(' ', '');
    if (clean.startsWith('256')) return clean;
    if (clean.startsWith('0')) return '256${clean.substring(1)}';
    return '256$clean';
  }
}