enum CompatibilityLevel {
  cocok,
  perluPerhatian,
  kurangCocok,
}

class FoodCompatibilityResult {
  final CompatibilityLevel level;
  final String title;
  final String summary;
  final String detailAdvice;
  final double? kaloriPercent;
  final double? proteinPercent;
  final double? lemakPercent;
  final double? karbohidratPercent;
  final double? gulaPercent;
  final double userTargetKalori;
  final String? userStatus;
  final bool isGuestFallback;
  final List<String> highlights;
  final List<String> warnings;

  const FoodCompatibilityResult({
    required this.level,
    required this.title,
    required this.summary,
    required this.detailAdvice,
    this.kaloriPercent,
    this.proteinPercent,
    this.lemakPercent,
    this.karbohidratPercent,
    this.gulaPercent,
    required this.userTargetKalori,
    this.userStatus,
    required this.isGuestFallback,
    this.highlights = const [],
    this.warnings = const [],
  });
}
