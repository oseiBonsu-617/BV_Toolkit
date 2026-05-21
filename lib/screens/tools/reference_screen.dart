import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../widgets/result_card.dart';

// ─── Data model ──────────────────────────────────────────────────────────────

class _Entry {
  final String title;
  final String cat;
  final List<String> tags;
  final String body;
  final String? code;
  final List<String>? bullets;
  final String? management;

  const _Entry({
    required this.title,
    required this.cat,
    required this.tags,
    required this.body,
    this.code,
    this.bullets,
    this.management,
  });

  bool matches(String q) {
    final lower = q.toLowerCase();
    return title.toLowerCase().contains(lower) ||
        cat.toLowerCase().contains(lower) ||
        tags.any((t) => t.toLowerCase().contains(lower)) ||
        body.toLowerCase().contains(lower) ||
        (code?.toLowerCase().contains(lower) ?? false) ||
        (bullets?.any((b) => b.toLowerCase().contains(lower)) ?? false) ||
        (management?.toLowerCase().contains(lower) ?? false);
  }
}

// ─── Reference data ──────────────────────────────────────────────────────────

const _kEntries = <_Entry>[

  // ── Binocular Vision ──────────────────────────────────────────────────────

  _Entry(
    title: 'Convergence Insufficiency',
    cat: 'BV',
    tags: ['CI', 'exo near', 'low AC/A', 'receded NPC', 'BO reduced'],
    body: 'Exophoria significantly greater at near than distance (≥4Δ difference). Receded NPC (break >5 cm). Reduced BO vergence at near. Most common symptomatic BV disorder.',
    bullets: [
      'Near exo >6Δ with normal or small distance exo',
      'NPC break >5 cm, recovery >7 cm',
      'BO near: blur <11Δ or break <15Δ',
      'AC/A typically low (<3 Δ/D)',
      'Common symptoms: headaches, blur at near, diplopia, reading fatigue',
    ],
    management: '1st line: Vision therapy (convergence exercises — CITT protocol). BI prism at near for immediate symptomatic relief. Plus add if accommodative component present.',
  ),

  _Entry(
    title: 'Convergence Excess',
    cat: 'BV',
    tags: ['CE', 'eso near', 'high AC/A', 'near deviation', 'plus add'],
    body: 'Esophoria significantly greater at near than distance. High AC/A ratio (>5 Δ/D). Near asthenopia, blur, occasional diplopia. Eso driven by accommodative convergence.',
    bullets: [
      'Near eso significantly > distance eso',
      'AC/A high (>5, often >7 Δ/D)',
      'BI vergences may be reduced at near',
      'Symptoms worsened by near work, improved with rest',
    ],
    management: '1st line: Plus add at near (reduces accommodative demand and convergence). BI prism if lens therapy insufficient. VT to reduce accommodative convergence. Executive bifocal in children.',
  ),

  _Entry(
    title: 'Divergence Insufficiency',
    cat: 'BV',
    tags: ['DI', 'eso distance', 'low AC/A', 'diplopia', 'VI nerve'],
    body: 'Esophoria or esotropia at distance with orthophoria or less eso at near. Low AC/A. Diplopia at distance. Must exclude VI nerve palsy or raised intracranial pressure.',
    bullets: [
      'Eso at distance, ortho or small eso at near',
      'AC/A low (<3 Δ/D)',
      'Bilateral DI is a red flag — exclude raised ICP',
      'Unilateral: exclude CN VI palsy',
      'Common in elderly (arterial compromise of CN VI)',
    ],
    management: 'BI prism at distance to relieve diplopia. Urgent neurological referral if sudden onset, bilateral, or associated with headache/papilloedema.',
  ),

  _Entry(
    title: 'Divergence Excess',
    cat: 'BV',
    tags: ['DE', 'exo distance', 'normal AC/A', 'intermittent', 'simulated'],
    body: 'Exophoria/tropia greater at distance, orthophoria at near. Distinguish simulated DE (patched near phoria = distance phoria) from true DE. Often intermittent.',
    bullets: [
      'Distance exo significantly > near exo',
      'Patch test: cover one eye 30–45 min then re-measure near phoria',
      'Simulated DE: near exo increases to equal distance after patching',
      'True DE: near phoria unchanged after patching',
      'AC/A normal or high in simulated; normal in true',
    ],
    management: 'Simulated DE: plus lenses (+3.00 DS) to stimulate accommodation and convergence. True DE: BO prism or VT. Surgery if large constant angle.',
  ),

  _Entry(
    title: 'Basic Exophoria',
    cat: 'BV',
    tags: ['basic exo', 'equal exo', 'normal AC/A', 'vergence training'],
    body: 'Similar exophoria at both distance and near (within 2–4Δ). Normal AC/A (3–5 Δ/D). Symptoms typically with sustained near work.',
    bullets: [
      'Distance exo ≈ near exo (within 4Δ)',
      'AC/A 3–5 Δ/D',
      'Reduced BO vergence amplitude common',
      'May fail Sheard\'s criterion',
    ],
    management: 'VT: BO vergence training (pencil push-ups, Brock string, prism flippers). BO prism if symptomatic and VT declines. Reading glasses with small BO prism in presbyopes.',
  ),

  _Entry(
    title: 'Basic Esophoria',
    cat: 'BV',
    tags: ['basic eso', 'equal eso', 'normal AC/A', 'BI prism'],
    body: 'Similar esophoria at both distance and near. Normal AC/A (3–5 Δ/D). Symptoms with sustained near work and distance viewing.',
    bullets: [
      'Distance eso ≈ near eso (within 4Δ)',
      'Normal AC/A',
      'Reduced BI vergence common',
      'May fail Percival\'s criterion',
    ],
    management: 'BI prism at near and/or distance. Plus add at near if accommodative component present. VT: BI vergence training. Rule out hyperopia driving eso.',
  ),

  _Entry(
    title: 'Fusional Vergence Dysfunction',
    cat: 'BV',
    tags: ['FVD', 'orthophoria', 'reduced BI and BO', 'Percival', 'facility'],
    body: 'Near-orthophoric but reduced both BI and BO vergences bilaterally. Fails Percival\'s criterion. Reduced vergence facility. Asthenopia without obvious phoria.',
    bullets: [
      'Phoria within normal limits',
      'Both BI and BO vergences below norms',
      'Fails Percival\'s criterion',
      'Reduced vergence facility (slow to recover from prism)',
    ],
    management: 'VT targeting both BI and BO vergence amplitude and facility. Brock string, barrel card, vectogram procedures. Often slow to respond — patient compliance critical.',
  ),

  _Entry(
    title: 'Accommodative Esotropia',
    cat: 'BV',
    tags: ['accommodative ET', 'cycloplegic', 'hyperopia', 'AC/A', 'bifocal'],
    body: 'Esotropia driven by accommodative convergence. Three types: fully accommodative (RAET), partially accommodative (PAET), and non-refractive accommodative (high AC/A type).',
    bullets: [
      'RAET: fully corrected by full hyperopic correction; normal AC/A',
      'PAET: residual ET after full correction; may need surgery',
      'High AC/A type: ortho/small eso at distance; ET at near; normal refraction',
      'Onset typically 2–4 years',
      'Cycloplegic refraction mandatory before treatment',
    ],
    management: 'Full cycloplegic refraction. Full hyperopic correction worn full-time. Executive bifocal (+2.50 to +3.00) for high AC/A type. Amblyopia treatment first. Surgery for residual PAET after optical stabilisation.',
  ),

  _Entry(
    title: 'Intermittent Exotropia',
    cat: 'BV',
    tags: ['XT', 'intermittent', 'distance', 'sun exposure', 'Newcastle'],
    body: 'Most common exotropia in children. Deviation controlled intermittently. Worsens with fatigue, illness, sun exposure, distance fixation. Three types: distance (DE), near (CI), basic.',
    bullets: [
      'Newcastle Control Score (NCS): 0 (never manifest) to 9 (constant)',
      'Monitor: VA, suppression, stereoacuity, control',
      'Sun squinting: diagnostic sign in young children',
      'PE ratio: ratio of near to distance deviation',
    ],
    management: 'Observation if well-controlled (NCS <3). Orthoptic exercises: monocular occlusion, convergence training. Surgery (lateral rectus recession) when control deteriorates (NCS ≥4 or >50% waking hours manifest).',
  ),

  // ── Accommodative ─────────────────────────────────────────────────────────

  _Entry(
    title: 'Accommodative Insufficiency',
    cat: 'Acc.',
    tags: ['AI', 'low amplitude', 'high lag', 'fails minus', 'Hofstetter', 'near blur'],
    body: 'Monocular amplitude below Hofstetter minimum. MEM lag >0.75D. Fails minus flipper. Near asthenopia and blur. Often co-exists with convergence insufficiency.',
    bullets: [
      'Amplitude < Hofstetter minimum (15 − 0.25 × age)',
      'MEM retinoscopy lag >0.75D',
      'Fails minus side of ±2.00 flippers',
      'NRA reduced (<+1.75D)',
      'Monocular acuity at near may be reduced',
    ],
    management: '1st line: Accommodative facility training (monocular then binocular flippers, near-far rock). Plus add at near for symptomatic relief. Investigate systemic causes (thyroid, anaemia, medications).',
  ),

  _Entry(
    title: 'Accommodative Excess / Spasm',
    cat: 'Acc.',
    tags: ['AE', 'spasm', 'pseudo-myopia', 'low lag', 'fails plus', 'cycloplegic'],
    body: 'Ciliary spasm causing sustained over-accommodation. MEM lag <0.25D or lead. Fails plus flipper. Apparent myopia that clears with cycloplegia. Distance blur.',
    bullets: [
      'Amplitude may appear normal or elevated',
      'MEM lag <0.25D or negative (lead)',
      'Fails plus side of ±2.00 flippers',
      'Distance VA improves with +1.00 or cycloplegia',
      'PRA (negative relative accommodation) reduced',
    ],
    management: 'Plus lenses at near to reduce accommodative demand. Short-term cycloplegics (atropine 0.5%) in severe spasm. Facility training (emphasise relaxation side). Screen time reduction.',
  ),

  _Entry(
    title: 'Accommodative Infacility',
    cat: 'Acc.',
    tags: ['infacility', 'slow facility', 'fails both sides', 'normal amplitude', 'Hart chart'],
    body: 'Normal amplitude but reduced facility — slow to change focus. Fails both +/− sides of flipper. <11 cpm binocular, <13 cpm monocular. Blur/asthenopia with focus changes.',
    bullets: [
      'Monocular facility <13 cpm with ±2.00 flippers',
      'Binocular facility <11 cpm',
      'Amplitude typically within normal limits',
      'Symptoms: blurred vision after changing distance, slow to clear',
    ],
    management: 'Monocular flipper training first, then binocular. Hart chart near-far rock. Push-up / push-down exercises. Typical course: 6–8 weeks of active training.',
  ),

  _Entry(
    title: 'Presbyopia',
    cat: 'Acc.',
    tags: ['presbyopia', 'age-related', 'reduced amplitude', 'plus add', 'PAL', 'reading glasses'],
    body: 'Physiological loss of accommodation with age due to lens hardening. Symptomatic from ~40–45 years. Functional limit when amplitude <3D. Blur at near is the primary symptom.',
    bullets: [
      'Hofstetter minimum amplitude = 15 − 0.25 × age',
      'Symptomatic onset when amplitude <3–4D',
      'Near add power ≈ ½ × (1/near distance − amplitude)',
      'Initial add: typically +0.75 to +1.00D at 40–45 years',
      'Final add: +2.50 to +3.00D by ~60 years',
    ],
    management: 'Single-vision readers. Progressive addition lenses (PALs) for distance-near. Occupational lenses for intermediate work. Contact lens options: monovision, multifocal CLs. Monitor for concurrent pathology (cataracts, macular).',
  ),

  _Entry(
    title: 'Pseudo-myopia',
    cat: 'Acc.',
    tags: ['pseudo-myopia', 'ciliary spasm', 'apparent myopia', 'young', 'near demand'],
    body: 'Apparent myopia due to ciliary spasm; not axial length increase. Distance VA improves with cycloplegic refraction or rest. Common in young patients with high near demands.',
    bullets: [
      'Distance blur that fluctuates and clears with rest or cycloplegia',
      'Cycloplegic refraction reveals less myopia or even hyperopia',
      'MEM lag very low (<0.25D) or lead',
      'Associated with excessive screen use, reading without breaks',
    ],
    management: 'Cycloplegic refraction to determine true refractive error. Reduce near demand (20-20-20 rule). Plus lenses at near. VT if associated with accommodative spasm. Avoid over-prescribing minus.',
  ),

  // ── Strabismus ────────────────────────────────────────────────────────────

  _Entry(
    title: 'Infantile Esotropia',
    cat: 'Strabismus',
    tags: ['congenital ET', 'early onset', 'large angle', 'DVD', 'surgery', 'cross fixation'],
    body: 'Constant esotropia present before 6 months of age. Large angle (≥30Δ). Cross-fixation common. Associated with dissociated vertical deviation (DVD), latent nystagmus, inferior oblique overaction.',
    bullets: [
      'Onset: birth to 6 months',
      'Angle: typically ≥30Δ; constant',
      'Cross-fixation: uses right eye for left gaze, left eye for right gaze',
      'Associated: DVD, latent nystagmus, IO overaction (50%)',
      'Amblyopia: may develop if fixation preference',
    ],
    management: 'Correct refractive error first. Amblyopia treatment if present. Surgery (bimedial recession) ideally before 2 years of age for binocular potential. Adjust for DVD/IO overaction at same sitting if severe.',
  ),

  _Entry(
    title: 'Refractive Accommodative Esotropia (RAET)',
    cat: 'Strabismus',
    tags: ['RAET', 'accommodative ET', 'hyperopia', 'fully correctable', 'glasses', 'cycloplegic'],
    body: 'Esotropia fully corrected by spectacle correction of hyperopia. Normal AC/A ratio. Onset typically 2–4 years. Often triggered by febrile illness, head injury, or visual stress.',
    bullets: [
      'Cycloplegic refraction reveals significant hyperopia (often +3.00 to +5.00D)',
      'ET fully corrected with full hyperopic prescription',
      'Normal AC/A (~3–5 Δ/D)',
      'Without glasses: esotropia; with glasses: ortho or small exo',
    ],
    management: 'Full cycloplegic hyperopic correction worn full-time. Amblyopia treatment if present. Do not under-prescribe — full correction is essential. Glasses usually required long-term; some reduction in hyperopia may occur with age.',
  ),

  _Entry(
    title: 'Non-refractive Accommodative ET (High AC/A)',
    cat: 'Strabismus',
    tags: ['accommodative ET', 'high AC/A', 'near ET', 'bifocal', 'distance ortho'],
    body: 'Distance orthophoria or small phoria; esotropia only at near. Normal refractive error. High AC/A (>6 Δ/D). Near ET driven by high AC/A — convergence excess triggers tropia.',
    bullets: [
      'Distance: ortho or small phoria',
      'Near: esotropia (often 20–30Δ)',
      'Refractive error: normal or low hyperopia',
      'AC/A: typically >6 Δ/D',
    ],
    management: 'Executive bifocal (+2.50 to +3.00 add) — flat-top to ensure use at near. Gradually reduce add as control improves. VT to reduce accommodative convergence. Monitor for conversion to basic ET.',
  ),

  _Entry(
    title: 'Intermittent Exotropia (X(T))',
    cat: 'Strabismus',
    tags: ['IXT', 'exotropia', 'intermittent', 'control', 'Newcastle', 'surgery'],
    body: 'Divergent strabismus controlled intermittently. Most common exotropia in childhood. Worsens with distance fixation, fatigue, sun exposure. Three subtypes: distance (DE type), near (CI type), basic.',
    bullets: [
      'Newcastle Control Score: 0–9 (0 = never manifest)',
      'Sun squinting/eye closure: diagnostic sign in young children',
      'Distance: worse when fixating objects >6 m',
      'Near CI-type: worse at near, often associated with actual CI',
      'Suppression: monocular suppression common during manifest phase',
    ],
    management: 'Monitor if well-controlled (NCS <3). Orthoptic exercises: pencil push-ups, convergence training. Part-time occlusion of dominant eye. Surgery (lateral rectus recession) for deteriorating control (NCS ≥4).',
  ),

  _Entry(
    title: 'Duane\'s Retraction Syndrome',
    cat: 'Strabismus',
    tags: ['Duane', 'co-innervation', 'abduction deficiency', 'globe retraction', 'CN VI', 'congenital'],
    body: 'Congenital CN VI aplasia with aberrant CN III innervation of the lateral rectus. Three types. Type I (most common): limited abduction, globe retraction on attempted adduction.',
    bullets: [
      'Type I (85%): limited/absent abduction; esotropia in primary position common',
      'Type II: limited adduction; exotropia',
      'Type III: limited both abduction and adduction',
      'Globe retraction and palpebral fissure narrowing on adduction',
      'Upshoot/downshoot: leash effect',
    ],
    management: 'Prism for small-angle in primary position. Surgery only for: significant deviation in primary position, marked face turn, severe anomalous head posture. Goal is ortho in primary — not full motility correction.',
  ),

  _Entry(
    title: 'Brown Syndrome',
    cat: 'Strabismus',
    tags: ['Brown', 'superior oblique', 'limited elevation adduction', 'tendon sheath', 'click'],
    body: 'Restriction of superior oblique tendon sheath limits elevation in adduction. Primary position usually orthophoric. Click may be felt/heard on adduction. Can be congenital or acquired.',
    bullets: [
      'Limited/absent elevation in adduction',
      'V pattern: widening on upgaze',
      'Click sign: palpable click in some cases',
      'Congenital: stable; Acquired (e.g. rheumatoid): may fluctuate',
      'MRI/ultrasound: tendon abnormality visible',
    ],
    management: 'Observe if primary position is ortho and no face turn. Acquired: treat underlying cause (steroids for inflammatory). Surgery (SO tendon lengthening) for significant primary deviation or anomalous head posture.',
  ),

  _Entry(
    title: 'Fourth Nerve (SO) Palsy',
    cat: 'Strabismus',
    tags: ['IV nerve', 'SO palsy', 'hypertropia', 'Bielschowsky', 'Parks 3-step', 'torsional diplopia'],
    body: 'Most common cause of acquired vertical diplopia. Hypertropia that increases on contralateral gaze and ipsilateral head tilt. Positive Bielschowsky head tilt test. Often congenital (decompensated).',
    bullets: [
      'Parks 3-step: Step 1 — which eye hyper; Step 2 — which gaze worsens; Step 3 — head tilt',
      'Bielschowsky: right head tilt → right hypertropia increases = right SO palsy',
      'Congenital SO palsy: large vertical fusional amplitude (>5Δ); facial asymmetry',
      'Acquired: diplopia often oblique/torsional',
      'Bilateral SO palsy: V-pattern, excyclotorsion >10°',
    ],
    management: 'Acute acquired: prism (vertical BI Fresnel) for diplopia. Observe 6 months for spontaneous recovery. Surgery (SO tuck, IO weakening, SR recession) for persisting deviation. VT not effective for palsy.',
  ),

  _Entry(
    title: 'Amblyopia',
    cat: 'Strabismus',
    tags: ['amblyopia', 'lazy eye', 'anisometropia', 'strabismus', 'patching', 'atropine', 'VA'],
    body: 'Reduced best corrected VA in one eye (or both) not explained by structural pathology, due to abnormal visual experience during visual development. Three types: strabismic, anisometropic, deprivation.',
    bullets: [
      'Strabismic: suppression of deviating eye; AC > 10Δ most common',
      'Anisometropic: ≥1.50D spherical or ≥1.00D cylindrical difference',
      'Deprivation: ptosis, cataract, dense media opacity — most severe',
      'Critical period: birth to ~7–9 years (some plasticity to ~12)',
      'Define as: BCVA ≤6/9 (20/30) or ≥2 lines VA difference between eyes',
    ],
    management: 'Correct refractive error first (12–16 weeks glasses before amblyopia treatment). Patching dominant eye: 2 hrs/day for mild–moderate; 6 hrs/day for severe. Atropine 1% penalisation (Sunday treatment). VT as adjunct in older children.',
  ),

  _Entry(
    title: 'Microtropia',
    cat: 'Strabismus',
    tags: ['microtropia', 'small angle', 'monofixation', 'central scotoma', 'ARC', 'peripheral fusion'],
    body: 'Small-angle strabismus (<10Δ). Central scotoma with anomalous retinal correspondence (ARC). Peripheral fusion intact. Reduced stereoacuity. Often missed on standard cover test.',
    bullets: [
      'Angle: typically 2–8Δ — may not be detectable on standard cover test',
      'Central suppression scotoma on 4-prism dioptre test',
      'Stereoacuity reduced: typically 200–800 arcsec',
      'Often associated with anisometropia and amblyopia',
      'ARC: different retinal points stimulated correspond subjectively',
    ],
    management: 'Correct refractive error. Amblyopia treatment if present. Usually stable — rarely progresses. Prism contraindicated (disrupts peripheral fusion). Monitor for decompensation.',
  ),

  // ── Norms ─────────────────────────────────────────────────────────────────

  _Entry(
    title: "Morgan's Norms — Phoria",
    cat: 'Norms',
    tags: ['phoria', 'Morgan', 'exophoria', 'esophoria', 'distance', 'near', 'norms'],
    body: "Expected phoria values at distance and near for a non-symptomatic population (Morgan 1944). Clinic norms used for comparison.",
    bullets: [
      'Distance: 1Δ exophoria (SD ±1.5Δ) — clinical range: ortho to 4Δ exo',
      'Near: 3Δ exophoria (SD ±5Δ) — clinical range: 0–6Δ exo',
      'Esophoria at either distance considered outside norm',
      'Exo > 6Δ at near is significant for CI pattern',
      'Prism convention: + = exo, − = eso',
    ],
  ),

  _Entry(
    title: "Morgan's Norms — Vergence (Distance)",
    cat: 'Norms',
    tags: ['vergence', 'Morgan', 'distance', 'BI', 'BO', 'fusional', 'break', 'blur'],
    body: 'Vergence range norms for distance fixation (6 m). All values in prism dioptres (Δ).',
    bullets: [
      'BI break: 7Δ | BI recovery: 4Δ',
      'BO blur: 9Δ | BO break: 19Δ | BO recovery: 10Δ',
      'BI blur not recordable for most patients at distance',
      'BO break <15Δ at distance: consider reduced fusional reserve',
    ],
  ),

  _Entry(
    title: "Morgan's Norms — Vergence (Near)",
    cat: 'Norms',
    tags: ['vergence', 'Morgan', 'near', 'BI', 'BO', 'fusional', 'break', 'blur'],
    body: 'Vergence range norms for near fixation (40 cm). All values in prism dioptres (Δ).',
    bullets: [
      'BI blur: 13Δ | BI break: 21Δ | BI recovery: 13Δ',
      'BO blur: 17Δ | BO break: 21Δ | BO recovery: 11Δ',
      'BO break <15Δ at near: associated with CI',
      'BI break <11Δ at near: reduced negative fusional vergence',
    ],
  ),

  _Entry(
    title: 'NPC Norms',
    cat: 'Norms',
    tags: ['NPC', 'near point convergence', 'break', 'recovery', 'CI', 'norms'],
    body: 'Near point of convergence measured with an accommodative target (pen/pencil). Abnormal NPC is a primary diagnostic criterion for convergence insufficiency.',
    bullets: [
      'Normal break: ≤5 cm from spectacle plane',
      'Normal recovery: ≤7 cm from spectacle plane',
      'Receded NPC: break >5 cm or recovery >7 cm',
      'Penlight + red Maddox rod: more sensitive; eliminates monocular suppression',
      'Repeat 3 times; report average; fatigue effect = CI indicator',
    ],
  ),

  _Entry(
    title: 'AC/A Ratio Norms',
    cat: 'Norms',
    tags: ['AC/A', 'accommodative convergence', 'ratio', 'gradient', 'calculated', 'norms'],
    body: 'AC/A ratio describes the amount of convergence (Δ) per unit of accommodation (D). Critical for classifying BV conditions and guiding management.',
    bullets: [
      'Normal: 3–5 Δ/D (gradient method)',
      'Low AC/A: <3 Δ/D — associated with CI',
      'High AC/A: 5–7 Δ/D — associated with CE',
      'Very high: >7 Δ/D — evaluate for accommodative esotropia',
      'Calculated AC/A tends to be higher than gradient method',
    ],
  ),

  _Entry(
    title: 'Accommodative Amplitude — Hofstetter',
    cat: 'Norms',
    tags: ['Hofstetter', 'amplitude', 'accommodation', 'age', 'minimum', 'expected', 'maximum'],
    body: "Hofstetter's formulas relate expected accommodative amplitude to age. Below minimum for age = accommodative insufficiency.",
    bullets: [
      'Minimum = 15 − 0.25 × age',
      'Expected = 18.5 − 0.30 × age',
      'Maximum = 25 − 0.40 × age',
      'Age 20: min 10D | expected 12.5D | max 17D',
      'Age 40: min 5D | expected 6.5D | max 9D',
      'Age 50: min 2.5D | expected 3.5D | max 5D',
    ],
  ),

  _Entry(
    title: 'Accommodative Facility Norms',
    cat: 'Norms',
    tags: ['facility', 'flippers', 'cpm', 'monocular', 'binocular', 'norms', '±2.00'],
    body: 'Measured with ±2.00D flippers at 40 cm (6/9 target). Cycles per minute (cpm). Failure indicates accommodative infacility.',
    bullets: [
      'Monocular: ≥13 cpm (some refs ≥11 cpm)',
      'Binocular: ≥11 cpm (some refs ≥8 cpm)',
      'Fails minus = AI; Fails plus = AE; Fails both = infacility',
      'Test duration: 1 minute per eye',
      'Age-matched norms vary — lower expected in children <8 yrs',
    ],
  ),

  _Entry(
    title: 'MEM Retinoscopy (Lag) Norms',
    cat: 'Norms',
    tags: ['MEM', 'monocular estimation method', 'lag', 'lead', 'accommodation', 'retinoscopy'],
    body: 'Dynamic retinoscopy at near (40 cm) to estimate accommodative response. Quick, binocular technique. Lag indicates under-accommodation; lead indicates over-accommodation.',
    bullets: [
      'Normal lag: +0.25 to +0.75D',
      'High lag: >+0.75D → accommodative insufficiency',
      'Low lag: <+0.25D (near zero or lead) → accommodative excess/spasm',
      'Procedure: insert lens in front of eye briefly; with = lag; against = lead',
      'Binocular conditions maintained throughout',
    ],
  ),

  _Entry(
    title: 'Stereoacuity Norms',
    cat: 'Norms',
    tags: ['stereoacuity', 'stereopsis', 'randot', 'TNO', 'titmus', 'arcsec', 'binocular'],
    body: 'Stereoacuity thresholds used to assess binocular vision quality. Measured in arc seconds — lower value = finer stereopsis.',
    bullets: [
      'Randot stereotest: ≤40 arcsec = normal; >200 arcsec = significantly reduced',
      'TNO: ≤60 arcsec normal; range 15–480 arcsec',
      'Titmus Fly: 3000 arcsec (gross only)',
      'Titmus Circles: 800–40 arcsec',
      'Absence of stereopsis: monocular suppression, amblyopia, or strabismus',
      'Lang Stereotest: 550–1200 arcsec; useful for pre-verbal children',
    ],
  ),

  _Entry(
    title: 'NRA / PRA Norms',
    cat: 'Norms',
    tags: ['NRA', 'PRA', 'relative accommodation', 'plus', 'minus', 'norms'],
    body: 'Relative accommodation tests the range of plus or minus lenses that can be added without blur at a fixed distance (40 cm). Used to assess accommodation–vergence relationship.',
    bullets: [
      'NRA (Negative Relative Accommodation — add plus): +2.00 to +2.50D',
      'PRA (Positive Relative Accommodation — add minus): −2.37D average',
      'High NRA, low PRA: over-accommodation (AE pattern)',
      'Low NRA, normal PRA: under-accommodation (AI pattern)',
      'Balanced NRA/PRA (within 0.50D): optimal lens power for near prescription',
    ],
  ),

  // ── Signs & Tests ─────────────────────────────────────────────────────────

  _Entry(
    title: 'Cover / Uncover Test',
    cat: 'Tests',
    tags: ['cover test', 'uncover', 'phoria', 'tropia', 'manifest', 'latent', 'deviation'],
    body: 'Differentiates heterophoria (latent) from heterotropia (manifest). Cover test detects tropia; uncover test detects phoria recovery. Perform at distance (6 m) and near (40 cm).',
    bullets: [
      'Cover test: cover one eye → watch uncovered eye → movement = tropia',
      'Uncover test: remove cover from covered eye → watch it move to re-fixate = phoria recovery',
      'Inward movement on uncover = exophoria; outward = esophoria; up/down = hyperphoria',
      'No movement: orthophoria or tropia fixed (no recovery)',
      'Direction of movement reveals direction of deviation',
    ],
  ),

  _Entry(
    title: 'Alternating Prism Cover Test (APCT)',
    cat: 'Tests',
    tags: ['APCT', 'prism cover test', 'total deviation', 'prism neutralisation', 'angle'],
    body: 'Measures total deviation (phoria + tropia). Cover alternates between eyes; prism added until no refixation movement is seen. More accurate than unilateral cover test.',
    bullets: [
      'Prism over deviating eye: base direction opposite to deviation',
      'Exo deviation: use BO prism; Eso: BI prism; Hyper: BD prism over hyper eye',
      'Endpoint: equal, opposite movements cancelled (neutralisation)',
      'Do at distance AND near; difference indicates AC/A pattern',
      'Note: APCT disrupts fusion — use for full deviation assessment, not for small angles with good control',
    ],
  ),

  _Entry(
    title: 'Worth 4 Dot Test (W4D)',
    cat: 'Tests',
    tags: ['Worth 4 dot', 'W4D', 'fusion', 'suppression', 'diplopia', 'ARC', 'binocular'],
    body: 'Tests binocular status and identifies suppression. 2 red (right eye), 2 green (left eye), 1 white dot. Red-green glasses worn. Performed at distance (6 m) and near (33 cm).',
    bullets: [
      '4 dots (2 red + 2 green or 1 red + 1 white + 2 green): binocular single vision / fusion',
      '2 dots (red only): left eye suppression',
      '3 dots (green only): right eye suppression',
      '5 dots: diplopia (uncrossed = eso; crossed = exo)',
      'Distance W4D: tests peripheral fusion; Near: tests central fusion',
    ],
  ),

  _Entry(
    title: 'Bielschowsky Head Tilt Test',
    cat: 'Tests',
    tags: ['Bielschowsky', 'head tilt', 'SO palsy', 'hypertropia', 'IV nerve', 'Parks 3-step'],
    body: 'Third step of Parks 3-step test for superior oblique (CN IV) palsy. Tilt head towards the side of the hypertropic eye — hypertropia increases in SO palsy.',
    bullets: [
      'Parks Step 1: Which eye is hyper? (identifies the two possible paretic muscles)',
      'Parks Step 2: On which gaze direction is hypertropia greater? (narrows to two muscles)',
      'Parks Step 3 (Bielschowsky): Head tilt — ipsilateral = increases hypertropia in SO palsy',
      'Right head tilt → Right hypertropia increases → Right SO palsy',
      'False positive: SR palsy of the other eye (similar pattern)',
    ],
  ),

  _Entry(
    title: 'NPC Measurement',
    cat: 'Tests',
    tags: ['NPC', 'near point convergence', 'procedure', 'accommodative target', 'penlight'],
    body: 'Measures the nearest point at which both eyes can maintain single binocular vision. Two methods: accommodative target and penlight + red filter.',
    bullets: [
      'Accommodative target: hold pen/pencil at arm\'s length; move slowly toward nose',
      'Patient reports: first blur, then diplopia (break point)',
      'Move target back until fusion recovers (recovery point)',
      'Penlight + red Maddox rod: more sensitive; patient reports colour separation',
      'Repeat 3 times; average the results; note fatigue effect across trials',
      'Normal: break ≤5 cm, recovery ≤7 cm from spectacle plane',
    ],
  ),

  _Entry(
    title: 'Bagolini Striated Lens Test',
    cat: 'Tests',
    tags: ['Bagolini', 'suppression', 'ARC', 'binocular', 'fusion', 'striated'],
    body: 'Tests binocular status with minimal dissociation. Lenses create a streak from a point light source. More sensitive to suppression than Worth 4 Dot. Can detect harmonious ARC.',
    bullets: [
      'Right lens: streak at 135°; Left lens: streak at 45° — form an X through the light',
      'Normal BSV: full X with light at centre (no suppression)',
      'Suppression: gap/scotoma in one streak near the light',
      'ARC: X formed but off-centre (anomalous retinal correspondence)',
      'Diplopia: two separate streaks',
    ],
  ),

  _Entry(
    title: 'Randot Stereotest',
    cat: 'Tests',
    tags: ['Randot', 'stereotest', 'stereoacuity', 'polarised', 'circles', 'animals'],
    body: 'Polarised test measuring global and local stereopsis at near (40 cm). Available in Randot Preschool and standard adult versions. Threshold measured in arc seconds.',
    bullets: [
      'Suppression check: circles (500 arcsec); if fails → check for suppression first',
      'Animals: 400, 200, 100 arcsec — gross stereopsis',
      'Circles: 400, 200, 140, 100, 70, 50, 40, 30, 20 arcsec',
      'Pass threshold: correct 3 of 3 or 4 of 6 attempts at each level',
      'Normal adults: ≤40 arcsec; below 200 arcsec = functional stereopsis present',
    ],
  ),

  _Entry(
    title: 'Fixation Disparity & Mallett Unit',
    cat: 'Tests',
    tags: ['fixation disparity', 'Mallett', 'associated phoria', 'vergence', 'oculomotor stress'],
    body: 'Fixation disparity: small misalignment of retinal images during bifoveal fixation. More clinically relevant than dissociated phoria for prescribing prism.',
    bullets: [
      'Associated phoria (Mallett): prism that eliminates the fixation disparity',
      'Often less than dissociated phoria — indicates real-world vergence demand',
      'Mallett unit: OXO target; central nonius lines misalign when fixation disparity present',
      'Distance and near associated phoria may differ — each assessed separately',
      'Prescribe prism to eliminate associated phoria where symptomatic',
    ],
  ),

  // ── Formulas ──────────────────────────────────────────────────────────────

  _Entry(
    title: 'AC/A — Calculated Method',
    cat: 'Formulas',
    tags: ['AC/A', 'calculated', 'IPD', 'phoria', 'formula'],
    body: 'Uses IPD and the difference between near and distance phorias. Less accurate than gradient method due to proximal convergence influence.',
    code: 'AC/A = (IPD/10) + (Pn − Pd) / (1/Nd)',
    bullets: [
      'IPD = interpupillary distance in mm',
      'Pn = near phoria (+ exo, − eso) in Δ',
      'Pd = distance phoria in Δ',
      'Nd = near test distance in metres (e.g. 0.40 for 40 cm)',
      'Normal: 3–5 Δ/D',
    ],
  ),

  _Entry(
    title: 'AC/A — Gradient Method',
    cat: 'Formulas',
    tags: ['AC/A', 'gradient', 'lens', 'phoria', 'formula'],
    body: 'Measures phoria change per unit of additional lens power. More accurate than calculated; eliminates proximal convergence. Use ±1.00D or ±2.00D.',
    code: 'AC/A = |ΔPhoria| / |Lens Power|',
    bullets: [
      'Measure phoria at near; add +1.00D or −1.00D; re-measure phoria',
      'Phoria change / lens power = AC/A',
      'Example: near phoria changes from 3Δ exo to 1Δ exo with +1.00D → AC/A = 2/1 = 2 Δ/D',
      'Use negative lens if measuring positive AC/A; positive lens if measuring effect of minus',
    ],
  ),

  _Entry(
    title: "Sheard's Criterion",
    cat: 'Formulas',
    tags: ["Sheard's", 'prism', 'compensating vergence', 'exo', 'formula', 'criterion'],
    body: "Patient's compensating vergence must be at least twice the phoria. If fails, prism is required. Better predictor for exophoric conditions.",
    code: 'Pass: CV ≥ 2 × |phoria|\nPrism = (2/3)|Ph| − (1/3) × CV',
    bullets: [
      'CV = compensating vergence break (BO for exo; BI for eso)',
      'Example: exo 8Δ, BO break 12Δ → 12 < 2×8 = 16 → Fails; Prism = 2/3×8 − 1/3×12 = 5.3 − 4 = 1.3Δ BI',
      'Prism direction: BI for exo conditions; BO for eso',
    ],
  ),

  _Entry(
    title: "Percival's Criterion",
    cat: 'Formulas',
    tags: ["Percival's", 'prism', 'vergence range', 'eso', 'formula', 'criterion'],
    body: 'Lesser vergence must be at least one-half the greater vergence. If fails, prism is required. Better predictor for esophoric conditions.',
    code: 'Pass: L ≥ G/2\nPrism = G/3 − 2L/3',
    bullets: [
      'G = greater vergence (BO break if eso; BI break if exo)',
      'L = lesser vergence (BI break if eso; BO break if exo)',
      'Example: BO near break 21Δ, BI near break 4Δ → G=21, L=4 → 4 < 21/2=10.5 → Fails; P = 7 − 2.7 = 4.3Δ BI',
    ],
  ),

  _Entry(
    title: 'Hofstetter Amplitude Formulas',
    cat: 'Formulas',
    tags: ['Hofstetter', 'amplitude', 'accommodation', 'age', 'minimum', 'maximum', 'formula'],
    body: 'Three formulas give age-expected accommodative amplitude for clinical comparison.',
    code: 'Min = 15 − 0.25 × Age\nExpected = 18.5 − 0.30 × Age\nMax = 25 − 0.40 × Age',
    bullets: [
      'All values in dioptres (D)',
      'Age 30: min 7.5D | expected 9.5D | max 13D',
      'Age 45: min 3.75D | expected 5D | max 7D',
      'Amplitude below minimum = accommodative insufficiency',
    ],
  ),

  _Entry(
    title: "Prentice's Rule",
    cat: 'Formulas',
    tags: ["Prentice's rule", 'prism', 'decentration', 'lens power', 'induced prism'],
    body: 'Calculates prismatic effect induced when gaze passes through a lens at a point away from the optical centre.',
    code: 'Δ = P × d',
    bullets: [
      'Δ = induced prism (prism dioptres)',
      'P = lens power in dioptres',
      'd = decentration from optical centre in centimetres',
      'Example: +4.00D lens, 0.5 cm decentration = 4 × 0.5 = 2Δ',
      'Base direction: base in if decentred nasally (for plus lens)',
    ],
  ),

  _Entry(
    title: 'Prism Dioptre',
    cat: 'Formulas',
    tags: ['prism dioptre', 'angle', 'deviation', 'formula', 'tangent'],
    body: 'Prism dioptre (Δ) is the standard unit of prismatic power. 1Δ displaces image 1 cm at 1 metre.',
    code: 'Δ = 100 × tan(angle in degrees)',
    bullets: [
      '1Δ = 1 cm displacement at 1 m = 0.57°',
      '2Δ ≈ 1.1° | 5Δ ≈ 2.9° | 10Δ ≈ 5.7° | 20Δ ≈ 11.3°',
      'Prism addition: base-to-base (BI + BI) = sum if same eye; use Prentice for combined',
    ],
  ),

  _Entry(
    title: 'Near Point of Accommodation',
    cat: 'Formulas',
    tags: ['near point', 'accommodation', 'NPA', 'formula', 'amplitude'],
    body: 'Converts accommodative amplitude to the nearest distance at which the eye can focus.',
    code: 'NPA (m) = 1 / Amplitude (D)',
    bullets: [
      'Amplitude 10D → NPA = 0.10 m = 10 cm',
      'Amplitude 4D → NPA = 0.25 m = 25 cm',
      'Amplitude 2D → NPA = 0.50 m = 50 cm',
      'presbyopic: amplitude <3D → NPA >33 cm; near work impossible without add',
    ],
  ),

  _Entry(
    title: 'Near Add Power (Presbyopia)',
    cat: 'Formulas',
    tags: ['near add', 'presbyopia', 'plus add', 'reading', 'formula', 'amplitude'],
    body: 'Calculates the minimum plus add needed for comfortable near vision, using amplitude reserve (patient should use ≤half of available amplitude).',
    code: 'Add = 1/d − Amplitude/2',
    bullets: [
      'd = desired near working distance in metres',
      'At 40 cm: demand = 2.50D; if amplitude = 3D, half = 1.50D → add = 2.50 − 1.50 = +1.00D',
      'Start conservative; increase as amplitude reduces with age',
      'Maximum comfortable add: 1/d (full demand if no amplitude reserve)',
    ],
  ),

  _Entry(
    title: 'Vergence Demand at Near',
    cat: 'Formulas',
    tags: ['vergence demand', 'NPC', 'IPD', 'convergence', 'formula'],
    body: 'Maximum vergence demand is determined by the ratio of IPD to viewing distance.',
    code: 'Vergence (Δ) ≈ IPD (cm) / distance (m)',
    bullets: [
      'IPD = 6 cm, distance = 0.10 m: demand ≈ 60Δ convergence (approximate max)',
      'At 40 cm: 6/0.4 = 15Δ convergence demand',
      'At 25 cm: 6/0.25 = 24Δ',
      'Used to estimate convergence effort at given working distance',
    ],
  ),
];

// ─── Screen ──────────────────────────────────────────────────────────────────

const _kCategories = ['BV', 'Acc.', 'Strabismus', 'Norms', 'Tests', 'Formulas'];

class ReferenceScreen extends StatefulWidget {
  const ReferenceScreen({super.key});
  @override
  State<ReferenceScreen> createState() => _ReferenceScreenState();
}

class _ReferenceScreenState extends State<ReferenceScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _category = 'BV';
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<_Entry> get _shown {
    if (_query.isNotEmpty) {
      return _kEntries.where((e) => e.matches(_query)).toList();
    }
    return _kEntries.where((e) => e.cat == _category).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSearching = _query.isNotEmpty;
    final entries = _shown;

    return Column(
      children: [
        _buildSearchBar(isDark),
        if (!isSearching) _buildCategoryChips(isDark),
        Expanded(
          child: entries.isEmpty
              ? EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No results for "$_query"',
                  subtitle: 'Try a condition name, symptom, or abbreviation',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: entries.length,
                  itemBuilder: (_, i) => _buildEntry(entries[i], isDark, isSearching),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchCtrl,
          focusNode: _focusNode,
          onChanged: (v) => setState(() => _query = v.trim()),
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            filled: false,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 11),
            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF8E8E93)),
            suffixIcon: _query.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                      _focusNode.unfocus();
                    },
                    child: const Icon(Icons.cancel_rounded, size: 18, color: Color(0xFF8E8E93)),
                  )
                : null,
            hintText: 'Search conditions, norms, formulas…',
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF8E8E93)),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(bool isDark) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: _kCategories.map((cat) {
          final selected = cat == _category;
          return GestureDetector(
            onTap: () => setState(() => _category = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? kPrimary : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? kPrimary : (isDark ? const Color(0xFF48484A) : const Color(0xFFD1D1D6)),
                  width: 1,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? Colors.white : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEntry(_Entry e, bool isDark, bool showCategoryBadge) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            iconColor: kPrimary,
            collapsedIconColor: const Color(0xFF8E8E93),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showCategoryBadge) ...[
                  _catPill(e.cat),
                  const SizedBox(height: 4),
                ],
                Text(e.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 5),
                Wrap(spacing: 4, runSpacing: 4,
                    children: e.tags.take(4).map((t) => Pill.info(t)).toList()),
              ],
            ),
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Body
                Text(e.body, style: TextStyle(
                  fontSize: 12, height: 1.6,
                  color: isDark ? const Color(0xFFEBEBEB) : const Color(0xFF3A3A3C),
                )),
                // Code block
                if (e.code != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: kOkBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(e.code!,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, color: kOkText)),
                  ),
                ],
                // Bullets
                if (e.bullets != null) ...[
                  const SizedBox(height: 8),
                  ...e.bullets!.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        margin: const EdgeInsets.only(top: 5, right: 8),
                        width: 4, height: 4,
                        decoration: BoxDecoration(
                          color: kPrimary.withAlpha(180),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(b, style: TextStyle(
                          fontSize: 12, height: 1.5,
                          color: isDark ? const Color(0xFFD1D1D6) : const Color(0xFF3A3A3C),
                        )),
                      ),
                    ]),
                  )),
                ],
                // Management
                if (e.management != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.medical_services_outlined, size: 13, color: kPrimary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(e.management!, style: TextStyle(
                          fontSize: 11.5, height: 1.55,
                          color: isDark ? const Color(0xFFD1D1D6) : const Color(0xFF3A3A3C),
                        )),
                      ),
                    ]),
                  ),
                ],
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _catPill(String cat) {
    return switch (cat) {
      'BV'         => Pill.normal(cat),
      'Acc.'       => Pill.purple(cat),
      'Strabismus' => Pill.info(cat),
      'Norms'      => Pill.warn(cat),
      'Tests'      => Pill(cat, bg: kBadgeBlueBg, fg: kBadgeBlueText),
      'Formulas'   => Pill(cat, bg: const Color(0xFFEEEDFE), fg: const Color(0xFF3C3489)),
      _            => Pill.info(cat),
    };
  }
}
