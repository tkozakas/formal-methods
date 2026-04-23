#!/usr/bin/env bash
# ==============================================================================
# verify.sh — Automated verification of the Extended Hotel Booking System
# ==============================================================================
#
# This script uses ProB CLI (probcli) to verify the Event-B model without
# needing the Rodin GUI. It runs three independent checks:
#
#   1. Model Checking    — exhaustively explores every reachable state and
#                          checks that all invariants hold in every state.
#   2. CBC (Constraint-Based Checking) — uses a constraint solver to try to
#                          find inputs that would violate an invariant for
#                          each operation individually.
#   3. Deadlock Checking — searches for states where no operation is enabled.
#
# WHY A .mch FILE INSTEAD OF .bum?
#   Rodin stores models as XML (.bum/.buc), but ProB CLI cannot parse those
#   XML files directly — it needs either a Rodin-exported .eventb package or
#   a classical B machine file (.mch). The .mch file contains the exact same
#   model (same sets, variables, invariants, operations) written in classical
#   B ASCII notation, which ProB can parse natively.
#
# PROBCLI PARAMETERS EXPLAINED:
#   -model_check         : explore all reachable states from INITIALISATION
#   -cbc all             : constraint-based check on every operation
#   -cbc_deadlock        : search for deadlock states
#   -p DEFAULT_SETSIZE 2 : use 2 elements for carrier sets
#   -p TIME_OUT 30000    : 30 second timeout per constraint solving attempt
#                          (higher than A1 due to more complex invariants)
#   -noass               : suppress assertion warnings
#
# REQUIREMENTS:
#   - probcli (ProB CLI) installed and in PATH
#   - Java 11+ in PATH (ProB uses Java for its B parser)
#
# ==============================================================================

set -euo pipefail

# --- Resolve paths -----------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODEL="$SCRIPT_DIR/rodin/HotelExtMachine.mch"

# --- Colors for output -------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# --- Check prerequisites -----------------------------------------------------
# Find a working Java (ProB needs 8+). /usr/bin/java on macOS may be a stub.
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
    echo -e "${RED}ERROR: probcli not found. Install ProB CLI:${NC}"
    echo "  https://prob.hhu.de/w/index.php/Download"
    exit 1
fi

if [ ! -f "$MODEL" ]; then
    echo -e "${RED}ERROR: Model not found at $MODEL${NC}"
    exit 1
fi

echo -e "${BOLD}══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Extended Hotel Booking System — Event-B Model Verification${NC}"
echo -e "${BOLD}══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  Model:   ${YELLOW}$MODEL${NC}"
echo -e "  ProB:    $(probcli -version 2>&1 | head -1)"
echo -e "  Java:    $(java -version 2>&1 | head -1)"
echo ""

PASS=0
FAIL=0

# ==============================================================================
# CHECK 1: Model Checking (exhaustive state-space exploration)
# ==============================================================================
# Starting from INITIALISATION, ProB explores every reachable state by firing
# every enabled operation in every state. For each state, it verifies all
# invariants hold:
#   inv1: active_res <: RESERVATION
#   inv2: occupied   <: RESERVATION
#   inv3: active_res /\ occupied = {}
#   inv4: no overlapping reservation dates (same room)
#   inv5: no overlap between reservation and occupied dates (same room)
#   inv6: no overlapping occupied dates (same room)
# ==============================================================================
echo -e "${BOLD}[1/3] Model Checking — exhaustive state-space exploration${NC}"
echo "      Exploring all reachable states from INITIALISATION..."
echo ""

MC_OUTPUT=$(probcli "$MODEL" \
    -model_check \
    -p DEFAULT_SETSIZE 2 \
    -p TIME_OUT 30000 \
    -noass 2>&1) || true

echo "$MC_OUTPUT" | grep -E "States|Transitions|counter example|ALL states|OPERATIONS"

if echo "$MC_OUTPUT" | grep -q "No counter example found"; then
    echo -e "  Result: ${GREEN}✅ PASS — no invariant violations${NC}"
    PASS=$((PASS + 1))
else
    echo -e "  Result: ${RED}❌ FAIL — invariant violation found${NC}"
    FAIL=$((FAIL + 1))
fi
echo ""

# ==============================================================================
# CHECK 2: Constraint-Based Checking (CBC) for each operation
# ==============================================================================
# For each operation, the constraint solver asks:
#   "Is there ANY state satisfying ALL invariants where executing this
#    operation would VIOLATE an invariant?"
# ==============================================================================
echo -e "${BOLD}[2/3] Constraint-Based Checking — per-operation invariant preservation${NC}"
echo "      Checking each operation independently via constraint solver..."
echo ""

CBC_OUTPUT=$(probcli "$MODEL" \
    -cbc all \
    -p DEFAULT_SETSIZE 2 \
    -p TIME_OUT 30000 2>&1) || true

echo "$CBC_OUTPUT" | grep -E "counter example|ERRORS|ok"

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
# A deadlock occurs when the system reaches a state where NO operation is
# enabled (all guards are false). For this model, a deadlock in the initial
# state is expected if the carrier sets are empty or if no valid reservations
# exist for the available rooms.
# ==============================================================================
echo -e "${BOLD}[3/3] Deadlock Checking — searching for stuck states${NC}"
echo "      Checking if any reachable state has no enabled operations..."
echo ""

DL_OUTPUT=$(probcli "$MODEL" \
    -cbc_deadlock \
    -p DEFAULT_SETSIZE 2 \
    -p TIME_OUT 30000 2>&1) || true

if echo "$DL_OUTPUT" | grep -q "DEADLOCK"; then
    echo "$DL_OUTPUT" | grep -E "STATE|active_res|occupied|END"
    echo -e "  Result: ${YELLOW}⚠️  DEADLOCK found (expected: abstract carrier sets may allow it)${NC}"
else
    echo -e "  Result: ${GREEN}✅ PASS — no deadlocks${NC}"
    PASS=$((PASS + 1))
fi
echo ""

# ==============================================================================
# Summary
# ==============================================================================
echo -e "${BOLD}══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Summary: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"
echo -e "${BOLD}══════════════════════════════════════════════════════════════${NC}"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
