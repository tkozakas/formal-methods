MACHINE HotelMachine
SETS
    CUSTOMER;
    ROOM
VARIABLES
    vacant_rooms,
    reserved_rooms,
    occupied_rooms
INVARIANT
    vacant_rooms <: ROOM &                      /* Vacant rooms are a subset of all rooms */
    reserved_rooms : ROOM +-> CUSTOMER &        /* Each room reserved by at most one customer */
    occupied_rooms : ROOM +-> CUSTOMER &        /* Each room occupied by at most one customer */
    vacant_rooms /\ dom(reserved_rooms) = {} &  /* R10: Vacant and reserved are disjoint */
    vacant_rooms /\ dom(occupied_rooms) = {} &  /* R10: Vacant and occupied are disjoint */
    occupied_rooms <: reserved_rooms            /* R8: Every occupied room is reserved by same customer */
INITIALISATION
    vacant_rooms := ROOM ||
    reserved_rooms := {} ||
    occupied_rooms := {}
OPERATIONS
    /* R3, R4: A customer reserves a vacant room */
    ReserveRoom(rr, cc) =
        PRE
            rr : vacant_rooms &             /* R3: Only vacant rooms can be reserved */
            cc : CUSTOMER &                 /* Must be a valid customer */
            rr /: dom(reserved_rooms) &     /* Room not already reserved */
            rr /: dom(occupied_rooms)       /* Room not already occupied */
        THEN
            vacant_rooms := vacant_rooms - {rr} ||              /* Remove from vacant */
            reserved_rooms := reserved_rooms \/ {rr |-> cc}     /* R4: Store room->customer mapping */
        END;

    /* R5, R6, R11: Cancel a reservation, room becomes vacant */
    CancelReservation(rr) =
        PRE
            rr : dom(reserved_rooms) &      /* R5: Room must have a reservation */
            rr /: dom(occupied_rooms) &      /* Cannot cancel if guest is checked in */
            rr /: vacant_rooms              /* Room is not vacant (consistency) */
        THEN
            reserved_rooms := {rr} <<| reserved_rooms ||    /* R11: Delete reservation data */
            vacant_rooms := vacant_rooms \/ {rr}            /* R6: Room becomes vacant again */
        END;

    /* R7, R8: Customer checks into their reserved room */
    CheckIn(rr, cc) =
        PRE
            rr |-> cc : reserved_rooms &    /* R8: Room must be reserved by this customer */
            rr /: dom(occupied_rooms) &     /* Room not already occupied */
            rr /: vacant_rooms              /* Room is not vacant (it is reserved) */
        THEN
            occupied_rooms := occupied_rooms \/ {rr |-> cc}     /* R7: Room becomes occupied */
        END;

    /* R9, R11: Guest checks out, room becomes vacant, all data deleted */
    CheckOut(rr) =
        PRE
            rr : dom(occupied_rooms) &      /* Room must be occupied */
            rr : dom(reserved_rooms) &      /* Room must be reserved (guaranteed by inv6) */
            rr /: vacant_rooms              /* Room is not vacant */
        THEN
            occupied_rooms := {rr} <<| occupied_rooms ||    /* Remove from occupied */
            reserved_rooms := {rr} <<| reserved_rooms ||    /* R11: Delete reservation data */
            vacant_rooms := vacant_rooms \/ {rr}            /* R9: Room becomes vacant again */
        END
END
