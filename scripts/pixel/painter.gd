extends Node2D
## A canvas that redraws every frame by calling `paint(canvas)`.

var paint: Callable


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if paint.is_valid():
		paint.call(self)
