# Roblox Project AI Instructions

This project follows enterprise-grade Roblox architecture and **OpenSpec-compatible** implementation workflow.

## Product & implementation docs

| Document | Purpose |
|----------|---------|
| [docs/GDD-Camping-Survivor.md](docs/GDD-Camping-Survivor.md) | Product spec (what the game is) |
| [docs/Implementation-Plan.md](docs/Implementation-Plan.md) | Slice index and dependencies |
| [openspec/config.yaml](openspec/config.yaml) | AI context, capabilities map |
| [openspec/specs/](openspec/specs/) | Living technical specs per capability |

## OpenSpec-compatible workflow (required)

Before implementing any feature:

1. **Read the active change** in `openspec/changes/<slice-id>/`:
   - `proposal.md` → `design.md` → `specs/` → `tasks.md` → `verify.md`
2. **Read** the capability spec in `openspec/specs/<capability>/spec.md`
3. **Read** the relevant GDD chapter in `docs/GDD-Camping-Survivor.md`
4. Implement **only** what `tasks.md` describes
5. Run all checks in `verify.md`
6. **Merge** spec deltas into `openspec/specs/` and **archive** the change to `openspec/changes/archive/`

**Rules:**

- **One slice at a time** — do not start slice N+1 until slice N tasks are 100% `[x]` and verified
- **No code without spec delta** for new or changed behavior
- **New feature** = new folder under `openspec/changes/`, not ad-hoc edits

**Standard prompt:** *"Ejecuta slice-XX según openspec/changes/slice-XX-*/. No avances hasta verify.md completo."*

## Architecture (every change)

1. Analyze requirements (from openspec + GDD)
2. Design services, controllers, remotes
3. Define security validations
4. Define persistence (repositories only)
5. Generate implementation

Never skip architectural planning.

Always prioritize:

- Maintainability
- Security
- Scalability
- Extensibility

Assume:

- 100+ concurrent players
- Future expansion
- Multiplayer environment

Never create quick fixes.

Never place business logic inside LocalScripts.

Server is always authoritative.

UI is passive: display data and send user intent only.
