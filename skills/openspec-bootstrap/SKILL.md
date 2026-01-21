---
name: openspec-bootstrap
description: Bootstrap a new project for OpenSpec by analyzing raw materials (docs, transcripts, ideas) and interviewing the user to generate foundation documents (project.md, initial specs). Use when starting a new project, the user mentions "bootstrap", "new project", "create PRD", or when openspec/project.md doesn't exist yet.
---

# OpenSpec Bootstrap

Generate OpenSpec foundation documents by analyzing raw materials and interviewing the user.

## Quick Start

1. Check if `openspec/` exists; if not, run `openspec init --tools factory`
2. Ask user for any raw materials (docs, transcripts, URLs)
3. Analyze materials, identify gaps
4. Interview user to fill gaps (always required)
5. Generate `project.md` and initial specs
6. Validate with `openspec validate --strict`

## Core Principle

**Raw materials inform but never complete the picture.** Always interview the user to fill gaps, clarify ambiguities, and validate assumptions.

## Workflow

### Phase 0: Verify OpenSpec

```bash
ls openspec/ 2>/dev/null || echo "Not initialized"
```

If missing, run `openspec init --tools factory` (non-interactive).

If `openspec/project.md` exists with content, warn user and confirm before overwriting.

### Phase 1: Intake

Ask: "Do you have existing materials to share? (docs, transcripts, URLs, repos)"

If yes, collect and proceed to Phase 2. If no, skip to Phase 3.

### Phase 2: Analyze Materials

For each material provided:
1. Read/fetch content
2. Extract: problem statements, users, technical decisions, features, goals
3. Note gaps and ambiguities

Summarize findings before interviewing:
```
From your materials:
- Problem: [extracted]
- Users: [extracted]
- Solution ideas: [extracted]
- Technical context: [extracted]
- Gaps to clarify: [list]
```

### Phase 3: Interview

Ask 2-3 questions at a time. Adapt based on what's already known.

**Core areas to cover:**
1. Problem & why now
2. Users & context  
3. Solution vision (MVP vs full)
4. Technical foundation (stack, constraints)
5. Scope & priorities (what's OUT)

See [references/questions.md](references/questions.md) for full question bank and interview techniques.

**Stop when** you have enough to generate: clear problem, defined users, core capabilities, tech stack, and scope boundaries.

### Phase 4: Generate

Create artifacts using templates from [references/templates.md](references/templates.md):

1. **`openspec/project.md`** - Project context, tech stack, conventions
2. **`openspec/specs/[capability]/spec.md`** - One per distinct capability
3. **`openspec/changes/bootstrap-v1/`** (optional) - Initial implementation proposal

### Phase 5: Review & Validate

Present generated artifacts to user:
```
Created:
- openspec/project.md
- openspec/specs/[cap1]/spec.md
- openspec/specs/[cap2]/spec.md
- openspec/changes/bootstrap-v1/ (if requested)

Review each file. What needs adjustment?
```

Iterate until approved, then run:
```bash
openspec validate --strict
```

Use [checklists.md](checklists.md) to verify completeness.

### Phase 6: Complete

Confirm success and next steps:
```
OpenSpec ready. Next:
1. Review specs: openspec list --specs
2. Start building: openspec show bootstrap-v1
3. Create changes: openspec/changes/[change-id]/
```

## References

- [references/questions.md](references/questions.md) - Full interview question bank
- [references/templates.md](references/templates.md) - Document templates
- [checklists.md](checklists.md) - Validation checklists

## Success Criteria

- `openspec/project.md` exists with all sections populated
- At least one capability spec in `openspec/specs/`
- Each spec has requirements with scenarios
- `openspec validate --strict` passes
- User has reviewed and approved
