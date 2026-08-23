# Sampling units, identifiers, and raising

Biotic is hierarchical. Decide the biological and operational sampling unit before filtering, joining, completing zeros, or calculating rates. A row in `stnall` is a catchsample record, not necessarily a haul.

## Stable identifiers

Use these keys in decreasing order of convenience:

| Context | Key |
|---|---|
| BioticExplorerServer (BES) database | `missionid + serialnumber` |
| Native NMD Biotic mission and fishstation | `missiontype + startyear + platform + missionnumber + serialnumber` |
| Catchsample within a fishstation | fishstation key + `catchsampleid` |
| Individual within a catchsample | catchsample key + `specimenid` |

`missionid` is a BES convenience field. It is not part of native NMD Biotic. Do not substitute `cruise`, `platformname`, or `callsignal` for the native mission key without first proving uniqueness; names and labels can change or be missing.

The usual haul identifier is `serialnumber` within a mission. The field `station` identifies the sampling unit recorded by the survey. Usually one fishstation record represents one haul, but special gears such as multisamplers can assign one `serialnumber` to each bag and the same `station` to the physical haul. This convention is uncommon and must be verified from survey design, time, position, depth sequence, and comments before records are combined.

## Catchsamples and catch parts

A species can occur in several catchsamples or catch parts within one fishstation. These rows may represent disjoint fractions, subsamples, sex-specific parts, products, or repeated/overlapping records. The intended logic is sometimes stated only in comments for a `serialnumber + commonname` combination.

Before aggregation:

1. Inspect `catchsampleid`, `catchcategory`, `catchpartnumber`, product fields, raising fields, and comments.
2. Test whether station metadata are constant within the intended fishstation key.
3. Determine whether catchsample rows are additive, nested, or alternative representations.
4. Sum only disjoint quantities. Do not sum overlapping total-and-subpart records.
5. Record any survey-specific rule and flag unresolved combinations for review.

When a response is aggregated to a larger sampling unit, aggregate its effort at the same level. For rates and densities, sum additive catches and denominators first, then divide. Averaging row-level rates gives incorrect weighting when effort differs.

## True zeros

Construct the qualified fishstation roster before filtering to the target species. Aggregate the target catch to the chosen sampling unit, left-join it to that roster, and replace absence of a target catch record with zero only after confirming that the catch was completely recorded. A missing or partial catch record is not automatically a biological zero.

## Raising length and individual observations

`catchcount` is the count represented by a catchsample and may already be estimated. `lengthsamplecount` is the number measured for length. For a representative length sample with both values positive, the number represented by each measured fish is

`representation = catchcount / lengthsamplecount`.

Keep this as a numeric weight where possible; duplicating rows with `uncount()` needlessly expands data and rounding the factor loses information. Calculate representation within the catchsample key, not across species, catch parts, or fishstations. If `catchcount` is missing but `catchweight`, `lengthsampleweight`, and `lengthsamplecount` are valid and the sample is representative, the EggaN workflow estimated

`catchcount = catchweight / lengthsampleweight * lengthsamplecount`.

Use that fallback only after verifying compatible product types and catch-part logic. Do not replace an unknown raising factor with the observed sample count. Preserve the unraised number measured separately from the raised abundance.

## Minimum validation

- Assert uniqueness at the intended output key.
- Report duplicate catchsample keys and conflicting fishstation metadata.
- Report missing identifiers, effort, catch totals, and raising inputs.
- Compare sums before and after aggregation.
- Keep the fishstation roster and positive-catch table as separate objects until zero completion is validated.

The official NMD Biotic v3 schema defines the native mission key and notes that multisampler compartments may share `station`: <https://www.imr.no/formats/nmdbiotic/v3/nmdbioticv3_en.html>.
