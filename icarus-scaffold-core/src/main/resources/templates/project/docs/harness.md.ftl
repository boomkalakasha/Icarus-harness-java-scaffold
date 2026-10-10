# Engineering harness / 研发 Harness

The harness connects a human/Agent guide, an architecture reference map, a
durable task contract and runnable verification. The coding host owns edits,
tool permissions and scheduling. This verifier checks local conditions; it
does not enforce a sandbox or independently prove user authorization.

## First loop

1. Read [AGENTS.md](../AGENTS.md) and the affected [architecture](architecture.md)
   entries. Follow necessary references rather than loading every document.
2. Edit [task.json](../harness/task.json): goal, allowed effects, operation mode,
   sources, required answers and the full approved scope. Reuse this record for
   progress and the next step; do not maintain a second completion ledger.
3. Run `python harness/verify.py` for a context/task preflight. A necessary
   unanswered question stays pending; elapsed time is not an answer.
4. When implementation and local build effects are authorized, run
   `python harness/verify.py --build --record`. This runs only the fixed Maven
   verify command, never a command supplied by task.json. Python 3.10+ and Maven
   or a local wrapper are required; the tool does not install them.
5. Inspect the report. Source/build evidence does not prove runtime, acceptance
   or release. Step state remains human/host maintained; completed local checks
   do not mark steps done. Continue until all approved steps meet their criteria.

`--record` creates a new local result under `harness/results/` without
overwriting an earlier result. This directory is ignored by Git. Each report
records the task digest and Git identity when this project itself is a Git
root. A parent checkout's HEAD is not presented as this project's version.
Timed-out builds stop their owned Windows process tree or dedicated POSIX
session; unconfirmed cleanup is a separate failed check. This does not sandbox
processes that deliberately detach from that tree/session.

## Architecture optimization rhythm

Establish necessary context → connect one useful path → enable remaining
entry points → verify the entire approved scope → update only affected sources
and references. Keep critical input, consistency and permission checks through
every stage. Re-anchor after context compression, scope changes or new source
facts. A task handoff preserves unresolved dependencies and the next action.

At startup and natural handoffs, scan for reusable methods or recurring
failures. Put a short learning candidate in `learning` with evidence, owner,
verification and next review; otherwise leave `summary: none` plus the scan
reason. Choose Markdown or offline HTML by reading benefit, reusing existing
reports. Keep project facts in the project and general methods in their Skill.

中文：按实际影响读取资料，保留必要上下文；规格、决定、代码和测试走引用。
先贯通再迭代，局部检查通过后继续整个已批准范围；必要答复未到只推进独立工作。
任务状态由一处维护，验收结果分层表达，交接保留待答依赖和下一步。宿主负责执行
权限与调度；本工具提供本地检查及可追溯结果，不自动部署或判定业务验收。
