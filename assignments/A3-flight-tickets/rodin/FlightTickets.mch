MACHINE FlightTickets
/* Flight Ticket System — flat B machine for ProB verification.
 * Mirrors the Event-B project (C0 static data + M0 dynamic state). */

SETS
    CITIES; FLIGHTS; DATES

ABSTRACT_CONSTANTS
    dep, dest, seats, schedule, price   /* constants */

PROPERTIES
    dep      : FLIGHTS --> CITIES &
    dest     : FLIGHTS --> CITIES &
    /* a flight cannot start and end in the same city */
    !f.(f : FLIGHTS => dep(f) /= dest(f)) &
    seats    : FLIGHTS --> NATURAL1 &
    schedule : FLIGHTS <-> DATES &
    price    : schedule --> NATURAL

VARIABLES
    available

INVARIANT
    available : schedule --> NATURAL &
    /* free seats never exceed plane capacity */
    !(f,d).(f|->d : schedule => available(f|->d) <= seats(f))

INITIALISATION
    /* every scheduled flight starts fully empty (all seats free) */
    available := %(f,d).(f|->d : schedule | seats(f))

OPERATIONS

    /* book n seats — guard: flight is scheduled, n >= 1, enough free seats */
    book(f, d, n) =
        PRE
            f|->d : schedule &
            n     : NATURAL1 &
            n <= available(f|->d)
        THEN
            available(f|->d) := available(f|->d) - n
        END;

    /* cancel n seats — guard: flight scheduled, n >= 1, doesn't exceed capacity */
    cancel(f, d, n) =
        PRE
            f|->d : schedule &
            n     : NATURAL1 &
            available(f|->d) + n <= seats(f)
        THEN
            available(f|->d) := available(f|->d) + n
        END;

    /* book a connection c1 -> c2 -> c3 on date d within budget max_total.
     * guard: pick layover c2 and two distinct flights f1, f2 such that
     *   legs match the cities, both are scheduled on d,
     *   each has a free seat, and total price fits the budget */
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
                /* <+ is function override: update only these two entries */
                available := available <+ {
                    f1|->d |-> available(f1|->d) - 1,   /* leg 1: one fewer free seat */
                    f2|->d |-> available(f2|->d) - 1    /* leg 2: one fewer free seat */
                }
            END
        END

END
