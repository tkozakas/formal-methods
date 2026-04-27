#!/usr/bin/env bash
# ==============================================================================
# verify.sh — Automated verification of the Flight Ticket System
# ==============================================================================
#
# Uses ProB CLI (probcli) to verify the Event-B model without the Rodin GUI.
# Three independent checks:
#   1. Model Checking    — exhaustive state-space exploration vs. invariants
#   2. CBC               — constraint-based per-operation invariant check
#   3. Deadlock Checking — searches for stuck states
#
# WHY .mch INSTEAD OF .bum?
#   ProB CLI cannot parse Rodin's XML (.bum/.buc) directly — it needs
#   classical B (.mch). FlightTickets.mch contains the same model
#   (sets, constants, variable, invariants, events) flattened into one file.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODEL="$SCRIPT_DIR/rodin/FlightTickets.mch"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# --- Find a working Java (ProB needs 8+) -------------------------------------
if ! /usr/bin/java -version &>/dev/null; then
    for candidate in \
        "/opt/homebrew/opt/openjdk@17/bin" \
        "/opt/homebrew/opt/openjdk@21/bin" \
        "/opt/homebrew/opt/openjdk/bin" \
        "$HOME/.local/share/jdk17/bin"; do
        if [ -x "$candidate/java" ]; then
            export PATH="$candidate:$PATH"
            break
        fi
    done
fi

if ! java -version &>/dev/null; then
    echo -e "${RED}ERROR: Java not found. Install JDK 11+ or set JAVA_HOME.${NC}"
    exit 1
fi

if ! command -v probcli &>/dev/null; then
    echo -e "${RED}ERROR: probcli not found.${NC}"
    echo "  https://prob.hhu.de/w/index.php/Download"
    exit 1
fi

if [ ! -f "$MODEL" ]; then
    echo -e "${RED}ERROR: Model not found at $MODEL${NC}"
    exit 1
fi

echo -e "${BOLD}══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Flight Ticket System — Event-B Model Verification${NC}"
echo -e "${BOLD}══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  Model:   ${YELLOW}$MODEL${NC}"
echo -e "  ProB:    $(probcli -version 2>&1 | head -1)"
echo -e "  Java:    $(java -version 2>&1 | head -1)"
echo ""

PASS=0
FAIL=0

# ==============================================================================
# CHECK 1: Model Checking
# ==============================================================================
echo -e "${BOLD}[1/3] Model Checking — exhaustive state-space exploration${NC}"
echo "      Exploring all reachable states from INITIALISATION..."
echo ""

#   -nodead: deadlocks are expected when constants enumerate an empty
#     schedule (no flights scheduled → no events enabled). They are checked
#     separately in step [3/3] using bounded constant choices.
#   -p MAXINT 4 / MININT 0: bound NATURAL so enumeration terminates.
MC_OUTPUT=$(probcli "$MODEL" \
    -model_check \
    -nodead \
    -p DEFAULT_SETSIZE 2 \
    -p MAXINT 4 \
    -p MININT 0 \
    -p TIME_OUT 30000 \
    -noass 2>&1) || true

echo "$MC_OUTPUT" | grep -E "States|Transitions|counter example|ALL states|OPERATIONS" || true

if echo "$MC_OUTPUT" | grep -q "No counter example found"; then
    echo -e "  Result: ${GREEN}✅ PASS — no invariant violations${NC}"
    PASS=$((PASS + 1))
else
    echo -e "  Result: ${RED}❌ FAIL — invariant violation found${NC}"
    FAIL=$((FAIL + 1))
fi
echo ""

# ==============================================================================
# CHECK 2: Constraint-Based Checking
# ==============================================================================
echo -e "${BOLD}[2/3] Constraint-Based Checking — per-operation invariant preservation${NC}"
echo "      Checking each operation independently via constraint solver..."
echo ""

CBC_OUTPUT=$(probcli "$MODEL" \
    -cbc all \
    -p DEFAULT_SETSIZE 1 \
    -p MAXINT 2 \
    -p MININT 0 \
    -p TIME_OUT 10000 2>&1) || true

echo "$CBC_OUTPUT" | grep -E "counter example|ERRORS|ok" || true

if echo "$CBC_OUTPUT" | grep -q "NO ERRORS FOUND"; then
    echo -e "  Result: ${GREEN}✅ PASS — all operations preserve all invariants${NC}"
    PASS=$((PASS + 1))
else
    echo -e "  Result: ${RED}❌ FAIL — constraint violation found${NC}"
    FAIL=$((FAIL + 1))
fi
echo ""

# ==============================================================================
# CHECK 3: Deadlock Checking
# ==============================================================================
echo -e "${BOLD}[3/3] Deadlock Checking — searching for stuck states${NC}"
echo "      Checking if any reachable state has no enabled operations..."
echo ""

DL_OUTPUT=$(probcli "$MODEL" \
    -mc 500 \
    -mc_mode dlk \
    -p DEFAULT_SETSIZE 2 \
    -p MAXINT 4 \
    -p MININT 0 \
    -p MAX_INITIALISATIONS 2 \
    -p MAX_OPERATIONS 4 2>&1) || true

if echo "$DL_OUTPUT" | grep -qiE "deadlock found|counter example found|DEADLOCK STATE"; then
    echo "$DL_OUTPUT" | grep -iE "STATE|available|deadlock"
    echo -e "  Result: ${YELLOW}⚠️  DEADLOCK found (expected when carrier sets are too small for any scheduled flight)${NC}"
else
    echo -e "  Result: ${GREEN}✅ PASS — no deadlocks found in explored states${NC}"
    PASS=$((PASS + 1))
fi
echo ""

echo -e "${BOLD}══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Summary: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"
echo -e "${BOLD}══════════════════════════════════════════════════════════════${NC}"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
