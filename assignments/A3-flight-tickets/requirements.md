# Assignment 3 — Flight Ticket System: Requirements

Source: Lecture 8 (`MIV_8_0331.pdf`), slides 37–39. Deadline: April 28th.

## The 12 Requirements (verbatim)

1. **Purpose.** The purpose of the system is to facilitate booking tickets to available flights between cities.

2. **Flight = pair of cities.** Each flight is associated with a pair of cities: the departure city and the destination city.

3. **Distinct endpoints.** The departure and destination cities for the same flight should be different.

4. **Multiple dates per flight.** The same flight might occur on different dates (days).

5. **Static schedule.** The information about specific dates when the flight occurs is constant and is available in the system.

6. **Per-flight seat capacity.** There is a maximal number of plane seats, which can be different for each flight.

7. **Track available tickets.** The system should keep track of a number of available tickets for a particular flight and a date.

8. **Book operation.** The system should provide an operation for booking (if possible) a number of tickets for a particular flight on a particular date.

9. **Cancel operation.** The system should have an operation for cancelling a number of tickets for a particular flight on a particular date.

10. **Prices.** The system also keeps the information about the prices for a particular flight on specific dates.

11. **Connecting flights.** An additional booking operation should allow to book, if possible, two connecting flights (i.e., with the same intermediate city) for a pair of given cities, a specific date, and the maximal price of two flights.

12. **Non-deterministic choice.** If there are several pairs of possible connecting flights satisfying the criteria, the actual connecting flights can be chosen non-deterministically.

---

## Refinement plan (M0 → M1 → M2)

The abstract-to-concrete strategy mirrors Lecture 8's file-transfer example: each refinement adds one conceptual layer and preserves all earlier invariants.

### **Context C0 + Machine M0** — *static world, no booking yet*
Covers requirements **1–7**.

- **Carrier sets:** `CITIES`, `FLIGHTS`, `DATES`.
- **Constants:** `dep`, `dest` (flight → city), `seats` (flight → ℕ₁), `schedule` (flight ↔ date).
- **Axioms:** distinct endpoints (req 3), positive seat capacity (req 6), schedule totality (req 5).
- **Variable:** `available ∈ schedule → ℕ` — current free tickets (req 7).
- **Initialisation:** `available(f ↦ d) = seats(f)` for every scheduled `(f, d)`.
- **Events:** a single abstract non-deterministic `update_availability` event that decreases or increases `available` within `0..seats(f)`. This is the abstract "something happened to the inventory" event that will later be refined into concrete `book` / `cancel`.

### **Machine M1 refines M0** — *concrete booking operations*
Covers requirements **8–9**. Superposition + refinement of non-determinism.

- Adds two concrete events `book(f, d, n)` and `cancel(f, d, n)` that both **refine** the abstract `update_availability`.
- `book` strengthens the guard: `n ≤ available(f ↦ d)`, action `available(f ↦ d) := available(f ↦ d) − n`.
- `cancel` strengthens the guard: `available(f ↦ d) + n ≤ seats(f)`, action `available(f ↦ d) := available(f ↦ d) + n`.
- No new variables; pure refinement of non-determinism (Lecture 8, slide 7 pattern).

### **Context C1 extends C0 + Machine M2 refines M1** — *prices & connecting flights*
Covers requirements **10–12**. Context extension + superposition.

- **C1** adds constant `price ∈ schedule → ℕ` (req 10).
- **M2** adds a new event `book_connecting(c₁, c₃, d, max_total)`:
  - Non-deterministically picks an intermediate city `c₂`, flights `f₁` (c₁→c₂) and `f₂` (c₂→c₃), both scheduled on date `d`, both with ≥ 1 available seat, and `price(f₁ ↦ d) + price(f₂ ↦ d) ≤ max_total` (reqs 11–12).
  - Decrements `available` for both legs.
  - This event **refines** the abstract `update_availability` twice-over (or is modelled as a convergent new event that performs two abstract steps — we'll discuss the exact framing when we get there).

---

## Mapping: requirement → model element

| Req | Where it is enforced |
|-----|----------------------|
| 1   | Existence of the whole system (trivial) |
| 2   | `dep, dest ∈ FLIGHTS → CITIES` in C0 |
| 3   | Axiom `∀f · dep(f) ≠ dest(f)` in C0 |
| 4   | `schedule ∈ FLIGHTS ↔ DATES` (relation, not function) in C0 |
| 5   | `schedule` is a **constant** in C0 |
| 6   | `seats ∈ FLIGHTS → ℕ₁` in C0 |
| 7   | Variable `available ∈ schedule → ℕ` + invariant `∀(f↦d) · available(f↦d) ≤ seats(f)` in M0 |
| 8   | Event `book` in M1 |
| 9   | Event `cancel` in M1 |
| 10  | Constant `price` in C1 |
| 11  | Event `book_connecting` in M2 |
| 12  | `book_connecting` uses `ANY` (non-deterministic choice) in M2 |
