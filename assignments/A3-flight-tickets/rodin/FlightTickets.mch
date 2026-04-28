MACHINE FlightTickets
/* ============================================================================
 * Flight Ticket System — classical B encoding for ProB verification
 *
 * Mirrors the Event-B refinement chain:
 *   C0 + M0  : static schedule + abstract `available` variable
 *   M1       : concrete book / cancel events refining update_availability
 *   C1 + M2  : prices + book_connecting (two legs through intermediate city)
 *
 * All machines collapsed into one classical B file because ProB CLI parses
 * .mch directly (Rodin XML is not parsed by probcli without export).
 * Requirements satisfied (1–12) — see requirements.md.
 * ============================================================================ */
SETS
    CITIES;
    FLIGHTS;
    DATES
ABSTRACT_CONSTANTS
    dep,           /* req 2 */
    dest,          /* req 2 */
    seats,         /* req 6 */
    schedule,      /* req 4, 5 */
    price          /* req 10 */
PROPERTIES
    dep      : FLIGHTS --> CITIES &
    dest     : FLIGHTS --> CITIES &
    !f.(f : FLIGHTS => dep(f) /= dest(f)) &        /* req 3 */
    seats    : FLIGHTS --> NATURAL1 &              /* req 6 */
    schedule : FLIGHTS <-> DATES &                  /* req 4 */
    price    : schedule --> NATURAL                 /* req 10 */
VARIABLES
    available                                       /* req 7 */
INVARIANT
    available : schedule --> NATURAL &
    !(f,d).(f|->d : schedule => available(f|->d) <= seats(f))
INITIALISATION
    available := schedule * {0}
OPERATIONS

    /* ------------------------------------------------------------------------
     * Abstract event from M0 — kept here so ProB can model-check the abstract
     * non-deterministic update of inventory. Concrete book/cancel operations
     * (refinements) restrict its non-determinism in M1.
     * ------------------------------------------------------------------------ */
    update_availability(f, d, newval) =
        PRE
            f|->d : schedule &
            newval : 0 .. seats(f)
        THEN
            available(f|->d) := newval
        END;

    /* req 8: book n tickets for flight f on date d (refines update_availability) */
    book(f, d, n) =
        PRE
            f|->d : schedule &
            n     : NATURAL1 &
            n <= available(f|->d)
        THEN
            available(f|->d) := available(f|->d) - n
        END;

    /* req 9: cancel n tickets (refines update_availability) */
    cancel(f, d, n) =
        PRE
            f|->d : schedule &
            n     : NATURAL1 &
            available(f|->d) + n <= seats(f)
        THEN
            available(f|->d) := available(f|->d) + n
        END;

    /* req 11, 12: book two connecting flights c1 -> c2 -> c3 on date d
     * with combined price <= max_total. Intermediate city c2 and concrete
     * flights f1, f2 are chosen non-deterministically via ANY. */
    book_connecting(c1, c3, d, max_total) =
        PRE
            c1 : CITIES & c3 : CITIES &
            c1 /= c3 &
            d  : DATES &
            max_total : NATURAL
        THEN
            ANY c2, f1, f2 WHERE
                c2 : CITIES & c2 /= c1 & c2 /= c3 &
                f1 : FLIGHTS & f2 : FLIGHTS & f1 /= f2 &
                dep(f1) = c1 & dest(f1) = c2 &
                dep(f2) = c2 & dest(f2) = c3 &
                f1|->d : schedule & f2|->d : schedule &
                available(f1|->d) >= 1 &
                available(f2|->d) >= 1 &
                price(f1|->d) + price(f2|->d) <= max_total
            THEN
                available := available <+ {
                    f1|->d |-> available(f1|->d) - 1,
                    f2|->d |-> available(f2|->d) - 1
                }
            END
        END

END
