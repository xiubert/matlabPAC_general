# matlabPAC_general
helpful functions for auditory data analysis and experiments

## Speaker calibration files

`speakerCalibration/calibrationOutput_oscopeFile_*.mat` files are produced by
`speakerCal_oscDataFile.m` (and its per-rig variants) from oscilloscope recordings of
played stimuli. Every stimulus-generation script in `stimuliGeneration/` reads one to
convert a desired dB SPL into the gain hardcoded into a `.signal` file.

File names follow
`calibrationOutput_oscopeFile_<micType>mic_<Gcal>gain_<yyyymmdd>_<rig>.mat`.

### Contents

Each file holds a **single struct** named `calibration_oscopeFile`. Load it without
assuming the variable name:

```matlab
calS = load(calFile);
calSname = fieldnames(calS);
calS = calS.(calSname{1});
```

| Field | Type | Meaning |
|---|---|---|
| `date` | char `yyyymmdd` | when the calibration was run |
| `micType` | char | measurement microphone |
| `VtoPa` | double | microphone volts per pascal |
| `micCalV` | double | reference Vrms measured from the mic calibrator |
| `micCaldB` | double | dB SPL of that reference (94, B&K Type 4231) |
| `Gcal` | double | stimulator gain the stimuli were played at (1800) |
| `Tcal` | table | every individual measurement: `sound_ID`, `Vrms`, `dBcalc` |
| `Tmean` | table | per-stimulus means: `sound_ID`, `Vrms`, `dB` |
| `TgainSet` | table | convenience gain lookup, `sound_ID` plus one column per dB level |
| `Tproblem` | table | **present only** when some level needed >10 V into the speaker amp |

`Tmean` is the one that matters for stimulus generation. Row 1 is always the calibrator
reference (`sound_ID` containing `'reference'`, and its `Vrms` equals `micCalV`); every
other row is a played stimulus.

### Reading a calibration file

Generation scripts do not touch these fields directly. They go through
`helperFcns/auditory/loadSpeakerCal.m`, which normalizes **either** schema — the
`Tmean` oscilloscope-file calibrations above, or older inverse-filter calibrations
carrying `freq` + `Vout` — into one canonical struct:

```matlab
cal = loadSpeakerCal();                 % or loadSpeakerCal(fullPath)
% cal.schema   'Tmean' | 'legacy'
% cal.micCalV, cal.micCaldB, cal.Gcal
% cal.soundID  nSounds x 1 cellstr, calibrator reference row removed
% cal.Vrms     nSounds x 1 measured Vrms at cal.Gcal
% cal.freq     1 x nSounds, NaN where the ID is a name rather than a frequency

[freq,Vrms] = calSelectSounds(cal,'PromptString','Select frequencies');
Vwant = dBwant2voltage(dBlvls, cal.micCalV);   % desired dB -> volts
Gset  = Vwant2gain(Vwant, Vrms, cal.Gcal);     % volts -> stimulator gain
```

`calSelectSounds` prompts with `listdlg` for `Tmean` files (which mix tones and noise)
and returns everything without prompting for legacy files (which hold only tones).
`calFindSound(cal, [7711 15422])` looks stimuli up non-interactively by frequency or by
sound ID.

Picking the wrong stimulus silently produces wrong sound levels, which is why selection
is an explicit prompt rather than a fixed string match.

**Never read gains from `TgainSet`.** Its column names differ between rigs (see below),
so indexing it by name is not portable. Recompute from `cal.Vrms` with the two-line
chain above — that is what every generation script now does.

### Differences between the current rig files

Two files are in this folder, one per rig. Beyond the recorded values, they differ in
three ways that matter to code reading them:

| | `..._20260515_scientifica.mat` | `..._20260528_sutter.mat` |
|---|---|---|
| BPN `sound_ID` | `BBN_6-64kHz` | `BB_6-64` |
| `Tmean` rows | 2 — reference + BPN only | 30 — reference + 28 tones + BPN |
| `TgainSet` columns | `lvl_20_dB` … `lvl_80_dB` | `30 dB` … `80 dB` |

1. **The BPN stimulus is named differently on each rig**, so never match it with a
   hardcoded string — select it from `Tmean.sound_ID`.
2. **The scientifica file contains no pure-tone rows at all**, only broadband noise.
   Tone-based generation scripts have nothing to work from in that file.
3. **`TgainSet` column names use different conventions.** The scientifica variant
   (`speakerCal_oscDataFile_scientifica.m:184`) writes valid identifiers `lvl_<dB>_dB`,
   while the base script (`speakerCal_oscDataFile.m:181`) writes `<dB> dB` with a space,
   which has to be indexed as `T.('30 dB')`. The dB ranges also differ (20–80 vs 30–80)
   because the two scripts default `gSetDBstart` to 20 and 30 respectively. `TgainSet`
   is a human-facing convenience table; generation scripts recompute gains from `Tmean`
   via `loadSpeakerCal` and are unaffected.

Everything else is identical in format: same struct name, same field set, same classes,
and `Tcal`/`Tmean` carry the same variable names and types in both.

Tone `sound_ID` values in the sutter file are **bare frequency strings** (`'5000'`,
`'10905'`, …) with no unit suffix.

### Note for tone-based generation scripts

These oscilloscope-derived files have **no `freq` or `Vout` fields** — per-tone data
lives in `Tmean`, keyed by those frequency strings. `loadSpeakerCal` maps both layouts
onto `cal.freq` / `cal.Vrms`, so scripts work with either; nothing should read `.freq`
or `.Vout` off the raw struct any more.
