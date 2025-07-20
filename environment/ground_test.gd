extends Node2D

@onready var ground_layer := %GroundLayer

# Constants
const BLOCK_SIZE = 17
const MAP_SIZE_IN_BLOCKS = 16
const TOTAL_MAP_SIZE = BLOCK_SIZE * MAP_SIZE_IN_BLOCKS # 272

# Town and road settings
const MIN_TOWNS = 25
const MAX_TOWNS = 25
const MIN_ROAD_WIDTH = 2
const MAX_ROAD_WIDTH = 5

# Tile IDs (adjust these based on your tileset)
const TILE_GRASS = 0
const TILE_TOWN = 1
const TILE_ROAD = 2

# Data structures
var towns: Array[Vector2i] = []  # Block coordinates
var roads: Array[Array] = []     # Road segments
var astar_grid: AStarGrid2D
var rng: RandomNumberGenerator

func _ready():
	rng = RandomNumberGenerator.new()
	rng.randomize()
	
	setup_astar_grid()
	generate_world()

func setup_astar_grid():
	"""Initialize AStar grid for pathfinding"""
	astar_grid = AStarGrid2D.new()
	astar_grid.size = Vector2i(MAP_SIZE_IN_BLOCKS, MAP_SIZE_IN_BLOCKS)
	astar_grid.cell_size = Vector2(BLOCK_SIZE, BLOCK_SIZE)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()

func generate_world():
	"""Main generation function"""
	clear_map()
	generate_towns()
	generate_roads()
	render_map()

func clear_map():
	"""Fill entire map with grass"""
	for x in range(TOTAL_MAP_SIZE):
		for y in range(TOTAL_MAP_SIZE):
			ground_layer.set_cell(Vector2i(x, y), 0, Vector2i(1, 1))

func generate_towns():
	"""Generate town positions using block coordinates"""
	towns.clear()
	var num_towns = rng.randi_range(MIN_TOWNS, MAX_TOWNS)
	
	# Ensure towns don't overlap
	var attempts = 0
	while towns.size() < num_towns and attempts < 100:
		var town_block = Vector2i(
			rng.randi_range(1, MAP_SIZE_IN_BLOCKS - 2),  # Leave border for roads
			rng.randi_range(1, MAP_SIZE_IN_BLOCKS - 2)
		)
		
		if not towns.has(town_block):
			towns.append(town_block)
			# Mark this block as occupied in AStar (higher cost)
			astar_grid.set_point_weight_scale(town_block, 10.0)
		
		attempts += 1
	
	print("Generated ", towns.size(), " towns at blocks: ", towns)

func generate_roads():
	"""Generate roads connecting all towns using AStar pathfinding"""
	roads.clear()
	
	if towns.size() < 2:
		return
	
	# Create minimum spanning tree approach
	var connected_towns: Array[Vector2i] = [towns[0]]
	var unconnected_towns: Array[Vector2i] = towns.slice(1)
	
	# Connect each remaining town to the closest connected town
	while unconnected_towns.size() > 0:
		var best_connection = null
		var shortest_path = []
		var shortest_distance = INF
		
		# Find the shortest path from any connected town to any unconnected town
		for connected_town in connected_towns:
			for unconnected_town in unconnected_towns:
				var path = astar_grid.get_id_path(connected_town, unconnected_town)
				if path.size() > 0 and path.size() < shortest_distance:
					shortest_distance = path.size()
					shortest_path = path
					best_connection = unconnected_town
		
		# Add the best connection
		if best_connection != null:
			roads.append(shortest_path)
			connected_towns.append(best_connection)
			unconnected_towns.erase(best_connection)
	
	# Optionally add some extra connections for more interesting road network
	add_extra_roads()

func add_extra_roads():
	"""Add some additional roads for a more connected network"""
	var extra_roads = rng.randi_range(1, 3)
	
	for i in range(extra_roads):
		if towns.size() >= 2:
			var town_a = towns[rng.randi_range(0, towns.size() - 1)]
			var town_b = towns[rng.randi_range(0, towns.size() - 1)]
			
			if town_a != town_b:
				var path = astar_grid.get_id_path(town_a, town_b)
				if path.size() > 0:
					roads.append(path)

func render_map():
	"""Render towns and roads on the tilemap"""
	# Render towns
	for town_block in towns:
		render_town(town_block)
	
	# Render roads
	for road in roads:
		render_road(road)

func render_town(block_pos: Vector2i):
	"""Render a town in the specified block"""
	var start_cell = block_pos * BLOCK_SIZE
	
	# Fill the entire block with town tiles
	for x in range(BLOCK_SIZE):
		for y in range(BLOCK_SIZE):
			var cell_pos = start_cell + Vector2i(x, y)
			ground_layer.set_cell(cell_pos, 0, Vector2i(11, 1))

func render_road(path: Array):
	"""Render a road along the given path with clean connections"""
	if path.size() < 2:
		return
		
	var road_width = rng.randi_range(MIN_ROAD_WIDTH, MAX_ROAD_WIDTH)
	
	# Convert block path to cell path
	var cell_path = []
	for block_pos in path:
		var block_center = Vector2i(block_pos) * BLOCK_SIZE + Vector2i(BLOCK_SIZE / 2, BLOCK_SIZE / 2)
		cell_path.append(block_center)
	
	# Draw road using cellular approach
	draw_road_path(cell_path, road_width)

func draw_road_path(cell_path: Array, width: int):
	"""Draw road using a cellular approach to avoid corner artifacts"""
	var road_cells = {}
	var half_width = width / 2
	
	# Process each segment of the path
	for i in range(cell_path.size() - 1):
		var start = Vector2i(cell_path[i])
		var end = Vector2i(cell_path[i + 1])
		
		# Get all cells along this line segment
		var line_cells = get_line_cells(start, end)
		
		# For each cell on the line, add surrounding cells based on width
		for cell in line_cells:
			# Determine the perpendicular direction for width
			var direction = Vector2((end - start)).normalized()
			var perpendicular: Vector2
			
			if abs(direction.x) > abs(direction.y):
				# Horizontal line, expand vertically
				perpendicular = Vector2(0, 1)
			else:
				# Vertical line, expand horizontally
				perpendicular = Vector2(1, 0)
			
			# Add cells perpendicular to the line
			for offset in range(-half_width, width - half_width):
				var road_cell = cell + Vector2i(perpendicular * offset)
				road_cells[road_cell] = true
	
	# Render all road cells
	for cell_pos in road_cells.keys():
		if is_valid_cell(cell_pos):
			ground_layer.set_cell(cell_pos, 0, Vector2i(1, 3))
	ground_layer.set_cells_terrain_connect(road_cells.keys(), 0, 1)

func get_line_cells(start: Vector2i, end: Vector2i) -> Array:
	"""Get all cells along a line using Bresenham's algorithm"""
	var cells = []
	var x0 = start.x
	var y0 = start.y
	var x1 = end.x
	var y1 = end.y
	
	var dx = abs(x1 - x0)
	var dy = abs(y1 - y0)
	var sx = 1 if x0 < x1 else -1
	var sy = 1 if y0 < y1 else -1
	var err = dx - dy
	
	var x = x0
	var y = y0
	
	while true:
		cells.append(Vector2i(x, y))
		
		if x == x1 and y == y1:
			break
			
		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			x += sx
		if e2 < dx:
			err += dx
			y += sy
	
	return cells

# Removed get_road_segment_cells - using new approach

func is_valid_cell(cell_pos: Vector2i) -> bool:
	"""Check if cell position is within map bounds"""
	return cell_pos.x >= 0 and cell_pos.x < TOTAL_MAP_SIZE and \
		   cell_pos.y >= 0 and cell_pos.y < TOTAL_MAP_SIZE

# Public functions for regeneration
func regenerate():
	"""Regenerate the entire world"""
	generate_world()

func set_seed(seed_value: int):
	"""Set random seed for reproducible generation"""
	rng.seed = seed_value

# Debug function
func get_generation_info() -> Dictionary:
	"""Return information about the generated world"""
	return {
		"towns": towns,
		"roads": roads.size(),
		"total_blocks": MAP_SIZE_IN_BLOCKS * MAP_SIZE_IN_BLOCKS
	}
