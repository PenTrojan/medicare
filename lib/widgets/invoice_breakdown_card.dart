import 'package:flutter/material.dart';
import '../models/bill_model.dart';

class InvoiceBreakdownCard extends StatelessWidget {
  final BillModel bill;
  // void callback is a function that takes no argument and returns nothing
  // seperates network requests from the ui
  final VoidCallback? onPayPressed;

  const InvoiceBreakdownCard({Key? key, required this.bill, this.onPayPressed})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pricing = bill.pricingStructure;
    final breakdown = bill.financialBreakdown;
    final escrow = bill.escrowSummary;

    // Check if the bill is already processed to switch up UI themes
    final String currentStatus = escrow.financialStatus.toUpperCase();
    final bool isPaid =
        currentStatus == 'PAID' ||
        currentStatus == 'ESCROW_HELD' ||
        currentStatus == 'RELEASED';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Invoice Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPaid ? Colors.green.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    escrow.financialStatus.toUpperCase(),
                    style: TextStyle(
                      color: isPaid
                          ? Colors.green.shade700
                          : Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildRow(
              'Total Calculated Days',
              '${pricing.totalDays} days (8h/day)',
            ),
            _buildRow('Assistant Daily Rate', 'Rs. ${pricing.dailyRate}'),
            const SizedBox(height: 8),
            _buildRow(
              'Gross Labor Subtotal',
              'Rs. ${pricing.grossContractValue}',
              isBold: true,
            ),
            const Divider(height: 24),
            _buildRow(
              'Platform Fee (${(breakdown.platformFeeRate * 100).toInt()}%)',
              'Rs. ${breakdown.platformFeeAmount}',
            ),
            _buildRow(
              'Infrastructure Tax (${(breakdown.taxRate * 100).toInt()}%)',
              'Rs. ${breakdown.taxAmount}',
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Funding Required',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rs. ${escrow.totalRequiredFromSeeker}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isPaid ? Colors.grey : Colors.green.shade700,
                  ),
                ),
              ],
            ),

            // --- Dynamic Action Section ---
            if (!isPaid && onPayPressed != null) ...[
              const Divider(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                onPressed: onPayPressed,
                child: const Text(
                  'Confirm & Pay Bill',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ] else if (isPaid) ...[
              const Divider(height: 32),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'This bill has been settled.',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
