# Security Rules

Never trust client data.

Always validate:

- Currency
- XP
- Damage
- Cooldowns
- Inventory
- Position
- Rewards

The client only requests actions.

The server calculates outcomes.

Bad:

FireServer(5000)

Good:

FireServer(enemyId)

Server determines rewards.