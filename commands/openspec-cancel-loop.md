---
description: "Cancel the active OpenSpec loop"
---

# Cancel OpenSpec Loop

```bash
if [[ -f .factory/openspec-loop.json ]]; then
  rm .factory/openspec-loop.json
  echo "OpenSpec loop cancelled."
else
  echo "No active OpenSpec loop found."
fi
```
