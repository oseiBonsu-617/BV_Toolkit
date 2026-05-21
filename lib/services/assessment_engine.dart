import '../models/assessment.dart';
import '../models/test_session.dart';

class AssessmentEngine {
  // ─── Public entry points ────────────────────────────────────────────────────

  AssessmentResult assess(AssessmentInput input) {
    final s   = input.symptoms;
    final cd  = input.coverDistance;
    final cn  = input.coverNear;
    final age = input.age;

    final nearSymptoms = s.contains(Symptom.eyestrain) ||
        s.contains(Symptom.headaches) ||
        s.contains(Symptom.readingDifficulty) ||
        s.contains(Symptom.wordMovement) ||
        s.contains(Symptom.blurNear);

    final distanceSymptoms =
        s.contains(Symptom.blurDistance) || s.contains(Symptom.diplopia);

    final flags = <String>[];
    if (_isVaReduced(input.vaDistance, near: false)) {
      flags.add('Reduced distance VA (${input.vaDistance}) — optimise refractive correction before BV assessment.');
    }
    if (_isVaReduced(input.vaNear, near: true)) {
      flags.add('Reduced near VA (${input.vaNear}) — check near correction before interpreting near BV findings.');
    }
    if (age != null && age >= 40) {
      flags.add('Age ≥ 40 — accommodative amplitude reduction is expected (Donders\' norm); interpret amplitude and MEM accordingly.');
    }
    if (s.contains(Symptom.diplopia)) {
      flags.add('Diplopia reported — if phoria is large or decompensating, consider a full strabismus evaluation.');
    }

    // CI
    if (cn == CoverResult.exo && nearSymptoms) {
      return AssessmentResult(
        primaryImpression: 'Convergence Insufficiency',
        differential: 'Accommodative insufficiency',
        rationale: 'Exophoria at near with near-related symptoms is the hallmark of CI. Receded NPC and reduced BO vergence at near are expected findings.',
        recommendations: _ciRecs(),
        flags: flags,
        plan: _ciPlan(),
      );
    }

    // CE
    if (cn == CoverResult.eso && nearSymptoms) {
      return AssessmentResult(
        primaryImpression: 'Convergence Excess',
        differential: 'Accommodative esotropia',
        rationale: 'Esophoria at near with near symptoms suggests CE. High AC/A ratio is the key diagnostic feature. Gradient method is preferred.',
        recommendations: _ceRecs(),
        flags: flags,
        plan: _cePlan(),
      );
    }

    // DI
    if (cd == CoverResult.eso &&
        (cn == null || cn == CoverResult.ortho || cn == CoverResult.exo)) {
      final diFlags = [
        ...flags,
        if (s.contains(Symptom.diplopia))
          'Sudden-onset distance diplopia with esophoria warrants neurological referral to rule out VI nerve palsy.',
      ];
      return AssessmentResult(
        primaryImpression: 'Divergence Insufficiency',
        differential: 'Basic esophoria / VI nerve palsy',
        rationale: 'Esophoria greater at distance than near suggests DI. Rule out neurological causes if onset is sudden or diplopia is present.',
        recommendations: _diRecs(),
        flags: diFlags,
        plan: _diPlan(),
      );
    }

    // DE
    if (cd == CoverResult.exo &&
        (cn == null || cn == CoverResult.ortho) &&
        distanceSymptoms) {
      return AssessmentResult(
        primaryImpression: 'Divergence Excess',
        differential: 'Pseudo-divergence excess / basic exophoria',
        rationale: 'Exophoria greater at distance with distance symptoms suggests DE. +3.00 lens or occlusion test can differentiate true DE from pseudo-DE.',
        recommendations: _deRecs(),
        flags: flags,
        plan: _dePlan(),
      );
    }

    // Basic Exo + near symptoms → CI likely
    if (cd == CoverResult.exo && cn == CoverResult.exo && nearSymptoms) {
      return AssessmentResult(
        primaryImpression: 'Convergence Insufficiency (likely)',
        differential: 'Basic exophoria',
        rationale: 'Exophoria at both distances with near-specific symptoms favours CI. NPC is the key differentiator.',
        recommendations: _ciRecs(),
        flags: flags,
        plan: _ciPlan(),
      );
    }

    // Basic Exo
    if (cd == CoverResult.exo && cn == CoverResult.exo) {
      return AssessmentResult(
        primaryImpression: 'Basic Exophoria',
        differential: 'Convergence insufficiency / Divergence excess',
        rationale: 'Exophoria approximately equal at both distances without a clear pattern. Full vergence and NPC profile needed to classify.',
        recommendations: _basicExoRecs(),
        flags: flags,
        plan: _basicExoPlan(),
      );
    }

    // Basic Eso
    if (cd == CoverResult.eso && cn == CoverResult.eso) {
      return AssessmentResult(
        primaryImpression: 'Basic Esophoria',
        differential: 'Divergence insufficiency / Convergence excess',
        rationale: 'Esophoria approximately equal at distance and near. AC/A ratio and symptom profile will differentiate.',
        recommendations: _basicEsoRecs(),
        flags: flags,
        plan: _basicEsoPlan(),
      );
    }

    // Accommodative
    if (nearSymptoms &&
        (cd == CoverResult.ortho || cn == CoverResult.ortho || (cd == null && cn == null)) &&
        (age == null || age < 40)) {
      return AssessmentResult(
        primaryImpression: 'Accommodative Dysfunction',
        differential: 'Convergence insufficiency / Vergence anomaly',
        rationale: 'Near symptoms with minimal phoria suggest an accommodative component (AI, excess, or infacility). AC/A and MEM will differentiate.',
        recommendations: _accommodativeRecs(),
        flags: flags,
        plan: _accommodativePlan(),
      );
    }

    // Presbyopia
    if (s.contains(Symptom.blurNear) && age != null && age >= 40) {
      return AssessmentResult(
        primaryImpression: 'Presbyopia / Age-related Near Difficulty',
        differential: 'Accommodative insufficiency',
        rationale: 'Near blur in a patient ≥ 40 years is most likely presbyopia. A BV overlay is possible if symptoms are disproportionate to the refractive add.',
        recommendations: _presbyopiaRecs(),
        flags: flags,
        plan: _presbyopiaPlan(),
      );
    }

    // Full battery fallthrough
    return AssessmentResult(
      primaryImpression: 'No Specific Pattern — Full BV Workup',
      rationale: 'Insufficient signs to identify a primary pattern. A complete BV battery is recommended.',
      recommendations: _fullRecs(),
      flags: flags,
    );
  }

  /// Derive a management plan from actual measured session values.
  DiagnosisPlan? planFromSession(TestSession session) {
    final phNear = session.numVal('ph_near');
    final phDist = session.numVal('ph_dist');
    final npcBrk = session.numVal('npc_brk');
    final npcRec = session.numVal('npc_rec');

    if (phNear == null && phDist == null) return null;

    final nearExo  = phNear != null && phNear  >  2;
    final nearEso  = phNear != null && phNear  < -2;
    final distExo  = phDist != null && phDist  >  2;
    final distEso  = phDist != null && phDist  < -2;
    final npcBad   = (npcBrk != null && npcBrk > 5) || (npcRec != null && npcRec > 7);

    if (nearExo && npcBad)                      return _ciPlan();
    if (distEso && !nearEso)                    return _diPlan();
    if (distExo && !nearExo && distExo)         return _dePlan();
    if (nearEso && (!distEso || phNear < phDist - 2)) {
      return _cePlan();
    }
    if (nearExo)                                return _basicExoPlan();
    if (nearEso && distEso)                     return _basicEsoPlan();
    return null;
  }

  // ─── Recommendation lists ───────────────────────────────────────────────────

  List<SectionRecommendation> _ciRecs() => const [
    SectionRecommendation(section: RecommendedSection.npc,           priority: TestPriority.high,   rationale: 'Receded NPC (>5 cm break) is a primary CI diagnostic criterion.'),
    SectionRecommendation(section: RecommendedSection.phoria,        priority: TestPriority.high,   rationale: 'Near exophoria magnitude determines Sheard\'s criterion threshold.'),
    SectionRecommendation(section: RecommendedSection.vergenceNear,  priority: TestPriority.high,   rationale: 'Reduced BO vergence at near confirms CI; BI vergence may be elevated.'),
    SectionRecommendation(section: RecommendedSection.analysis,      priority: TestPriority.high,   rationale: 'Sheard\'s criterion directly tests whether BO vergence compensates for the exophoria.'),
    SectionRecommendation(section: RecommendedSection.acaRatio,      priority: TestPriority.medium, rationale: 'Low AC/A is typical in CI; differentiates from convergence excess.'),
    SectionRecommendation(section: RecommendedSection.diagnosis,     priority: TestPriority.medium, rationale: 'Record facility and MEM for a complete accommodative-vergence profile.'),
  ];

  List<SectionRecommendation> _ceRecs() => const [
    SectionRecommendation(section: RecommendedSection.phoria,        priority: TestPriority.high,   rationale: 'Near esophoria is the primary finding; compare distance vs near magnitude.'),
    SectionRecommendation(section: RecommendedSection.acaRatio,      priority: TestPriority.high,   rationale: 'High AC/A (>7 Δ/D) defines CE; gradient method preferred.'),
    SectionRecommendation(section: RecommendedSection.vergenceNear,  priority: TestPriority.high,   rationale: 'Reduced BI vergence at near confirms the convergence excess pattern.'),
    SectionRecommendation(section: RecommendedSection.analysis,      priority: TestPriority.medium, rationale: 'Percival\'s criterion for the esophoric patient.'),
    SectionRecommendation(section: RecommendedSection.diagnosis,     priority: TestPriority.medium, rationale: 'MEM lag and facility may reveal an accommodative excess component.'),
  ];

  List<SectionRecommendation> _diRecs() => const [
    SectionRecommendation(section: RecommendedSection.phoria,           priority: TestPriority.high,   rationale: 'Confirm distance esophoria exceeds near; this gradient is diagnostic for DI.'),
    SectionRecommendation(section: RecommendedSection.vergenceDistance, priority: TestPriority.high,   rationale: 'Reduced BI vergence at distance is the primary vergence finding in DI.'),
    SectionRecommendation(section: RecommendedSection.acaRatio,         priority: TestPriority.medium, rationale: 'Low AC/A differentiates DI from CE with uncorrected hyperopia.'),
    SectionRecommendation(section: RecommendedSection.analysis,         priority: TestPriority.medium, rationale: 'Percival\'s criterion evaluates distance fusional reserve balance.'),
  ];

  List<SectionRecommendation> _deRecs() => const [
    SectionRecommendation(section: RecommendedSection.phoria,           priority: TestPriority.high,   rationale: 'Confirm exophoria is greater at distance than near.'),
    SectionRecommendation(section: RecommendedSection.vergenceDistance, priority: TestPriority.high,   rationale: 'BO vergence at distance assesses compensation for the distance exophoria.'),
    SectionRecommendation(section: RecommendedSection.acaRatio,         priority: TestPriority.medium, rationale: 'High AC/A may indicate pseudo-DE; guides treatment (minus lens vs prism).'),
    SectionRecommendation(section: RecommendedSection.vergenceNear,     priority: TestPriority.low,    rationale: 'Near vergence for a complete profile.'),
  ];

  List<SectionRecommendation> _basicExoRecs() => const [
    SectionRecommendation(section: RecommendedSection.phoria,        priority: TestPriority.high,   rationale: 'Quantify phoria at both distances; equal magnitudes confirm basic exophoria.'),
    SectionRecommendation(section: RecommendedSection.npc,           priority: TestPriority.high,   rationale: 'Receded NPC would reclassify this as CI even when distance exo is equal.'),
    SectionRecommendation(section: RecommendedSection.vergenceNear,  priority: TestPriority.high,   rationale: 'BO vergence at near is the primary treatment target in exophoria.'),
    SectionRecommendation(section: RecommendedSection.vergenceDistance, priority: TestPriority.medium, rationale: 'Complete the vergence profile for both distances.'),
    SectionRecommendation(section: RecommendedSection.acaRatio,      priority: TestPriority.medium, rationale: 'AC/A differentiates CI (low) from DE (high).'),
    SectionRecommendation(section: RecommendedSection.analysis,      priority: TestPriority.high,   rationale: 'Sheard\'s criterion for exophoric patients.'),
  ];

  List<SectionRecommendation> _basicEsoRecs() => const [
    SectionRecommendation(section: RecommendedSection.phoria,           priority: TestPriority.high,   rationale: 'Equal esophoria at both distances confirms basic esophoria pattern.'),
    SectionRecommendation(section: RecommendedSection.acaRatio,         priority: TestPriority.high,   rationale: 'Normal AC/A confirms basic esophoria; high/low redirects to CE or DI.'),
    SectionRecommendation(section: RecommendedSection.vergenceDistance, priority: TestPriority.high,   rationale: 'BI vergence at distance assesses fusional reserve.'),
    SectionRecommendation(section: RecommendedSection.vergenceNear,     priority: TestPriority.high,   rationale: 'BI vergence at near completes the bilateral profile.'),
    SectionRecommendation(section: RecommendedSection.analysis,         priority: TestPriority.medium, rationale: 'Percival\'s criterion for the esophoric patient.'),
  ];

  List<SectionRecommendation> _accommodativeRecs() => const [
    SectionRecommendation(section: RecommendedSection.phoria,        priority: TestPriority.high,   rationale: 'Establish phoria profile to differentiate accommodative from vergence aetiology.'),
    SectionRecommendation(section: RecommendedSection.acaRatio,      priority: TestPriority.high,   rationale: 'AC/A is central to differentiating AI, CE, and accommodative spasm.'),
    SectionRecommendation(section: RecommendedSection.diagnosis,     priority: TestPriority.high,   rationale: 'Amplitude, facility, MEM, and NPC break are the core accommodative battery.'),
    SectionRecommendation(section: RecommendedSection.npc,           priority: TestPriority.medium, rationale: 'Rule out CI as a co-existing or primary diagnosis.'),
    SectionRecommendation(section: RecommendedSection.vergenceNear,  priority: TestPriority.medium, rationale: 'BO vergence at near for a complete accommodative-vergence interaction profile.'),
  ];

  List<SectionRecommendation> _presbyopiaRecs() => const [
    SectionRecommendation(section: RecommendedSection.phoria,       priority: TestPriority.high,   rationale: 'Decompensating exophoria at near is common in presbyopes.'),
    SectionRecommendation(section: RecommendedSection.diagnosis,    priority: TestPriority.high,   rationale: 'Amplitude confirms presbyopia; MEM and facility useful for add optimisation.'),
    SectionRecommendation(section: RecommendedSection.npc,          priority: TestPriority.medium, rationale: 'NPC may be receded in presbyopes, mimicking CI symptoms.'),
    SectionRecommendation(section: RecommendedSection.vergenceNear, priority: TestPriority.low,    rationale: 'Near vergence baseline if add change is planned or symptoms persist.'),
  ];

  List<SectionRecommendation> _fullRecs() => const [
    SectionRecommendation(section: RecommendedSection.phoria,           priority: TestPriority.high,   rationale: 'Distance and near phoria is the foundation of the BV profile.'),
    SectionRecommendation(section: RecommendedSection.npc,              priority: TestPriority.high,   rationale: 'NPC is a sensitive screening test for convergence function.'),
    SectionRecommendation(section: RecommendedSection.acaRatio,         priority: TestPriority.high,   rationale: 'AC/A ratio guides classification of any identified phoria.'),
    SectionRecommendation(section: RecommendedSection.vergenceDistance, priority: TestPriority.medium, rationale: 'Distance vergence profile.'),
    SectionRecommendation(section: RecommendedSection.vergenceNear,     priority: TestPriority.medium, rationale: 'Near vergence profile.'),
    SectionRecommendation(section: RecommendedSection.analysis,         priority: TestPriority.medium, rationale: 'Sheard\'s / Percival\'s once phoria and vergence are known.'),
    SectionRecommendation(section: RecommendedSection.diagnosis,        priority: TestPriority.low,    rationale: 'Full accommodative battery if near symptoms are present.'),
  ];

  // ─── Diagnosis & management plans ──────────────────────────────────────────

  DiagnosisPlan _ciPlan() => const DiagnosisPlan(
    name: 'Convergence Insufficiency (CI)',
    criteria: [
      'Exophoria at near ≥ 4Δ greater than at distance',
      'NPC break > 6 cm (or > 5 cm on repeated testing)',
      'BO fusional vergence at near failing Sheard\'s criterion',
    ],
    options: [
      ManagementOption(
        tier: ManagementTier.firstLine,
        title: 'Office-based vision therapy',
        detail: '12–24 sessions. Evidence-based first choice (CITT trial). Includes Brock string, pencil push-ups, stereogram cards, jump vergences, and computer-based VT (HTS / Vivid Vision).',
      ),
      ManagementOption(
        tier: ManagementTier.secondLine,
        title: 'Base-in prism',
        detail: 'Prescribe 1/3 of Sheard\'s criterion value as BI prism. Use if VT is declined or after VT plateau. Relieves symptoms but does not resolve the underlying deficit.',
      ),
      ManagementOption(
        tier: ManagementTier.adjunct,
        title: 'Home VT programme',
        detail: 'Pencil push-ups (15 min/day) and Brock string home practice. Less effective than office-based VT; useful as maintenance between sessions.',
      ),
    ],
    referralCriteria: [
      'Manifest (constant) exotropia at near',
      'Diplopia persisting after completing vision therapy',
      'Neurological symptoms (sudden onset, papilloedema, headache)',
    ],
    reviewSchedule: 'Review at 4–6 weeks after VT initiation. Reassess at 3 months. Discharge when CISS score normalises and NPC ≤ 5 cm.',
    patientAdvice: 'Apply the 20-20-20 rule during near work (20 min → 20 s looking at 20 feet). Ensure adequate desk lighting and comfortable screen distance. Slightly inclined reading surface may reduce symptoms.',
  );

  DiagnosisPlan _cePlan() => const DiagnosisPlan(
    name: 'Convergence Excess (CE)',
    criteria: [
      'Esophoria at near ≥ 4–6Δ greater than at distance',
      'AC/A ratio > 7 Δ/D (gradient method)',
      'Reduced negative fusional vergence (BI) at near',
    ],
    options: [
      ManagementOption(
        tier: ManagementTier.firstLine,
        title: 'Plus lenses at near',
        detail: 'Prescribe +1.00 to +2.00 D reading addition to reduce accommodative convergence demand. Perform cycloplegic refraction first to rule out latent hyperopia.',
      ),
      ManagementOption(
        tier: ManagementTier.secondLine,
        title: 'Vision therapy',
        detail: 'BI fusional vergence training, accommodative facility exercises (flippers). Indicated if plus lenses alone are insufficient or declined.',
      ),
      ManagementOption(
        tier: ManagementTier.adjunct,
        title: 'Base-in prism at near',
        detail: 'Add BI prism to near Rx if plus lens alone is insufficient. Use Percival\'s criterion to determine prism amount.',
      ),
    ],
    referralCriteria: [
      'Manifest esotropia (constant or intermittent tropia at near)',
      'Suspected accommodative esotropia in a child — cycloplegic refraction and orthoptic referral',
      'Non-compliant child with large-angle eso not responding to plus lenses',
    ],
    reviewSchedule: 'Review 4–6 weeks after prescribing plus lenses. If eso resolves, reassess annually. If persists, initiate VT.',
    patientAdvice: 'Wear near correction consistently, especially for reading and device use. Avoid prolonged near work without correction. Ensure full hyperopic prescription is worn if applicable.',
  );

  DiagnosisPlan _diPlan() => const DiagnosisPlan(
    name: 'Divergence Insufficiency (DI)',
    criteria: [
      'Esophoria greater at distance than near',
      'Reduced BI vergence at distance',
      'Normal or low AC/A ratio',
    ],
    options: [
      ManagementOption(
        tier: ManagementTier.firstLine,
        title: 'Base-in prism at distance',
        detail: 'Prescribe BI prism in distance correction. Start with 1Δ BI per eye; adjust to comfort. Provides immediate relief. Use Percival\'s criterion to guide amount.',
      ),
      ManagementOption(
        tier: ManagementTier.secondLine,
        title: 'Vision therapy (divergence)',
        detail: 'Distance BO vergence training, anti-suppression therapy. Longer treatment course than CI; results are variable.',
      ),
    ],
    referralCriteria: [
      'URGENT: Sudden-onset diplopia — rule out VI nerve palsy (neurological referral same day)',
      'Diplopia not controlled with prism after 6 weeks of wear',
      'Progressive increase in deviation angle',
    ],
    reviewSchedule: 'If neurological concern: refer urgently. For stable cases, review 2–4 weeks after prism prescription.',
    patientAdvice: 'Report immediately if diplopia worsens, becomes constant, or if new symptoms develop (facial numbness, severe headache, diplopia at near). Avoid driving if diplopia is uncontrolled.',
  );

  DiagnosisPlan _dePlan() => const DiagnosisPlan(
    name: 'Divergence Excess (DE)',
    criteria: [
      'Exophoria or exotropia greater at distance than near',
      'Deviation increases with prolonged cover (true DE excluded if not)',
      'AC/A ratio may be elevated (pseudo-DE)',
    ],
    options: [
      ManagementOption(
        tier: ManagementTier.firstLine,
        title: 'Minus lens trial',
        detail: 'If pseudo-DE confirmed (high AC/A): -1.00 to -2.00 D full-time lens to stimulate accommodative convergence. Re-evaluate at 6–8 weeks.',
      ),
      ManagementOption(
        tier: ManagementTier.secondLine,
        title: 'Vision therapy',
        detail: 'Anti-suppression therapy (Bagolini lenses, red filter), divergence awareness, jump vergence exercises at distance.',
      ),
      ManagementOption(
        tier: ManagementTier.adjunct,
        title: 'Patching / penalisation',
        detail: 'Part-time patching of the non-deviating eye to reduce suppression and stimulate fusion. Used alongside VT.',
      ),
    ],
    referralCriteria: [
      'Constant exotropia or large-angle (> 20Δ) intermittent exotropia',
      'Cosmetically significant deviation',
      'Failure to control with non-surgical treatment after 6 months',
    ],
    reviewSchedule: '3-month review after initiating treatment. If deviation > 20Δ and poorly controlled, refer for surgical evaluation.',
    patientAdvice: 'Monitor for increasing frequency or duration of exo episodes. Bright outdoor light may worsen the deviation — sunglasses can help. Report if deviation becomes constant.',
  );

  DiagnosisPlan _basicExoPlan() => const DiagnosisPlan(
    name: 'Basic Exophoria',
    criteria: [
      'Exophoria approximately equal at distance and near (within 10Δ)',
      'NPC within normal limits (break ≤ 5 cm)',
      'Normal or mildly reduced BO vergence',
    ],
    options: [
      ManagementOption(
        tier: ManagementTier.firstLine,
        title: 'Vision therapy',
        detail: 'BO vergence training (push-up vergences, Brock string, stereogram cards), jump vergence exercises at distance and near. Typical course: 8–12 sessions.',
      ),
      ManagementOption(
        tier: ManagementTier.adjunct,
        title: 'Base-out prism (if Sheard\'s fails)',
        detail: 'Prescribe 1/3 of Sheard\'s criterion as BO prism if VT is insufficient or declined.',
      ),
    ],
    referralCriteria: [
      'Decompensation to manifest exotropia',
      'Diplopia not controlled after VT',
    ],
    reviewSchedule: '6–8 weeks after VT initiation. Most cases respond within 8–12 sessions.',
    patientAdvice: '20-20-20 rule for near work. Regular breaks during extended reading. Ensure adequate lighting.',
  );

  DiagnosisPlan _basicEsoPlan() => const DiagnosisPlan(
    name: 'Basic Esophoria',
    criteria: [
      'Esophoria approximately equal at distance and near',
      'Normal AC/A ratio (3–5 Δ/D)',
      'Reduced BI fusional vergence',
    ],
    options: [
      ManagementOption(
        tier: ManagementTier.firstLine,
        title: 'Full hyperopic correction',
        detail: 'Ensure full cycloplegic refraction is prescribed and worn. Uncorrected hyperopia is a common driver of basic esophoria.',
      ),
      ManagementOption(
        tier: ManagementTier.secondLine,
        title: 'Vision therapy',
        detail: 'BI vergence training, jump vergences, anti-suppression therapy if indicated.',
      ),
      ManagementOption(
        tier: ManagementTier.adjunct,
        title: 'Base-in prism',
        detail: 'Add BI prism to spectacle Rx if VT is insufficient. Use Percival\'s criterion to guide amount.',
      ),
    ],
    referralCriteria: [
      'Manifest esotropia',
      'Amblyopia present',
      'Eso not controlled after full Rx and VT',
    ],
    reviewSchedule: '4–6 weeks after Rx change. VT course: 8–12 sessions.',
    patientAdvice: 'Wear spectacle correction consistently. Headaches and eye strain should improve once the full Rx is stabilised.',
  );

  DiagnosisPlan _accommodativePlan() => const DiagnosisPlan(
    name: 'Accommodative Dysfunction',
    criteria: [
      'Reduced amplitude (below Hofstetter minimum: 15 − 0.25 × age)',
      'Poor accommodative facility (< 11 cpm binocular or monocular)',
      'Abnormal MEM lag (> 0.75 D for AI; < 0.25 D for excess)',
    ],
    options: [
      ManagementOption(
        tier: ManagementTier.firstLine,
        title: 'Accommodative vision therapy',
        detail: 'Hart chart (distance and near), loose lens rock, ±2.00 D flipper exercises. 6–12 week programme. Highly effective for AI and infacility.',
      ),
      ManagementOption(
        tier: ManagementTier.adjunct,
        title: 'Near reading add',
        detail: 'Low add (+0.75 to +1.50 D) for symptomatic relief during VT. Reduces accommodative demand while function is restored.',
      ),
      ManagementOption(
        tier: ManagementTier.secondLine,
        title: 'Minus lens stimulation (for excess/spasm)',
        detail: '-0.50 to -1.00 D to break accommodative spasm; follow with accommodative facility VT.',
      ),
    ],
    referralCriteria: [
      'No improvement after a 12-session VT programme',
      'Unilateral accommodative paresis — consider neurological cause',
      'Accommodative spasm not resolving — consider cycloplegic refraction and systemic review',
    ],
    reviewSchedule: 'Review at 4–6 weeks. Re-measure amplitude and facility at each review visit.',
    patientAdvice: 'Complete home exercises daily (10–15 min). Take regular breaks from near work. Adequate desk lighting reduces accommodative demand.',
  );

  DiagnosisPlan _presbyopiaPlan() => const DiagnosisPlan(
    name: 'Presbyopia',
    criteria: [
      'Age ≥ 40 years with reduced near amplitude',
      'Near blur clearing at distance or with reading addition',
      'Push-up near point > 25 cm (amplitude < 4 D)',
    ],
    options: [
      ManagementOption(
        tier: ManagementTier.firstLine,
        title: 'Near reading addition',
        detail: 'Prescribe ½ of available amplitude (Hofstetter rule). Typical range: +1.00 D at 40–44 yrs → +2.50 D at 60+. Tailor to working distance and task.',
      ),
      ManagementOption(
        tier: ManagementTier.firstLine,
        title: 'Progressive addition lenses (PALs)',
        detail: 'Consider corridor length, intermediate zone for VDU use, and patient lifestyle. Alternatives: bifocals, occupational lenses.',
      ),
      ManagementOption(
        tier: ManagementTier.adjunct,
        title: 'Contact lens options',
        detail: 'Multifocal CLs or monovision. Discuss monovision limitations (reduced stereo, driving). Trial period recommended.',
      ),
    ],
    referralCriteria: [
      'Unexpectedly early presbyopia (< 38 years) — consider diabetes, medication, or systemic causes',
      'Decompensating exophoria at near requiring prismatic correction in addition to add',
    ],
    reviewSchedule: 'Annual review. Increase add by ~+0.25 D every 2–3 years as amplitude reduces.',
    patientAdvice: 'Presbyopia is a natural ageing process — the crystalline lens gradually loses flexibility. Reading glasses or PALs are the mainstay. Larger font sizes and good lighting help for incidental near tasks.',
  );

  // ─── VA parser ──────────────────────────────────────────────────────────────

  bool _isVaReduced(String? va, {required bool near}) {
    if (va == null || va.trim().isEmpty) return false;
    final v = va.trim();
    final snellen6  = RegExp(r'^6/(\d+)$').firstMatch(v);
    if (snellen6 != null) return (int.tryParse(snellen6.group(1)!) ?? 0) > 9;
    final snellen20 = RegExp(r'^20/(\d+)$').firstMatch(v);
    if (snellen20 != null) return (int.tryParse(snellen20.group(1)!) ?? 0) > 30;
    final nNotation = RegExp(r'^[Nn](\d+)$').firstMatch(v);
    if (nNotation != null) return (int.tryParse(nNotation.group(1)!) ?? 0) > 8;
    return false;
  }
}
