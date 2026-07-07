==========
QUICKSTART
==========
PRODUCT: DeveFact
AUDIENCE: Human operator
STATUS: BATCH_0011_DRAFT

WHAT DEVEFACT DOES:
DeveFact converts a vague operational need or software idea into a controlled AI execution path.

MINIMUM LOOP:
1. Write the idea in plain language.
2. Generate or create a run.
3. Answer discovery questions.
4. Review the Orchestrator output.
5. Review the Executor task packet.
6. Run safe dry-run.
7. Apply only with explicit confirmation.
8. Verify with TOVS.
9. Commit locally only after OK_TO_COMMIT.
10. Push only if explicitly decided.

CURRENT LOCAL TOOL:
TOOLS/DEVF.NEW_RUN.v0.ps1

SAFE DEFAULT:
Everything starts as dry-run. Real changes require explicit confirmation text.

NEVER DO BY DEFAULT:
- Push.
- Deploy.
- Modify DB/schema.
- Store secrets.
- Write outside the approved module.
- Treat generated stubs as production code.