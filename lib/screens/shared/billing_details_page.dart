import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BillingDetailsPage extends StatelessWidget {
  final String jobId;
  final bool
  isSeeker; // Dynamically configures layout views based on persona role

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
          if (snapshot.hasError)
            return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("No invoice generated for this arrangement yet."),
            );
          }

          final billData = snapshot.data!.data() as Map<String, dynamic>;
          final pricing = billData['pricingStructure'] as Map<String, dynamic>;
          final breakdown =
              billData['financialBreakdown'] as Map<String, dynamic>;
          final escrow = billData['escrowSummary'] as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBanner(escrow['financialStatus']),
                const SizedBox(height: 24),
                _buildLedgerSection(
                  title: "Contract Metrics",
                  rows: [
                    _ledgerRow(
                      "Total Duration",
                      "${pricing['totalDays']} Days",
                    ),
                    _ledgerRow(
                      "Agreed Rate",
                      "Rs. ${pricing['dailyRate']} / Day",
                    ),
                    _ledgerRow(
                      "Gross Value",
                      "Rs. ${pricing['grossContractValue']}",
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildLedgerSection(
                  title: "Financial Ledger Particulars",
                  rows: isSeeker
                      ? [
                          _ledgerRow(
                            "Regulatory Surcharges (2%)",
                            "Rs. ${breakdown['taxAmount']}",
                          ),
                          const Divider(),
                          _ledgerRow(
                            "Total Consolidated Liability",
                            "Rs. ${escrow['totalRequiredFromSeeker']}",
                            isBold: true,
                          ),
                        ]
                      : [
                          _ledgerRow(
                            "System Application Fee (10%)",
                            "- Rs. ${breakdown['platformFeeAmount']}",
                          ),
                          const Divider(),
                          _ledgerRow(
                            "Net Cleared Earnings Payout",
                            "Rs. ${breakdown['netAssistantPayout']}",
                            isBold: true,
                          ),
                        ],
                ),
                const SizedBox(height: 40),
                if (isSeeker && escrow['financialStatus'] == "GENERATED")
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
          Text(
            displayMsg,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: bannerColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerSection({
    required String title,
    required List<Widget> rows,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: rows),
          ),
        ),
      ],
    );
  }

  Widget _ledgerRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFF1E293B),
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
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
