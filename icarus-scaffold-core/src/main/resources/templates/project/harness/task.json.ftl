{
  "goal": "Review and verify the generated ${artifact} starting point",
  "operationMode": "IMPLEMENT_AND_VERIFY",
  "allowedEffects": ["local-build-artifacts", "local-evidence-records"],
  "context": ["AGENTS.md", "docs/architecture.md", "docs/harness.md", "pom.xml"],
  "requiredAnswers": [],
  "steps": [
    {"id": "review", "status": "pending", "acceptance": "Inspect the affected architecture and source references"},
    {"id": "build", "status": "pending", "acceptance": "Generated project Maven verify succeeds"}
  ],
  "nextAction": "Review the generated architecture and confirm the intended task scope",
  "learning": {"candidates": [], "summary": "none", "reason": "Initial generated record; no work has been reviewed yet"}
}
