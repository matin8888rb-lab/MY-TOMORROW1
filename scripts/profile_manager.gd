extends Node

const SAVE_PATH := "user://player_profile.cfg"

func has_profile() -> bool:
	var config := ConfigFile.new()
	return config.load(SAVE_PATH) == OK and config.has_section("profile")

func load_profile() -> Dictionary:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK or not config.has_section("profile"):
		return {}
	return {
		"first_name": str(config.get_value("profile", "first_name", "")),
		"last_name": str(config.get_value("profile", "last_name", "")),
		"skin_tone": int(config.get_value("profile", "skin_tone", 0)),
		"hair_color": int(config.get_value("profile", "hair_color", 0)),
		"hair_style": int(config.get_value("profile", "hair_style", 0)),
		"outfit_color": int(config.get_value("profile", "outfit_color", 0))
	}

func save_profile(profile: Dictionary) -> bool:
	var config := ConfigFile.new()
	config.set_value("profile", "first_name", str(profile.get("first_name", "")))
	config.set_value("profile", "last_name", str(profile.get("last_name", "")))
	config.set_value("profile", "skin_tone", clampi(int(profile.get("skin_tone", 0)), 0, 3))
	config.set_value("profile", "hair_color", clampi(int(profile.get("hair_color", 0)), 0, 3))
	config.set_value("profile", "hair_style", clampi(int(profile.get("hair_style", 0)), 0, 2))
	config.set_value("profile", "outfit_color", clampi(int(profile.get("outfit_color", 0)), 0, 3))
	return config.save(SAVE_PATH) == OK
