extends RefCounted
## Progress is local to this device/browser. No account, telemetry, or remote API.

const SAVE_PATH := "user://expedition_v1.json"
const MAX_MODULES := 6

var bank := 0
var cargo := 0
var modules := 0
var discovered: Array[String] = []
var collected: Array[String] = []

func build_cost() -> int:
	return 4 + modules * 2

func deposit() -> int:
	var amount := cargo
	bank += cargo
	cargo = 0
	return amount

func build_module() -> bool:
	if modules >= MAX_MODULES or bank < build_cost():
		return false
	bank -= build_cost()
	modules += 1
	return true

func scan(id: String) -> bool:
	if discovered.has(id):
		return false
	discovered.append(id)
	return true

func collect(id: String) -> bool:
	if collected.has(id) or cargo >= 20:
		return false
	collected.append(id)
	cargo += 1
	return true

func to_data() -> Dictionary:
	return {"version": 1, "seed": 731942, "bank": bank, "cargo": cargo, "modules": modules, "discovered": discovered, "collected": collected}

func load_data(data: Dictionary) -> void:
	if data.get("version", 0) != 1 or data.get("seed", 0) != 731942:
		return
	bank = clampi(int(data.get("bank", 0)), 0, 1000000)
	cargo = clampi(int(data.get("cargo", 0)), 0, 20)
	modules = clampi(int(data.get("modules", 0)), 0, MAX_MODULES)
	discovered.clear()
	collected.clear()
	var saved_discoveries = data.get("discovered", [])
	if not saved_discoveries is Array:
		saved_discoveries = []
	var saved_collected = data.get("collected", [])
	if not saved_collected is Array:
		saved_collected = []
	for id in saved_discoveries:
		if id is String and not discovered.has(id):
			discovered.append(id)
	for id in saved_collected:
		if id is String and not collected.has(id):
			collected.append(id)

func save_game() -> bool:
	var file := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(to_data()))
	file.close()
	return DirAccess.rename_absolute(SAVE_PATH + ".tmp", SAVE_PATH) == OK

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if data is Dictionary:
		load_data(data)
