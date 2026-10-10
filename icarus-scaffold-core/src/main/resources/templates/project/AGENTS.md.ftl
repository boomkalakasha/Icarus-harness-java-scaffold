# Generated service agent guide

This project is a small Spring Boot service generated from a public template.

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

- `domain` owns business types and invariants.
- `application` owns use cases and orchestration.
- `infrastructure` owns adapters and persistence implementations.
- `api` owns HTTP transport and request mapping.
- `boot` owns application wiring and the process entry point.

Keep dependencies pointing inward. Add tests beside the module that owns the
behavior. Do not add credentials, private repositories, shell execution, or
machine-specific paths to this project.

## AI guidance coverage

This root guide is the project-level instruction for the generated stock
modules. Do not add a module guide just because a folder exists. Add a nearest
module guide only when a module has a distinct command, external contract,
data/security boundary, release or ownership lifecycle, or dependency
direction that the root guide cannot state clearly. Keep that guide short and
link it back to this root guide.

## Local verification

```text
mvn test
mvn package
```

Run the application only when you need to inspect the HTTP contract. The
health endpoint is `/actuator/health` and the sample API is `/api/greetings`.

## Optional GitHub open-source delivery

When this generated project is intentionally maintained as a public GitHub
repository, protect `main`, merge through reviewed pull requests, and use
truthful Conventional Commits. Release immutable `vMAJOR.MINOR.PATCH` tags only
after required checks pass; build artifacts from the exact tag and attach
checksums. Keep customer configuration and private deployment automation in a
private downstream repository. A GitHub Release proves publication of source
or artifacts, not production deployment or traffic cutover.

If the project remains internal, follow its closest repository Git/CI rules
instead. Do not silently replace an internal delivery policy with GitHub Flow.
