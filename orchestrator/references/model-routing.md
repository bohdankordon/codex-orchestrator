# Worker Model Routing

This reference contains operational default model/effort preferences for worker delegation.

It does not change worker authority, role boundaries, evidence obligations, or the parent's decision about whether delegation is useful.

Role selection comes first.
Model selection comes after the parent has decided that a worker role is appropriate.

## Default routing

| Worker      | Default model                          | Effort |
| ----------- | -------------------------------------- | ------ |
| code-mapper | opencode-go/muse-spark-1.3-contributor | xhigh  |
| implementer | opencode-go/deepseek-flash             | max    |
| verifier    | gpt-5.6-luna                           | max    |
| reviewer    | opencode-go/glm-5.3-flash              | max    |
| debugger    | opencode-go/muse-spark-1.3-contributor | xhigh  |

`gpt-5.6-luna` means the native ChatGPT/Codex model.

Do not substitute `opencode-go/gpt-5.6-luna`.

## Routing behavior

When spawning a worker under the current OpenCodex v1 surface, explicitly provide:

- the intended `agent_type`;
- the model from this table;
- the corresponding reasoning effort.

Do not rely on Featured ordering to infer role mapping.

Do not silently substitute another model when the requested route fails.

If the default model is unavailable or unsuitable under a task-specific provider/data restriction, the parent decides the fallback explicitly and should disclose any material reduction in independence or capability.

Do not configure or depend on a silent global fallback chain for role routing.

## Manual fallback preferences

These are preferences, not automatic proxy fallback chains.

code-mapper:

1. DeepSeek V4.1 Flash max
2. native GPT-5.6 Luna max when appropriate

implementer:

1. Muse Spark 1.3 Contributor xhigh

verifier:

1. GLM-5.3 Flash max
2. Muse Spark 1.3 Contributor xhigh

reviewer:

1. native GPT-5.6 Luna max
2. Muse Spark 1.3 Contributor xhigh

debugger:

1. DeepSeek V4.1 Flash max

The parent may choose another available model when concrete task evidence justifies it.

## Independent challenge

Model diversity is a secondary system property, never a reason to ignore task evidence.

With the default mapping:

- production implementation is primarily DeepSeek;
- behavioral verification is primarily native Luna;
- static review is primarily GLM;
- Muse handles high-volume mapping and causal debugging.

When independent challenge materially matters, avoid unnecessarily collapsing implementation and challenge onto the same model/provider family when an equivalently capable independent route is available.

Do not delegate merely to obtain model diversity.

## Benchmark overrides

Explicit evaluation/benchmark assignments may intentionally override this routing table.

A benchmark-specified model and effort take precedence over these defaults.

Do not change the worker contract to conduct such comparisons.

## Data/provider restrictions

A project/user restriction on a provider or model overrides this routing preference.

Do not route repository or user data to a disallowed provider merely because it is the default model.

Choose an allowed fallback or return the limitation to the parent.

## Updating this file

This file is operational routing configuration.

Future benchmark results, model releases, quota changes, or provider-policy changes may update this file without requiring changes to the five worker role contracts.
