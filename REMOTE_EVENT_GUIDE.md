# Remote Event Guide

Every remote must have:

Request
Validation
Response

Example:

AttackEvent

Request:

{
    targetId
}

Validation:

- target exists
- player alive
- cooldown valid

Response:

damage applied

Never pass rewards from client.