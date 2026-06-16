import 'package:flutter/material.dart';
import '../models/bill_model.dart';

class InvoiceBreakdownCard extends StatelessWidget {
  final BillModel bill;

  const InvoiceBreakdownCard({Key? key, required this.bill}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pricing = bill.pricingStructure;
    final breakdown = bill.financialBreakdown;
    final escrow = bill.escrowSummary;

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
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    escrow.financialStatus,
                    style: TextStyle(
                      color: Colors.blue.shade700,
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
            _buildRow('Assistant Daily Rate', '\$${pricing.dailyRate}.00'),
            const SizedBox(height: 8),
            _buildRow(
              'Gross Labor Subtotal',
              '\$${pricing.grossContractValue}.00',
              isBold: true,
            ),
            const Divider(height: 24),
            _buildRow(
              'Platform Fee (${(breakdown.platformFeeRate * 100).toInt()}%)',
              '\$${breakdown.platformFeeAmount}.00',
            ),
            _buildRow(
              'Infrastructure Tax (${(breakdown.taxRate * 100).toInt()}%)',
              '\$${breakdown.taxAmount}.00',
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
                  '\$${escrow.totalRequiredFromSeeker}.00',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
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
