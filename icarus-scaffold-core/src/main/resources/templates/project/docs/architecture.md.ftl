# Architecture and reference map

This document owns the generated starting architecture, not future product
requirements. Update affected entries as the code evolves. Read linked source
before making an important change; a map is navigation, not loaded context.

## Starting boundaries

Java 17 / Spring Boot; profile `${profile}`. Dependencies point from transport
and wiring towards use cases and domain types. Start with one working path,
enable further entry points after their relevant checks, then close the entire
approved scope recorded in [the task](../harness/task.json).

<#if profile == "simple">
<#assign source="src/main/java/" + packagePath>
<#assign test="src/test/java/" + packagePath>
<#else>
<#assign source="">
</#if>
| Responsibility | Implementation and symbol | Verification |
|---|---|---|
<#if profile == "simple">
| Domain | [Greeting](${"../" + source}/domain/Greeting.java) | [GreetingTest](${"../" + test}/domain/GreetingTest.java) |
| Use case | [GreetingService](${"../" + source}/application/GreetingService.java) | [GreetingServiceTest](${"../" + test}/application/GreetingServiceTest.java) |
| Adapter | [InMemoryGreetingRepository](${"../" + source}/infrastructure/InMemoryGreetingRepository.java) | [InMemoryGreetingRepositoryTest](${"../" + test}/infrastructure/InMemoryGreetingRepositoryTest.java) |
| Transport | [GreetingController](${"../" + source}/api/GreetingController.java) | [GeneratedApplicationTest](${"../" + test}/boot/GeneratedApplicationTest.java) |
| Wiring | [GeneratedApplication](${"../" + source}/boot/GeneratedApplication.java) | Same application test |
<#else>
| Domain | [Greeting](../domain/src/main/java/${packagePath}/domain/Greeting.java) | [GreetingTest](../domain/src/test/java/${packagePath}/domain/GreetingTest.java) |
| Use case | [GreetingService](../application/src/main/java/${packagePath}/application/GreetingService.java) | [GreetingServiceTest](../application/src/test/java/${packagePath}/application/GreetingServiceTest.java) |
| Adapter | [InMemoryGreetingRepository](../infrastructure/src/main/java/${packagePath}/infrastructure/InMemoryGreetingRepository.java) | [InMemoryGreetingRepositoryTest](../infrastructure/src/test/java/${packagePath}/infrastructure/InMemoryGreetingRepositoryTest.java) |
| Transport | [GreetingController](../api/src/main/java/${packagePath}/api/GreetingController.java) | [GeneratedApplicationTest](../boot/src/test/java/${packagePath}/boot/GeneratedApplicationTest.java) |
| Wiring | [GeneratedApplication](../boot/src/main/java/${packagePath}/boot/GeneratedApplication.java) | Same application test |
</#if>

The sample path is `GET /api/greetings` → GreetingService →
InMemoryGreetingRepository → Greeting. These entries describe source, not
runtime observation or a production acceptance result.

## Incremental architecture work

For each affected capability, link its confirmed specification, decision,
implementation symbols and tests here. An independent contract needs adequate
documentation even without a module AGENTS.md. Ordinary utility directories
inherit the nearest relevant guidance. Write only this layer's differences;
keep the canonical specification and step status with their existing owners.
Add an ADR only for an actual long-lived choice. Record unclear intent, broken
references and uncertain versions instead of treating existing code as correct
requirements. Reuse valid context; recheck after scope, contract or source changes.
