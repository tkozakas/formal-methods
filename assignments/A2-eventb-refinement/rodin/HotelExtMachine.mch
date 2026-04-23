MACHINE HotelExtMachine
SETS
    CUSTOMER;
    ROOM;
    DATE;
    RESERVATION
ABSTRACT_CONSTANTS
    res_room,
    res_customer,
    res_dates
PROPERTIES
    res_room : RESERVATION --> ROOM &              /* Each reservation has exactly one room */
    res_customer : RESERVATION --> CUSTOMER &       /* Each reservation has exactly one customer */
    res_dates : RESERVATION --> POW1(DATE)          /* Each reservation has non-empty dates */
VARIABLES
    active_res,
    occupied
INVARIANT
    active_res <: RESERVATION &                     /* R3: Active reservations subset */
    occupied <: RESERVATION &                       /* R9: Occupied bookings subset */
    active_res /\ occupied = {} &                   /* A reservation can't be both */
    !(r1,r2).(r1 : active_res & r2 : active_res    /* R5: No overlapping reservation dates */
              & r1 /= r2 & res_room(r1) = res_room(r2)
              => res_dates(r1) /\ res_dates(r2) = {}) &
    !(r,o).(r : active_res & o : occupied          /* R5,R11: No overlap reservation/occupied */
            & res_room(r) = res_room(o)
            => res_dates(r) /\ res_dates(o) = {}) &
    !(o1,o2).(o1 : occupied & o2 : occupied        /* R11: No overlap between two occupied */
              & o1 /= o2 & res_room(o1) = res_room(o2)
              => res_dates(o1) /\ res_dates(o2) = {})
INITIALISATION
    active_res := {} ||
    occupied := {}
OPERATIONS
    /* R1, R4, R5: A customer makes a reservation */
    ReserveRoom(rv) =
        PRE
            rv : RESERVATION &                                          /* Valid reservation */
            rv /: active_res \/ occupied &                              /* Not already in the system */
            !(r).(r : active_res & res_room(r) = res_room(rv)          /* R5: No clash with reservations */
                  => res_dates(r) /\ res_dates(rv) = {}) &
            !(o).(o : occupied & res_room(o) = res_room(rv)            /* R5,R11: No clash with occupied */
                  => res_dates(o) /\ res_dates(rv) = {})
        THEN
            active_res := active_res \/ {rv}
        END;

    /* R6, R7: Cancel a reservation */
    CancelReservation(rv) =
        PRE
            rv : active_res                                             /* Must be active */
        THEN
            active_res := active_res - {rv}
        END;

    /* R8, R10: Check in with reservation — move from active_res to occupied */
    CheckInWithReservation(rv) =
        PRE
            rv : active_res &                                           /* Must be active */
            rv /: occupied &                                            /* Theorem: follows from inv3 */
            !(r).(r : active_res & r /= rv & res_room(r) = res_room(rv) /* Theorem: follows from inv4 */
                  => res_dates(r) /\ res_dates(rv) = {}) &
            !(o).(o : occupied & res_room(o) = res_room(rv)             /* Theorem: follows from inv5 */
                  => res_dates(o) /\ res_dates(rv) = {})
        THEN
            active_res := active_res - {rv} ||                          /* Remove from active */
            occupied := occupied \/ {rv}                                /* Add to occupied */
        END;

    /* R12: Check in without reservation — fresh RESERVATION straight to occupied */
    CheckInWithoutReservation(rv) =
        PRE
            rv : RESERVATION &                                          /* Valid reservation */
            rv /: active_res \/ occupied &                              /* Not already in the system */
            !(r).(r : active_res & res_room(r) = res_room(rv)          /* No clash with reservations */
                  => res_dates(r) /\ res_dates(rv) = {}) &
            !(o).(o : occupied & res_room(o) = res_room(rv)            /* No clash with occupied */
                  => res_dates(o) /\ res_dates(rv) = {})
        THEN
            occupied := occupied \/ {rv}
        END;

    /* R13: Check out */
    CheckOut(rv) =
        PRE
            rv : occupied                                               /* Must be occupied */
        THEN
            occupied := occupied - {rv}
        END
END
