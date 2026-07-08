import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/job.dart';
import '../../widgets/job_list_view.dart'; // Reuse clean list layout!
import '../../themes/app_colors.dart';
import 'billing_details_page.dart';

class PaymentsPage extends StatelessWidget {
  final bool isSeeker;

  const PaymentsPage({super.key, required this.isSeeker});

  Future<void> _handleGuestRedirect(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

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
                  color: AppColors.textMain,
                ),
              ),
            ),
            Expanded(
              child: _buildBillingListStream(
                uid: uid,
                targetStatuses: ["RELEASED", "REFUNDED", "PARTIALLY_REFUNDED"],
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
    if (user == null || user.isAnonymous) {
      return _buildGuestOverlay(context);
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            isSeeker ? "Payment Center" : "Earnings Dashboard",
            style: const TextStyle(
              color: AppColors.textMain,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.history, color: AppColors.textSecondary),
              onPressed: () => _showHistory(context, user.uid),
              tooltip: "View Financial History",
            ),
          ],
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: isSeeker
                ? const [
                    Tab(
                      text: "Action Required",
                      icon: Icon(Icons.payment_outlined),
                    ),
                    Tab(text: "Held", icon: Icon(Icons.lock_clock_outlined)),
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
                    targetStatuses: ["GENERATED"],
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

  Widget _buildGuestOverlay(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          isSeeker ? "Payment Center" : "Earnings Dashboard",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                "Sign In Required",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Please authenticate your account to look up ongoing escrow balances, "
                "settle active care invoices, or track compiled processing payout histories.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => _handleGuestRedirect(context),
                icon: const Icon(Icons.login_rounded),
                label: const Text(
                  "Sign In / Register",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
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
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
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

            final metadata = data['metadata'] as Map<String, dynamic>?;
            final String cleanJobId = metadata?['jobId'] ?? data['id'] ?? '';

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
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.08),
                  child: const Icon(
                    Icons.receipt_long,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  "Arrangement Ledger ID: ${cleanJobId.substring(0, 6).toUpperCase()}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                subtitle: Text(
                  "Duration: ${pricing['totalDays']} Days • Click to examine",
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                trailing: Text(
                  "Rs. ${displayAmount.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textMain,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BillingDetailsPage(
                        jobId: cleanJobId,
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
