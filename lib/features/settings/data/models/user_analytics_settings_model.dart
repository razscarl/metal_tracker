class UserAnalyticsSettings {
  final String userId;
  // Gold-Silver Ratio
  final double gsrLowMark;
  final double gsrHighMark;
  final String gsrLowText;
  final String gsrHighText;
  final String gsrMidText;
  // Local Premium
  final double lpLowMark;
  final double lpHighMark;
  final String lpLowText;
  final String lpHighText;
  final String lpMidText;
  // Dealer Spread — Gold
  final double spreadGoldBuyPct;
  final double spreadGoldHoldPct;
  // Dealer Spread — Silver
  final double spreadSilverBuyPct;
  final double spreadSilverHoldPct;
  // Dealer Spread — Platinum
  final double spreadPlatBuyPct;
  final double spreadPlatHoldPct;
  // Local Spread — shared labels (low/mid/high)
  final String spreadLowLabel;
  final String spreadMidLabel;
  final String spreadHighLabel;

  const UserAnalyticsSettings({
    required this.userId,
    this.gsrLowMark = 60.0,
    this.gsrHighMark = 70.0,
    this.gsrLowText = 'Buy Gold',
    this.gsrHighText = 'Buy Silver',
    this.gsrMidText = 'Hold',
    this.lpLowMark = -2.0,
    this.lpHighMark = 2.0,
    this.lpLowText = 'Buy Now',
    this.lpHighText = 'Avoid',
    this.lpMidText = 'Neutral',
    this.spreadGoldBuyPct = 2.0,
    this.spreadGoldHoldPct = 5.0,
    this.spreadSilverBuyPct = 10.0,
    this.spreadSilverHoldPct = 20.0,
    this.spreadPlatBuyPct = 25.0,
    this.spreadPlatHoldPct = 35.0,
    this.spreadLowLabel = 'Buy',
    this.spreadMidLabel = 'Hold',
    this.spreadHighLabel = 'Avoid',
  });

  factory UserAnalyticsSettings.defaults(String userId) {
    return UserAnalyticsSettings(userId: userId);
  }

  factory UserAnalyticsSettings.fromJson(Map<String, dynamic> json) {
    return UserAnalyticsSettings(
      userId: json['user_id'] as String,
      gsrLowMark: (json['gsr_low_mark'] as num?)?.toDouble() ?? 60.0,
      gsrHighMark: (json['gsr_high_mark'] as num?)?.toDouble() ?? 70.0,
      gsrLowText: json['gsr_low_text'] as String? ?? 'Buy Gold',
      gsrHighText: json['gsr_high_text'] as String? ?? 'Buy Silver',
      gsrMidText: json['gsr_mid_text'] as String? ?? 'Hold',
      lpLowMark: (json['lp_low_mark'] as num?)?.toDouble() ?? -2.0,
      lpHighMark: (json['lp_high_mark'] as num?)?.toDouble() ?? 2.0,
      lpLowText: json['lp_low_text'] as String? ?? 'Buy Now',
      lpHighText: json['lp_high_text'] as String? ?? 'Avoid',
      lpMidText: json['lp_mid_text'] as String? ?? 'Neutral',
      spreadGoldBuyPct:
          (json['spread_gold_buy_pct'] as num?)?.toDouble() ?? 2.0,
      spreadGoldHoldPct:
          (json['spread_gold_hold_pct'] as num?)?.toDouble() ?? 5.0,
      spreadSilverBuyPct:
          (json['spread_silver_buy_pct'] as num?)?.toDouble() ?? 10.0,
      spreadSilverHoldPct:
          (json['spread_silver_hold_pct'] as num?)?.toDouble() ?? 20.0,
      spreadPlatBuyPct:
          (json['spread_plat_buy_pct'] as num?)?.toDouble() ?? 25.0,
      spreadPlatHoldPct:
          (json['spread_plat_hold_pct'] as num?)?.toDouble() ?? 35.0,
      spreadLowLabel: json['spread_low_label'] as String? ?? 'Buy',
      spreadMidLabel: json['spread_mid_label'] as String? ?? 'Hold',
      spreadHighLabel: json['spread_high_label'] as String? ?? 'Avoid',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'gsr_low_mark': gsrLowMark,
      'gsr_high_mark': gsrHighMark,
      'gsr_low_text': gsrLowText,
      'gsr_high_text': gsrHighText,
      'gsr_mid_text': gsrMidText,
      'lp_low_mark': lpLowMark,
      'lp_high_mark': lpHighMark,
      'lp_low_text': lpLowText,
      'lp_high_text': lpHighText,
      'lp_mid_text': lpMidText,
      'spread_gold_buy_pct': spreadGoldBuyPct,
      'spread_gold_hold_pct': spreadGoldHoldPct,
      'spread_silver_buy_pct': spreadSilverBuyPct,
      'spread_silver_hold_pct': spreadSilverHoldPct,
      'spread_plat_buy_pct': spreadPlatBuyPct,
      'spread_plat_hold_pct': spreadPlatHoldPct,
      'spread_low_label': spreadLowLabel,
      'spread_mid_label': spreadMidLabel,
      'spread_high_label': spreadHighLabel,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  UserAnalyticsSettings copyWith({
    double? gsrLowMark,
    double? gsrHighMark,
    String? gsrLowText,
    String? gsrHighText,
    String? gsrMidText,
    double? lpLowMark,
    double? lpHighMark,
    String? lpLowText,
    String? lpHighText,
    String? lpMidText,
    double? spreadGoldBuyPct,
    double? spreadGoldHoldPct,
    double? spreadSilverBuyPct,
    double? spreadSilverHoldPct,
    double? spreadPlatBuyPct,
    double? spreadPlatHoldPct,
    String? spreadLowLabel,
    String? spreadMidLabel,
    String? spreadHighLabel,
  }) {
    return UserAnalyticsSettings(
      userId: userId,
      gsrLowMark: gsrLowMark ?? this.gsrLowMark,
      gsrHighMark: gsrHighMark ?? this.gsrHighMark,
      gsrLowText: gsrLowText ?? this.gsrLowText,
      gsrHighText: gsrHighText ?? this.gsrHighText,
      gsrMidText: gsrMidText ?? this.gsrMidText,
      lpLowMark: lpLowMark ?? this.lpLowMark,
      lpHighMark: lpHighMark ?? this.lpHighMark,
      lpLowText: lpLowText ?? this.lpLowText,
      lpHighText: lpHighText ?? this.lpHighText,
      lpMidText: lpMidText ?? this.lpMidText,
      spreadGoldBuyPct: spreadGoldBuyPct ?? this.spreadGoldBuyPct,
      spreadGoldHoldPct: spreadGoldHoldPct ?? this.spreadGoldHoldPct,
      spreadSilverBuyPct: spreadSilverBuyPct ?? this.spreadSilverBuyPct,
      spreadSilverHoldPct: spreadSilverHoldPct ?? this.spreadSilverHoldPct,
      spreadPlatBuyPct: spreadPlatBuyPct ?? this.spreadPlatBuyPct,
      spreadPlatHoldPct: spreadPlatHoldPct ?? this.spreadPlatHoldPct,
      spreadLowLabel: spreadLowLabel ?? this.spreadLowLabel,
      spreadMidLabel: spreadMidLabel ?? this.spreadMidLabel,
      spreadHighLabel: spreadHighLabel ?? this.spreadHighLabel,
    );
  }
}
