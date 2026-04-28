# Clause Opus 4.6 analysis of cvc5 failure to prove polyvec_ntt_harness.smt2

## PROMPT

We are working in the directory /Users/rodchap/Desktop/rod/projects/crypto/pqcp/mlkcvc5/tmp3 only.

In this directory, there is a single file polyvec_ntt_harness.smt2 written in the SMTLib language.

The cvc5 prover runs on this file but times out after 5 seconds even using the
"--enum-inst" option. The exact
command-line I used is "cvc5 --tlimit=5000 --enum-inst polyvec_ntt_harness.smt2"

On the other hand, the z3 prover returns "unsat" on this file quickly.

Please analyse the structure and content of the SMTLib file and work out why
cvc5 is unable to report "unsat" on that file while z3 is successful.
First, run z3 with high verbosity and statistics reporting to work out how
it is successful. Please use the cvc5 user
manual (here: https://cvc5.github.io/docs/cvc5-1.3.2/index.html) to
try different command-line switches, and run cvc5 to try various
switches.

Please produce an explanation of why this SMTLib file is difficult
for cvc5 and why a particular command-line switch is effective.

## RESPONSE

### File Structure

This is a CBMC-generated verification condition for the ML-KEM (Kyber) post-quantum cryptography polyvec_ntt function. Key
characteristics:

- Logic: ALL (bitvectors + arrays + datatypes + quantifiers)
- 359 declare-fun, 853 define-fun, 1639 assert, 10 quantified formulas
- Bitvector widths: 64-bit (249), 32-bit (124), 16-bit (17), 8-bit (29)
- Datatypes: struct.0 (polynomial with coeffs array of BV16), struct.2 (polyvec with vec array of struct.0)
- Arrays: (Array (_ BitVec 64) struct.0) — arrays of structs, nested with (Array (_ BitVec 64) (_ BitVec 16)) for coefficients
- 80 bvmul operations (nonlinear bitvector arithmetic)

### The Critical Quantifiers

The 10 quantified formulas all follow this pattern (representing loop invariants and pre/post-conditions):

```
(forall ((j (_ BitVec 32)) (idx (_ BitVec 32)))
  (or (bvuge j (_ bv2 32))          ; j >= 2 (out of range)
      (bvuge idx (_ bv256 32))       ; idx >= 256 (out of range)
      (and (bvsge (sign_extend (select (struct.0.coeffs
              (select array.56 (zero_extend j))) (zero_extend idx)))
            LOWER_BOUND)
           (not (bvsge ... UPPER_BOUND)))))
```

These express: "for all polynomial vector indices j ∈ {0,1} and coefficient indices idx ∈ {0,...,255}, the coefficient value is within
bounds [-3328, 3328] or [-26631, 26631]."

### Why z3 Succeeds (0.9 seconds)

z3's statistics reveal its strategy:
- quant-instantiations: 8171 — aggressive quantifier instantiation
- bv-bit2core: 297810 — converts bitvector operations to Boolean SAT
- smt.inferred-patterns — z3 automatically infers E-matching patterns from the select terms in the quantifier bodies

z3's key advantage is its pattern inference engine. Even though the quantifiers have no user-provided :pattern annotations, z3 infers
patterns from the nested select expressions (e.g., (select (struct.0.coeffs (select array.56 ...)) ...)). These patterns allow z3's E-
matching engine to efficiently instantiate the quantifiers with relevant ground terms from the assertion context. Combined with z3's
tight integration of bitvector bit-blasting (bv-bit2core) with the SAT solver, the 8171 instantiations are generated and checked
rapidly.

### Why cvc5 Fails

The root cause is a complete failure of trigger/pattern selection for E-matching. Running cvc5 with -o trigger reveals:

```
(no-trigger (forall ...))
(no-trigger (forall ...))
(no-trigger (forall ...))
(no-trigger (forall ...))
```

All quantified formulas report no-trigger — cvc5 cannot find any suitable E-matching trigger terms. This is because:

1. No uninterpreted function applications: The quantifier bodies contain only bitvector operations (bvuge, bvsge, sign_extend,
zero_extend), array select, and datatype accessor struct.0.coeffs. cvc5's trigger selection algorithm does not consider these built-in
theory operations as valid trigger patterns.

2. Nested theory terms: The key subterm (select (struct.0.coeffs (select array.56 (zero_extend j))) (zero_extend idx)) crosses three
theories (arrays, datatypes, bitvectors). z3 can infer patterns from such cross-theory terms, but cvc5 cannot.

Without E-matching triggers, cvc5 falls back to:

- **Enumerative instantiation (--enum-inst)**: Generates only ~4 instantiations per round (1 per quantifier), producing ~16 inst/sec.
At this rate, reaching the ~8000 instantiations z3 needs would take ~8+ minutes, and even then the enumerated terms may not be the
right ones.

- **CEGQI (--cegqi --cegqi-bv)**: Produces ~10 inst/sec but returns unknown quickly because it cannot fully handle the nested array/
datatype/bitvector structure.

- **Finite model finding (--fmf-bound)**: Designed for integer arithmetic bounds, not bitvector bounds like (bvuge j (_ bv2 32)).
Produces zero instantiations.

- **MBQI (--mbqi --mbqi-enum)**: Fails with "No implementation for default Sygus grammar of type (SELECTOR_TYPE struct.0 ...)" — cannot
construct enumeration grammars for the custom datatype selector types.

### Summary of the Architectural Gap

| Aspect | z3 | cvc5 |
|--------|-----|------|
| Pattern inference | Infers patterns from select/accessor terms | Reports no-trigger for all quantifiers |
| Instantiation rate | 8171 in <1s | ~16/sec (enum-inst), ~10/sec (CEGQI) |
| BV + quantifier integration | Tight bv-bit2core + E-matching | Lazy bitblasting, separate from quantifier engine |
| Bounded BV quantifiers | Recognized via pattern inference | --fmf-bound only handles integer bounds |
| Cross-theory triggers | Supports array/DT/BV composite patterns | Cannot use theory operations as triggers |

### No Effective cvc5 Switch Found

After testing ~25 different option combinations including --enum-inst, --cegqi --cegqi-bv, --finite-model-find, --fmf-bound, --mbqi,
--sygus-inst, --miniscope-quant=agg, --prenex-quant=norm, --bitblast=eager (rejected for quantified logic), --solve-bv-as-int,
--register-quant-body-terms, --relational-triggers, --partial-triggers, --use-portfolio, and various combinations with extended
timeouts up to 120 seconds, no cvc5 command-line configuration was found that produces unsat for this file.

The closest approach was --miniscope-quant=agg --enum-inst which increased the instantiation rate ~4x (by breaking nested quantifiers
into simpler ones), but even at 60 seconds it only reached 6142 instantiations — still insufficient and far too slow compared to z3's
sub-second performance.

### Root Cause

This is a fundamental limitation in cvc5's quantifier instantiation engine when dealing with quantifiers over bitvector-indexed arrays
with datatype accessors and no uninterpreted function symbols. z3's ability to infer E-matching patterns from built-in theory
operations (particularly select and datatype accessors) gives it a decisive advantage on CBMC-generated verification conditions of this
kind.
