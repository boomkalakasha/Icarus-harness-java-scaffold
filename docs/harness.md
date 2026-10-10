# Java engineering harness

Icarus Harness Java Scaffold evolves the existing project generator into a
repeatable architecture-improvement environment. Both architecture profiles
generate an Agent guide, a reference map with source/test links, a durable task
contract and a Python standard-library verifier. Python 3.10+ is needed only
for the harness checker; the generated application remains Java 17/Spring Boot.

```text
confirmed request -> validated generator -> project ZIP
                                          -> AGENTS + architecture references
                                          -> task goal/effects/full scope/answers
                                          -> preflight -> fixed Maven verify
                                          -> local versioned evidence -> next action
```

## Responsibility and ownership

- The generator owns safe coordinates, deterministic templates and ZIP paths.
- The generated map owns architecture boundaries and references. Specs and tests
  retain their original ownership; a missing module guide does not waive a
  distinct contract's documentation needs.
- `harness/task.json` owns current scope, steps, pending answers and next action.
  The verifier never marks those steps complete after a successful build.
- The host owns coding execution, permissions, model selection and scheduling.
  The checker is a cooperative local gate, not a sandbox or authorization service.
- Evidence reports separate source/build, runtime, acceptance and release. They
  retain the task digest and project Git identity when available. An enclosing
  checkout's HEAD is not assigned to an uninitialized generated project.

## First usable loop

Generate either profile using the existing CLI/REST. Unpack, read affected map
entries and update the task. Run `python harness/verify.py`, then the explicitly
selected `--build --record` path. A required unanswered question returns a
waiting result without starting Maven. Read-only or plan-only task mode blocks
the build; read-only mode also blocks recording. Commands supplied by task
data are not executed. Result files are new, local and Git-ignored.

Connect one useful path, enable further entry points incrementally, then close
the full approved scope. Preserve important validation and permission checks
at every stage. Reuse valid context, re-anchor after scope/source changes, and
keep handoffs in the current task instead of a second ledger. At natural
checkpoints, capture reusable methods or explain a none result. Select report
format according to reading benefit. General methods live in the companion
[AI-first Skill](https://github.com/boomkalakasha/ai-first-vibe-coding-skill);
this project owns their executable Java starting environment.

## Compatibility and current limits

The repository is renamed from `icarus-ai-spring-scaffold` to
`Icarus-harness-java-scaffold`. Maven coordinates, Java package names, CLI
options and REST routes remain compatible; no new service or model runtime is
introduced. New files are included in both generated profiles, so newly
generated ZIP bytes differ from previous versions while default/explicit
profile equivalence remains deterministic. Existing projects adopt these files
through a reviewed diff; generation does not overwrite their source.

The fixed build command can use a local Maven wrapper or installed Maven.
Timed-out builds stop their owned process tree (Windows PID tree or a dedicated
POSIX session). Cleanup that cannot be confirmed is reported separately as a
failed check; it is not a sandbox for processes that deliberately escape.
Dependencies may be fetched according to the user's Maven configuration. The
verifier does not start a server or claim runtime/acceptance/release checks.
Those checks remain with the project's cases and explicitly selected workflows.
A local check is not full-scope or production acceptance. Code generation
continues to use the existing no-overwrite and trusted-classpath boundaries.
