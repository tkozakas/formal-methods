# Hotel Booking System — Formal Requirements

## R1
The hotel booking system handles room reservation by customers.

## R2
The system must have exactly 4 operations: room reservation, cancellation, customer check-in, customer check-out.

## R3
Only vacant hotel rooms can be reserved.

## R4
A reservation stores the information about the reserved room and the customer.

## R5
A reservation can be cancelled.

## R6
After cancellation, the previously reserved room becomes vacant.

## R7
After a customer's check-in, the reserved room gets the status "occupied".

## R8
Each occupied room is reserved and associated with the same customer.

## R9
After a customer's check-out, the previously occupied room becomes vacant.

## R10
A vacant room cannot be at the same time considered as reserved or occupied by the system.

## R11
Once a reservation is cancelled or a customer checks out, all the information about the reservation is deleted from the system.
