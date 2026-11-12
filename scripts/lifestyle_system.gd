extends Node

signal lifestyle_changed
signal home_upgrade_purchased(upgrade_id: String)

const SAVE_PATH := "user://lifestyle_state.cfg"
const ACTIVITY_DATA := {
	"reading": {"label":"کتاب‌خوانی", "energy":8.0, "minutes":45, "skill":"knowledge", "xp":12},
	"walking": {"label":"پیاده‌روی", "energy":10.0, "minutes":35, "skill":"fitness", "xp":12},
	"painting": {"label":"نقاشی آزاد", "energy":9.0, "minutes":50, "skill":"art", "xp":14}
}
const UPGRADE_DATA := {
	"lamp": {"label":"چراغ ایستاده", "price":25.0},
	"bookshelf": {"label":"قفسه کتاب", "price":45.0},
	"plant": {"label":"گیاه آپارتمانی", "price":18.0}
}
const COOKING_SEQUENCE := ["نان", "پنیر", "گوجه"]
const PAINTING_SEQUENCE := ["آبی", "زرد", "سبز"]

var skills: Dictionary = {"knowledge":0, "fitness":0, "art":0, "cooking":0, "social":0}
var owned_upgrades: Array[String] = []
var completed_activities: int = 0
var last_event_day: int = -1
var active_minigame: String = ""
var minigame_step: int = 0

func _ready() -> void:
	_load_state()

func do_activity(activity_id: String) -> String:
	if not ACTIVITY_DATA.has(activity_id):
		return "این فعالیت در دسترس نیست."
	var data: Dictionary = ACTIVITY_DATA[activity_id]
	var cost := float(data["energy"])
	if LifeSystem.energy < cost:
		return "برای این فعالیت انرژی کافی نداری؛ کمی استراحت کن."
	LifeSystem.energy = maxf(0.0, LifeSystem.energy - cost)
	LifeSystem.advance_time(int(data["minutes"]))
	_add_skill_xp(str(data["skill"]), int(data["xp"]))
	completed_activities += 1
	_save_state()
	lifestyle_changed.emit()
	return "%s انجام شد؛ مهارتت کمی پیشرفت کرد." % str(data["label"])

func attend_city_event() -> String:
	if last_event_day == LifeSystem.day_number:
		return "امروز در رویداد محله شرکت کرده‌ای؛ رویداد بعدی فردا برگزار می‌شود."
	if LifeSystem.energy < 12.0:
		return "برای شرکت در رویداد انرژی کافی نداری."
	if not EconomySystem.spend_money(5.0):
		return "برای هزینه ورود به رویداد £5 لازم داری."
	LifeSystem.energy = maxf(0.0, LifeSystem.energy - 12.0)
	LifeSystem.advance_time(90)
	last_event_day = LifeSystem.day_number
	_add_skill_xp("social", 16)
	_add_skill_xp("art", 4)
	_save_state()
	lifestyle_changed.emit()
	return "در رویداد محله شرکت کردی؛ با مردم آشنا شدی و مهارت اجتماعی‌ات بهتر شد."

func buy_home_upgrade(upgrade_id: String) -> String:
	if not UPGRADE_DATA.has(upgrade_id):
		return "این وسیله در فروشگاه خانه موجود نیست."
	if owned_upgrades.has(upgrade_id):
		return "این وسیله را قبلاً خریده‌ای."
	var data: Dictionary = UPGRADE_DATA[upgrade_id]
	if not EconomySystem.spend_money(float(data["price"])):
		return "موجودی کافی نیست؛ قیمت این وسیله £%.0f است." % float(data["price"])
	owned_upgrades.append(upgrade_id)
	_save_state()
	home_upgrade_purchased.emit(upgrade_id)
	lifestyle_changed.emit()
	return "%s به خانه‌ات اضافه شد." % str(data["label"])

func begin_minigame(game_id: String) -> String:
	if game_id != "cooking" and game_id != "painting":
		return "این بازی کوچک پیدا نشد."
	if game_id == "cooking" and not LifeSystem.energy >= 5.0:
		return "برای تمرین آشپزی انرژی کافی نداری."
	if game_id == "painting" and not LifeSystem.energy >= 5.0:
		return "برای نقاشی انرژی کافی نداری."
	active_minigame = game_id
	minigame_step = 0
	if game_id == "cooking":
		return "سفارش ساندویچ: مواد را به ترتیب درست انتخاب کن."
	return "الگوی رنگ را به ترتیب درست انتخاب کن."

func submit_minigame_step(choice: String) -> String:
	if active_minigame == "":
		return "اول یک بازی کوچک را شروع کن."
	var sequence: Array = COOKING_SEQUENCE if active_minigame == "cooking" else PAINTING_SEQUENCE
	if choice != str(sequence[minigame_step]):
		minigame_step = 0
		return "ترتیب درست نبود؛ دوباره از مرحله اول شروع کن."
	minigame_step += 1
	if minigame_step < sequence.size():
		return "درست بود! مرحله %d از ۳." % (minigame_step + 1)
	var completed_game := active_minigame
	active_minigame = ""
	minigame_step = 0
	LifeSystem.energy = maxf(0.0, LifeSystem.energy - 5.0)
	LifeSystem.advance_time(20)
	if completed_game == "cooking":
		_add_skill_xp("cooking", 22)
		_add_skill_xp("knowledge", 3)
		_save_state()
		lifestyle_changed.emit()
		return "آفرین! ساندویچ را درست آماده کردی؛ مهارت آشپزی پیشرفت کرد."
	_add_skill_xp("art", 22)
	_save_state()
	lifestyle_changed.emit()
	return "نقاشی را کامل کردی؛ مهارت هنری پیشرفت کرد."

func get_skill_summary() -> String:
	return "دانش %d | ورزش %d | هنر %d | آشپزی %d | اجتماعی %d" % [
		int(skills.get("knowledge", 0)), int(skills.get("fitness", 0)),
		int(skills.get("art", 0)), int(skills.get("cooking", 0)),
		int(skills.get("social", 0))
	]

func get_progress_summary() -> String:
	return "فعالیت‌ها: %d | وسایل خانه: %d" % [completed_activities, owned_upgrades.size()]

func _add_skill_xp(skill: String, amount: int) -> void:
	skills[skill] = mini(100, int(skills.get(skill, 0)) + amount)

func _save_state() -> void:
	var config := ConfigFile.new()
	config.set_value("lifestyle", "skills", skills)
	config.set_value("lifestyle", "owned_upgrades", owned_upgrades)
	config.set_value("lifestyle", "completed_activities", completed_activities)
	config.set_value("lifestyle", "last_event_day", last_event_day)
	config.save(SAVE_PATH)

func _load_state() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	var loaded_skills: Variant = config.get_value("lifestyle", "skills", skills)
	if loaded_skills is Dictionary:
		for key in skills.keys():
			skills[key] = clampi(int(loaded_skills.get(key, 0)), 0, 100)
	var loaded_upgrades: Variant = config.get_value("lifestyle", "owned_upgrades", [])
	if loaded_upgrades is Array:
		for item in loaded_upgrades:
			if UPGRADE_DATA.has(str(item)) and not owned_upgrades.has(str(item)):
				owned_upgrades.append(str(item))
	completed_activities = maxi(0, int(config.get_value("lifestyle", "completed_activities", 0)))
	last_event_day = int(config.get_value("lifestyle", "last_event_day", -1))
