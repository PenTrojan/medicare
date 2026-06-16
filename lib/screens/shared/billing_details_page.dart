import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/bill_model.dart';
import '../../widgets/invoice_breakdown_card.dart';

class BillingDetailsPage extends StatelessWidget {
  final String jobId;
  final bool isSeeker; // Configures active payment context views dynamically

  const BillingDetailsPage({
    super.key,
    required this.jobId,
    required this.isSeeker,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Invoice & Escrow Details"),
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A8A),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bills')
            .doc(jobId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("No invoice generated for this arrangement yet."),
            );
          }

          // Convert raw document map into our validated type-safe model
          final rawData = snapshot.data!.data() as Map<String, dynamic>;
          final bill = BillModel.fromMap(rawData);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBanner(bill.escrowSummary.financialStatus),
                const SizedBox(height: 24),

                // Unified modular widget handles persona-based math splits
                InvoiceBreakdownCard(bill: bill),

                const SizedBox(height: 40),
                if (isSeeker &&
                    bill.escrowSummary.financialStatus == "GENERATED")
                  ElevatedButton(
                    onPressed: () => _initializeSecurePaymentGateway(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Authorize Payment Capture",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner(String status) {
    Color bannerColor;
    String displayMsg;

    switch (status) {
      case "GENERATED":
        bannerColor = Colors.orange;
        displayMsg = "Awaiting Payer Funding Action";
        break;
      case "ESCROW_HELD":
        bannerColor = Colors.green;
        displayMsg = "Capital Locked in Secured Escrow Account";
        break;
      case "RELEASED":
        bannerColor = Colors.blue;
        displayMsg = "Funds Distributed to Assistant Account Ledger";
        break;
      default:
        bannerColor = Colors.grey;
        displayMsg = status;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: bannerColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayMsg,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: bannerColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _initializeSecurePaymentGateway(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Connecting securely to Stripe checkout systems..."),
      ),
    );
  }
}
