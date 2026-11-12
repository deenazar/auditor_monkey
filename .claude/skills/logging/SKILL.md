---
name: logging
description: Use whenever writing app code that handles user actions, errors, sync or background jobs.
---

# Logging

- Use one central logger with levels: debug, info, warning, error.
- Log key user actions, errors with context, sync and background jobs.
- NEVER log passwords, tokens, amounts tied to identity, or personal data.
- Debug logs are off in release builds.
- Crash/error reporting is on in production.
