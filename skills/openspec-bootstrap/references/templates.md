# OpenSpec Templates

Templates for generating OpenSpec foundation documents.

## project.md Template

```markdown
# Project Context

## Purpose
[2-3 sentences: What this project does and why it matters]

Key goals:
- [Goal 1]
- [Goal 2]
- [Goal 3]

## Tech Stack
- **[Category]**: [Technology] ([reason if non-obvious])

## Project Conventions

### Code Style
[Conventions from discussion or sensible defaults]

### Architecture Patterns
[Key patterns to follow]

### Testing Strategy
[How testing will work]

### Git Workflow
[Branch strategy, commit conventions]

## Domain Context
[Key domain concepts the project deals with]

## Important Constraints
[Hard constraints from interview]

## External Dependencies
[Systems, APIs, services to integrate with]
```

## Capability Spec Template

Create at `openspec/specs/[capability-name]/spec.md`:

```markdown
# [Capability Name]

[One paragraph description of what this capability provides]

## Requirements

### Requirement: [Descriptive Name]
The system SHALL [behavior description using normative language].

#### Scenario: [Happy path name]
- **GIVEN** [precondition]
- **WHEN** [action taken]
- **THEN** [expected outcome]

#### Scenario: [Edge case or error name]
- **GIVEN** [precondition]
- **WHEN** [action taken]
- **THEN** [expected outcome]

### Requirement: [Another Requirement]
The system MUST [another behavior].

#### Scenario: [Scenario name]
- **GIVEN** [precondition]
- **WHEN** [action]
- **THEN** [outcome]
```

### Spec Writing Guidelines

- Use **SHALL** or **MUST** for normative requirements
- Each requirement needs at least one scenario
- Scenarios use **GIVEN/WHEN/THEN** format
- Keep requirements atomic and testable
- Use `#### Scenario:` format (4 hashtags) for scenarios

## Change Proposal Template

Create at `openspec/changes/[change-id]/proposal.md`:

```markdown
# Change: [Brief Description]

## Why
[1-2 sentences on the problem or opportunity this addresses]

## What Changes
- [Bullet list of changes]
- [Mark breaking changes with **BREAKING**]

## Impact
- Affected specs: [list capabilities]
- Affected code: [key files/systems]
```

## Tasks Template

Create at `openspec/changes/[change-id]/tasks.md`:

```markdown
## 1. [Phase/Category Name]
- [ ] 1.1 [Specific task description]
- [ ] 1.2 [Another task]
- [ ] 1.3 [Another task]

## 2. [Next Phase/Category]
- [ ] 2.1 [Task]
- [ ] 2.2 [Task]

## 3. Verification
- [ ] 3.1 Run test suite
- [ ] 3.2 Manual testing of [key flows]
- [ ] 3.3 Update documentation if needed
```

### Task Writing Guidelines

- Use numbered sections for phases/categories
- Use checkbox format: `- [ ]` for pending, `- [x]` for complete
- Keep tasks small and verifiable (1-4 hours each)
- Include verification/testing tasks
- Order by dependency (earlier tasks unblock later ones)

## Bootstrap Change Proposal

For the initial implementation, use change-id `bootstrap-v1`:

**proposal.md**:
```markdown
# Change: Bootstrap Initial Implementation

## Why
Initial implementation of [project name] based on requirements gathering session.

## What Changes
- Implement core [capability 1]
- Implement core [capability 2]
- Set up project structure and tooling

## Impact
- Affected specs: [list all initial specs]
- New code: [key components to build]
```

**tasks.md**:
```markdown
## 1. Project Setup
- [ ] 1.1 Initialize project structure
- [ ] 1.2 Set up development environment
- [ ] 1.3 Configure tooling (lint, test, build)
- [ ] 1.4 Create initial README

## 2. [First Capability]
- [ ] 2.1 [Foundation task]
- [ ] 2.2 [Core implementation]
- [ ] 2.3 [Tests]

## 3. [Second Capability]
- [ ] 3.1 [Foundation task]
- [ ] 3.2 [Core implementation]
- [ ] 3.3 [Tests]

## 4. Integration & Verification
- [ ] 4.1 Integration testing
- [ ] 4.2 Documentation review
- [ ] 4.3 Final validation
```
