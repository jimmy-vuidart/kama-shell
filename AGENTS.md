# AGENTS.md (Agent Runtime Optimized)

## EXECUTION MODE

You are an autonomous coding agent. Your goal is to iteratively build a Linux desktop shell based on:

images/maquette.png

You MUST:
- act incrementally
- keep the project runnable
- produce visible progress every cycle
- follow strict task decomposition

---

## PRIMARY OBJECTIVE

Deliver a functional MVP of a desktop shell with:

- Left sidebar
- Top control bar
- Main content area (Gaming / Dev views)
- Right control panel
- Bottom dock
- System widgets (CPU, RAM, Battery, Network, Audio)

---

## HARD RULES

1. ALWAYS prioritize visual fidelity to the mockup.
2. NEVER block on system integrations → use mocks.
3. NEVER refactor large areas unless required.
4. ALWAYS ship something visible per iteration.
5. KEEP tasks small and atomic.
6. PROJECT MUST REMAIN RUNNABLE.

---

## ITERATION LOOP (MANDATORY)

For EACH cycle:

1. Select ONE atomic task
2. Implement minimal version
3. Ensure project runs
4. Compare with maquette
5. Log report
6. Move to next task

---

## TASK SIZE DEFINITION

A valid task:
- modifies few files
- produces visible UI change OR functional unit
- has clear completion criteria

INVALID tasks:
- “build whole UI”
- “refactor entire architecture”
- “implement all services”

---

## PRIORITY ORDER

P0:
- project bootstrap
- root layout
- sidebar
- main panels
- dock

P1:
- top bar
- core components
- navigation
- styling system

P2:
- mock widgets
- control center
- views (gaming/dev)

P3:
- real system integrations
- app scanning
- refinements

---

## REQUIRED FIRST TASKS

1. Initialize AGS project
2. Create root shell window
3. Render empty layout zones:
   - sidebar
   - main
   - right panel
   - dock

DO NOT SKIP.

---

## VISUAL TARGET

Use ONLY:
images/maquette.png

Match:
- layout proportions
- spacing
- card style
- blur / glass
- gradients
- rounded corners

---

## TECH STACK

- AGS
- TypeScript
- GTK4
- SCSS

---

## FILE STRUCTURE (ENFORCE)

src/
  components/
  widgets/
  views/
  layouts/
  services/
  state/
  styles/

images/
  maquette.png

---

## DATA STRATEGY

Order:
1. mock data
2. fake realistic data
3. real data

Each widget MUST support:
- mock
- loading
- fallback

---

## COMPONENT STRATEGY

Build reusable primitives:

- Card
- Button
- IconButton
- Slider
- Toggle
- Section

Reuse aggressively.

---

## UI RULES

- no visual clutter
- strong alignment
- consistent spacing
- short labels
- high contrast readability

---

## CONTROL CENTER REQUIREMENTS

Must include:
- battery
- volume slider
- brightness slider
- wifi toggle
- bluetooth toggle

---

## DOCK REQUIREMENTS

- centered icons
- equal spacing
- hover feedback (later)

---

## VIEW REQUIREMENTS

### Gaming
- launcher cards
- game grid (mock ok)

### Dev
- project list
- tool shortcuts

---

## SYSTEM INTEGRATION (LATE)

Only after UI is stable:
- CPU/RAM
- Battery
- Network
- Audio

---

## BLOCKING RULE

If blocked:
- mock it
- skip it
- log it
- continue

DO NOT STALL.

---

## CODE QUALITY RULES

- no dead code
- no duplication
- clear naming
- small files

---

## DONE CRITERIA

Task is DONE if:
- visible result exists
- no crash
- matches mock intent
- code is clean enough

---

## REPORT FORMAT (MANDATORY)

After EACH task:

[Task]
<name>

[Goal]
<what you wanted>

[Result]
<what works>

[Files]
<modified files>

[Visual]
<match vs maquette>

[Issues]
<problems>

[Next]
<next task>

---

## SESSION SUMMARY

At end:

[Completed]
...

[Next]
...

[Blockers]
...

---

## FINAL INSTRUCTION

Start NOW with:

Task: Initialize project + render empty shell layout.

Do not plan further. Execute.
