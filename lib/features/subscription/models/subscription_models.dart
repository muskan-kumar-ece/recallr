import 'package:cloud_firestore/cloud_firestore.dart';

/// Available subscription tiers in Recallr.
enum SubscriptionTier {
  starter(
    id: 'starter',
    displayName: 'Starter',
    tagline: 'Personal Memory Vault',
    monthlyPriceInr: 0,
    annualPriceInr: 0,
    monthlyPriceUsd: 0.0,
    annualPriceUsd: 0.0,
    storageLimitBytes: 104857600, // 100 MB
    monthlyCreditsTotal: 20,
    maxContacts: 50,
  ),
  pro(
    id: 'pro',
    displayName: 'Pro Networker',
    tagline: 'Active Dealmakers & Executives',
    monthlyPriceInr: 49,
    annualPriceInr: 399,
    monthlyPriceUsd: 0.99,
    annualPriceUsd: 7.99,
    storageLimitBytes: 1610612736, // 1.5 GB
    monthlyCreditsTotal: 250,
    maxContacts: -1, // Unlimited
  ),
  executive(
    id: 'executive',
    displayName: 'Executive',
    tagline: 'High-Volume Power Operators',
    monthlyPriceInr: 149,
    annualPriceInr: 1299,
    monthlyPriceUsd: 1.99,
    annualPriceUsd: 16.99,
    storageLimitBytes: 6442450944, // 6.0 GB
    monthlyCreditsTotal: 1000,
    maxContacts: -1, // Unlimited
  );

  final String id;
  final String displayName;
  final String tagline;
  final int monthlyPriceInr;
  final int annualPriceInr;
  final double monthlyPriceUsd;
  final double annualPriceUsd;
  final int storageLimitBytes;
  final int monthlyCreditsTotal;
  final int maxContacts;

  const SubscriptionTier({
    required this.id,
    required this.displayName,
    required this.tagline,
    required this.monthlyPriceInr,
    required this.annualPriceInr,
    required this.monthlyPriceUsd,
    required this.annualPriceUsd,
    required this.storageLimitBytes,
    required this.monthlyCreditsTotal,
    required this.maxContacts,
  });

  static SubscriptionTier fromId(String? id) {
    if (id == null) return SubscriptionTier.starter;
    return SubscriptionTier.values.firstWhere(
      (t) => t.id == id.toLowerCase(),
      orElse: () => SubscriptionTier.starter,
    );
  }

  bool get isUnlimitedContacts => maxContacts == -1;

  double get storageLimitMb => storageLimitBytes / (1024 * 1024);
  double get storageLimitGb => storageLimitBytes / (1024 * 1024 * 1024);

  String get formattedStorageLimit {
    if (storageLimitGb >= 1.0) {
      return '${storageLimitGb.toStringAsFixed(1)} GB';
    }
    return '${storageLimitMb.toStringAsFixed(0)} MB';
  }
}

/// Available micro top-up credit packs (credits never expire).
enum CreditPack {
  pack150(
    id: 'credit_pack_150',
    credits: 150,
    priceInr: 19,
    priceUsd: 0.49,
    title: '150 AI Credits',
    subtitle: 'Quick networking boost',
  ),
  pack500(
    id: 'credit_pack_500',
    credits: 500,
    priceInr: 49,
    priceUsd: 0.99,
    title: '500 AI Credits',
    subtitle: 'Most popular top-up',
    isPopular: true,
  ),
  pack1500(
    id: 'credit_pack_1500',
    credits: 1500,
    priceInr: 129,
    priceUsd: 1.99,
    title: '1,500 AI Credits',
    subtitle: 'Best value pack',
  );

  final String id;
  final int credits;
  final int priceInr;
  final double priceUsd;
  final String title;
  final String subtitle;
  final bool isPopular;

  const CreditPack({
    required this.id,
    required this.credits,
    required this.priceInr,
    required this.priceUsd,
    required this.title,
    required this.subtitle,
    this.isPopular = false,
  });

  static CreditPack? fromId(String id) {
    for (final pack in CreditPack.values) {
      if (pack.id == id) return pack;
    }
    return null;
  }
}

/// Represents the active user subscription, credit ledger, and storage quota.
class UserSubscription {
  final SubscriptionTier tier;
  final String status; // active, past_due, canceled
  final String currency; // INR, USD
  final int storageLimitBytes;
  final int storageUsedBytes;
  final int monthlyCreditsTotal;
  final int monthlyCreditsUsed;
  final int purchasedCredits;
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final String billingProvider; // store, stripe, manual, mock
  final String? productId;
  final DateTime updatedAt;

  const UserSubscription({
    required this.tier,
    this.status = 'active',
    this.currency = 'INR',
    required this.storageLimitBytes,
    this.storageUsedBytes = 0,
    required this.monthlyCreditsTotal,
    this.monthlyCreditsUsed = 0,
    this.purchasedCredits = 0,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    this.billingProvider = 'mock',
    this.productId,
    required this.updatedAt,
  });

  /// Default Starter tier instance for new accounts.
  factory UserSubscription.defaultStarter() {
    final now = DateTime.now();
    return UserSubscription(
      tier: SubscriptionTier.starter,
      status: 'active',
      currency: 'INR',
      storageLimitBytes: SubscriptionTier.starter.storageLimitBytes,
      storageUsedBytes: 0,
      monthlyCreditsTotal: SubscriptionTier.starter.monthlyCreditsTotal,
      monthlyCreditsUsed: 0,
      purchasedCredits: 0,
      currentPeriodStart: now,
      currentPeriodEnd: now.add(const Duration(days: 30)),
      billingProvider: 'mock',
      updatedAt: now,
    );
  }

  /// Remaining monthly plan credits.
  int get remainingMonthlyCredits {
    final remaining = monthlyCreditsTotal - monthlyCreditsUsed;
    return remaining > 0 ? remaining : 0;
  }

  /// Total available credits including top-up balance.
  int get totalAvailableCredits => remainingMonthlyCredits + purchasedCredits;

  /// Whether the user has any AI credits remaining.
  bool get hasAiCredits => totalAvailableCredits > 0;

  /// Percentage of monthly credits used (0.0 to 1.0).
  double get monthlyCreditsUsageRatio {
    if (monthlyCreditsTotal <= 0) return 1.0;
    return (monthlyCreditsUsed / monthlyCreditsTotal).clamp(0.0, 1.0);
  }

  /// Percentage of cloud storage used (0.0 to 1.0).
  double get storageUsageRatio {
    if (storageLimitBytes <= 0) return 1.0;
    return (storageUsedBytes / storageLimitBytes).clamp(0.0, 1.0);
  }

  /// Human-readable storage used in MB or GB.
  String get formattedStorageUsed {
    final usedMb = storageUsedBytes / (1024 * 1024);
    if (usedMb >= 1024) {
      return '${(usedMb / 1024).toStringAsFixed(2)} GB';
    }
    return '${usedMb.toStringAsFixed(1)} MB';
  }

  /// Human-readable storage limit.
  String get formattedStorageLimit {
    final limitMb = storageLimitBytes / (1024 * 1024);
    if (limitMb >= 1024) {
      return '${(limitMb / 1024).toStringAsFixed(1)} GB';
    }
    return '${limitMb.toStringAsFixed(0)} MB';
  }

  /// Check whether an upload of [additionalBytes] would exceed the storage limit.
  bool isStorageExceeded([int additionalBytes = 0]) {
    return (storageUsedBytes + additionalBytes) > storageLimitBytes;
  }

  /// Formatted localized price for a given tier.
  String formatPrice(SubscriptionTier targetTier, {bool annual = false}) {
    if (currency == 'USD') {
      final price = annual ? targetTier.annualPriceUsd : targetTier.monthlyPriceUsd;
      return price == 0 ? 'Free' : '\$${price.toStringAsFixed(2)}${annual ? '/yr' : '/mo'}';
    }
    final price = annual ? targetTier.annualPriceInr : targetTier.monthlyPriceInr;
    return price == 0 ? 'Free' : '₹$price${annual ? '/yr' : '/mo'}';
  }

  /// Formatted localized price for a credit pack.
  String formatCreditPackPrice(CreditPack pack) {
    if (currency == 'USD') {
      return '\$${pack.priceUsd.toStringAsFixed(2)}';
    }
    return '₹${pack.priceInr}';
  }

  UserSubscription copyWith({
    SubscriptionTier? tier,
    String? status,
    String? currency,
    int? storageLimitBytes,
    int? storageUsedBytes,
    int? monthlyCreditsTotal,
    int? monthlyCreditsUsed,
    int? purchasedCredits,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    String? billingProvider,
    String? productId,
    DateTime? updatedAt,
  }) {
    return UserSubscription(
      tier: tier ?? this.tier,
      status: status ?? this.status,
      currency: currency ?? this.currency,
      storageLimitBytes: storageLimitBytes ?? this.storageLimitBytes,
      storageUsedBytes: storageUsedBytes ?? this.storageUsedBytes,
      monthlyCreditsTotal: monthlyCreditsTotal ?? this.monthlyCreditsTotal,
      monthlyCreditsUsed: monthlyCreditsUsed ?? this.monthlyCreditsUsed,
      purchasedCredits: purchasedCredits ?? this.purchasedCredits,
      currentPeriodStart: currentPeriodStart ?? this.currentPeriodStart,
      currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
      billingProvider: billingProvider ?? this.billingProvider,
      productId: productId ?? this.productId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tier': tier.id,
      'status': status,
      'currency': currency,
      'storageLimitBytes': storageLimitBytes,
      'storageUsedBytes': storageUsedBytes,
      'monthlyCreditsTotal': monthlyCreditsTotal,
      'monthlyCreditsUsed': monthlyCreditsUsed,
      'purchasedCredits': purchasedCredits,
      'currentPeriodStart': Timestamp.fromDate(currentPeriodStart),
      'currentPeriodEnd': Timestamp.fromDate(currentPeriodEnd),
      'billingProvider': billingProvider,
      if (productId != null) 'productId': productId,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory UserSubscription.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return UserSubscription(
      tier: SubscriptionTier.fromId(map['tier'] as String?),
      status: map['status'] as String? ?? 'active',
      currency: map['currency'] as String? ?? 'INR',
      storageLimitBytes: (map['storageLimitBytes'] as num?)?.toInt() ??
          SubscriptionTier.starter.storageLimitBytes,
      storageUsedBytes: (map['storageUsedBytes'] as num?)?.toInt() ?? 0,
      monthlyCreditsTotal: (map['monthlyCreditsTotal'] as num?)?.toInt() ??
          SubscriptionTier.starter.monthlyCreditsTotal,
      monthlyCreditsUsed: (map['monthlyCreditsUsed'] as num?)?.toInt() ?? 0,
      purchasedCredits: (map['purchasedCredits'] as num?)?.toInt() ?? 0,
      currentPeriodStart: (map['currentPeriodStart'] as Timestamp?)?.toDate() ?? now,
      currentPeriodEnd: (map['currentPeriodEnd'] as Timestamp?)?.toDate() ??
          now.add(const Duration(days: 30)),
      billingProvider: map['billingProvider'] as String? ?? 'mock',
      productId: map['productId'] as String?,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? now,
    );
  }

  factory UserSubscription.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserSubscription.fromMap(data);
  }
}

/// Ledger record tracking credit deductions and purchases.
class CreditLedgerEntry {
  final String id;
  final DateTime timestamp;
  final String type; // debit, credit
  final int amount;
  final String reason; // ask_query, pack_purchase, monthly_renewal
  final Map<String, dynamic>? metadata;

  const CreditLedgerEntry({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.amount,
    required this.reason,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
      'amount': amount,
      'reason': reason,
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory CreditLedgerEntry.fromMap(Map<String, dynamic> map, String id) {
    return CreditLedgerEntry(
      id: id,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: map['type'] as String? ?? 'debit',
      amount: (map['amount'] as num?)?.toInt() ?? 1,
      reason: map['reason'] as String? ?? '',
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }
}
