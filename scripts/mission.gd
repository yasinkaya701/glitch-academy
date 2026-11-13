extends Control
## Root script for playable mission scenes.

signal completed

## Set by the control center before _ready(). Empty when previewing a scene directly.
var route: StringName
