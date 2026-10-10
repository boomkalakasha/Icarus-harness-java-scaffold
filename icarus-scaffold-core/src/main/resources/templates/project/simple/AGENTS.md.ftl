# Generated service agent guide

This project uses the simple profile: one Maven module with a small set of
inward-facing packages. It was generated from a public template.

## Architecture optimization loop

Read the relevant [architecture map](docs/architecture.md) and source before
editing. [harness/task.json](harness/task.json) owns the current goal, allowed
effects, approved scope, necessary answers and next action. The map owns
boundaries and references; tests own executable cases. Reuse valid context,
and re-anchor after scope/source changes or a handoff. Links do not load bodies.
Run the [local harness](docs/harness.md) for preflight and build evidence.
An unanswered necessary question blocks dependent changes; continue independent
work. One path passing is an intermediate result until the full approved scope
closes. Keep a minimal persistent task record, and scan for reusable methods
at natural handoffs; record none with a reason when nothing merits promotion.

## Boundaries

- `${packageName}.domain` owns business types and invariants.
- `${packageName}.application` owns use cases and orchestration.
- `${packageName}.infrastructure` owns adapters and persistence implementations.
- `${packageName}.api` owns HTTP transport and request mapping.
- `${packageName}.boot` owns application wiring and the process entry point.

Keep dependencies pointing inward. Add tests beside the package that owns the
behavior. Do not add credentials, private repositories, shell execution, or
machine-specific paths to this project.

## AI guidance coverage

This root guide is the project-level instruction for the generated packages.
Do not add a module guide just because a folder exists. Add a nearest module
guide only when a package grows into a module with a distinct command, external
contract, data/security boundary, release or ownership lifecycle, or dependency
direction that the root guide cannot state clearly. Keep that guide short and
link it back to this root guide.

## Local verification

```text
mvn test
mvn package
```

Run the application only when you need to inspect the HTTP contract. The
health endpoint is `/actuator/health` and the sample API is `/api/greetings`.

The simple profile is a starting point, not a production-readiness or
deployment guarantee. Split packages into independently releasable modules
only when the service has a real boundary that benefits from that cost.
