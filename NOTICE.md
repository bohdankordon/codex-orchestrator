# Provenance notice

This is an independent community project. It is not affiliated with or endorsed
by OpenAI, OpenCode, OpenCodex, or the model providers referenced in its routing
documentation.

## Third-party design influence

The five worker role contracts in `agents/` were written for this project. During
their design, two public agent collections were consulted as reference material:

- VoltAgent `awesome-codex-subagents` (MIT), in particular the debugger and
  error-detective role definitions;
- `wshobson/agents` (MIT), in particular the agent-teams debugger role.

What was taken is design-level. The published role files keep general debugging
and review principles such as trigger-to-symptom mapping, mechanism-based
hypotheses, falsification, first-causal-failure reasoning, and explicit
uncertainty. Several source behaviours were deliberately not adopted, including
single-hypothesis loyalty, automatic implementation authority, mandatory
post-fix validation, and percentage confidence.

## Text comparison

The published role files were compared against the upstream files named above.
None of the five files contains an eight-word sequence that occurs in any of
them; the longest common contiguous run is three words ("by the parent"). Because
no substantial portion of the upstream software was reproduced, their MIT
notices are not required in this repository, and no third-party license text is
reproduced here. The upstream projects remain the property of their authors.

This notice records that text comparison. It is not legal advice.
