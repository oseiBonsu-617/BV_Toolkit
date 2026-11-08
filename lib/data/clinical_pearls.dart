/// A one-line clinical teaching point, linked to the Reference entry that
/// explains it.
class ClinicalPearl {
  const ClinicalPearl(this.text, this.refTitle);

  final String text;

  /// Title of the Reference entry that "Learn more" opens.
  final String refTitle;
}

/// Home shows one of these a day, in this order.
const List<ClinicalPearl> kClinicalPearls = [
  ClinicalPearl(
    "Sheard's criterion (reserve at least twice the demand) suits exophoria; Percival's (demand in the middle third of the range) suits esophoria.",
    "Sheard's Criterion",
  ),
  ClinicalPearl(
    'Convergence insufficiency: exophoria greater at near, a receded NPC and reduced base-out at near.',
    'Convergence Insufficiency',
  ),
  ClinicalPearl(
    'Convergence excess: esophoria greater at near with a high AC/A. A plus add at near is first-line.',
    'Convergence Excess',
  ),
  ClinicalPearl(
    'Measure NPC with an accommodative target and repeat it. An NPC that recedes on repetition supports convergence insufficiency.',
    'NPC Measurement',
  ),
  ClinicalPearl(
    'A normal NPC breaks at 5 cm or closer and recovers by 7 cm.',
    'NPC Norms',
  ),
  ClinicalPearl(
    "Hofstetter's minimum amplitude is 15 − 0.25 × age. An amplitude below it suggests accommodative insufficiency.",
    'Accommodative Amplitude — Hofstetter',
  ),
  ClinicalPearl(
    'Accommodative insufficiency: amplitude below the age minimum, a high MEM lag, reduced PRA and difficulty clearing minus on facility.',
    'Accommodative Insufficiency',
  ),
  ClinicalPearl(
    'Accommodative excess: a low or negative MEM lag, reduced NRA and difficulty clearing plus on facility.',
    'Accommodative Excess / Spasm',
  ),
  ClinicalPearl(
    'A normal MEM lag is about +0.25 to +0.75 D.',
    'MEM Retinoscopy (Lag) Norms',
  ),
  ClinicalPearl(
    'Calculated AC/A = IPD (cm) + (near phoria − distance phoria) ÷ near demand (D), with eso entered as positive.',
    'AC/A — Calculated Method',
  ),
  ClinicalPearl(
    'The gradient AC/A is usually lower than the calculated AC/A because it excludes proximal vergence.',
    'AC/A — Gradient Method',
  ),
  ClinicalPearl(
    'A normal AC/A ratio is about 3–5 Δ/D (gradient method).',
    'AC/A Ratio Norms',
  ),
  ClinicalPearl(
    "Prentice's rule: induced prism (Δ) = decentration (cm) × lens power (D).",
    "Prentice's Rule",
  ),
  ClinicalPearl(
    "Divergence insufficiency: esophoria greater at distance with a low AC/A. If it's new, rule out a sixth nerve palsy.",
    'Divergence Insufficiency',
  ),
  ClinicalPearl(
    'Basic exophoria: a similar exo deviation at distance and near with a normal AC/A.',
    'Basic Exophoria',
  ),
  ClinicalPearl(
    'Basic esophoria: a similar eso deviation at distance and near with a normal AC/A.',
    'Basic Esophoria',
  ),
  ClinicalPearl(
    'Fusional vergence dysfunction: little or no phoria, but reduced base-in and base-out ranges at distance and near.',
    'Fusional Vergence Dysfunction',
  ),
  ClinicalPearl(
    'Superior oblique palsy: the hypertropia is worse on gaze to the opposite side and on head tilt to the same side.',
    'Fourth Nerve (SO) Palsy',
  ),
  ClinicalPearl(
    'Bielschowsky head tilt: in a superior oblique palsy, the hypertropia increases on tilt towards the affected side.',
    'Bielschowsky Head Tilt Test',
  ),
  ClinicalPearl(
    'Refractive accommodative esotropia is usually hyperopic and is controlled by the full cycloplegic prescription.',
    'Refractive Accommodative Esotropia (RAET)',
  ),
  ClinicalPearl(
    'High AC/A esotropia: straight at distance with glasses but esotropic at near. Consider a bifocal.',
    'Non-refractive Accommodative ET (High AC/A)',
  ),
  ClinicalPearl(
    'Brown syndrome limits elevation in adduction and can mimic an inferior oblique palsy; forced duction is positive.',
    'Brown Syndrome',
  ),
  ClinicalPearl(
    'Duane type 1: limited abduction, with globe retraction and narrowing of the lid fissure on adduction.',
    "Duane's Retraction Syndrome",
  ),
  ClinicalPearl(
    'Worth 4 Dot: four lights means fusion, five means diplopia, and two or three means one eye is suppressed.',
    'Worth 4 Dot Test (W4D)',
  ),
  ClinicalPearl(
    'The cover–uncover test detects a tropia; the alternating cover test reveals the total deviation, phoria included.',
    'Cover / Uncover Test',
  ),
  ClinicalPearl(
    'Facility that fails on minus only suggests insufficiency, on plus only suggests excess, and on both suggests infacility.',
    'Accommodative Facility Norms',
  ),
  ClinicalPearl(
    'Microtropia: a small angle (under 10 Δ) with anomalous correspondence, often with mild amblyopia.',
    'Microtropia',
  ),
  ClinicalPearl(
    'Near add for presbyopia: keep half the amplitude in reserve — add = working-distance demand − half the amplitude.',
    'Near Add Power (Presbyopia)',
  ),
  ClinicalPearl(
    'Pseudomyopia from accommodative spasm reduces under cycloplegia — confirm with a cycloplegic refraction.',
    'Pseudo-myopia',
  ),
  ClinicalPearl(
    'Amblyopia treatment starts with full refractive correction; many children improve with glasses alone.',
    'Amblyopia',
  ),
];
