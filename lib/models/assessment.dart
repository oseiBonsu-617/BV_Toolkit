import 'package:flutter/material.dart';

enum Symptom {
  headaches,
  eyestrain,
  diplopia,
  blurNear,
  blurDistance,
  readingDifficulty,
  wordMovement,
}

extension SymptomX on Symptom {
  String get label => switch (this) {
    Symptom.headaches => 'Headaches',
    Symptom.eyestrain => 'Eye strain',
    Symptom.diplopia => 'Double vision',
    Symptom.blurNear => 'Blur at near',
    Symptom.blurDistance => 'Blur at distance',
    Symptom.readingDifficulty => 'Reading difficulty',
    Symptom.wordMovement => 'Words moving',
  };
  IconData get icon => switch (this) {
    Symptom.headaches => Icons.sick_outlined,
    Symptom.eyestrain => Icons.visibility_off_outlined,
    Symptom.diplopia => Icons.filter_none_outlined,
    Symptom.blurNear => Icons.blur_on_outlined,
    Symptom.blurDistance => Icons.blur_circular_outlined,
    Symptom.readingDifficulty => Icons.menu_book_outlined,
    Symptom.wordMovement => Icons.swap_horiz_outlined,
  };
}

enum CoverResult { ortho, exo, eso, hyper }

extension CoverResultX on CoverResult {
  String get label => switch (this) {
    CoverResult.ortho => 'Ortho',
    CoverResult.exo => 'Exo',
    CoverResult.eso => 'Eso',
    CoverResult.hyper => 'Hyper',
  };
}

enum RecommendedSection {
  phoria,
  acaRatio,
  npc,
  vergenceDistance,
  vergenceNear,
  analysis,
  diagnosis,
}

extension RecommendedSectionX on RecommendedSection {
  String get label => switch (this) {
    RecommendedSection.phoria => 'Phoria',
    RecommendedSection.acaRatio => 'AC/A ratio',
    RecommendedSection.npc => 'NPC',
    RecommendedSection.vergenceDistance => 'Vergence — Distance',
    RecommendedSection.vergenceNear => 'Vergence — Near',
    RecommendedSection.analysis => "Sheard's / Percival's",
    RecommendedSection.diagnosis => 'Diagnosis inputs',
  };
  IconData get icon => switch (this) {
    RecommendedSection.phoria => Icons.remove_red_eye_outlined,
    RecommendedSection.acaRatio => Icons.functions,
    RecommendedSection.npc => Icons.open_with,
    RecommendedSection.vergenceDistance => Icons.compare_arrows,
    RecommendedSection.vergenceNear => Icons.compare_arrows,
    RecommendedSection.analysis => Icons.balance_outlined,
    RecommendedSection.diagnosis => Icons.medical_services_outlined,
  };
}

enum TestPriority { high, medium, low }

// ─── Management plan model ─────────────────────────────────────────────────

enum ManagementTier { firstLine, secondLine, adjunct }

extension ManagementTierX on ManagementTier {
  String get label => switch (this) {
    ManagementTier.firstLine  => '1st line',
    ManagementTier.secondLine => '2nd line',
    ManagementTier.adjunct    => 'Adjunct',
  };
}

class ManagementOption {
  final ManagementTier tier;
  final String title;
  final String detail;
  const ManagementOption({
    required this.tier,
    required this.title,
    required this.detail,
  });
}

class DiagnosisPlan {
  final String name;
  final List<String> criteria;
  final List<ManagementOption> options;
  final List<String> referralCriteria;
  final String reviewSchedule;
  final String patientAdvice;
  const DiagnosisPlan({
    required this.name,
    required this.criteria,
    required this.options,
    required this.referralCriteria,
    required this.reviewSchedule,
    required this.patientAdvice,
  });
}

class SectionRecommendation {
  final RecommendedSection section;
  final TestPriority priority;
  final String rationale;
  const SectionRecommendation({
    required this.section,
    required this.priority,
    required this.rationale,
  });
}

class AssessmentInput {
  final Set<Symptom> symptoms;
  final CoverResult? coverDistance;
  final CoverResult? coverNear;
  final String? vaDistance;
  final String? vaNear;
  final int? age;
  const AssessmentInput({
    required this.symptoms,
    this.coverDistance,
    this.coverNear,
    this.vaDistance,
    this.vaNear,
    this.age,
  });
}

class AssessmentResult {
  final String primaryImpression;
  final String? differential;
  final String rationale;
  final List<SectionRecommendation> recommendations;
  final List<String> flags;
  final DiagnosisPlan? plan;
  const AssessmentResult({
    required this.primaryImpression,
    this.differential,
    required this.rationale,
    required this.recommendations,
    this.flags = const [],
    this.plan,
  });

  List<SectionRecommendation> get sorted {
    final order = [TestPriority.high, TestPriority.medium, TestPriority.low];
    final copy = [...recommendations];
    copy.sort((a, b) => order.indexOf(a.priority).compareTo(order.indexOf(b.priority)));
    return copy;
  }

  Set<RecommendedSection> get allSections =>
      recommendations.map((r) => r.section).toSet();
}
