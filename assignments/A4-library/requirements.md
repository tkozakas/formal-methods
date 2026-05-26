# Assignment 4 — Library System: Requirements

Source: Lecture 10 (`MIV_10_0421.pdf`), slides 35–37. Deadline: May 26th.

## The 10 Requirements (verbatim)

1. A library system manages books and book readers in a library.
2. Books can be loaned to the readers of the library.
3. There could be several copies of the same book in the library.
4. The system should record the library books, their availability to the readers, as well as which books are currently loaned to which readers.
5. There is an upper bound of the number of books (a predefined constant) that a single reader can loan.
6. The last copy of a book cannot be loaned.
7. The same reader cannot loan more than one copy of the same book.
8. If a book is not available, a reader can be put on the waiting list for that book (this is only possible for the books with more than one copy).
9. The system must allow to loan a book (if possible), return a book, put a reader on the waiting list, add more copies of a new or already existing book.
10. If the waiting list for a particular book is not empty, then the book can be loaned only for the first reader from the waiting list.

---

## Model design (flat: single context + single machine)

### Note on requirement 10 (waitlist "first reader")

The model uses a **set-based waitlist** `waitlist : BOOKS ↔ READERS` rather than a
position-tracking FIFO queue. Consequently, requirement 10 is interpreted as
**"the next loan of book `b` must go to *some* reader on the waitlist"** instead
of the strict "first" reader. This is a valid **abstract** interpretation:
- Strict FIFO is a refinement of non-deterministic choice from the waitlist.
- It greatly simplifies invariants and proof obligations.
- A future refinement step could replace `waitlist : BOOKS ↔ READERS` with
  `waitlist : BOOKS → (ℕ1 ⇸ READERS)` to add explicit ordering.

### Context **C0**

| Element     | Type            | Purpose                            | Req |
|-------------|-----------------|------------------------------------|-----|
| `BOOKS`     | carrier set     | all possible books                 | 1   |
| `READERS`   | carrier set     | all possible readers               | 1   |
| `max_loans` | `ℕ1`            | per-reader loan cap                | 5   |

### Machine **M0**

| Variable    | Type                | Purpose                                            | Req     |
|-------------|---------------------|----------------------------------------------------|---------|
| `copies`    | `BOOKS → ℕ`         | total copies in library (0 = not stocked)          | 3, 4    |
| `loans`     | `READERS ↔ BOOKS`   | who currently has what (no duplicate r↦b)          | 2, 4, 7 |
| `waitlist`  | `BOOKS ↔ READERS`   | per-book set of waiting readers                    | 8, 10   |

**Invariants:**
- `inv1–3` typing
- `inv4: ∀b,r · b↦r ∈ waitlist ⇒ copies(b) ≥ 2` (req 8: waitlist only for multi-copy books)
- `inv5: ∀r · card(loans[{r}]) ≤ max_loans` (req 5)
- `inv6: ∀b · loans∼[{b}] ≠ ∅ ⇒ card(loans∼[{b}]) < copies(b)` (req 6: last copy reserved)
- `inv7: ∀b · card(waitlist[{b}]) ≤ card(READERS)` (sanity bound)

**Events:** `loan_book`, `return_book`, `add_to_waitlist`, `add_copies` (req 9)

- `loan_book(r, b)`:
  - guards: `b ∈ dom(copies) ∧ copies(b) ≥ 2`
  - `r↦b ∉ loans` (req 7)
  - `card({b' · r↦b' ∈ loans}) < max_loans` (req 5)
  - `card(loans∼[{b}]) < copies(b) − 1` (req 6)
  - if `b ∈ dom(waitlist)`, reader at position 1 must be `r` (req 10)
  - action: add `r↦b` to loans; if `r` was at position 1, remove and decrement others.

- `return_book(r, b)`:
  - guard: `r↦b ∈ loans`
  - action: remove `r↦b` from loans

- `add_to_waitlist(r, b)`:
  - guards: `copies(b) ≥ 2` (req 8: only for multi-copy books)
  - book unavailable: `card(loans∼[{b}]) = copies(b) − 1`
  - reader not already waiting for that book
  - action: append `r` at next free position

- `add_copies(b, k)`:
  - guards: `b ∈ BOOKS ∧ k ∈ ℕ1`
  - action: `copies(b) := copies(b) + k` (handles both new and existing books)
