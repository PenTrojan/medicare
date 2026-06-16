import 'package:cloud_functions/cloud_functions.dart';

class BillingService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Invokes isolated backend billing engine to compute metrics
  Future<Map<String, dynamic>?> generateInvoiceLedger(String jobId) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable(
        'generateJobBill',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
      );

      final result = await callable.call(<String, dynamic>{'jobId': jobId});

      if (result.data != null) {
        return Map<String, dynamic>.from(result.data as Map);
      }
      return null;
    } on FirebaseFunctionsException catch (e) {
      print('Billing Core Error: [${e.code}] - ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected Network Error: $e');
      return null;
    }
  }
}
