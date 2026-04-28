# Assignment 3 — Flight Ticket System (Event-B)

A three-step refinement of a flight-booking system, modelled in Event-B and
verified with ProB. Implements the 12 requirements from Lecture 8
(see [`requirements.md`](requirements.md)).

---

## 1. Structure (in plain words)

Three layers, each adding more detail without breaking earlier promises:

```
┌─────────────────────────────────────────────────┐
│ M2 + C1   "Prices and connecting flights"       │  most concrete
│   adds: price, book_connecting                  │
├─────────────────────────────────────────────────┤
│ M1        "Concrete book and cancel"            │
│   adds: book, cancel (refine update_availability│
├─────────────────────────────────────────────────┤
│ M0 + C0   "Static world"                        │  most abstract
│   adds: cities, flights, dates, seat counts,    │
│         available variable                      │
└─────────────────────────────────────────────────┘
```

- **Contexts (`C0`, `C1`)** = static facts that never change (carrier sets,
  constants, axioms). Like saying "London exists; flight LH123 has 100 seats."
- **Machines (`M0`, `M1`, `M2`)** = dynamic state that changes over time
  (variables, invariants, events). Like saying "right now LH123 on Monday has
  73 free seats."
- **Refinement** = "more detail, same promises." Each machine refines the
  previous one and inherits all its invariants automatically.

> **Key insight — refinement flows upward.**
> If M2 is verified correct, then M1 and M0 are automatically correct too.
> Refinement obligations guarantee that every concrete event in M2 still
> behaves as the abstract event it refines, so all earlier invariants are
> preserved. A single "NO ERRORS FOUND" on M2 proves the whole chain is sound.
> (The reverse is **not** true: verifying M0 alone says nothing about M1 or
> M2 — each refinement step adds new behaviour with its own proof obligations.)

| Layer  | Sees       | Refines | Adds |
|--------|------------|---------|------|
| **C0** | —          | —       | `CITIES`, `FLIGHTS`, `DATES`, `dep`, `dest`, `seats`, `schedule` |
| **M0** | C0         | —       | variable `available`, abstract event `update_availability` |
| **M1** | C0         | M0      | concrete events `book`, `cancel` |
| **C1** | extends C0 | —       | constant `price` |
| **M2** | C1         | M1      | new event `book_connecting` |

Files in `rodin/`:
- `C0.buc`, `C1.buc` — contexts (Rodin XML)
- `M0.bum`, `M1.bum`, `M2.bum` — machines (Rodin XML)
- `FlightTickets.mch` — flat classical-B encoding used by ProB CLI

---

## 2. Variable, axioms, invariants, guards explained

### The single variable

```
available ∈ schedule → ℕ
```

For each `(flight, date)` pair that is in the schedule, `available` stores a
non-negative integer = how many seats are still free right now. **This is the
only thing that changes.** Cities, flight info, prices are fixed forever.

### Axioms (in C0/C1) — facts about constants

| Axiom in C0 | What it says in plain words |
|---|---|
| `dep ∈ FLIGHTS → CITIES`   | every flight has exactly one departure city |
| `dest ∈ FLIGHTS → CITIES`  | every flight has exactly one destination city |
| `∀f · dep(f) ≠ dest(f)`    | a flight cannot start and end in the same city |
| `seats ∈ FLIGHTS → ℕ₁`     | every flight has a positive seat capacity |
| `schedule ∈ FLIGHTS ↔ DATES` | flights happen on dates; same flight may occur on many dates (`↔` is a relation, not a function) |
| `price ∈ schedule → ℕ` (C1)| every scheduled (flight, date) has a non-negative price |

### Invariants (in M0) — safety rails always true

| Invariant | Plain words |
|---|---|
| `available ∈ schedule → ℕ` | every scheduled (flight, date) has a current free-seat count, and it's non-negative |
| `∀f,d · f↦d ∈ schedule ⇒ available(f↦d) ≤ seats(f)` | the free-seat count never exceeds the total capacity |

### Guards — preconditions that protect the invariants

Guards are conditions checked **before** an event fires. They guarantee the
event won't break any invariant. Example: `book(f, d, n)` requires
`n ≤ available(f↦d)` so we never go negative.

---

## 3. Requirement → model element (full mapping)

| # | Requirement (short) | Where it lives | What enforces it & why |
|---|---|---|---|
| 1 | Purpose: book tickets to available flights | The whole model | The system itself implements it |
| 2 | Flight = pair of cities (departure, destination) | C0 axm1, axm2 | Functions `dep, dest ∈ FLIGHTS → CITIES` mean every flight has *exactly one* departure and *exactly one* destination city |
| 3 | Departure ≠ destination | C0 axm3: `∀f · dep(f) ≠ dest(f)` | Universally quantified axiom forbids any flight with same start and end |
| 4 | Same flight on many dates | C0 axm5: `schedule ∈ FLIGHTS ↔ DATES` | The `↔` arrow is a *relation* (not a function), so one flight `f` can appear with many dates `d₁, d₂, …` |
| 5 | Schedule is static | `schedule` declared as **constant** (C0) | Constants never change between states; only variables can be assigned, and `schedule` is not a variable |
| 6 | Per-flight seat capacity | C0 axm4: `seats ∈ FLIGHTS → ℕ₁` | `ℕ₁` is positive naturals (≥ 1), so every flight has at least one seat; `→` ensures one capacity per flight |
| 7 | Track available tickets | M0 var `available` + inv1 + inv2 | Variable `available` stores current free seats; **inv1** types it (every scheduled (f,d) has a count); **inv2** caps it at `seats(f)` so it can never exceed total capacity |
| 8 | Book operation | M1 event `book(f, d, n)` | Event with parameters `f, d, n` (n tickets to book). **grd3:** `n ≤ available(f↦d)` — can't book more than what's free. **act1:** `available(f↦d) := available(f↦d) − n` |
| 9 | Cancel operation | M1 event `cancel(f, d, n)` | Parameters `f, d, n` (n tickets to free up). **grd3:** `available(f↦d) + n ≤ seats(f)` — can't cancel more than have been booked (would push count above capacity). **act1:** `available(f↦d) := available(f↦d) + n` |
| 10 | Per-flight, per-date prices | C1 constant: `price ∈ schedule → ℕ` | Total function from each scheduled (flight, date) to a non-negative price; constant so prices are fixed |
| 11 | Connecting flights | M2 event `book_connecting(c1, c3, d, max_total)` | Parameters: start city `c1`, end city `c3`, date `d`, price cap `max_total`. **grd4:** `dep(f1)=c1 ∧ dest(f1)=c2`. **grd5:** `dep(f2)=c2 ∧ dest(f2)=c3` (same intermediate city `c2`!). **grd6:** both legs are scheduled on `d`. **grd7:** both have ≥ 1 seat free. **grd9:** `price(f1↦d) + price(f2↦d) ≤ max_total`. **act1:** decrement both legs' availability by 1 in a single atomic action |
| 12 | Non-deterministic choice | M2 `book_connecting` uses `ANY c2, f1, f2 WHERE …` | The `ANY` clause introduces local existential variables — ProB / Rodin pick *any* `(c2, f1, f2)` triple satisfying the guards, not a specific one. This is exactly Event-B's non-determinism |

### Why the invariants matter for each operation

- **`book`** could violate `available ≥ 0` if it subtracted too much →
  guard `n ≤ available(f↦d)` blocks that.
- **`cancel`** could violate `available ≤ seats(f)` if it added too much →
  guard `available(f↦d) + n ≤ seats(f)` blocks that.
- **`book_connecting`** could violate `available ≥ 0` on either leg →
  guard `available(f1↦d) ≥ 1 ∧ available(f2↦d) ≥ 1` blocks that.

---

## 4. Verification

Run the checker (requires `probcli` and JDK 11+ on PATH):

```bash
./verify.sh
```

Three independent checks against `rodin/FlightTickets.mch`:

1. **Model checking** — exhaustive state-space exploration within the bounds
   `DEFAULT_SETSIZE=2`, `MAXINT=4`; confirms no reachable state in that
   bounded universe violates the invariants.
2. **CBC (constraint-based check)** — per-event constraint solver with
   `DEFAULT_SETSIZE=1`, `MAXINT=2`; for each operation it tries to find a
   pre-state + input that satisfies the guard and breaks an invariant. No
   counterexample found ⇒ invariant preservation holds within those bounds.
3. **Deadlock checking** — searches for stuck states; deadlocks are expected
   when ProB enumerates an empty schedule constant (no flights → no events
   enabled), so this step is informational.

Why a `.mch` file? ProB CLI cannot parse Rodin's XML (`.bum`/`.buc`) directly;
the classical-B `.mch` encodes the same sets, constants, variable, invariants
and events of M2 in one file.

### Important: bounded checking ≠ formal proof

`./verify.sh` runs **ProB**, which is a *model checker* and *constraint
solver*. It establishes correctness **only for the finite bounded universe**
it explored (sets of size ≤ 2, integers ≤ 4). This is strong evidence —
no counterexample exists in that space — but it is **not** the same as
discharging Event-B's proof obligations (POs) symbolically.

The full Event-B POs (invariant preservation `evt/inv/INV`, refinement
simulation `evt/act/SIM`, guard strengthening `evt/grd/GRD`, witness
feasibility `evt/wfis/WFIS`, etc.) live in the Rodin `.bum`/`.buc` files
and are discharged by Rodin's auto-prover / interactive prover inside the
Rodin Platform GUI. **This step has not been performed here** — running
the auto-prover requires opening the project in Rodin and is outside the
scope of this CLI verification script.

In summary:

| What was done                                | What it proves                              |
|----------------------------------------------|---------------------------------------------|
| ProB model checking (bounded)                | No invariant violation in bounded states    |
| ProB CBC (bounded)                           | Each event preserves invariants (bounded)   |
| Rodin auto-prover on POs                     | *Not run* — would give symbolic guarantee   |

The Rodin XML files are structurally complete and ready for the auto-prover;
opening `rodin/` as a Rodin project would generate and (for most POs)
automatically discharge them.
