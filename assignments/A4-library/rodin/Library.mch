MACHINE Library
/* Bibliotekos sistema — plokščia klasikinė B mašina ProB verifikacijai.
 * Atspindi Event-B projektą (C0 kontekstas + M0 mašina). */

SETS
    BOOKS; READERS

ABSTRACT_CONSTANTS
    max_loans   /* skolinimosi riba vienam skaitytojui */

PROPERTIES
    max_loans : NATURAL1 &
    max_loans = 2   /* konkreti reikšmė ProB enumeracijai */

VARIABLES
    copies,     /* bendras egzempliorių skaičius kiekvienai knygai (0 = nėra) */
    loans,      /* kas šiuo metu turi kurią knygą */
    waitlist    /* laukiančių skaitytojų aibė kiekvienai knygai */

INVARIANT
    copies   : BOOKS --> NATURAL &
    loans    : READERS <-> BOOKS &
    waitlist : BOOKS <-> READERS &
    /* laukimo sąrašai egzistuoja tik knygoms su keliais egzemplioriais */
    !(b,r).(b|->r : waitlist => copies(b) >= 2) &
    /* nė vienas skaitytojas neviršija skolinimosi ribos */
    !r.(r : READERS => card(loans[{r}]) <= max_loans) &
    /* paskutinis bet kurios knygos egzempliorius visada lieka bibliotekoje */
    !b.(b : BOOKS & loans~[{b}] /= {} => card(loans~[{b}]) < copies(b))

INITIALISATION
    /* tuščia biblioteka: nėra egzempliorių, paskolų ir laukimo sąrašų */
    copies   := BOOKS * {0} ||
    loans    := {} ||
    waitlist := {}

OPERATIONS

    /* pridėti k egzempliorių knygos b — sąlyga: k >= 1 (apribota dėl modelio tikrinimo) */
    add_copies(b, k) =
        PRE
            b : BOOKS &
            k : NATURAL1 &
            k <= 3
        THEN
            copies(b) := copies(b) + k
        END;

    /* paskolinti knygą b skaitytojui r — sąlyga:
     *   knyga turi >=2 egzempliorius, skaitytojas jos dar neturi,
     *   skaitytojas neviršija skolinimosi ribos, bent vienas egzempliorius
     *   lieka bibliotekoje, o jei laukimo sąrašas netuščias — skaitytojas
     *   privalo jame būti */
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

    /* grąžinti knygą b, kurią turi skaitytojas r */
    return_book(r, b) =
        PRE
            r|->b : loans
        THEN
            loans := loans - {r|->b}
        END;

    /* įrašyti skaitytoją r į knygos b laukimo sąrašą — sąlyga:
     *   knyga turi >=2 egzempliorius, šiuo metu nepasiekiama (likęs tik
     *   paskutinis egzempliorius), skaitytojas dar nelaukia */
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
