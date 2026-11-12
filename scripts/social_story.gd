extends Node

signal social_changed
signal dialogue_changed(title: String, body: String, choices: Array[String], visible: bool)

const SAVE_PATH := "user://social_story.cfg"
const PEOPLE := [
	{"name":"اِما","role":"کتابدار محله","intro":"سلام! من اِما هستم. تازه به ریورساید آمده‌ای؟","reply":"اگر دنبال شروع تازه‌ای هستی، کتابخانه جای خوبی برای پیدا کردن فرصت‌هاست."},
	{"name":"جیمز","role":"صاحب کافه","intro":"روز بخیر! من جیمز هستم. این اطراف تازه‌واردی؟","reply":"گاهی یک گفت‌وگوی خوب، شروع یک دوستی طولانی است."},
	{"name":"سوفیا","role":"دانشجوی هنر","intro":"سلام! من سوفیا هستم. از محله ما خوشت آمده؟","reply":"من معمولاً عصرها به پارک می‌روم. شاید آنجا دوباره همدیگر را دیدیم."},
	{"name":"الیور","role":"همسایه","intro":"سلام همسایه! من الیورم. اگر کمکی خواستی خبر بده.","reply":"خوشحالم که آشنا شدیم. محله با آدم‌های تازه جذاب‌تر می‌شود."},
	{"name":"میـا","role":"فروشنده","intro":"سلام! دنبال چیزی می‌گردی؟ من میا هستم.","reply":"ممنون که سر زدی. روز خوبی داشته باشی!"},
	{"name":"نوآ","role":"رهگذر","intro":"سلام! هوای لندن امروز بد نیست، نه؟","reply":"امیدوارم روز خوبی داشته باشی."}
]

var relationships: Dictionary = {}
var quest_stage: int = 0
var active_person: int = -1
var active_choices: Array[String] = []

func _ready() -> void:
	_load_state()

func begin_conversation(person_id: int) -> String:
	if person_id < 0 or person_id >= PEOPLE.size():
		return "شخصیتی برای گفت‌وگو پیدا نشد."
	active_person = person_id
	var person: Dictionary = PEOPLE[person_id]
	var affinity := int(relationships.get(str(person_id), 0))
	var body := str(person["intro"])
	if affinity >= 2:
		body = "خوشحالم دوباره می‌بینمت! " + str(person["reply"])
	var choices: Array[String] = ["خودت را معرفی کن", "درباره محله بپرس", "فعلاً خداحافظ"]
	active_choices = choices
	dialogue_changed.emit("%s — %s" % [person["name"], person["role"]], body, choices, true)
	return ""

func choose_dialogue(choice_index: int) -> void:
	if active_person < 0 or choice_index < 0 or choice_index >= active_choices.size():
		return
	var person: Dictionary = PEOPLE[active_person]
	var key := str(active_person)
	var affinity := int(relationships.get(key, 0))
	var body := ""
	var choices: Array[String] = []
	if choice_index == 0:
		body = "من تازه به لندن آمده‌ام و می‌خواهم اینجا زندگی تازه‌ای بسازم."
		affinity += 1
		choices = ["ادامه بده", "پایان گفت‌وگو"]
	elif choice_index == 1:
		body = str(person["reply"])
		affinity += 1
		choices = ["ممنون از راهنمایی", "پایان گفت‌وگو"]
	else:
		body = "از آشنایی با تو خوشحال شدم. روز خوبی داشته باشی!"
		choices = ["پایان"]
	relationships[key] = mini(affinity, 10)
	_update_quest_stage()
	_save_state()
	social_changed.emit()
	if choice_index == 2:
		_finish_dialogue()
		return
	active_choices = choices
	dialogue_changed.emit(str(person["name"]), body, choices, true)

func _finish_dialogue() -> void:
	active_person = -1
	active_choices.clear()
	dialogue_changed.emit("", "", [], false)

func _update_quest_stage() -> void:
	if relationships.size() >= 3:
		quest_stage = 2
	elif relationships.size() >= 1:
		quest_stage = 1

func get_relationship_summary() -> String:
	return "آشنایی‌ها: %d نفر" % relationships.size()

func get_quest_text() -> String:
	match quest_stage:
		0: return "مأموریت: با یکی از ساکنان محله آشنا شو"
		1: return "مأموریت: با دو نفر دیگر گفت‌وگو کن"
		_: return "مأموریت آغازین تکمیل شد!"
	
func _save_state() -> void:
	var config := ConfigFile.new()
	config.set_value("social", "relationships", relationships)
	config.set_value("story", "quest_stage", quest_stage)
	config.save(SAVE_PATH)

func _load_state() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	relationships = config.get_value("social", "relationships", {})
	quest_stage = int(config.get_value("story", "quest_stage", 0))
