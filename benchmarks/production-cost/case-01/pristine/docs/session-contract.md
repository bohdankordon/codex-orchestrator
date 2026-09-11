# Session contract

POST /session/rotate returns exactly `{"refreshToken":"..."}`.

A successful rotation invalidates the presented token.

SESSION_V2 is an optional alternate rotation path and defaults to off.

The response body must not gain additional keys without an API guild contract review.
