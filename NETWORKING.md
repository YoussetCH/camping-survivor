# Networking Standards

Use RemoteEvents by default.

Use RemoteFunctions only when absolutely necessary.

Folder:

ReplicatedStorage
    Remotes
        Events
        Functions

Naming:

AttackEvent
EquipWeaponEvent
PurchaseItemEvent
QuestCompletedEvent

Avoid:

ActionEvent
TestEvent
DoStuffEvent

Flow:

Client
 -> Controller
 -> RemoteEvent
 -> Service
 -> Response

Server validates every request.