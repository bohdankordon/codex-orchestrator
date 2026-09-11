# Event format migration

Current production emits `{"version":2,"value":"..."}`.

Version 1 is intentionally unsupported: ingestion rejects it.

Persisted fixtures were required to migrate to the version-2 shape.
