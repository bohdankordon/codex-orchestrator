# Security

## Reporting

Do not open a public issue for a security-sensitive problem. If private security
reporting is enabled for this repository, use it. Otherwise open a minimal issue
asking for a private contact channel and include no sensitive detail.

Never paste any of the following into an issue, pull request, or discussion:

- credentials, API keys, bearer tokens, or session cookies;
- provider or ChatGPT account identifiers, e-mail addresses, or raw quota payloads;
- private repository contents you are not permitted to publish.

Redact account and provider metadata before sharing logs or telemetry samples.

## Scope

This project distributes role definitions, references, and documentation. It does
not store or manage provider credentials, and it does not call any model
provider: installation and routing use the credentials and runtime already
configured in your own Codex/OpenCodex environment.

Relevant reports include unsafe delegation or ownership behaviour, a worker
contract that appears to permit unauthorised production or history mutation, and
packaging material that leaks operator data.

No response-time or remediation guarantee is offered.
