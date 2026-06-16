// lib/widgets/billing_summary_view.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/shared/billing_details_page.dart';

class BillingSummaryView extends StatelessWidget {
  final bool isSeeker;

  const BillingSummaryView({super.key, required this.isSeeker});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null)
      return const Center(child: Text("Please login to track balances."));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bills')
          .where(
            isSeeker ? 'metadata.seekerId' : 'metadata.assistantId',
            isEqualTo: uid,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text("No financial ledger entries recorded yet."),
          );
        }

        // Calculate running totals for the financial summary dashboard
        double totalVolume = 0;
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final escrow = data['escrowSummary'] as Map<String, dynamic>;
          final breakdown = data['financialBreakdown'] as Map<String, dynamic>;

          if (escrow['financialStatus'] != "GENERATED") {
            totalVolume += isSeeker
                ? (escrow['totalRequiredFromSeeker'] as num).toDouble()
                : (breakdown['netAssistantPayout'] as num).toDouble();
          }
        }

        return Column(
          children: [
            _buildMetricsBanner(totalVolume),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final escrow = data['escrowSummary'] as Map<String, dynamic>;
                  final pricing =
                      data['pricingStructure'] as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        "Arrangement: ${data['id']}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Duration: ${pricing['totalDays']} Days • Status: ${escrow['financialStatus']}",
                      ),
                      trailing: Text(
                        "Rs. ${isSeeker ? escrow['totalRequiredFromSeeker'] : data['financialBreakdown']['netAssistantPayout']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BillingDetailsPage(
                              jobId: data['id'],
                              isSeeker: isSeeker,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricsBanner(double amount) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSeeker ? "Total Capital Capitalized" : "Total Earnings Cleared",
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            "Rs. ${amount.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
