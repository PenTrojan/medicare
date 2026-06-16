class BillModel {
  final String id;
  final BillMetadata metadata;
  final PricingStructure pricingStructure;
  final FinancialBreakdown financialBreakdown;
  final EscrowSummary escrowSummary;

  BillModel({
    required this.id,
    required this.metadata,
    required this.pricingStructure,
    required this.financialBreakdown,
    required this.escrowSummary,
  });

  factory BillModel.fromMap(Map<String, dynamic> map) {
    return BillModel(
      id: map['id'] ?? '',
      metadata: BillMetadata.fromMap(map['metadata'] ?? {}),
      pricingStructure: PricingStructure.fromMap(map['pricingStructure'] ?? {}),
      financialBreakdown: FinancialBreakdown.fromMap(
        map['financialBreakdown'] ?? {},
      ),
      escrowSummary: EscrowSummary.fromMap(map['escrowSummary'] ?? {}),
    );
  }
}

class BillMetadata {
  final String jobId;
  final String seekerId;
  final String assistantId;

  BillMetadata({
    required this.jobId,
    required this.seekerId,
    required this.assistantId,
  });

  factory BillMetadata.fromMap(Map<String, dynamic> map) {
    return BillMetadata(
      jobId: map['jobId'] ?? '',
      seekerId: map['seekerId'] ?? '',
      assistantId: map['assistantId'] ?? '',
    );
  }
}

class PricingStructure {
  final double totalDays;
  final int dailyRate;
  final int grossContractValue;

  PricingStructure({
    required this.totalDays,
    required this.dailyRate,
    required this.grossContractValue,
  });

  factory PricingStructure.fromMap(Map<String, dynamic> map) {
    return PricingStructure(
      totalDays: (map['totalDays'] as num?)?.toDouble() ?? 0.0,
      dailyRate: (map['dailyRate'] as num?)?.toInt() ?? 0,
      grossContractValue: (map['grossContractValue'] as num?)?.toInt() ?? 0,
    );
  }
}

class FinancialBreakdown {
  final double platformFeeRate;
  final int platformFeeAmount;
  final int netAssistantPayout;
  final double taxRate;
  final int taxAmount;

  FinancialBreakdown({
    required this.platformFeeRate,
    required this.platformFeeAmount,
    required this.netAssistantPayout,
    required this.taxRate,
    required this.taxAmount,
  });

  factory FinancialBreakdown.fromMap(Map<String, dynamic> map) {
    return FinancialBreakdown(
      platformFeeRate: (map['platformFeeRate'] as num?)?.toDouble() ?? 0.0,
      platformFeeAmount: (map['platformFeeAmount'] as num?)?.toInt() ?? 0,
      netAssistantPayout: (map['netAssistantPayout'] as num?)?.toInt() ?? 0,
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['taxAmount'] as num?)?.toInt() ?? 0,
    );
  }
}

class EscrowSummary {
  final int totalRequiredFromSeeker;
  final int currentEscrowBalance;
  final String financialStatus;

  EscrowSummary({
    required this.totalRequiredFromSeeker,
    required this.currentEscrowBalance,
    required this.financialStatus,
  });

  factory EscrowSummary.fromMap(Map<String, dynamic> map) {
    return EscrowSummary(
      totalRequiredFromSeeker:
          (map['totalRequiredFromSeeker'] as num?)?.toInt() ?? 0,
      currentEscrowBalance: (map['currentEscrowBalance'] as num?)?.toInt() ?? 0,
      financialStatus: map['financialStatus'] ?? 'GENERATED',
    );
  }
}
