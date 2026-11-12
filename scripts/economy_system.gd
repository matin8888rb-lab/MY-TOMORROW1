extends Node

signal economy_changed

const SAVE_PATH := "user://economy_state.cfg"
const STARTING_MONEY := 120.0
const FOOD_PRICE := 8.0
const WEEKLY_RENT := 90.0
const SHIFT_WAGE := 48.0

var money: float = STARTING_MONEY
var food_stock: int = 2
var total_earned: float = 0.0
var total_spent: float = 0.0
var shifts_completed: int = 0

func _ready() -> void:
	_load_state()
	economy_changed.emit()

func buy_food() -> String:
	if money < FOOD_PRICE:
		return "پول کافی برای خرید غذا نداری."
	money -= FOOD_PRICE
	food_stock += 1
	total_spent += FOOD_PRICE
	_save_state()
	economy_changed.emit()
	return "یک وعده غذا به قیمت £8 خریدی."

func consume_food() -> String:
	if food_stock <= 0:
		return "غذا نداری؛ از فروشگاه خرید کن."
	food_stock -= 1
	LifeSystem.eat_meal()
	_save_state()
	economy_changed.emit()
	return "غذا خوردی؛ گرسنگی‌ات کمتر شد."

func work_shift() -> String:
	if LifeSystem.energy < 20.0:
		return "انرژی کافی برای یک شیفت کاری نداری؛ کمی استراحت کن."
	money += SHIFT_WAGE
	total_earned += SHIFT_WAGE
	shifts_completed += 1
	LifeSystem.energy = maxf(0.0, LifeSystem.energy - 22.0)
	LifeSystem.advance_time(240)
	LifeSystem.save_state()
	_save_state()
	economy_changed.emit()
	return "شیفت کاری تمام شد؛ £48 دستمزد گرفتی."

func pay_rent() -> String:
	if LifeSystem.rent_due_in_days > 0:
		return "هنوز موعد اجاره نرسیده؛ %d روز باقی مانده." % LifeSystem.rent_due_in_days
	if money < WEEKLY_RENT:
		return "برای پرداخت اجاره £90 لازم داری؛ موجودی کافی نیست."
	money -= WEEKLY_RENT
	total_spent += WEEKLY_RENT
	LifeSystem.rent_due_in_days = 7
	LifeSystem.save_state()
	_save_state()
	economy_changed.emit()
	return "اجاره هفتگی £90 پرداخت شد. خانه‌ات برای هفت روز دیگر تمدید شد."

func pay_transport_fare() -> bool:
	const FARE := 3.0
	if money < FARE:
		return false
	money -= FARE
	total_spent += FARE
	_save_state()
	economy_changed.emit()
	return true

func get_money_text() -> String:
	return "£%.0f" % money

func _save_state() -> void:
	var config := ConfigFile.new()
	config.set_value("economy", "money", money)
	config.set_value("economy", "food_stock", food_stock)
	config.set_value("economy", "total_earned", total_earned)
	config.set_value("economy", "total_spent", total_spent)
	config.set_value("economy", "shifts_completed", shifts_completed)
	config.save(SAVE_PATH)

func _load_state() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	money = maxf(0.0, float(config.get_value("economy", "money", STARTING_MONEY)))
	food_stock = maxi(0, int(config.get_value("economy", "food_stock", 2)))
	total_earned = maxf(0.0, float(config.get_value("economy", "total_earned", 0.0)))
	total_spent = maxf(0.0, float(config.get_value("economy", "total_spent", 0.0)))
	shifts_completed = maxi(0, int(config.get_value("economy", "shifts_completed", 0)))
