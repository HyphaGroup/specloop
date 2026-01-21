# Bootstrap Completion Checklists

## Pre-Generation Checklist

Before generating OpenSpec artifacts, confirm:

- [ ] OpenSpec initialized (`openspec/` directory exists)
- [ ] Problem statement is clear and specific
- [ ] Target users are identified
- [ ] Core capabilities are defined
- [ ] Tech stack is known (or sensible defaults chosen)
- [ ] Scope boundaries are established (what's OUT)
- [ ] User has validated understanding

## Output Validation Checklist

After generating, verify each artifact:

### project.md
- [ ] Purpose section has 2-3 clear sentences
- [ ] Key goals are specific and measurable
- [ ] Tech stack is complete (language, framework, infra)
- [ ] Code style conventions are defined
- [ ] Architecture patterns are documented
- [ ] Testing strategy is specified
- [ ] Domain context explains key concepts
- [ ] Constraints are listed
- [ ] External dependencies are identified

### Capability Specs
- [ ] At least one spec exists in `openspec/specs/`
- [ ] Each spec has a clear one-paragraph description
- [ ] Each spec has at least one requirement
- [ ] Requirements use SHALL/MUST language
- [ ] Each requirement has at least one scenario
- [ ] Scenarios use `#### Scenario:` format (4 hashtags)
- [ ] Scenarios follow GIVEN/WHEN/THEN structure
- [ ] Requirements are atomic and testable

### Bootstrap Change Proposal (if created)
- [ ] `proposal.md` has Why, What Changes, Impact sections
- [ ] `tasks.md` has numbered phases
- [ ] Tasks are small and verifiable (1-4 hours each)
- [ ] Tasks are ordered by dependency
- [ ] Verification tasks are included

### Validation
- [ ] `openspec validate --strict` passes
- [ ] No orphaned specs or broken references
- [ ] User has reviewed all artifacts
- [ ] User has approved to proceed

## Common Issues & Fixes

### "Requirement must have at least one scenario"
- Ensure scenarios use `#### Scenario:` (4 hashtags, not 3)
- Don't use bullet points or bold for scenario headers

### "Change must have at least one delta"
- Check `changes/[name]/specs/` directory exists
- Verify spec files have operation headers (`## ADDED Requirements`)

### Vague requirements
- Add specific acceptance criteria
- Include concrete examples in scenarios
- Quantify where possible (response time, error rates)

### Missing scope boundaries
- Explicitly list what's NOT included
- Add "Out of Scope" section to proposal
- Create future-consideration notes

## Post-Bootstrap Next Steps

After successful bootstrap:

1. **Review specs** - Walk through each capability with stakeholders
2. **Prioritize** - Order capabilities by importance/dependency
3. **Start building** - Run `openspec show bootstrap-v1` to see tasks
4. **Iterate** - Use `openspec` commands to manage changes

Useful commands:
```bash
openspec list              # See active changes
openspec list --specs      # See all capabilities
openspec show bootstrap-v1 # View bootstrap proposal
openspec validate --strict # Verify everything is valid
```
