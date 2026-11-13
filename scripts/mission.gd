extends Control
## Root script for playable mission scenes.

signal completed
## Görev en başta geri istendi: kontrol merkezi merkeze döner. Tek başına açıldıysa pencere kapanır.
signal exit_requested

## Set by the control center before _ready(). Empty when previewing a scene directly.
var route: StringName
