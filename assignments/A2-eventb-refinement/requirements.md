# Extended Hotel Booking System — Formal Requirements

## R1
The hotel booking system handles room reservation by customers.

## R2
The system must have operations (events) for room reservation, cancellation, customer check-in (with a reservation), customer check-in (without a reservation), and customer check-out.

## R3
Each reservation is stored by the system until it is cancelled or the reservation customer checks-in (with a reservation).

## R4
A reservation stores the information about the reserved room, the reserved dates, and the customer.

## R5
For any reservation, its dates cannot overlap with any other reservation (or occupied) dates for the same room.

## R6
A reservation can be cancelled.

## R7
After cancellation, the stored reservation is removed from the system.

## R8
After a customer's check-in (with a reservation), the reserved room gets the status "occupied" and the stored reservation is removed from the system.

## R9
The system keeps the information about the occupied rooms, the customers, and the dates they are staying.

## R10
After a customer's check-in (with a reservation), the information from the room reservation is associated with (copied to) that of the occupied room.

## R11
For any occupied room, its dates cannot overlap with any reservation (or occupied by another customer) dates for the same room.

## R12
A customer can check-in (without a reservation), if there is an unoccupied and unreserved room for the specified dates.

## R13
Once a customer checks-out, the information about the occupied room (the customer and dates) is removed from the system.
