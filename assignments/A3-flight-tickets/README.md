# Assignment 3 — Flight Ticket System (Event-B)

A three-step refinement of a flight-booking system, modelled in Event-B and
verified with ProB. Implements the 12 requirements from Lecture 8
(see [`requirements.md`](requirements.md)).

## Refinement chain

| Layer  | Sees    | Refines | Adds |
|--------|---------|---------|------|
| **C0** | —       | —       | `CITIES`, `FLIGHTS`, `DATES`, `dep`, `dest`, `seats`, `schedule` (req 2–6) |
| **M0** | C0      | —       | variable `available`, abstract event `update_availability` (req 7) |
| **M1** | C0      | M0      | concrete events `book`, `cancel` refining `update_availability` (req 8–9) |
| **C1** | extends C0 | —    | constant `price` (req 10) |
| **M2** | C1      | M1      | new event `book_connecting` (req 11–12) |

Files in `rodin/`:
- `C0.buc`, `C1.buc` — contexts (Rodin XML format)
- `M0.bum`, `M1.bum`, `M2.bum` — machines (Rodin XML format)
- `FlightTickets.mch` — flat classical-B encoding of M2 used by ProB CLI

## Requirements → model element

| Req | Where enforced |
|-----|----------------|
| 1   | the model itself |
| 2   | `dep, dest ∈ FLIGHTS → CITIES` (C0) |
| 3   | axiom `∀f · dep(f) ≠ dest(f)` (C0) |
| 4   | `schedule ∈ FLIGHTS ↔ DATES` — relation, not function (C0) |
| 5   | `schedule` is a **constant** (C0) |
| 6   | `seats ∈ FLIGHTS → ℕ₁` (C0) |
| 7   | variable `available ∈ schedule → ℕ` + invariant `available(f↦d) ≤ seats(f)` (M0) |
| 8   | event `book(f, d, n)` (M1) |
| 9   | event `cancel(f, d, n)` (M1) |
| 10  | constant `price ∈ schedule → ℕ` (C1) |
| 11  | event `book_connecting(c1, c3, d, max_total)` (M2) |
| 12  | `book_connecting` uses `ANY c2, f1, f2 WHERE …` — non-deterministic choice (M2) |

## Verification

Run the checker (requires `probcli` and JDK 11+ on PATH):

```bash
./verify.sh
```

The script runs three checks against `rodin/FlightTickets.mch`:

1. **Model checking** — exhaustive state-space exploration confirms no
   reachable state violates the invariants.
2. **Constraint-based checking (CBC)** — per-event constraint solver
   confirms each operation preserves the invariants.
3. **Deadlock checking** — searches for stuck states; deadlocks are expected
   when constants are enumerated with an empty schedule (no flights → no
   events enabled), so this step is informational.

Why a `.mch` file? ProB CLI cannot parse Rodin's XML (`.bum`/`.buc`) directly;
the classical-B `.mch` encodes the same sets, constants, variable, invariants
and events of M2 in one file. The Rodin XML files remain the canonical model
and can be opened in the Rodin GUI to discharge the proof obligations
(refinement + invariant preservation) automatically with the auto-prover.
