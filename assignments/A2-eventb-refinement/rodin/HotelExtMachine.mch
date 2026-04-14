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
    res_room : RESERVATION --> ROOM &              /* Each reservation is for exactly one room */
    res_customer : RESERVATION --> CUSTOMER &       /* Each reservation is for exactly one customer */
    res_dates : RESERVATION --> POW1(DATE)          /* Each reservation has non-empty dates */
VARIABLES
    active_res,
    occ_rooms,
    occ_dates
INVARIANT
    active_res <: RESERVATION &                     /* R3: Active reservations subset */
    occ_rooms : ROOM +-> CUSTOMER &                 /* R9: Occupied rooms to customers */
    occ_dates : ROOM +-> POW1(DATE) &               /* R9: Occupied rooms to dates */
    dom(occ_rooms) = dom(occ_dates) &               /* Consistency */
    !(r1,r2).(r1 : active_res & r2 : active_res    /* R5: No overlapping reservation dates */
              & r1 /= r2 & res_room(r1) = res_room(r2)
              => res_dates(r1) /\ res_dates(r2) = {}) &
    !(r).(r : active_res & res_room(r) : dom(occ_dates)  /* R5,R11: No overlap between */
          => res_dates(r) /\ occ_dates(res_room(r)) = {})  /*         reservation and occupied dates */
INITIALISATION
    active_res := {} ||
    occ_rooms := {} ||
    occ_dates := {}
OPERATIONS
    /* R1, R4, R5: A customer makes a reservation */
    ReserveRoom(rv) =
        PRE
            rv : RESERVATION &                                          /* Must be a valid reservation */
            rv /: active_res &                                           /* Not already active */
            !(r).(r : active_res & res_room(r) = res_room(rv)          /* R5: Dates don't overlap with */
                  => res_dates(r) /\ res_dates(rv) = {}) &             /*     existing reservations */
            (res_room(rv) : dom(occ_dates)                              /* R5: Dates don't overlap with */
             => res_dates(rv) /\ occ_dates(res_room(rv)) = {})         /*     occupied dates */
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

    /* R8, R10: Check in with reservation */
    CheckInWithReservation(rv) =
        PRE
            rv : active_res &                                           /* Must be active */
            res_room(rv) /: dom(occ_rooms) &                            /* Room not occupied */
            res_room(rv) /: dom(occ_dates) &                            /* Theorem: follows from inv4 */
            !(r).(r : active_res & r /= rv & res_room(r) = res_room(rv) /* Theorem: follows from inv5 */
                  => res_dates(r) /\ res_dates(rv) = {})
        THEN
            active_res := active_res - {rv} ||                          /* Remove reservation */
            occ_rooms := occ_rooms \/ {res_room(rv) |-> res_customer(rv)} ||  /* Room becomes occupied */
            occ_dates := occ_dates \/ {res_room(rv) |-> res_dates(rv)}         /* Copy dates */
        END;

    /* R12: Check in without reservation */
    CheckInWithoutReservation(rr, cc, dd) =
        PRE
            rr : ROOM &                                                 /* Valid room */
            cc : CUSTOMER &                                             /* Valid customer */
            dd : POW1(DATE) &                                           /* Non-empty dates */
            rr /: dom(occ_rooms) &                                      /* Room not occupied */
            rr /: dom(occ_dates) &                                      /* Theorem: follows from inv4 */
            !(r).(r : active_res & res_room(r) = rr                    /* Dates don't overlap with */
                  => res_dates(r) /\ dd = {})                          /*   reservations for this room */
        THEN
            occ_rooms := occ_rooms \/ {rr |-> cc} ||                    /* Room becomes occupied */
            occ_dates := occ_dates \/ {rr |-> dd}                       /* Store dates */
        END;

    /* R13: Check out */
    CheckOut(rr) =
        PRE
            rr : dom(occ_rooms) &                                       /* Room must be occupied */
            rr : dom(occ_dates)                                         /* Theorem: follows from inv4 */
        THEN
            occ_rooms := {rr} <<| occ_rooms ||                          /* Remove customer info */
            occ_dates := {rr} <<| occ_dates                             /* Remove date info */
        END
END
