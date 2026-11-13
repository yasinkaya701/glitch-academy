extends Resource
## Station metadata is kept with its scene so each station can evolve independently.

@export var id: StringName
@export var title: String
@export var subject: String
@export var grade: int
@export var routes: PackedStringArray
@export_multiline var description: String
@export var curriculum: String
@export var source_url: String
@export var scene: PackedScene
