# Roblox Project AI Instructions

This project follows enterprise-grade Roblox architecture and **OpenSpec-compatible** implementation workflow.

## Product & implementation docs

| Document | Purpose |
|----------|---------|
| [docs/GDD-Camping-Survivor.md](docs/GDD-Camping-Survivor.md) | Product spec (what the game is) |
| [docs/Implementation-Plan.md](docs/Implementation-Plan.md) | Slice index and dependencies |
| [docs/Feature-Modules.md](docs/Feature-Modules.md) | **Modular features & components** (isolation, registries, checklists) |
| [docs/Item-Icons.md](docs/Item-Icons.md) | Add or change inventory/crafting item icons |
| [openspec/config.yaml](openspec/config.yaml) | AI context, capabilities map |
| [openspec/specs/](openspec/specs/) | Living technical specs per capability |

## OpenSpec workflow (required)

Use **Cursor slash commands** ([OpenSpec docs](https://github.com/Fission-AI/OpenSpec)):

| Command | Purpose |
|---------|---------|
| `/opsx:propose <idea>` | Create change + artifacts (proposal, specs, design, tasks, verify) |
| `/opsx:apply` | Implement tasks from active change |
| `/opsx:archive` | Merge spec deltas and archive (after verify + user approval) |

Default schema: `roblox-slice` in [openspec/config.yaml](openspec/config.yaml).

Before implementing any feature:

1. **Propose** — `/opsx:propose` or ensure change exists under `openspec/changes/<slice-id>/`
2. **Read** artifacts: `proposal.md` → `design.md` → `specs/` → `tasks.md` → `verify.md`
3. **Read** capability spec in `openspec/specs/<capability>/spec.md` and relevant GDD chapter
4. **Apply** — `/opsx:apply` — implement only what `tasks.md` describes; mark `[x]` per task
5. **Verify** — complete `verify.md`; run `openspec validate <change>`
6. **Archive** — `/opsx:archive` after user approves

**Rules:**

- **One slice at a time** — do not start slice N+1 until slice N is archived
- **No code without spec delta** for new or changed behavior
- Refresh slash commands after OpenSpec upgrades: `openspec update`

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

## Feature modules (required)

Every new gameplay element or reusable component MUST be **isolated and pluggable**.

- Guide: [docs/Feature-Modules.md](docs/Feature-Modules.md)
- Spec: [openspec/specs/feature-modules/spec.md](openspec/specs/feature-modules/spec.md)
- Rule: [.cursor/rules/roblox-feature-modules.mdc](.cursor/rules/roblox-feature-modules.mdc)

No feature-specific logic inside orchestrator services (`CampService`, etc.). Use registries + `GameEvents`.

## Localization (required)

- **Default language:** English (`en`). **Launch:** English + Spanish (`es`).
- GDD §1.11 · technical spec: [openspec/specs/localization/spec.md](openspec/specs/localization/spec.md)
- No hardcoded player-facing strings in controllers; use `Shared/Localization/`
- Persist preference in `PlayerProfile.settings.locale` (server validates)
- Extensible: new language = new locale file + registry entry
