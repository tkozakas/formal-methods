MACHINE Library
/* Library System — flat classical-B machine for ProB verification.
 * Mirrors the Event-B project (C0 context + M0 machine). */

SETS
    BOOKS; READERS

ABSTRACT_CONSTANTS
    max_loans   /* per-reader loan cap */

PROPERTIES
    max_loans : NATURAL1 &
    max_loans = 2   /* concrete value for ProB enumeration */

VARIABLES
    copies,     /* total copies per book (0 = not stocked) */
    loans,      /* who currently has what */
    waitlist    /* per-book set of waiting readers */

INVARIANT
    copies   : BOOKS --> NATURAL &
    loans    : READERS <-> BOOKS &
    waitlist : BOOKS <-> READERS &
    /* waitlists only exist for multi-copy books */
    !(b,r).(b|->r : waitlist => copies(b) >= 2) &
    /* no reader exceeds the loan cap */
    !r.(r : READERS => card(loans[{r}]) <= max_loans) &
    /* last copy of any book always stays in the library */
    !b.(b : BOOKS & loans~[{b}] /= {} => card(loans~[{b}]) < copies(b))

INITIALISATION
    /* empty library: no copies, no loans, no waitlists */
    copies   := BOOKS * {0} ||
    loans    := {} ||
    waitlist := {}

OPERATIONS

    /* add k copies of book b — guard: k >= 1 (bounded for model-check enumeration) */
    add_copies(b, k) =
        PRE
            b : BOOKS &
            k : NATURAL1 &
            k <= 3
        THEN
            copies(b) := copies(b) + k
        END;

    /* loan book b to reader r — guard:
     *   book has >=2 copies, reader doesn't already hold it,
     *   reader below loan cap, at least one copy stays in library,
     *   and if a waitlist exists the reader must be on it */
    loan_book(r, b) =
        PRE
            r : READERS &
            b : BOOKS &
            copies(b) >= 2 &
            r|->b /: loans &
            card(loans[{r}]) < max_loans &
            card(loans~[{b}]) < copies(b) - 1 &
            (waitlist[{b}] = {} or r : waitlist[{b}])
        THEN
            loans    := loans \/ {r|->b} ||
            waitlist := waitlist - {b|->r}
        END;

    /* return book b held by reader r */
    return_book(r, b) =
        PRE
            r|->b : loans
        THEN
            loans := loans - {r|->b}
        END;

    /* put reader r on waitlist for unavailable book b — guard:
     *   book has >=2 copies, currently fully out (only last copy left),
     *   reader not already waiting */
    add_to_waitlist(r, b) =
        PRE
            r : READERS &
            b : BOOKS &
            copies(b) >= 2 &
            card(loans~[{b}]) = copies(b) - 1 &
            b|->r /: waitlist
        THEN
            waitlist := waitlist \/ {b|->r}
        END

END
