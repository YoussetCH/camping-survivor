# Architecture

Layers:

Client Layer
Controller Layer
Networking Layer
Service Layer
Persistence Layer

## Controllers

Responsibilities:

- UI
- Input
- Camera
- Audio

Controllers must never:

- Modify player data
- Award rewards
- Save datastore

## Services

Responsibilities:

- Business logic
- Validation
- Economy
- Inventory
- Quests
- Combat

Services are the only place where gameplay rules exist.

## Shared

Contains:

- Types
- Constants
- DTOs
- Utility functions