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

## Model design (single context + single machine)

### Context **C0** — static data

| Element     | Type                          | Purpose                                  | Req |
|-------------|-------------------------------|------------------------------------------|-----|
| `CITIES`    | carrier set                   | the set of all cities                    | 2   |
| `FLIGHTS`   | carrier set                   | the set of all flights                   | 2   |
| `DATES`     | carrier set                   | the set of all calendar dates            | 4   |
| `dep`       | `FLIGHTS → CITIES`            | departure city of each flight            | 2   |
| `dest`      | `FLIGHTS → CITIES`            | destination city of each flight          | 2   |
| `seats`     | `FLIGHTS → ℕ₁`                | seat capacity per flight                 | 6   |
| `schedule`  | `FLIGHTS ↔ DATES`             | which flights run on which dates         | 4,5 |
| `price`     | `schedule → ℕ`                | ticket price per (flight, date)          | 10  |

**Axioms:**
- `∀f · dep(f) ≠ dest(f)` (req 3)
- `seats`, `schedule`, `price` are constants → schedule is static (req 5)

### Machine **M0** — dynamic state and operations

| Variable    | Type                  | Purpose                              | Req |
|-------------|-----------------------|--------------------------------------|-----|
| `available` | `schedule → ℕ`        | currently free tickets per (f, d)    | 7   |

**Invariant:** `∀(f↦d) ∈ schedule · available(f↦d) ≤ seats(f)`

**Initialisation:** `available(f↦d) := seats(f)` for every scheduled pair.

**Events:**

| Event              | Parameters                       | Guard                                                                                                  | Action                                                          | Req   |
|--------------------|----------------------------------|--------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------|-------|
| `book`             | `f, d, n`                        | `(f↦d) ∈ schedule ∧ n ∈ ℕ₁ ∧ n ≤ available(f↦d)`                                                       | `available(f↦d) := available(f↦d) − n`                          | 8     |
| `cancel`           | `f, d, n`                        | `(f↦d) ∈ schedule ∧ n ∈ ℕ₁ ∧ available(f↦d) + n ≤ seats(f)`                                            | `available(f↦d) := available(f↦d) + n`                          | 9     |
| `book_connecting`  | `c1, c3, d, max_total, f1, f2`   | `f1, f2` chosen non-det.; `dep(f1)=c1`, `dest(f1)=dep(f2)`, `dest(f2)=c3`; both scheduled on `d`; both have ≥1 seat; `price(f1↦d) + price(f2↦d) ≤ max_total` | `available(f1↦d) := available(f1↦d) − 1`; `available(f2↦d) := available(f2↦d) − 1` | 11,12 |

The `ANY f1, f2 WHERE …` form gives the non-deterministic choice required by req 12.
