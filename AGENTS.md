# Specloop

This is the Specloop augmentation for Factory Droid and OpenCode.

## What It Does

Specloop automatically executes OpenSpec changes using Beads for work coordination. It intercepts agent stop attempts and continues working through tasks until all are complete.

## Development

When working on this project:

- `hooks/stop-hook.sh` - Droid stop hook (bash)
- `plugins/openspec-loop.ts` - OpenCode plugin (TypeScript)
- `scripts/openspec-status` - Status display (Python with Rich)
- `scripts/openspec-import-beads` - Import script (bash)
- `commands/*.md` - Slash command definitions
- `install.sh` - Installation script

## Testing

Install to a test project and run:

```bash
./install.sh /path/to/test-project --droid
cd /path/to/test-project
bd init
/openspec-prioritize
/openspec-apply-loop
```

## OpenSpec Integration

This project uses OpenSpec for its own development. See `openspec/` for specs and changes.
