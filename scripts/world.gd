extends Node2D

const MapLoader = preload("res://scripts/framework/map_loader.gd/")
var map_loader
var current_map

func _ready():
	map_loader = MapLoader.new(self)
	map_loader.switch_to("Map0.tscn")
	

func change_map(map_name):
	map_loader.switch_to(map_name)
	