import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/job.dart';
import '../../widgets/job_list_view.dart'; // Reuse your clean list layout!
import 'billing_details_page.dart';

class PaymentsPage extends StatelessWidget {
  final bool isSeeker;

  const PaymentsPage({super.key, required this.isSeeker});

  void _showHistory(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                isSeeker ? "Payment History" : "Payout History",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ),
            Expanded(
              child: _buildBillingListStream(
                uid: uid,
                targetStatuses: ["RELEASED", "REFUNDED"],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please sign in to view balances.")),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: Text(
            isSeeker ? "Payment Center" : "Earnings Dashboard",
            style: const TextStyle(
              color: Color(0xFF1E3A8A),
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.history, color: Color(0xFF1E3A8A)),
              onPressed: () => _showHistory(context, user.uid),
              tooltip: "View Financial History",
            ),
          ],
          bottom: TabBar(
            labelColor: const Color(0xFF3B82F6),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF3B82F6),
            tabs: isSeeker
                ? const [
                    Tab(
                      text: "Action Required",
                      icon: Icon(Icons.payment_outlined),
                    ),
                    Tab(
                      text: "In Escrow",
                      icon: Icon(Icons.lock_clock_outlined),
                    ),
                  ]
                : const [
                    Tab(
                      text: "Pending Clearance",
                      icon: Icon(Icons.hourglass_empty_outlined),
                    ),
                    Tab(
                      text: "Cleared Funds",
                      icon: Icon(Icons.check_circle_outline),
                    ),
                  ],
          ),
        ),
        body: TabBarView(
          children: isSeeker
              ? [
                  // Seeker Tab 1: Invoices that need payment
                  _buildBillingListStream(
                    uid: user.uid,
                    targetStatuses: ["GENERATED"],
                  ),
                  // Seeker Tab 2: Money safely deposited in escrow
                  _buildBillingListStream(
                    uid: user.uid,
                    targetStatuses: ["ESCROW_HELD"],
                  ),
                ]
              : [
                  // Assistant Tab 1: Ongoing jobs where money is locked in escrow
                  _buildBillingListStream(
                    uid: user.uid,
                    targetStatuses: ["ESCROW_HELD"],
                  ),
                  // Assistant Tab 2: Completed jobs waiting for automatic bank transfer
                  _buildBillingListStream(
                    uid: user.uid,
                    targetStatuses: ["RELEASED"],
                  ),
                ],
        ),
      ),
    );
  }

  Widget _buildBillingListStream({
    required String uid,
    required List<String> targetStatuses,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bills')
          .where(
            isSeeker ? 'metadata.seekerId' : 'metadata.assistantId',
            isEqualTo: uid,
          )
          .where('escrowSummary.financialStatus', whereIn: targetStatuses)
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
            child: Text(
              "No financial records found in this category.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final escrow = data['escrowSummary'] as Map<String, dynamic>;
            final pricing = data['pricingStructure'] as Map<String, dynamic>;

            final double displayAmount = isSeeker
                ? (escrow['totalRequiredFromSeeker'] as num).toDouble()
                : (data['financialBreakdown']['netAssistantPayout'] as num)
                      .toDouble();

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.receipt_long, color: Color(0xFF3B82F6)),
                ),
                title: Text(
                  "Arrangement Ledger ID: ${data['id'].toString().substring(0, 6).toUpperCase()}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Duration: ${pricing['totalDays']} Days • Click to examine",
                ),
                trailing: Text(
                  "Rs. ${displayAmount.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
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
        );
      },
    );
  }
}
