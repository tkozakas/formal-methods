MACHINE FlightTickets
/* Skrydžių bilietų sistema — plokščia B mašina ProB verifikacijai.
 * Atspindi Event-B projektą (C0 statiniai duomenys + M0 dinaminė būsena). */

SETS
    CITIES; FLIGHTS; DATES

ABSTRACT_CONSTANTS
    dep, dest, seats, schedule, price   /* konstantos */

PROPERTIES
    dep      : FLIGHTS --> CITIES &
    dest     : FLIGHTS --> CITIES &
    /* skrydis negali prasidėti ir baigtis tame pačiame mieste */
    !f.(f : FLIGHTS => dep(f) /= dest(f)) &
    seats    : FLIGHTS --> NATURAL1 &
    schedule : FLIGHTS <-> DATES &
    price    : schedule --> NATURAL

VARIABLES
    available

INVARIANT
    available : schedule --> NATURAL &
    /* laisvų vietų skaičius niekada neviršija lėktuvo talpos */
    !(f,d).(f|->d : schedule => available(f|->d) <= seats(f))

INITIALISATION
    /* kiekvienas suplanuotas skrydis pradeda visiškai tuščias (visos vietos laisvos) */
    available := %(f,d).(f|->d : schedule | seats(f))

OPERATIONS

    /* užsakyti n vietų — sąlyga: skrydis suplanuotas, n >= 1, pakanka laisvų vietų */
    book(f, d, n) =
        PRE
            f|->d : schedule &
            n     : NATURAL1 &
            n <= available(f|->d)
        THEN
            available(f|->d) := available(f|->d) - n
        END;

    /* atšaukti n vietų — sąlyga: skrydis suplanuotas, n >= 1, neviršija talpos */
    cancel(f, d, n) =
        PRE
            f|->d : schedule &
            n     : NATURAL1 &
            available(f|->d) + n <= seats(f)
        THEN
            available(f|->d) := available(f|->d) + n
        END;

    /* užsakyti jungiamąjį skrydį c1 -> c2 -> c3 datą d neviršijant biudžeto max_total.
     * sąlyga: pasirinkti tarpinį miestą c2 ir du skirtingus skrydžius f1, f2 taip, kad
     *   atkarpos atitiktų miestus, abu būtų suplanuoti datą d,
     *   kiekvienas turėtų laisvą vietą, o bendra kaina tilptų į biudžetą */
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
                /* <+ yra funkcijos perrašymas: atnaujina tik šiuos du įrašus */
                available := available <+ {
                    f1|->d |-> available(f1|->d) - 1,   /* 1-oji atkarpa: viena vieta mažiau */
                    f2|->d |-> available(f2|->d) - 1    /* 2-oji atkarpa: viena vieta mažiau */
                }
            END
        END

END
