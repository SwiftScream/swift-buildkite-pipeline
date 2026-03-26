# AI Agent Guide: BuildkitePipeline

This repository provides `BuildkitePipeline`, a Swift library for generating Buildkite pipeline YAML from strongly typed Swift code.

## What This Project Does

- Lets developers define Buildkite pipelines with Swift result builders instead of hand-written YAML.
- Encodes pipeline definitions into Buildkite-compatible YAML (and JSON for debugging).
- Preserves important output behavior such as key ordering and predictable field encoding.

## How It Works

Core data flow:

1. Author pipeline via DSL (`Pipeline { ... }`, `Step`, `Group`, `Wait`, `Trigger`, etc.).
2. DSL constructs typed internal models (`PipelineModel`, `StepModel`, step-specific models).
3. Renderer encodes models through `Encodable`:
   - YAML via Yams (`YAMLEncoder`)
   - JSON via `JSONEncoder` for debugging

Primary source directories:

- `Sources/BuildkitePipeline/DSL`: user-facing DSL, builders, step modifiers, generator protocol.
- `Sources/BuildkitePipeline/Model`: serializable schema-aligned model types.
- `Sources/BuildkitePipeline/Rendering`: YAML/JSON rendering.
- `Sources/BuildkitePipeline/Support`: encoding helpers (`OrderedKeyValuePairs`, `JSONValue`, dynamic coding keys).
- `Tests/BuildkitePipelineTests`: behavior and serialization tests (Swift Testing).

## Key Conventions To Preserve

### 1) Separation of concerns

- Keep DSL surface and serializable model distinct.
- New user-facing APIs should map to model fields through existing conversion points.

### 2) Immutable modifier style

- Step/template modifiers return updated copies (functional style), not mutating in place.
- Follow existing `.map { ... }` pattern in step extensions.

### 3) Ordered key behavior

- `env`, `agents`, and plugin options intentionally preserve declaration/insertion order where applicable.
- Do not replace `OrderedKeyValuePairs` behavior with plain dictionary encoding.

### 4) Template merge semantics

`StepTemplate` behavior is intentionally asymmetric:

- Template values apply first.
- Step-local values override scalar/keyed conflicts.
- Additive arrays (plugins, notify, artifact paths) are prepended from template, then step values follow.
- Templates apply recursively to command steps nested in groups.

### 5) YAML shape compatibility

- Field names and encoding forms are chosen to match Buildkite expectations (for example `depends_on`, `soft_fail`, `artifact_paths`).
- `ArtifactPaths` encode as a semicolon-delimited string.
- Keep encoded output stable unless intentionally changing behavior.

## Buildkite References (Use These When Extending Schema Coverage)

- Pipeline step format and concepts:
  - <https://buildkite.com/docs/pipelines/configure/defining-steps>
- Agent pipeline upload format details:
  - <https://buildkite.com/docs/agent/cli/reference/pipeline#pipeline-format>
- Official Buildkite pipeline JSON schema repository:
  - <https://github.com/buildkite/pipeline-schema>
- Direct schema file:
  - <https://raw.githubusercontent.com/buildkite/pipeline-schema/main/schema.json>

## Local Development

- Swift tools: `6.2`
- Platform target: macOS 13+
- Run tests:

```bash
swift test
```

- When any files under `Tests/BuildkitePipelineTests/Fixtures/YAML/` are added or modified, run:

```bash
./.scripts/validate-pipeline-fixtures.sh
```

## Guidance For AI Coding Agents

- Prefer extending existing model/DSL patterns over introducing parallel abstractions.
- When adding a new field:
  1. Add model support in `Model/`.
  2. Add DSL surface in `DSL/` (builder attribute or step modifier as appropriate).
  3. Add serialization tests in `Tests/BuildkitePipelineTests/PipelineSerializationTests.swift`.
- If output format changes, add/update fixture assertions.
- Keep public API additions documented in `README.md` examples where relevant.

## Current Known Scope Notes

- Trigger step coverage is incomplete for all possible Buildkite trigger attributes (see TODO in model).
- Notification backends are not exhaustive (see TODO in common types).
