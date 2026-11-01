extends Node3D

# الزيتون والحجر (Olive & Stone) v0.4 - colony survival prototype rooted in Palestine.
# A brand-new colony right after a disaster near Haifa: 5 survivors, a fire and two
# patched tents on a small levelled terrace. Nothing grows by itself - villagers walk
# to resource points, gather, and carry loads back. Experience unlocks buildings and
# building plots. Arabic, right-to-left interface.

const VERSION := "2.2.0"
const GRID := 48
const TILE_SIZE := 75.0
const START_POP := 5
const BASE_HOUSING := 6
const SAVE_PATH := "user://olive_stone_save.json"
const AUTOSAVE_PATH := "user://olive_stone_autosave.json"
const SETTINGS_PATH := "user://settings.cfg"
const SAVE_VERSION := 6
const WORLD_SEED := 987654
const SEA_COLOR := Color("#477f91")
const DAY_LENGTH := 25.0
const WALK_SPEED := 70.0
const FOOD_PER_VILLAGER := 1.0
const WATER_PER_VILLAGER := 1.2
const AUTOSAVE_EVERY := 150.0
const CAM_OFFSET := Vector3(1800, 2200, 2100)
const CAMP_CELL := Vector2i(15, 24)
const PLATEAU_R0 := 5.2
const PLATEAU_R1 := 7.6
const TRAIL_CELL := 26.0
const TRAIL_MAX := 900
const MAX_LEVEL := 5
const LEVEL_XP := [0.0, 60.0, 180.0, 400.0, 750.0]
const SEASON_DAYS := 20
const SEASON_NAMES := ["ربيع", "صيف", "خريف", "شتاء"]
const SEASON_AR := ["🌱 الربيع", "☀ الصيف", "🍂 الخريف", "❄ الشتاء"]
const SEASON_WATER_MUL := [1.0, 1.4, 1.0, 1.0]
const SEASON_FOOD_MUL := [1.0, 1.0, 1.0, 1.2]
const SEASON_SKY := [Color("#c8dff0"), Color("#d8eed0"), Color("#e8c870"), Color("#9ab8d0")]
const SEASON_COLOR := [Color("#7acc60"), Color("#ffc840"), Color("#e87030"), Color("#80b0e0")]
const PLACE_CELL := 88.0      # grid cell width in world units for free placement
const PLAY_RADIUS := 480.0    # max building distance from camp center

# ── City Skylines systems ──────────────────────────────────────────────────────
# Land value: how much each completed building radiates to nearby grid cells per day
const LAND_VALUE_SOURCES := {
	"Mosque":      {"radius": 3, "delta": 28.0},
	"Town Square": {"radius": 4, "delta": 24.0},
	"Diwan":       {"radius": 3, "delta": 22.0},
	"School":      {"radius": 3, "delta": 18.0},
	"Library":     {"radius": 3, "delta": 18.0},
	"Clinic":      {"radius": 2, "delta": 14.0},
	"Plaza":       {"radius": 3, "delta": 12.0},
	"Well":        {"radius": 2, "delta":  8.0},
	"Stone House": {"radius": 1, "delta":  5.0},
	"Large House": {"radius": 1, "delta":  5.0},
	"Khan":        {"radius": 2, "delta": 10.0},
	# Negative — noise / industrial pollution
	"Quarry":      {"radius": 2, "delta": -22.0},
	"Workshop":    {"radius": 2, "delta": -16.0},
	"Small Quarry":{"radius": 1, "delta": -10.0},
	"Pen":         {"radius": 1, "delta":  -8.0},
}
# Service coverage: daily benefit per villager within radius (world units)
const SERVICE_COVERAGE := {
	"Mosque":      {"radius": 220.0, "morale": 0.5},
	"Town Square": {"radius": 160.0, "morale": 0.3, "discontent": -0.12},
	"Plaza":       {"radius": 140.0, "morale": 0.25},
	"Clinic":      {"radius": 160.0, "heal_bonus": 1.5},
	"School":      {"radius": 200.0, "xp_bonus": 0.5},
	"Library":     {"radius": 200.0, "xp_bonus": 1.0},
	"Watchtower":  {"radius": 320.0},
}
# Minimum land value required to PLACE certain buildings
const MIN_LAND_VALUE_REQ := {
	"Stone House": 20.0,
	"Large House": 25.0,
	"Khan":        30.0,
	"Library":     30.0,
	"School":      25.0,
	"Diwan":       35.0,
	"Town Square": 25.0,
}

const RES_NAMES := ["Food", "Water", "Wood", "Stone", "Scrap", "Oil", "Dinar"]
const RES_AR := {
	"Food": "طعام", "Water": "ماء", "Wood": "خشب",
	"Stone": "حجر", "Scrap": "خردة", "Oil": "زيت", "Dinar": "دينار"
}
const RES_COLORS := {
	"Food": Color("#e0ac4a"), "Water": Color("#56b0e0"), "Wood": Color("#b07a45"),
	"Stone": Color("#d8d0bb"), "Scrap": Color("#d0844f"),
	"Oil": Color("#c8b84a"), "Dinar": Color("#f5d060")
}
# Dinar doesn't count against workers; Oil produced by Olive Press
const RES_TOP_BAR := ["Food", "Water", "Wood", "Stone", "Scrap", "Oil", "Dinar"]
const START_RESOURCES := {"Food": 50.0, "Water": 60.0, "Wood": 60.0, "Stone": 40.0, "Scrap": 20.0, "Oil": 0.0, "Dinar": 10.0}
const START_JOBS := {"Food": 2, "Water": 2, "Wood": 1, "Stone": 0, "Scrap": 0}
# Caravan trades: list of {day_from, res_buy, cost_dinar, res_sell, earn_dinar}
const CARAVAN_INTERVAL := 10
const CARAVAN_FIRST_DAY := 15
# Tax levels {name, rate, discontent_per_day}
const TAX_LEVELS := [
	{"ar": "بلا ضريبة", "dinar": 0.0, "discontent": 0.0},
	{"ar": "خفيفة 5%", "dinar": 3.0, "discontent": 0.0},
	{"ar": "معتدلة 15%", "dinar": 8.0, "discontent": 1.0},
	{"ar": "ثقيلة 30%", "dinar": 15.0, "discontent": 3.0}
]
# Moral events pool
const MORAL_EVENTS := [
	{
		"text": "وصلت عائلة لاجئة تطلب الانضمام. الموارد شحيحة لكن قلوب ناجيك تطلب المساعدة.",
		"a": "استقبلهم (+2 سكان، طعام −20)", "b": "اعتذر برفق (لا تغيير)",
		"effect_a": "refugee_accept", "effect_b": "none"
	},
	{
		"text": "اكتشف أحد الناجين كنزًا من الدنانير في أنقاض منزل قديم.",
		"a": "وزّعه على الجميع (معنوية +10)", "b": "ضعه في الخزينة (+25 دينار)",
		"effect_a": "morale_boost", "effect_b": "dinar_bonus"
	},
	{
		"text": "طلب تاجر مرور شراء فائض الطعام.",
		"a": "بيعه (طعام −30، دينار +20)", "b": "احتفظ بالطعام للشتاء",
		"effect_a": "sell_food", "effect_b": "none"
	},
	{
		"text": "وباء بسيط أصاب بعض الناجين. الطبيب يحتاج خردة لصنع دواء.",
		"a": "علّجهم (خردة −15، صحة +20)", "b": "اعتمد على الراحة (صحة −10)",
		"effect_a": "treat_illness", "effect_b": "rest_illness"
	},
	{
		"text": "شاب يريد تعلم الحرفة لكنه يحتاج أدوات من الورشة.",
		"a": "علّمه (خردة −10، XP +30)", "b": "وجّهه للعمل الميداني",
		"effect_a": "train_craftsman", "effect_b": "none"
	},
	{
		"text": "اقترح ناجٍ حفر خندق دفاعي حول المخيم.",
		"a": "ابدأ الحفر (حجر −20، أمان +)", "b": "ليست أولوية الآن",
		"effect_a": "build_trench", "effect_b": "none"
	},
]
const TEXT_SIZES := [1.0, 1.15, 1.3]
const TEXT_SIZE_AR := ["صغير", "متوسط", "كبير"]

# Survivor villages — discovered through exploration, each sells specific resources
const VILLAGES := [
	{"key": "akka_fishers", "ar": "صيادو عكا",
		"sells": [{"res": "Food", "qty": 8, "dinar": 4}, {"res": "Wood", "qty": 6, "dinar": 3}],
		"buys": [{"res": "Stone", "qty": 5, "dinar": 3}, {"res": "Scrap", "qty": 4, "dinar": 3}]},
	{"key": "marj_farmers", "ar": "مزارعو مرج ابن عامر",
		"sells": [{"res": "Food", "qty": 15, "dinar": 6}, {"res": "Stone", "qty": 5, "dinar": 4}],
		"buys": [{"res": "Scrap", "qty": 4, "dinar": 3}, {"res": "Wood", "qty": 6, "dinar": 3}]},
	{"key": "carmel_quarriers", "ar": "حجّارو الكرمل",
		"sells": [{"res": "Stone", "qty": 12, "dinar": 5}, {"res": "Scrap", "qty": 6, "dinar": 4}],
		"buys": [{"res": "Food", "qty": 8, "dinar": 3}, {"res": "Wood", "qty": 6, "dinar": 3}]},
	{"key": "northern_workshop", "ar": "ورشة الشمال",
		"sells": [{"res": "Scrap", "qty": 8, "dinar": 4}, {"res": "Wood", "qty": 10, "dinar": 4}],
		"buys": [{"res": "Food", "qty": 8, "dinar": 3}, {"res": "Stone", "qty": 5, "dinar": 3}]},
	{"key": "galilee_groves", "ar": "بستانيو الجليل",
		"sells": [{"res": "Oil", "qty": 8, "dinar": 5}, {"res": "Food", "qty": 6, "dinar": 3}],
		"buys": [{"res": "Stone", "qty": 5, "dinar": 3}, {"res": "Scrap", "qty": 4, "dinar": 3}]},
	{"key": "coast_traders", "ar": "تجار الساحل",
		"sells": [{"res": "Food", "qty": 6, "dinar": 4}, {"res": "Stone", "qty": 8, "dinar": 5}, {"res": "Wood", "qty": 8, "dinar": 4}],
		"buys": [{"res": "Oil", "qty": 4, "dinar": 5}, {"res": "Food", "qty": 8, "dinar": 3}, {"res": "Wood", "qty": 6, "dinar": 3}]},
]
const EXPLORE_BASE_COST := 5
const EXPLORE_COST_STEP := 3
const EXPLORE_DAYS := 2
const NAMES := [
	"مريم", "يوسف", "ليلى", "عمر", "سلمى", "خالد", "نور", "حسن", "رنا", "طارق",
	"أمل", "سمير", "هدى", "كريم", "دينا", "فادي", "لين", "بسام", "حنان", "زياد",
	"ريم", "جمال", "سارة", "وليد", "إيناس", "مجد", "لينا", "رامي", "فرح", "نبيل"
]
const SKILLS := ["Medicine", "Farming", "Construction", "Gathering", "Engineering"]
const SKILL_AR := {"Medicine": "طب", "Farming": "زراعة", "Construction": "بناء", "Gathering": "جمع", "Engineering": "هندسة"}
const SKILL_COLORS := {
	"Medicine": Color("#e07070"), "Farming": Color("#7fb04f"), "Construction": Color("#e0a040"),
	"Gathering": Color("#9a7bc0"), "Engineering": Color("#4a90c0")
}

# Natural resource points outside the terrace (placed deterministically).
const SOURCE_DEFS := {
	"Food": {"count": 5, "min": 6.0, "max": 9.5, "yield": 3.5, "time": 3.0, "amount": 160.0, "regen": 0.10, "infinite": false, "label": "تين وأعشاب برية"},
	"Water": {"count": 3, "min": 6.0, "max": 9.5, "yield": 4.0, "time": 2.0, "amount": 0.0, "regen": 0.0, "infinite": true, "label": "نبع"},
	"Wood": {"count": 6, "min": 6.0, "max": 10.5, "yield": 3.5, "time": 3.5, "amount": 220.0, "regen": 0.06, "infinite": false, "label": "صنوبر وخروب"},
	"Stone": {"count": 5, "min": 6.0, "max": 10.5, "yield": 3.0, "time": 4.0, "amount": 260.0, "regen": 0.0, "infinite": false, "label": "صخور كلسية"},
	"Scrap": {"count": 3, "min": 6.0, "max": 10.0, "yield": 2.5, "time": 4.0, "amount": 120.0, "regen": 0.0, "infinite": false, "label": "أنقاض قديمة"}
}

# Plot classes (footprints in world units) and the fixed plots of the terrace.
const PLOT_SIZES := {"S": Vector2(80, 80), "M": Vector2(168, 88), "L": Vector2(168, 168)}
const PLOT_AR := {"S": "صغيرة", "M": "متوسطة", "L": "كبيرة"}
# v2.0.0: Free placement — no fixed plots. Buildings placed freely on flat plateau, grid-snapped.
# Zone painting is a separate layer: zones give bonuses, not restrictions.

const BUILDINGS := {
	"Tent": {
		"ar": "خيمة", "cls": "S", "lv": 1, "tab": "home", "cost": {"Wood": 12.0, "Scrap": 4.0},
		"time": 6.0, "housing": 3, "gather": {}, "storage": false, "xp": 20.0, "scale": 1.0,
		"desc": "مأوى مرتجل يتسع لـ3 ناجين."
	},
	"Well": {
		"ar": "بئر", "cls": "S", "lv": 1, "tab": "res", "cost": {"Stone": 16.0, "Wood": 8.0},
		"time": 10.0, "housing": 0, "storage": false, "xp": 25.0, "scale": 1.4,
		"gather": {"res": "Water", "yield": 4.0, "time": 4.0, "slots": 3},
		"desc": "ماء قريب لا ينضب (3 سقّائين).",
		"upgrade": {"cost": {"Stone": 12.0, "Wood": 8.0}, "gather_yield": 6.0, "gather_slots": 4, "ar": "بئر معقودة", "desc": "4 سقّائين، 6 وحدة/جولة"}
	},
	"Storehouse": {
		"ar": "مخزن", "cls": "M", "lv": 1, "tab": "serv", "cost": {"Wood": 22.0, "Stone": 8.0},
		"time": 10.0, "housing": 0, "gather": {}, "storage": true, "xp": 30.0, "scale": 1.75,
		"desc": "نقطة تسليم تقصّر رحلات الجمع."
	},
	"Farm": {
		"ar": "مزرعة", "cls": "L", "lv": 1, "tab": "res", "cost": {"Wood": 14.0, "Stone": 6.0},
		"time": 12.0, "housing": 0, "storage": false, "xp": 30.0, "scale": 2.05,
		"gather": {"res": "Food", "yield": 5.0, "time": 5.0, "slots": 2},
		"desc": "طعام لا ينضب بمحصول كبير (مزارعان).",
		"upgrade": {"cost": {"Wood": 10.0, "Stone": 8.0}, "gather_yield": 8.0, "gather_slots": 3, "ar": "مزرعة مسقية", "desc": "3 مزارعين، 8 وحدة/جولة بالري"}
	},
	"Olive Grove": {
		"ar": "بستان زيتون", "cls": "L", "lv": 2, "tab": "res", "cost": {"Wood": 16.0, "Stone": 5.0},
		"time": 12.0, "housing": 0, "storage": false, "xp": 35.0, "scale": 2.1,
		"gather": {"res": "Food", "yield": 3.5, "time": 4.0, "slots": 3},
		"desc": "طعام لا ينضب بقطاف سريع (3 قطّافين)."
	},
	"Stone House": {
		"ar": "بيت حجري", "cls": "M", "lv": 2, "tab": "home", "cost": {"Wood": 20.0, "Stone": 22.0},
		"time": 16.0, "housing": 6, "gather": {}, "storage": false, "xp": 45.0, "scale": 1.9,
		"desc": "بيت من حجر القدس يتسع لـ6 ناجين."
	},
	"Pen": {
		"ar": "حظيرة", "cls": "M", "lv": 2, "tab": "res", "cost": {"Wood": 22.0, "Stone": 10.0},
		"time": 14.0, "housing": 0, "storage": false, "xp": 35.0, "scale": 1.85,
		"gather": {"res": "Food", "yield": 2.5, "time": 6.0, "slots": 2},
		"desc": "حظيرة ماعز ودجاج — بيض ولحم يومي (راعيان)."
	},
	"Kitchen": {
		"ar": "مطبخ", "cls": "M", "lv": 2, "tab": "serv", "cost": {"Wood": 16.0, "Stone": 12.0, "Scrap": 5.0},
		"time": 12.0, "housing": 0, "storage": false, "xp": 35.0, "scale": 1.8,
		"gather": {}, "kitchen": true,
		"desc": "يحوّل الطعام الخام إلى وجبات — يقلل الاستهلاك اليومي 25%."
	},
	"Olive Press": {
		"ar": "معصرة زيتون", "cls": "M", "lv": 3, "tab": "res", "cost": {"Wood": 20.0, "Stone": 16.0},
		"time": 14.0, "housing": 0, "storage": false, "xp": 40.0, "scale": 1.8,
		"gather": {"res": "Oil", "yield": 3.0, "time": 6.0, "slots": 2},
		"desc": "يعصر زيت الزيتون (2 عمال). الزيت يُباع للقوافل أو يُطبخ."
	},
	"Quarry": {
		"ar": "مقلع", "cls": "L", "lv": 3, "tab": "res", "cost": {"Wood": 22.0, "Scrap": 6.0},
		"time": 16.0, "housing": 0, "storage": false, "xp": 50.0, "scale": 2.05,
		"gather": {"res": "Stone", "yield": 3.5, "time": 5.0, "slots": 3},
		"desc": "حجر لا ينضب (3 قلّاعين)."
	},
	"Workshop": {
		"ar": "ورشة", "cls": "M", "lv": 3, "tab": "serv", "cost": {"Wood": 20.0, "Stone": 14.0, "Scrap": 8.0},
		"time": 18.0, "housing": 0, "storage": false, "xp": 60.0, "scale": 1.9,
		"gather": {"res": "Scrap", "yield": 2.5, "time": 5.0, "slots": 2},
		"desc": "خردة لا تنضب: تفكيك وإصلاح (عاملان)."
	},
	"Small Quarry": {
		"ar": "مقلع صغير", "cls": "S", "lv": 1, "tab": "res", "cost": {"Wood": 8.0, "Scrap": 4.0},
		"time": 8.0, "housing": 0, "storage": false, "xp": 22.0, "scale": 1.25,
		"gather": {"res": "Stone", "yield": 2.0, "time": 5.0, "slots": 1},
		"desc": "مقلع بسيط في الأنقاض — حجر مبكر (عامل واحد)."
	},
	"Stable": {
		"ar": "إسطبل", "cls": "M", "lv": 2, "tab": "serv", "cost": {"Wood": 20.0, "Stone": 14.0},
		"time": 14.0, "housing": 0, "storage": false, "xp": 40.0, "scale": 1.9,
		"gather": {}, "stable": true,
		"desc": "خيول للنقل — يضاعف الكميات عند التجارة مع القرى المستكشفة."
	},
	"Small House": {
		"ar": "منزل صغير", "cls": "S", "lv": 1, "tab": "home", "cost": {"Wood": 16.0, "Stone": 10.0},
		"time": 10.0, "housing": 4, "gather": {}, "storage": false, "xp": 28.0, "scale": 1.2,
		"desc": "بيت صغير من الطوب — مأوى دائم لـ4 ناجين."
	},
	"Large House": {
		"ar": "بيت عائلي", "cls": "L", "lv": 3, "tab": "home", "cost": {"Stone": 35.0, "Wood": 16.0},
		"time": 22.0, "housing": 10, "gather": {}, "storage": false, "xp": 55.0, "scale": 2.15,
		"desc": "منزل فلسطيني فسيح — يتسع لعائلة من 10 ناجين."
	},
	"Diwan": {
		"ar": "الديوان", "cls": "L", "lv": 3, "tab": "serv", "cost": {"Stone": 35.0, "Wood": 20.0, "Dinar": 30.0},
		"time": 20.0, "housing": 0, "storage": false, "xp": 80.0, "scale": 2.2,
		"gather": {}, "council": true,
		"desc": "مجلس المستوطنة — يفعّل الضرائب والقرارات الجماعية."
	},
	"Fishing Dock": {
		"ar": "رصيف الصيد", "cls": "L", "lv": 2, "tab": "res", "cost": {"Wood": 28.0, "Stone": 16.0},
		"time": 18.0, "housing": 0, "storage": false, "xp": 50.0, "scale": 2.1,
		"gather": {"res": "Food", "yield": 5.0, "time": 4.0, "slots": 3},
		"coastal": true,
		"desc": "رصيف على شاطئ حيفا — سمك طازج يوميًا (3 صيادين). يُبنى قرب البحر.",
		"upgrade": {"cost": {"Wood": 16.0, "Stone": 10.0}, "gather_yield": 8.0, "gather_slots": 4, "ar": "ميناء صيد", "desc": "4 صيادين، 8 وحدة/جولة"}
	},
	"Khan": {
		"ar": "الخان", "cls": "L", "lv": 4, "tab": "home", "cost": {"Stone": 45.0, "Wood": 22.0, "Dinar": 20.0},
		"time": 28.0, "housing": 15, "gather": {}, "storage": false, "xp": 80.0, "scale": 2.3,
		"desc": "خان كبير — مأوى للمسافرين والتجار يتسع لـ15 ناجيًا."
	},
	# ── مبانٍ ترفيهية وخدمية ── v2.0.0
	"Mosque": {
		"ar": "جامع", "cls": "M", "lv": 2, "tab": "serv", "cost": {"Stone": 28.0, "Wood": 14.0},
		"time": 18.0, "housing": 0, "gather": {}, "storage": false, "xp": 55.0, "scale": 1.95,
		"mosque": true,
		"desc": "يرفع المعنويات +15 كل 7 أيام (صلاة الجمعة)."
	},
	"Clinic": {
		"ar": "عيادة", "cls": "M", "lv": 2, "tab": "serv", "cost": {"Stone": 22.0, "Wood": 12.0, "Scrap": 8.0},
		"time": 16.0, "housing": 0, "gather": {}, "storage": false, "xp": 50.0, "scale": 1.85,
		"clinic": true,
		"desc": "تسرّع تعافي الصحة وتحمي من تفشي الأمراض."
	},
	"School": {
		"ar": "مدرسة", "cls": "M", "lv": 3, "tab": "serv", "cost": {"Stone": 30.0, "Wood": 18.0},
		"time": 20.0, "housing": 0, "gather": {}, "storage": false, "xp": 60.0, "scale": 1.9,
		"school": true,
		"desc": "يضاعف كسب XP ويرفع مهارات الناجين تدريجيًا."
	},
	"Town Square": {
		"ar": "ساحة المدينة", "cls": "L", "lv": 3, "tab": "serv", "cost": {"Stone": 35.0, "Wood": 16.0, "Dinar": 15.0},
		"time": 22.0, "housing": 0, "gather": {}, "storage": false, "xp": 70.0, "scale": 2.1,
		"town_square": true,
		"desc": "تجلب وافدين جدد وتجاراً كل 5 أيام عوضًا عن كل 8."
	},
	"Watchtower": {
		"ar": "برج المراقبة", "cls": "S", "lv": 1, "tab": "serv", "cost": {"Stone": 18.0, "Wood": 14.0},
		"time": 10.0, "housing": 0, "gather": {}, "storage": false, "xp": 30.0, "scale": 1.3,
		"watchtower": true,
		"desc": "يُنبّه مبكرًا بالأحداث الطارئة ويمنح يومًا إضافيًا للاستعداد."
	},
	"Plaza": {
		"ar": "ساحة عامة", "cls": "S", "lv": 2, "tab": "serv", "cost": {"Stone": 14.0, "Wood": 8.0},
		"time": 10.0, "housing": 0, "gather": {}, "storage": false, "xp": 28.0, "scale": 1.2,
		"plaza": true,
		"desc": "فضاء مفتوح — يرفع المعنويات +5 يوميًا."
	},
	"Library": {
		"ar": "مكتبة", "cls": "M", "lv": 3, "tab": "serv", "cost": {"Stone": 26.0, "Wood": 16.0, "Dinar": 10.0},
		"time": 18.0, "housing": 0, "gather": {}, "storage": false, "xp": 55.0, "scale": 1.85,
		"library": true,
		"desc": "تضاعف XP من التسليم وتفتح بحوثًا لاحقًا."
	}
}
const TABS := [["home", "سكن"], ["res", "موارد"], ["serv", "خدمات"]]

const GOALS := [
	{"key": "workers", "text": "افتح «العمال» وقرّر من يجمع ماذا."},
	{"key": "well", "text": "ابنِ بئرًا لماء قريب."},
	{"key": "tent", "text": "ابنِ خيمة لاستقبال ناجين جدد."},
	{"key": "storehouse", "text": "ابنِ مخزنًا لتقصير رحلات الجمع."},
	{"key": "farm", "text": "ابنِ مزرعة لطعام ثابت."},
	{"key": "pen", "text": "ابنِ حظيرة لتربية الماعز والدجاج."},
	{"key": "level2", "text": "ارتقِ بالمستوطنة إلى المستوى 2."},
	{"key": "kitchen", "text": "ابنِ مطبخًا لتحسين الطعام وخفض الاستهلاك."},
	{"key": "pop10", "text": "اجمع 10 ناجين."},
	{"key": "stone_house", "text": "ابنِ أول بيت من حجر القدس."},
	{"key": "level3", "text": "ارتقِ إلى المستوى 3."},
	{"key": "olive_press", "text": "ابنِ معصرة لعصر زيت الزيتون."},
	{"key": "caravan", "text": "انتظر القافلة الأولى (اليوم 15)."},
	{"key": "diwan", "text": "ابنِ الديوان: مجلس المستوطنة."},
	{"key": "pop20", "text": "اجمع 20 ناجيًا."},
	{"key": "day60", "text": "اصمد حتى اليوم 60."},
	{"key": "fishing_dock", "text": "ابنِ رصيف الصيد على شاطئ حيفا."},
	{"key": "level4", "text": "ارتقِ إلى المستوى 4."},
	{"key": "khan", "text": "ابنِ الخان — مأوى للمسافرين والتجار."},
	{"key": "mosque", "text": "ابنِ جامعًا لرفع المعنويات كل جمعة."},
	{"key": "clinic", "text": "ابنِ عيادة لحماية صحة الناجين."},
	{"key": "town_square", "text": "ابنِ ساحة المدينة لجلب الوافدين بسرعة."},
	{"key": "day90", "text": "اصمد حتى اليوم 90."}
]

# UI palette — v2.0.0 glassmorphism
const C_PANEL := Color(0.06, 0.07, 0.05, 0.82)
const C_BORDER := Color(1.0, 1.0, 1.0, 0.14)
const C_GOLD := Color("#e8c872")
const C_CREAM := Color("#f2e8cc")
const C_MUTED := Color("#b8ad8a")
const C_BTN := Color(0.22, 0.32, 0.14, 0.92)
const C_GREEN := Color("#5c8a3a")
const C_RED := Color("#9a4333")


class Building:
	var type := ""
	var plot := -1
	var pos := Vector3.ZERO
	var progress := 0.0
	var done := false
	var base_scale := 1.0
	var node: Node3D
	var model: Node3D
	var scaffold: Node3D
	var label: Label3D
	var upgrade_level := 0


class Plot:
	var idx := 0
	var cls := "S"
	var lv := 1
	var gx := 0
	var gz := 0
	var pos := Vector3.ZERO
	var size := Vector2.ZERO
	var node: Node3D
	var slab: MeshInstance3D
	var lock_label: Label3D
	var building: Building = null


class Source:
	var res := ""
	var label := ""
	var pos := Vector3.ZERO
	var amount := 0.0
	var max_amount := 0.0
	var infinite := false
	var yield_amt := 10.0
	var gather_time := 3.0
	var slots := 3
	var regen := 0.0
	var building: Building = null
	var node: Node3D


class Villager:
	var vname := ""
	var skill := ""
	var node: Node3D
	var carry_node: MeshInstance3D
	var task := "idle"
	var job := ""
	var state := ""
	var target: Building = null
	var src: Source = null
	var releasing := false
	var carry_res := ""
	var carry_amt := 0.0
	var goal := Vector3.ZERO
	var wait := 0.0
	var timer := 0.0
	var phase := 0.0


# Simple vector icons drawn in code (no image assets needed).
class IconCanvas extends Control:
	var kind := ""
	var color := Color("#f2e8cc")

	func _draw() -> void:
		var s := minf(size.x, size.y)
		var c := size * 0.5
		var u := s / 24.0
		match kind:
			"build":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-10, -1) * u, c + Vector2(0, -10) * u, c + Vector2(10, -1) * u]), color)
				draw_rect(Rect2(c + Vector2(-7, -1) * u, Vector2(14, 10) * u), color)
				draw_rect(Rect2(c + Vector2(-2, 3) * u, Vector2(4, 6) * u), Color(0.15, 0.17, 0.1))
			"workers":
				draw_circle(c + Vector2(-5, -5) * u, 3.4 * u, color)
				draw_circle(c + Vector2(5, -5) * u, 3.4 * u, color)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-10, 9) * u, c + Vector2(-8, 0) * u, c + Vector2(-2, 0) * u, c + Vector2(0, 9) * u]), color)
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, 9) * u, c + Vector2(2, 0) * u, c + Vector2(8, 0) * u, c + Vector2(10, 9) * u]), color)
			"missions":
				draw_rect(Rect2(c + Vector2(-7, -10) * u, Vector2(2.2, 20) * u), color)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-5, -10) * u, c + Vector2(9, -6) * u, c + Vector2(-5, -1) * u]), color)
			"pause":
				draw_rect(Rect2(c + Vector2(-6, -7) * u, Vector2(4, 14) * u), color)
				draw_rect(Rect2(c + Vector2(2, -7) * u, Vector2(4, 14) * u), color)
			"play":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-5, -7) * u, c + Vector2(7, 0) * u, c + Vector2(-5, 7) * u]), color)
			"menu":
				for k in range(3):
					draw_rect(Rect2(c + Vector2(-8, -6 + 5 * k) * u, Vector2(16, 2.4) * u), color)
			"plus":
				draw_rect(Rect2(c + Vector2(-7, -1.3) * u, Vector2(14, 2.6) * u), color)
				draw_rect(Rect2(c + Vector2(-1.3, -7) * u, Vector2(2.6, 14) * u), color)
			"minus":
				draw_rect(Rect2(c + Vector2(-7, -1.3) * u, Vector2(14, 2.6) * u), color)
			"villages":
				# Two houses with a path between them
				draw_colored_polygon(PackedVector2Array([c + Vector2(-11, 0) * u, c + Vector2(-6, -7) * u, c + Vector2(-1, 0) * u]), color)
				draw_rect(Rect2(c + Vector2(-10, 0) * u, Vector2(8, 7) * u), color)
				draw_colored_polygon(PackedVector2Array([c + Vector2(1, 1) * u, c + Vector2(6, -6) * u, c + Vector2(11, 1) * u]), color)
				draw_rect(Rect2(c + Vector2(2, 1) * u, Vector2(8, 6) * u), color)
				draw_rect(Rect2(c + Vector2(-3, 5) * u, Vector2(6, 2.5) * u), color.darkened(0.3))
			"log":
				# Open book / scroll
				draw_rect(Rect2(c + Vector2(-9, -8) * u, Vector2(8, 16) * u), color)
				draw_rect(Rect2(c + Vector2(1, -8) * u, Vector2(8, 16) * u), color)
				draw_line(c + Vector2(0, -8) * u, c + Vector2(0, 8) * u, Color(0.15, 0.17, 0.1), 1.5)
				draw_line(c + Vector2(-7, -4) * u, c + Vector2(-2, -4) * u, Color(0.15, 0.17, 0.1), 1.2)
				draw_line(c + Vector2(-7, -1) * u, c + Vector2(-2, -1) * u, Color(0.15, 0.17, 0.1), 1.2)
				draw_line(c + Vector2(-7, 2) * u, c + Vector2(-2, 2) * u, Color(0.15, 0.17, 0.1), 1.2)
			"missions2":
				# Star / flag variant for missions
				for k2 in range(5):
					var a2 := -PI * 0.5 + float(k2) * TAU / 5.0
					var ao := a2 + PI / 5.0
					draw_line(c + Vector2(cos(a2), sin(a2)) * 9 * u, c + Vector2(cos(ao), sin(ao)) * 4 * u, color, 1.5)
					draw_line(c + Vector2(cos(ao), sin(ao)) * 4 * u, c + Vector2(cos(a2 + TAU / 5.0), sin(a2 + TAU / 5.0)) * 9 * u, color, 1.5)
			"road":
				# Two parallel lines (road) with a dash in the middle
				draw_rect(Rect2(c + Vector2(-9, -8) * u, Vector2(18, 3) * u), color)
				draw_rect(Rect2(c + Vector2(-9, 5) * u, Vector2(18, 3) * u), color)
				draw_rect(Rect2(c + Vector2(-3, -1.5) * u, Vector2(6, 3) * u), color.darkened(0.3))
			"lv":
				# Land value heatmap — layered squares in gradient
				for li in range(3):
					var t2 := float(li) / 2.0
					var rc := color.lerp(Color("#e85040"), t2)
					draw_rect(Rect2(c + Vector2(-9 + li*3, -9 + li*3) * u, Vector2(18 - li*6, 18 - li*6) * u), rc, false, 1.8)
				draw_circle(c, 3.5 * u, color)


var resources: Dictionary = START_RESOURCES.duplicate()
var jobs: Dictionary = START_JOBS.duplicate()
var income_today := {"Food": 0.0, "Water": 0.0, "Wood": 0.0, "Stone": 0.0, "Scrap": 0.0, "Oil": 0.0}
var last_income := {"Food": 0.0, "Water": 0.0, "Wood": 0.0, "Stone": 0.0, "Scrap": 0.0, "Oil": 0.0}
var day := 1
var day_timer := 0.0
var morale := 70.0
var health := 100.0
var hope := 50.0
var discontent := 0.0
var cur_season := 0
var season_day := 0
var level := 1
var xp := 0.0
var peak_pop := START_POP
var game_speed := 1.0
var paused := false
var menu_open := false
var game_over := false
var goal_index := 0
var workers_opened := false
var text_size_index := 1
var selected_building := ""
var pending_gx := 0
var pending_gz := 0
var pending_valid := false
var occupied_cells: Dictionary = {}
var inspected: Building = null
var demolish_armed := false
var new_armed := false
var council_unlocked := false
var tax_level_idx := 0
var caravan_day := 0
var event_cooldown := 0
var kitchen_active := false
var pending_event := -1
var discovered_villages: Array[int] = []
var exploring := false
var explore_done_day := -1
var res_trend_history: Array[Dictionary] = []
var event_log: Array[String] = []
var caravan_timer := 0.0
var caravan_node: Node3D = null
var plateau_h := 0.0
var buildings: Array[Building] = []
var plots: Array[Plot] = []
var sources: Array[Source] = []
var survivors: Array[Villager] = []
var heights := PackedFloat32Array()
var camp_pos := Vector3.ZERO
var rng := RandomNumberGenerator.new()
var mat_cache := {}
var stone_texture: ImageTexture
var ar_font: Font
var no_source_day := {}
var trail_counts := {}
var trail_mm: MultiMesh
var trail_used := 0

# ── CS systems state ──────────────────────────────────────────────────────────
var land_value: Dictionary = {}   # Vector2i(gx,gz) → float 0-100
var demand_housing   := 50.0
var demand_production := 50.0
var demand_services  := 50.0
var lv_overlay       := false
var lv_overlay_root: Node3D = null
var service_xp_mult  := 1.0   # updated daily by _apply_service_coverage
var service_heal_mult := 1.0  # updated daily by _apply_service_coverage

var camera: Camera3D
var camera_target := Vector3.ZERO
var terrain_root: Node3D
var building_root: Node3D
var source_root: Node3D
var villager_root: Node3D
var ghost: Node3D
var ghost_mesh: MeshInstance3D
var ghost_mat: StandardMaterial3D
var plot_mats := {}

var drag_active := false
var drag_moved := false
var press_pos := Vector2.ZERO
var right_drag := false
var touches := {}
var pinch_last := 0.0

var sun_node: DirectionalLight3D
var world_env: Environment
var crisis_overlay: ColorRect
var crisis_alpha := 0.0

var hud: CanvasLayer
var ui_root: Control
var level_label: Label
var xp_bar: ProgressBar
var day_label: Label
var day_bar: ProgressBar
var res_value_labels := {}
var pop_label: Label
var pause_icon: IconCanvas
var speed_btn: Button
var goal_label: Label
var toast_panel: PanelContainer
var toast_label: Label
var toast_time := 0.0
var pause_banner: PanelContainer
var dock: PanelContainer
var build_sheet: PanelContainer
var build_tab := "home"
var tab_buttons := {}
var cards_box: HBoxContainer
var build_scroll: ScrollContainer
var road_mode := false
var drag_in_sheet := false
var council_btn: Button
var place_bar: PanelContainer
var place_label: Label
var confirm_btn: Button
var inspect_bar: PanelContainer
var inspect_label: Label
var demolish_btn: Button
var workers_sheet: PanelContainer
var morale_bar: ProgressBar
var health_bar: ProgressBar
var job_count_labels := {}
var job_rate_labels := {}
var free_label: Label
var villager_list: VBoxContainer
var villager_labels: Array[Label] = []
var missions_sheet: PanelContainer
var missions_list: VBoxContainer
var menu_layer: Control
var text_size_btn: Button
var new_btn: Button
var over_layer: Control
var over_label: Label
var start_screen: Control
var explore_btn: Button
var log_sheet: PanelContainer
var log_list: VBoxContainer
var villages_sheet: PanelContainer
var villages_content: VBoxContainer
var trend_labels := {}
var days_labels := {}
var season_label: Label
var upgrade_btn: Button
var ui_timer := 0.0
var assign_timer := 0.0
var autosave_timer := 0.0


func _ready() -> void:
	rng.randomize()
	ar_font = load("res://fonts/Amiri-Regular.ttf")
	_load_settings()
	stone_texture = _make_stone_texture()
	plateau_h = _natural_height(float(CAMP_CELL.x), float(CAMP_CELL.y))
	_build_heights()
	camp_pos = _grid_vertex(CAMP_CELL.x, CAMP_CELL.y)
	_build_world()
	_build_plots()
	_generate_sources()
	_build_camp()
	_build_trails()
	_build_camera()
	_build_lighting()
	_build_ghost()
	_build_ui()
	_create_survivors()
	_assign_tasks()
	_refresh_ui()
	# Welcome toast fires when the player actually starts/continues from the start screen


# ---------------------------------------------------------------- terrain

func _natural_height(gx: float, gz: float) -> float:
	var east := gx / float(GRID - 1)
	var north_south := gz / float(GRID - 1)
	var escarpment_center := 0.58 + 0.045 * sin((north_south * 1.2 + 0.12) * TAU)
	var rise := 430.0 / (1.0 + exp(-19.0 * (east - escarpment_center)))
	var ridge_center := 0.77 + 0.025 * sin(north_south * TAU * 1.4)
	var ridge := 75.0 * exp(-pow((east - ridge_center) / 0.075, 2.0))
	var wadi_a := 32.0 * exp(-pow((east - (0.47 + 0.035 * sin(north_south * 8.0))) / 0.028, 2.0))
	var wadi_b := 24.0 * exp(-pow((east - (0.68 + 0.025 * cos(north_south * 7.0))) / 0.025, 2.0))
	var local_relief := 9.0 * sin(gx * 0.39) * cos(gz * 0.31) + 5.0 * sin(gz * 0.67)
	return maxf(3.0, rise + ridge + local_relief - wadi_a - wadi_b)


# The settlement sits on a levelled terrace; outside it the land blends back to nature.
func _terrain_height(gx: float, gz: float) -> float:
	var natural := _natural_height(gx, gz)
	var r := Vector2(gx - float(CAMP_CELL.x), gz - float(CAMP_CELL.y)).length()
	var t := smoothstep(PLATEAU_R0, PLATEAU_R1, r)
	return lerpf(plateau_h, natural, t)


func _build_world() -> void:
	terrain_root = Node3D.new()
	terrain_root.name = "HaifaTerrain"
	add_child(terrain_root)
	source_root = Node3D.new()
	source_root.name = "ResourcePoints"
	add_child(source_root)
	building_root = Node3D.new()
	building_root.name = "SettlementBuildings"
	add_child(building_root)
	villager_root = Node3D.new()
	villager_root.name = "Villagers"
	add_child(villager_root)
	_build_sea()
	_build_land_mesh()
	_add_olive_groves()
	_add_geographic_labels()


func _vertex_color(gx: int, gz: int, h: float) -> Color:
	var n := sin(float(gx) * 1.7 + float(gz) * 0.9) * 0.5 + sin(float(gx) * 0.6 - float(gz) * 1.3) * 0.5
	var c: Color
	if h > 340.0:
		c = Color("#b3ab97")
	elif h > 190.0:
		c = Color("#8f9470").lerp(Color("#b3ab97"), clampf((h - 190.0) / 150.0, 0.0, 1.0))
	elif h > 60.0:
		c = Color("#9aa06e").lerp(Color("#8f9470"), clampf((h - 60.0) / 130.0, 0.0, 1.0))
	else:
		c = Color("#c4ae82").lerp(Color("#a8a574"), clampf(h / 60.0, 0.0, 1.0))
	var r := Vector2(float(gx - CAMP_CELL.x), float(gz - CAMP_CELL.y)).length()
	var dirt := 1.0 - smoothstep(PLATEAU_R0 - 0.6, PLATEAU_R1 - 0.8, r)
	c = c.lerp(Color("#b39a6a"), dirt * 0.85)
	return c.lightened(n * 0.035)


func _build_land_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(GRID - 1):
		for z in range(GRID - 1):
			if x + 0.5 < _coastline_x(float(z) + 0.5):
				continue
			for p in [Vector2i(x, z), Vector2i(x, z + 1), Vector2i(x + 1, z), Vector2i(x + 1, z), Vector2i(x, z + 1), Vector2i(x + 1, z + 1)]:
				var v := _grid_vertex(p.x, p.y)
				st.set_color(_vertex_color(p.x, p.y, v.y))
				st.add_vertex(v)
	st.index()
	st.generate_normals()
	var surface := MeshInstance3D.new()
	surface.name = "TerrainSurface"
	surface.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	surface.material_override = mat
	terrain_root.add_child(surface)


func _add_olive_groves() -> void:
	var wr := RandomNumberGenerator.new()
	wr.seed = WORLD_SEED + 1
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 2.4
	trunk_mesh.bottom_radius = 3.6
	trunk_mesh.height = 20.0
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 16.0
	crown_mesh.height = 22.0
	var spots: Array[Vector3] = []
	var groves := 0
	var tries := 0
	while groves < 12 and tries < 400:
		tries += 1
		var gx := wr.randi_range(7, GRID - 6)
		var gz := wr.randi_range(2, GRID - 3)
		if not _is_land(gx, gz):
			continue
		if Vector2(Vector2i(gx, gz) - CAMP_CELL).length() < PLATEAU_R1 + 1.5:
			continue
		if _grid_vertex(gx, gz).y > 320.0:
			continue
		groves += 1
		var center := _grid_vertex(gx, gz)
		for k in range(wr.randi_range(5, 9)):
			var px := center.x + wr.randf_range(-85.0, 85.0)
			var pz := center.z + wr.randf_range(-85.0, 85.0)
			spots.append(Vector3(px, _height_at_world(px, pz), pz))
	var trunks := MultiMesh.new()
	trunks.transform_format = MultiMesh.TRANSFORM_3D
	trunks.mesh = trunk_mesh
	trunks.instance_count = spots.size()
	var crowns := MultiMesh.new()
	crowns.transform_format = MultiMesh.TRANSFORM_3D
	crowns.mesh = crown_mesh
	crowns.instance_count = spots.size()
	for i in range(spots.size()):
		var s := wr.randf_range(0.8, 1.2)
		var basis := Basis.from_scale(Vector3(s, s, s))
		trunks.set_instance_transform(i, Transform3D(basis, spots[i] + Vector3(0.0, 10.0 * s, 0.0)))
		crowns.set_instance_transform(i, Transform3D(basis, spots[i] + Vector3(0.0, 27.0 * s, 0.0)))
	var trunk_node := MultiMeshInstance3D.new()
	trunk_node.multimesh = trunks
	trunk_node.material_override = _mat(Color("#6b553c"))
	terrain_root.add_child(trunk_node)
	var crown_node := MultiMeshInstance3D.new()
	crown_node.multimesh = crowns
	crown_node.material_override = _mat(Color("#7d8a58"))
	terrain_root.add_child(crown_node)


func _add_geographic_labels() -> void:
	_add_world_label("البحر المتوسط", Vector3(-1900, 30, -300), 2.6)
	_add_world_label("السهل الساحلي", _grid_vertex(10, 36) + Vector3(0, 50, 0), 1.7)
	_add_world_label("سفوح الكرمل", _grid_vertex(30, 20) + Vector3(0, 60, 0), 1.7)
	_add_world_label("قمة الكرمل", _grid_vertex(38, 14) + Vector3(0, 70, 0), 1.7)


func _add_world_label(text: String, pos: Vector3, pixel_size: float) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font = ar_font
	label.font_size = 30
	label.pixel_size = pixel_size
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.outline_size = 10
	label.outline_modulate = Color(0.15, 0.13, 0.08, 0.8)
	label.modulate = Color(1, 0.97, 0.88, 0.85)
	label.position = pos
	terrain_root.add_child(label)
	return label


func _build_camp() -> void:
	var camp := Node3D.new()
	camp.name = "Camp"
	camp.position = Vector3(camp_pos.x, plateau_h, camp_pos.z)
	terrain_root.add_child(camp)
	# fire ring of stones
	for i in range(9):
		var a := TAU * float(i) / 9.0
		_box(camp, Vector3(7, 5, 7), Vector3(cos(a) * 15.0, 2.5, sin(a) * 15.0), Color("#ffffff"), true)
	_cyl(camp, 10.0, 11.0, 2.0, Vector3(0, 1, 0), Color("#3d3530"))
	var flame := _cyl(camp, 0.0, 7.0, 20.0, Vector3(0, 12, 0), Color("#ff9a3c"))
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color("#ff9a3c")
	fm.emission_enabled = true
	fm.emission = Color("#ff7a1a")
	fm.emission_energy_multiplier = 1.4
	flame.material_override = fm
	# two patched starting tents
	for sx in [-100.0, 100.0]:
		var t := _make_tent_model()
		t.position = Vector3(sx, 0, -75)
		t.rotation_degrees.y = 180.0
		camp.add_child(t)
	# salvaged supplies by the fire
	_box(camp, Vector3(14, 10, 12), Vector3(34, 5, 28), Color("#8a6a40"))
	_box(camp, Vector3(12, 8, 10), Vector3(44, 14, 26), Color("#9a7a50"))
	_sphere(camp, 6.0, Vector3(-30, 6, 32), Color("#c8b48c"))
	_sphere(camp, 5.5, Vector3(-38, 5, 26), Color("#c8b48c"))
	# ruins of the old town around the terrace edge (the disaster)
	var wr := RandomNumberGenerator.new()
	wr.seed = WORLD_SEED + 7
	for i in range(18):
		var a := wr.randf() * TAU
		var r := wr.randf_range(410.0, 560.0)
		var p := camp_pos + Vector3(cos(a) * r, 0, sin(a) * r)
		var piece := Node3D.new()
		piece.position = Vector3(p.x, _height_at_world(p.x, p.z), p.z)
		piece.rotation_degrees.y = wr.randf_range(0.0, 360.0)
		terrain_root.add_child(piece)
		match i % 3:
			0:
				_box(piece, Vector3(44, 20, 8), Vector3(0, 8, 0), Color("#d9cdb0"), true)
				_box(piece, Vector3(14, 30, 8), Vector3(18, 13, 0), Color("#d9cdb0"), true)
			1:
				for k in range(4):
					var blk := _box(piece, Vector3(12, 8, 10), Vector3(wr.randf_range(-16, 16), 4, wr.randf_range(-12, 12)), Color("#cfc3a5"), true)
					blk.rotation_degrees = Vector3(wr.randf_range(-15, 15), wr.randf_range(0, 90), wr.randf_range(-15, 15))
			2:
				_cyl(piece, 2.0, 2.4, 26.0, Vector3(0, 12, 0), Color("#2f2a25"))
				var beam := _box(piece, Vector3(30, 3, 3), Vector3(6, 4, 4), Color("#2f2a25"))
				beam.rotation_degrees.y = 30.0


func _make_tent_model() -> Node3D:
	var m := Node3D.new()
	var cloth := _prism(m, Vector3(52, 34, 50), Vector3(0, 17, 0), Color("#d8c9a2"))
	cloth.rotation_degrees.y = 90.0
	var patch := _box(m, Vector3(16, 12, 1), Vector3(-12, 13, 18), Color("#9b6b4b"))
	patch.rotation_degrees.x = -26.0
	_box(m, Vector3(14, 22, 1), Vector3(0, 11, 25.4), Color("#4a3c2c"))
	_cyl(m, 1.4, 1.4, 40.0, Vector3(0, 20, 27), Color("#6b4f33"))
	_box(m, Vector3(10, 7, 9), Vector3(22, 3.5, 28), Color("#8a6a40"))
	return m


# ---------------------------------------------------------------- plots (dynamic — created on placement)

func _build_plots() -> void:
	# v2.0.0 free placement: no pre-created plot slabs.
	# Plots are created dynamically in _confirm_build().
	# Just initialise the material cache used by ghost and placed-slab rendering.
	plot_mats["built"] = _mat_alpha(Color(0.95, 0.89, 0.72, 0.25))
	plot_mats["target"] = _mat_alpha(Color(0.45, 0.9, 0.4, 0.6))
	plot_mats["invalid"] = _mat_alpha(Color(0.9, 0.3, 0.3, 0.5))


func _mat_alpha(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _refresh_plots() -> void:
	# Dynamic plots only hold placed buildings; just ensure slabs show as stone.
	for p in plots:
		if p.slab == null:
			continue
		if p.building != null:
			p.slab.visible = true
			p.slab.material_override = _stone_mat(Color("#e2d6b8"))


func _plot_at_point(pt: Vector3, margin: float = 18.0) -> Plot:
	for p in plots:
		if absf(pt.x - p.pos.x) <= p.size.x * 0.5 + margin and absf(pt.z - p.pos.z) <= p.size.y * 0.5 + margin:
			return p
	return null


# ─── Free Placement helpers ─────────────────────────────────────────────────

func _world_to_grid(wx: float, wz: float) -> Vector2i:
	return Vector2i(roundi((wx - camp_pos.x) / PLACE_CELL), roundi((wz - camp_pos.z) / PLACE_CELL))


func _grid_to_world(gx: int, gz: int) -> Vector3:
	return Vector3(camp_pos.x + float(gx) * PLACE_CELL, plateau_h, camp_pos.z + float(gz) * PLACE_CELL)


func _cells_for(gx: int, gz: int, cls: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	match cls:
		"S":
			cells.append(Vector2i(gx, gz))
		"M":
			cells.append(Vector2i(gx, gz))
			cells.append(Vector2i(gx + 1, gz))
		"L":
			cells.append(Vector2i(gx, gz))
			cells.append(Vector2i(gx + 1, gz))
			cells.append(Vector2i(gx, gz + 1))
			cells.append(Vector2i(gx + 1, gz + 1))
	return cells


func _can_place(gx: int, gz: int, cls: String, type: String = "") -> bool:
	var cells := _cells_for(gx, gz, cls)
	if cells.is_empty():
		return false
	var is_coastal := type != "" and BUILDINGS.has(type) and bool(BUILDINGS[type].get("coastal", false))
	var near_coast := false
	for cell in cells:
		if occupied_cells.has(cell):
			return false
		var wx := camp_pos.x + float(cell.x) * PLACE_CELL
		var wz := camp_pos.z + float(cell.y) * PLACE_CELL
		if Vector2(wx - camp_pos.x, wz - camp_pos.z).length() > PLAY_RADIUS:
			return false
		if is_coastal and wx < camp_pos.x - 200.0:
			near_coast = true
	if is_coastal and not near_coast:
		return false
	# Land value requirement
	var min_lv := float(MIN_LAND_VALUE_REQ.get(type, 0.0))
	if min_lv > 0.0 and _get_land_value(gx, gz) < min_lv:
		return false
	return true


func _create_dynamic_plot(gx: int, gz: int, cls: String) -> Plot:
	var p := Plot.new()
	p.idx = plots.size()
	p.cls = cls
	p.lv = 1
	p.gx = gx
	p.gz = gz
	p.size = PLOT_SIZES[cls]
	p.pos = _grid_to_world(gx, gz)
	p.node = Node3D.new()
	p.node.position = p.pos
	building_root.add_child(p.node)
	p.slab = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(p.size.x, 2.0, p.size.y)
	p.slab.mesh = bm
	p.slab.position = Vector3(0, 1.0, 0)
	p.slab.material_override = _stone_mat(Color("#e2d6b8"))
	p.node.add_child(p.slab)
	p.lock_label = Label3D.new()
	p.lock_label.visible = false
	p.node.add_child(p.lock_label)
	plots.append(p)
	for cell in _cells_for(gx, gz, cls):
		occupied_cells[cell] = true
	return p


# ---------------------------------------------------------------- dirt trails worn by walking

func _build_trails() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(TRAIL_CELL + 6.0, 0.6, TRAIL_CELL + 6.0)
	trail_mm = MultiMesh.new()
	trail_mm.transform_format = MultiMesh.TRANSFORM_3D
	trail_mm.mesh = mesh
	trail_mm.instance_count = TRAIL_MAX
	trail_mm.visible_instance_count = 0
	var node := MultiMeshInstance3D.new()
	node.multimesh = trail_mm
	node.material_override = _mat(Color("#9c8459"))
	terrain_root.add_child(node)


# ---------------------------------------------------------------- CS: land value, demand, coverage

func _get_land_value(gx: int, gz: int) -> float:
	return float(land_value.get(Vector2i(gx, gz), 0.0))


func _update_land_value() -> void:
	# Decay all cells toward 0
	var keys_to_erase: Array = []
	for k in land_value:
		land_value[k] = float(land_value[k]) - 1.2
		if float(land_value[k]) <= 0.0:
			keys_to_erase.append(k)
	for k in keys_to_erase:
		land_value.erase(k)
	# Radiate from completed buildings
	for b in buildings:
		if not b.done:
			continue
		if not LAND_VALUE_SOURCES.has(b.type):
			continue
		var src: Dictionary = LAND_VALUE_SOURCES[b.type]
		var radius: int = int(src["radius"])
		var delta: float = float(src["delta"])
		var pp: Plot = plots[b.plot]
		for dx in range(-radius, radius + 1):
			for dz in range(-radius, radius + 1):
				var dist := sqrt(float(dx * dx + dz * dz))
				if dist > float(radius) + 0.5:
					continue
				var falloff := 1.0 - dist / (float(radius) + 1.0)
				var cell := Vector2i(pp.gx + dx, pp.gz + dz)
				land_value[cell] = clampf(float(land_value.get(cell, 0.0)) + delta * falloff, 0.0, 100.0)
	if lv_overlay:
		_refresh_lv_overlay()


func _apply_service_coverage() -> void:
	service_xp_mult  = 1.0
	service_heal_mult = 1.0
	if survivors.is_empty():
		return
	var morale_add := 0.0
	var discont_add := 0.0
	var xp_add := 0.0
	var heal_add := 0.0
	var n := float(survivors.size())
	for b in buildings:
		if not b.done or not SERVICE_COVERAGE.has(b.type):
			continue
		var cov: Dictionary = SERVICE_COVERAGE[b.type]
		var rad: float = float(cov["radius"])
		var pp: Plot = plots[b.plot]
		var count_in_range := 0
		for v in survivors:
			var d := Vector2(v.node.position.x - pp.pos.x, v.node.position.z - pp.pos.z).length()
			if d <= rad:
				count_in_range += 1
		if count_in_range == 0:
			continue
		var coverage_ratio := float(count_in_range) / n
		if cov.has("morale"):
			morale_add += float(cov["morale"]) * coverage_ratio
		if cov.has("discontent"):
			discont_add += float(cov["discontent"]) * coverage_ratio
		if cov.has("heal_bonus"):
			heal_add += float(cov["heal_bonus"]) * coverage_ratio
		if cov.has("xp_bonus"):
			xp_add += float(cov["xp_bonus"]) * coverage_ratio
	morale = clampf(morale + morale_add, 0.0, 100.0)
	discontent = clampf(discontent + discont_add, 0.0, 100.0)
	if heal_add > 0.0:
		service_heal_mult = 1.0 + heal_add
	if xp_add > 0.0:
		service_xp_mult = 1.0 + xp_add


func _update_demand() -> void:
	var n := float(survivors.size())
	if n == 0.0:
		demand_housing = 0.0; demand_production = 0.0; demand_services = 0.0
		return
	# Housing: unsatisfied population fraction
	var cap := float(_housing_capacity())
	var unsatisfied := maxf(0.0, n - cap * 0.85)
	demand_housing = clampf(unsatisfied / n * 100.0 + (30.0 if cap < n * 1.2 else 0.0), 0.0, 100.0)
	# Production: resources below safety thresholds
	var shortage_score := 0.0
	if float(resources.get("Food",  0.0)) < n * FOOD_PER_VILLAGER  * 4.0: shortage_score += 35.0
	if float(resources.get("Water", 0.0)) < n * WATER_PER_VILLAGER * 4.0: shortage_score += 35.0
	if float(resources.get("Wood",  0.0)) < 25.0: shortage_score += 15.0
	if float(resources.get("Stone", 0.0)) < 25.0: shortage_score += 15.0
	demand_production = clampf(shortage_score, 0.0, 100.0)
	# Services: population vs service buildings coverage
	var svc_count := 0
	for b in buildings:
		if b.done and SERVICE_COVERAGE.has(b.type):
			svc_count += 1
	var ideal := maxf(1.0, n / 7.0)
	demand_services = clampf((1.0 - float(svc_count) / ideal) * 100.0, 0.0, 100.0)


func _toggle_lv_overlay() -> void:
	lv_overlay = not lv_overlay
	if lv_overlay:
		_refresh_lv_overlay()
		_toast("طبقة قيمة الأرض مفعّلة — أخضر = قيمة عالية، أحمر = منخفضة.", 4.0)
	else:
		if is_instance_valid(lv_overlay_root):
			lv_overlay_root.queue_free()
			lv_overlay_root = null
		_toast("أُخفيت طبقة قيمة الأرض.", 2.5)


func _refresh_lv_overlay() -> void:
	if is_instance_valid(lv_overlay_root):
		lv_overlay_root.queue_free()
	lv_overlay_root = Node3D.new()
	terrain_root.add_child(lv_overlay_root)
	var max_r := int(ceil(PLAY_RADIUS / PLACE_CELL)) + 1
	for gx in range(-max_r, max_r + 1):
		for gz in range(-max_r, max_r + 1):
			if Vector2(float(gx) * PLACE_CELL, float(gz) * PLACE_CELL).length() > PLAY_RADIUS + PLACE_CELL:
				continue
			var lv := float(land_value.get(Vector2i(gx, gz), 0.0))
			if lv < 2.0:
				continue
			var tile := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(PLACE_CELL * 0.85, 0.8, PLACE_CELL * 0.85)
			tile.mesh = bm
			tile.position = Vector3(camp_pos.x + float(gx) * PLACE_CELL, plateau_h + 1.8, camp_pos.z + float(gz) * PLACE_CELL)
			var t := lv / 100.0
			tile.material_override = _mat_alpha(Color(1.0 - t, 0.2 + t * 0.8, 0.1, 0.42))
			lv_overlay_root.add_child(tile)


func _toggle_road_mode() -> void:
	road_mode = not road_mode
	if road_mode:
		_hide_sheets()
		_toast("وضع رسم المسارات — المس أو اسحب على الأرض لرسم طريق ترابي.", 4.0)
	else:
		_toast("خرجت من وضع رسم المسارات.", 2.5)


func _paint_trail_at(screen_pos: Vector2) -> void:
	var hit: Variant = _ray_to_terrain(screen_pos)
	if hit == null:
		return
	var wp: Vector3 = hit
	var key := Vector2i(int(floor(wp.x / TRAIL_CELL)), int(floor(wp.z / TRAIL_CELL)))
	if trail_counts.get(key, 0.0) == -1.0:
		return
	if trail_used >= TRAIL_MAX:
		_toast("امتلأ الحد الأقصى لعدد المسارات.", 3.0)
		return
	var cx := (float(key.x) + 0.5) * TRAIL_CELL
	var cz := (float(key.y) + 0.5) * TRAIL_CELL
	var fr := _footing_range(cx, cz)
	trail_mm.set_instance_transform(trail_used, Transform3D(Basis(), Vector3(cx, (fr.x + fr.y) * 0.5 + 0.35, cz)))
	trail_used += 1
	trail_mm.visible_instance_count = trail_used
	trail_counts[key] = -1.0


func _note_step(flat: Vector3, dt: float) -> void:
	if trail_used >= TRAIL_MAX:
		return
	var key := Vector2i(int(floor(flat.x / TRAIL_CELL)), int(floor(flat.z / TRAIL_CELL)))
	var cur := float(trail_counts.get(key, 0.0))
	if cur < 0.0:
		return
	cur += dt
	if cur >= 2.5:
		var cx := (float(key.x) + 0.5) * TRAIL_CELL
		var cz := (float(key.y) + 0.5) * TRAIL_CELL
		var fr := _footing_range(cx, cz)
		if fr.y - fr.x < 14.0:
			trail_mm.set_instance_transform(trail_used, Transform3D(Basis(), Vector3(cx, (fr.x + fr.y) * 0.5 + 0.35, cz)))
			trail_used += 1
			trail_mm.visible_instance_count = trail_used
		trail_counts[key] = -1.0
	else:
		trail_counts[key] = cur


# ---------------------------------------------------------------- resource points

func _generate_sources() -> void:
	var wr := RandomNumberGenerator.new()
	wr.seed = WORLD_SEED
	var taken: Array[Vector2i] = [CAMP_CELL]
	for key in SOURCE_DEFS:
		var res: String = key
		var d: Dictionary = SOURCE_DEFS[res]
		var placed := 0
		var tries := 0
		while placed < int(d["count"]) and tries < 5000:
			tries += 1
			var cell := Vector2i(wr.randi_range(5, GRID - 2), wr.randi_range(2, GRID - 3))
			var dist := Vector2(cell - CAMP_CELL).length()
			if dist < float(d["min"]) or dist > float(d["max"]):
				continue
			if res == "Water" and (cell.x < 19 or cell.x > 25):
				continue
			if not _is_land(cell.x, cell.y):
				continue
			var too_close := false
			for t in taken:
				if Vector2(cell - t).length() < 2.0:
					too_close = true
					break
			if too_close:
				continue
			var v := _grid_vertex(cell.x, cell.y)
			var fr := _footing_range(v.x, v.z)
			if fr.y - fr.x > 40.0 or v.y > 330.0:
				continue
			taken.append(cell)
			var s := Source.new()
			s.res = res
			s.label = str(d["label"])
			s.pos = Vector3(v.x, fr.y, v.z)
			s.infinite = bool(d["infinite"])
			s.amount = float(d["amount"])
			s.max_amount = float(d["amount"])
			s.yield_amt = float(d["yield"])
			s.gather_time = float(d["time"])
			s.slots = 3
			s.regen = float(d["regen"])
			s.node = _make_source_visual(res)
			s.node.position = s.pos
			source_root.add_child(s.node)
			sources.append(s)
			placed += 1


func _add_building_source(b: Building) -> void:
	var def: Dictionary = BUILDINGS[b.type]
	var g: Dictionary = def["gather"]
	if g.is_empty():
		return
	var p: Plot = plots[b.plot]
	var s := Source.new()
	s.res = str(g["res"])
	s.label = str(def["ar"])
	s.pos = b.pos + Vector3(0, 0, p.size.y * 0.5 + 10.0)
	s.pos.y = _height_at_world(s.pos.x, s.pos.z)
	s.infinite = true
	s.yield_amt = float(g["yield"])
	s.gather_time = float(g["time"])
	s.slots = int(g["slots"])
	s.building = b
	sources.append(s)


# ---------------------------------------------------------------- building models

func _make_building_model(type: String) -> Node3D:
	var m := Node3D.new()
	var door := Color("#5a4632")
	var window := Color("#34444f")
	var cream := Color("#fff6e0")
	var wood := Color("#8a6a40")
	match type:
		"Tent":
			m.add_child(_make_tent_model())
		"Well":
			_cyl(m, 17.0, 18.0, 12.0, Vector3(0, 6, 0), Color.WHITE, true)
			_cyl(m, 13.0, 13.0, 1.5, Vector3(0, 12.5, 0), Color("#4aa3d9"))
			_cyl(m, 1.8, 1.8, 34.0, Vector3(-15, 17, 0), wood)
			_cyl(m, 1.8, 1.8, 34.0, Vector3(15, 17, 0), wood)
			var bar := _cyl(m, 1.5, 1.5, 34.0, Vector3(0, 33, 0), wood)
			bar.rotation_degrees.z = 90.0
			_cyl(m, 3.0, 3.0, 6.0, Vector3(0, 24, 0), Color("#7a5a35"))
			var tarp := _box(m, Vector3(40, 1.5, 22), Vector3(0, 36, 0), Color("#a3794f"))
			tarp.rotation_degrees.x = 8.0
		"Storehouse":
			_box(m, Vector3(52, 24, 42), Vector3(0, 12, 0), Color("#f4ead2"), true)
			var roof := _box(m, Vector3(58, 2.5, 48), Vector3(0, 26, 0), Color("#7f8a8a"))
			roof.rotation_degrees.x = 4.0
			_arch(m, -12, 0, 14, 19, 21.5, door)
			_arch(m, 12, 0, 14, 19, 21.5, door)
			for p in [Vector3(-22, 5, 28), Vector3(-14, 5, 30), Vector3(-18, 12, 29)]:
				_sphere(m, 5.0, p, Color("#d8c29a"))
			_box(m, Vector3(10, 8, 10), Vector3(22, 4, 28), wood)
			_box(m, Vector3(10, 8, 10), Vector3(22, 12, 28), Color("#9a7a50"))
		"Farm":
			for i in range(3):
				var h := 4.0 + 4.0 * float(i)
				var z := 18.0 - 18.0 * float(i)
				_box(m, Vector3(58, h, 4), Vector3(0, h * 0.5, z + 8.0), Color.WHITE, true)
				_box(m, Vector3(58, 2, 15), Vector3(0, h + 1.0, z), Color("#6b4f33"))
				for k in range(3):
					_box(m, Vector3(50, 3, 2.6), Vector3(0, h + 3.0, z - 4.0 + 4.0 * float(k)), Color("#86b552"))
			_box(m, Vector3(8, 10, 8), Vector3(-25, 5, 26), Color("#ffffff"), true)
		"Olive Grove":
			_box(m, Vector3(60, 1.5, 54), Vector3(0, 0.8, 0), Color("#b9a878"))
			_box(m, Vector3(60, 4, 3), Vector3(0, 2, 27), Color.WHITE, true)
			_box(m, Vector3(60, 4, 3), Vector3(0, 2, -27), Color.WHITE, true)
			_box(m, Vector3(3, 4, 54), Vector3(30, 2, 0), Color.WHITE, true)
			_box(m, Vector3(3, 4, 54), Vector3(-30, 2, 0), Color.WHITE, true)
			for p in [Vector3(-17, 0, -13), Vector3(17, 0, -13), Vector3(0, 0, 0), Vector3(-17, 0, 13), Vector3(17, 0, 13)]:
				_cyl(m, 1.8, 2.8, 11.0, p + Vector3(0, 5.5, 0), Color("#7a6648"))
				_sphere(m, 7.5, p + Vector3(-2, 15, 0), Color("#7d8f5a"))
				_sphere(m, 6.0, p + Vector3(3, 17, 2), Color("#6d7d4c"))
		"Stone House":
			_box(m, Vector3(46, 28, 40), Vector3(0, 14, 0), Color.WHITE, true)
			_box(m, Vector3(50, 3, 44), Vector3(0, 29.5, 0), cream, true)
			_parapet(m, 50.0, 44.0, 31.0)
			_dome(m, 12.0, Vector3(-8, 31, -5))
			_arch(m, 0, 0, 13, 20, 20.5, door)
			_arch(m, -14, 10, 7, 11, 20.5, window)
			_arch(m, 14, 10, 7, 11, 20.5, window)
			_box(m, Vector3(3, 14, 3), Vector3(18, 38, 12), Color("#2f6f2f"))
		"Quarry":
			_box(m, Vector3(56, 7, 22), Vector3(0, 3.5, -15), Color.WHITE, true)
			_box(m, Vector3(42, 6, 18), Vector3(0, 10, -17), cream, true)
			_box(m, Vector3(28, 5, 14), Vector3(0, 15.5, -19), Color.WHITE, true)
			var b1 := _box(m, Vector3(13, 9, 11), Vector3(-18, 4.5, 12), cream, true)
			b1.rotation_degrees.y = 15.0
			var b2 := _box(m, Vector3(11, 7, 9), Vector3(14, 3.5, 15), Color.WHITE, true)
			b2.rotation_degrees.y = -20.0
			_cyl(m, 1.6, 1.6, 32.0, Vector3(24, 16, 4), wood)
			_box(m, Vector3(28, 2, 2), Vector3(11, 32, 4), wood)
		"Workshop":
			_box(m, Vector3(48, 22, 38), Vector3(0, 11, 0), Color.WHITE, true)
			var vault := _cyl(m, 19.0, 19.0, 48.0, Vector3(0, 22, 0), cream, true)
			vault.rotation_degrees.z = 90.0
			_box(m, Vector3(7, 18, 7), Vector3(15, 36, -9), Color("#f4ead2"), true)
			_arch(m, 0, 0, 18, 18, 19.5, door)
			var awning := _box(m, Vector3(26, 1.5, 12), Vector3(0, 19, 26), Color("#a3794f"))
			awning.rotation_degrees.x = -12.0
			_box(m, Vector3(10, 6, 8), Vector3(-17, 3, 26), Color("#5b5b5b"))
		"Small House":
			_box(m, Vector3(32, 20, 28), Vector3(0, 10, 0), Color.WHITE, true)
			_box(m, Vector3(36, 2.5, 32), Vector3(0, 22.5, 0), cream, true)
			_parapet(m, 36.0, 32.0, 23.5)
			_arch(m, 0, 0, 9, 14, 15.0, door)
			_arch(m, -10, 8, 5, 8, 15.0, window)
			_arch(m, 10, 8, 5, 8, 15.0, window)
		"Small Quarry":
			_box(m, Vector3(34, 5, 16), Vector3(0, 2.5, -8), Color.WHITE, true)
			_box(m, Vector3(24, 4, 12), Vector3(0, 8, -10), cream, true)
			_cyl(m, 1.5, 1.5, 28.0, Vector3(14, 14, 2), wood)
			var bar2 := _cyl(m, 1.2, 1.2, 26.0, Vector3(6, 26, 2), wood)
			bar2.rotation_degrees.z = 90.0
			_box(m, Vector3(8, 5, 6), Vector3(-13, 2.5, 10), Color.WHITE, true)
		"Kitchen":
			_box(m, Vector3(46, 20, 38), Vector3(0, 10, 0), Color.WHITE, true)
			_box(m, Vector3(50, 2.5, 42), Vector3(0, 22, 0), cream, true)
			_arch(m, 0, 0, 14, 18, 20.5, door)
			_box(m, Vector3(8, 30, 8), Vector3(-16, 10, -16), Color.WHITE, true)
			_box(m, Vector3(12, 3, 12), Vector3(-16, 36, -16), Color("#5a5a5a"))
			_box(m, Vector3(22, 5, 18), Vector3(12, 2.5, 14), Color("#7a6648"))
			for fk in range(3):
				_cyl(m, 2.5, 2.5, 5.0, Vector3(-5.0 + float(fk) * 5.0, 10.0, 14.0), Color("#c04020"))
		"Pen":
			_box(m, Vector3(50, 2, 44), Vector3(0, 1, 0), Color("#b8a070"))
			for px in [-22, 22]:
				_box(m, Vector3(3, 14, 44), Vector3(float(px), 8, 0), Color.WHITE, true)
			_box(m, Vector3(50, 14, 3), Vector3(0, 8, -22), Color.WHITE, true)
			_box(m, Vector3(50, 14, 3), Vector3(0, 8, 22), Color.WHITE, true)
			_arch(m, 0, 0, 10, 14, 22.5, door)
			_box(m, Vector3(18, 16, 14), Vector3(-15, 8, -16), Color.WHITE, true)
			_box(m, Vector3(20, 2, 16), Vector3(-15, 17.5, -16), Color("#8a7050"))
			for ak in [Vector3(-4, 0, 5), Vector3(5, 0, -5)]:
				_sphere(m, 5.0, ak + Vector3(0, 8, 16), Color("#d4b060"))
		"Stable":
			_box(m, Vector3(50, 22, 42), Vector3(0, 11, 0), Color.WHITE, true)
			var sroof := _box(m, Vector3(56, 3, 48), Vector3(0, 24.5, 0), Color("#7a8888"))
			sroof.rotation_degrees.x = 3.0
			_arch(m, 0, 0, 16, 20, 22.5, door)
			_arch(m, -16, 8, 8, 12, 22.5, window)
			_arch(m, 16, 8, 8, 12, 22.5, window)
			for si in range(3):
				_box(m, Vector3(2.5, 10, 36), Vector3(-18.0 + float(si) * 18.0, 5, 2), Color("#b0905a"))
		"Olive Press":
			_box(m, Vector3(44, 18, 38), Vector3(0, 9, 0), Color.WHITE, true)
			var oproof := _cyl(m, 18.0, 18.0, 44.0, Vector3(0, 18, 0), cream, true)
			oproof.rotation_degrees.z = 90.0
			_arch(m, 0, 0, 14, 16, 19.5, door)
			_cyl(m, 10.0, 10.0, 5.0, Vector3(0, 2.5, 6), Color("#8a7048"))
			_cyl(m, 3.0, 3.0, 36.0, Vector3(10, 10, 6), Color.WHITE, true)
			_box(m, Vector3(4, 4, 4), Vector3(-12, 2, -10), Color("#c04820"))
		"Large House":
			_box(m, Vector3(56, 30, 48), Vector3(0, 15, 0), Color.WHITE, true)
			_box(m, Vector3(60, 3, 52), Vector3(0, 31.5, 0), cream, true)
			_parapet(m, 60.0, 52.0, 33.0)
			_dome(m, 14.0, Vector3(-10, 33, -10))
			_dome(m, 11.0, Vector3(14, 33, 8))
			_arch(m, 0, 0, 14, 22, 24.5, door)
			_arch(m, -18, 10, 8, 12, 24.5, window)
			_arch(m, 18, 10, 8, 12, 24.5, window)
			_arch(m, 0, 10, 8, 12, 24.5, window)
			_box(m, Vector3(4, 20, 4), Vector3(22, 42, 18), Color("#3a7a3a"))
		"Diwan":
			_box(m, Vector3(60, 28, 50), Vector3(0, 14, 0), Color.WHITE, true)
			_box(m, Vector3(66, 3.5, 56), Vector3(0, 29.5, 0), cream, true)
			_parapet(m, 66.0, 56.0, 31.5)
			for dk in [-14, 0, 14]:
				_dome(m, 12.0, Vector3(float(dk), 33, -8))
			_arch(m, 0, 0, 18, 24, 26.5, door)
			_arch(m, -20, 10, 10, 14, 26.5, window)
			_arch(m, 20, 10, 10, 14, 26.5, window)
			_box(m, Vector3(70, 5, 5), Vector3(0, 4, 26), Color("#c09040"))
			_box(m, Vector3(5, 40, 5), Vector3(-30, 20, 26), Color.WHITE, true)
			_box(m, Vector3(5, 40, 5), Vector3(30, 20, 26), Color.WHITE, true)
		"Fishing Dock":
			var sea := Color("#4a7a90")
			var plank := Color("#7a5a30")
			# Main pier deck
			_box(m, Vector3(60, 3, 24), Vector3(0, 1.5, -16), plank)
			# Pier posts / pylons
			for fpx in [-25.0, -10.0, 10.0, 25.0]:
				for fpz in [-22.0, -10.0]:
					_cyl(m, 2.0, 2.0, 20.0, Vector3(fpx, -8.0, fpz), Color("#6a4820"))
			# Pier extension forward
			_box(m, Vector3(20, 2.5, 30), Vector3(0, 1.2, -34), plank)
			for fpx2 in [-8.0, 8.0]:
				_cyl(m, 1.8, 1.8, 20.0, Vector3(fpx2, -8.0, -44.0), Color("#6a4820"))
			# Fishing hut
			_box(m, Vector3(26, 14, 20), Vector3(-16, 8, 2), Color.WHITE, true)
			var shutroof := _box(m, Vector3(30, 2, 24), Vector3(-16, 16, 2), Color("#8a7050"))
			shutroof.rotation_degrees.x = 5.0
			_arch(m, -16, 0, 9, 13, 12.5, door)
			# Nets on poles
			var np1 := _box(m, Vector3(1.5, 1.5, 24), Vector3(16, 18, -12), Color("#c8b890"))
			np1.rotation_degrees.z = 12.0
			_cyl(m, 1.2, 1.2, 22.0, Vector3(6, 11, -6), plank)
			_cyl(m, 1.2, 1.2, 22.0, Vector3(26, 11, -6), plank)
			# Water surface hint
			_box(m, Vector3(64, 1.0, 60), Vector3(0, -1.5, -18), sea)
		"Khan":
			# Large central building
			_box(m, Vector3(62, 32, 52), Vector3(0, 16, 0), Color.WHITE, true)
			_box(m, Vector3(68, 3.5, 58), Vector3(0, 33.5, 0), cream, true)
			_parapet(m, 68.0, 58.0, 35.0)
			# Four corner towers
			for kx in [-28, 28]:
				for kz in [-22, 22]:
					_box(m, Vector3(12, 38, 12), Vector3(float(kx), 19, float(kz)), Color.WHITE, true)
					_dome(m, 7.0, Vector3(float(kx), 38, float(kz)))
			# Central dome
			_dome(m, 16.0, Vector3(0, 35, -8))
			# Grand entrance arch
			_arch(m, 0, 0, 18, 26, 27.5, door)
			# Side arched windows
			for kwa in [-20, 20]:
				_arch(m, kwa, 10, 9, 13, 27.5, window)
			# Inner courtyard hint (recessed floor)
			_box(m, Vector3(36, 2, 28), Vector3(0, 1.5, 4), Color("#d8c8a0"))
			# Decorative columns
			for kcol in [-14, 14]:
				_cyl(m, 2.5, 2.5, 32.0, Vector3(float(kcol), 16, 27), Color.WHITE, true)
				_sphere(m, 3.5, Vector3(float(kcol), 33, 27), cream)
		"Mosque":
			# Main prayer hall
			_box(m, Vector3(52, 26, 44), Vector3(0, 13, 0), Color.WHITE, true)
			_box(m, Vector3(56, 3, 48), Vector3(0, 27.5, 0), cream, true)
			_parapet(m, 56.0, 48.0, 29.5)
			# Central large dome
			_dome(m, 16.0, Vector3(0, 31, -4))
			# Two smaller side domes
			_dome(m, 9.0, Vector3(-18, 31, 6))
			_dome(m, 9.0, Vector3(18, 31, 6))
			# Minaret (tall cylinder + cap)
			_cyl(m, 4.5, 4.5, 52.0, Vector3(-24, 26, -18), Color.WHITE, true)
			_cyl(m, 5.5, 3.5, 8.0, Vector3(-24, 80, -18), Color("#4a9a6a"))
			_sphere(m, 4.0, Vector3(-24, 90, -18), Color("#c8a820"))
			# Grand arched entrance
			_arch(m, 0, 0, 16, 22, 23.5, door)
			_arch(m, -16, 8, 8, 12, 23.5, window)
			_arch(m, 16, 8, 8, 12, 23.5, window)
		"Clinic":
			# Stone building with courtyard
			_box(m, Vector3(48, 24, 40), Vector3(0, 12, 0), Color.WHITE, true)
			_box(m, Vector3(52, 2.5, 44), Vector3(0, 25.5, 0), cream, true)
			_parapet(m, 52.0, 44.0, 27.0)
			_arch(m, 0, 0, 14, 18, 21.5, door)
			_arch(m, -14, 9, 7, 11, 21.5, window)
			_arch(m, 14, 9, 7, 11, 21.5, window)
			# Red cross sign on wall
			_box(m, Vector3(3, 12, 3), Vector3(0, 16, 21), Color("#d43030"))
			_box(m, Vector3(12, 3, 3), Vector3(0, 16, 21), Color("#d43030"))
			# Small dome over entrance
			_dome(m, 8.0, Vector3(0, 28, -8))
			# Herb garden patches
			for hp in [Vector3(-18, 1, 14), Vector3(18, 1, 14)]:
				_box(m, Vector3(10, 3, 8), hp, Color("#7a9a50"))
		"School":
			# Long rectangular hall
			_box(m, Vector3(54, 22, 42), Vector3(0, 11, 0), Color.WHITE, true)
			_box(m, Vector3(58, 2.5, 46), Vector3(0, 23.5, 0), cream, true)
			_parapet(m, 58.0, 46.0, 25.0)
			_arch(m, 0, 0, 14, 18, 22.5, door)
			# Row of arched windows
			for wx2 in [-20, -7, 7, 20]:
				_arch(m, wx2, 8, 6, 10, 22.5, window)
			# Small bell tower
			_box(m, Vector3(10, 22, 10), Vector3(20, 11, -16), Color.WHITE, true)
			_box(m, Vector3(12, 3, 12), Vector3(20, 24, -16), Color("#8a7850"))
			# Courtyard tree
			_cyl(m, 2.0, 3.0, 14.0, Vector3(-18, 7, 14), Color("#6a5038"))
			_sphere(m, 8.0, Vector3(-18, 18, 14), Color("#5a7a3a"))
		"Town Square":
			# Central paved area
			_box(m, Vector3(68, 2, 62), Vector3(0, 1, 0), Color("#d8caa8"))
			# Four low walls defining the square
			for tsw in [Vector3(0, 6, 28), Vector3(0, 6, -28)]:
				_box(m, Vector3(70, 10, 4), tsw, Color.WHITE, true)
			for tsw2 in [Vector3(32, 6, 0), Vector3(-32, 6, 0)]:
				_box(m, Vector3(4, 10, 62), tsw2, Color.WHITE, true)
			# Central decorative column/fountain
			_cyl(m, 5.0, 5.0, 18.0, Vector3(0, 9, 0), Color.WHITE, true)
			_sphere(m, 6.0, Vector3(0, 22, 0), Color("#4a9aaa"))
			# Corner olive trees
			for tp in [Vector3(-20, 0, -16), Vector3(20, 0, -16), Vector3(-20, 0, 16), Vector3(20, 0, 16)]:
				_cyl(m, 2.0, 2.8, 12.0, tp + Vector3(0, 6, 0), Color("#7a6648"))
				_sphere(m, 6.0, tp + Vector3(0, 16, 0), Color("#6a8050"))
			# Bench stones
			for bp in [Vector3(-14, 3, 22), Vector3(14, 3, 22)]:
				_box(m, Vector3(14, 5, 5), bp, Color.WHITE, true)
		"Watchtower":
			# Base foundation
			_box(m, Vector3(26, 8, 26), Vector3(0, 4, 0), Color.WHITE, true)
			# Main tower shaft
			_cyl(m, 9.0, 9.0, 64.0, Vector3(0, 36, 0), Color.WHITE, true)
			# Battlement top
			_box(m, Vector3(22, 8, 22), Vector3(0, 72, 0), Color.WHITE, true)
			_parapet(m, 22.0, 22.0, 76.0)
			# Arched doorway
			_arch(m, 0, 0, 7, 12, 9.5, door)
			# Arrow slits
			for sl in [0, 90, 180, 270]:
				var slx := sin(deg_to_rad(float(sl))) * 9.0
				var slz := cos(deg_to_rad(float(sl))) * 9.0
				_box(m, Vector3(3, 8, 2.5), Vector3(slx, 50, slz), window)
			# Flag pole
			_cyl(m, 1.2, 1.2, 22.0, Vector3(6, 76, 6), Color("#8a6a40"))
			_box(m, Vector3(12, 8, 1.5), Vector3(12, 86, 6), Color("#c83030"))
		"Plaza":
			# Paved circular-ish area
			_cyl(m, 32.0, 32.0, 3.0, Vector3(0, 1.5, 0), Color("#c8b888"))
			# Low border ring
			_cyl(m, 34.0, 34.0, 4.0, Vector3(0, 2, 0), Color.WHITE, true)
			_cyl(m, 30.0, 30.0, 4.0, Vector3(0, 2, 0), Color("#c8b888"))
			# Central feature: star of Bethlehem stone pattern + small fountain
			_cyl(m, 6.0, 6.0, 6.0, Vector3(0, 4, 0), Color("#4a8a9a"))
			_sphere(m, 5.0, Vector3(0, 10, 0), Color("#4aaacc"))
			# Benches around edge
			for ba in range(4):
				var angle := float(ba) * 90.0
				var bx := sin(deg_to_rad(angle)) * 22.0
				var bz := cos(deg_to_rad(angle)) * 22.0
				_box(m, Vector3(12, 5, 5), Vector3(bx, 3, bz), Color.WHITE, true)
			# Olive trees at four points
			for ta in [45, 135, 225, 315]:
				var tx := sin(deg_to_rad(float(ta))) * 26.0
				var tz := cos(deg_to_rad(float(ta))) * 26.0
				_cyl(m, 1.8, 2.5, 10.0, Vector3(tx, 5, tz), Color("#7a6648"))
				_sphere(m, 5.5, Vector3(tx, 14, tz), Color("#6a8050"))
		"Library":
			# Stone hall with rows of arched windows
			_box(m, Vector3(50, 26, 44), Vector3(0, 13, 0), Color.WHITE, true)
			_box(m, Vector3(54, 3, 48), Vector3(0, 27.5, 0), cream, true)
			_parapet(m, 54.0, 48.0, 29.5)
			# Two domes over reading rooms
			_dome(m, 11.0, Vector3(-12, 29, -6))
			_dome(m, 11.0, Vector3(12, 29, -6))
			# Grand entrance with columns
			_arch(m, 0, 0, 14, 20, 23.5, door)
			for lcol in [-18, -9, 9, 18]:
				_cyl(m, 2.2, 2.2, 24.0, Vector3(float(lcol), 12, 23), Color.WHITE, true)
				_sphere(m, 3.0, Vector3(float(lcol), 25, 23), cream)
			# Side arched windows
			for lw in [-15, 0, 15]:
				_arch(m, lw, 8, 7, 11, 23.5, window)
			# Scroll/book shelves hint on side
			for row_l in range(3):
				_box(m, Vector3(3, 8, 32), Vector3(-24, float(row_l) * 9 + 5, 0), Color("#8a6a40"))
	return m


func _make_scaffold(w: float, d: float) -> Node3D:
	var s := Node3D.new()
	var wood := Color("#8a6a40")
	for sx in [-0.5, 0.5]:
		for sz in [-0.5, 0.5]:
			_cyl(s, 2.0, 2.0, 50.0, Vector3(sx * w * 0.86, 26, sz * d * 0.86), wood)
	_box(s, Vector3(w * 0.9, 2.5, 2.5), Vector3(0, 46, -d * 0.43), wood)
	_box(s, Vector3(w * 0.9, 2.5, 2.5), Vector3(0, 46, d * 0.43), wood)
	return s


func _build_ghost() -> void:
	ghost = Node3D.new()
	ghost.visible = false
	add_child(ghost)
	ghost_mesh = MeshInstance3D.new()
	ghost_mesh.mesh = BoxMesh.new()
	ghost_mat = _mat_alpha(Color(0.3, 0.9, 0.3, 0.45))
	ghost_mesh.material_override = ghost_mat
	ghost.add_child(ghost_mesh)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 700.0
	camera.near = 10.0
	camera.far = 12000.0
	add_child(camera)
	camera_target = Vector3(camp_pos.x, 0.0, camp_pos.z)
	_update_camera()
	camera.current = true


# ---------------------------------------------------------------- settings

func _load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) == OK:
		text_size_index = clampi(int(cf.get_value("ui", "text_size", 1)), 0, TEXT_SIZES.size() - 1)
	_apply_text_size()


func _apply_text_size() -> void:
	get_tree().root.content_scale_factor = float(TEXT_SIZES[text_size_index])


func _cycle_text_size() -> void:
	text_size_index = (text_size_index + 1) % TEXT_SIZES.size()
	_apply_text_size()
	var cf := ConfigFile.new()
	cf.set_value("ui", "text_size", text_size_index)
	cf.save(SETTINGS_PATH)
	text_size_btn.text = "حجم الخط: %s" % TEXT_SIZE_AR[text_size_index]


# ---------------------------------------------------------------- UI building blocks

func _style(bg: Color, radius: int = 16, border: Color = Color(0, 0, 0, 0), bw: int = 0, margin: int = 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = margin * 0.7
	s.content_margin_bottom = margin * 0.7
	if bw > 0:
		s.set_border_width_all(bw)
		s.border_color = border
	return s


func _btn_style(bg: Color, pressed: bool = false) -> StyleBoxFlat:
	var s := _style(bg, 14, bg.darkened(0.35), 0, 12)
	s.border_width_bottom = 1 if pressed else 4
	s.border_color = bg.darkened(0.45)
	if pressed:
		s.content_margin_top += 3
	return s


func _panel_style() -> StyleBoxFlat:
	var s := _style(C_PANEL, 22, C_BORDER, 1, 14)
	s.shadow_color = Color(0, 0, 0, 0.55)
	s.shadow_size = 16
	s.shadow_offset = Vector2(0, 5)
	return s


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = ar_font
	t.default_font_size = 22
	t.set_stylebox("normal", "Button", _btn_style(C_BTN))
	t.set_stylebox("hover", "Button", _btn_style(C_BTN.lightened(0.1)))
	t.set_stylebox("pressed", "Button", _btn_style(C_BTN.darkened(0.1), true))
	t.set_stylebox("disabled", "Button", _btn_style(Color("#3a3d33")))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", C_CREAM)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color("#8a8a7a"))
	t.set_stylebox("panel", "PanelContainer", _panel_style())
	t.set_color("font_color", "Label", C_CREAM)
	t.set_stylebox("background", "ProgressBar", _style(Color(1, 1, 1, 0.12), 6, Color(0, 0, 0, 0), 0, 0))
	t.set_stylebox("fill", "ProgressBar", _style(C_GOLD, 6, Color(0, 0, 0, 0), 0, 0))
	return t


func _label(text: String, size: int, color: Color = C_CREAM) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(text: String, cb: Callable, min_size: Vector2 = Vector2(0, 60), fsize: int = 22, color: Color = C_BTN) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", fsize)
	if color != C_BTN:
		b.add_theme_stylebox_override("normal", _btn_style(color))
		b.add_theme_stylebox_override("hover", _btn_style(color.lightened(0.1)))
		b.add_theme_stylebox_override("pressed", _btn_style(color.darkened(0.1), true))
	b.pressed.connect(cb)
	return b


func _icon_button(kind: String, cb: Callable, size: float = 52.0) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(size, size)
	b.pressed.connect(cb)
	var ic := IconCanvas.new()
	ic.kind = kind
	ic.set_anchors_preset(Control.PRESET_FULL_RECT)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(ic)
	return b


func _dock_button(kind: String, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(132, 82)
	b.pressed.connect(cb)
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 0)
	b.add_child(vb)
	var ic := IconCanvas.new()
	ic.kind = kind
	ic.custom_minimum_size = Vector2(0, 36)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(ic)
	var l := _label(text, 19)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(l)
	return b


func _dot(color: Color, d: float = 12.0) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(d, d)
	p.add_theme_stylebox_override("panel", _style(color, int(d), Color(0, 0, 0, 0), 0, 0))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return p


func _bar(color: Color, w: float = 100.0, h: float = 8.0) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(w, h)
	bar.show_percentage = false
	bar.max_value = 100.0
	bar.add_theme_stylebox_override("fill", _style(color, 6, Color(0, 0, 0, 0), 0, 0))
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bar


func _anchored_panel(preset: int) -> PanelContainer:
	var p := PanelContainer.new()
	p.set_anchors_preset(preset)
	ui_root.add_child(p)
	return p


# ---------------------------------------------------------------- UI layout

func _build_ui() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	ui_root = Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.theme = _make_theme()
	ui_root.layout_direction = Control.LAYOUT_DIRECTION_RTL
	hud.add_child(ui_root)
	_build_top_bar()
	_build_goal_banner()
	_build_crisis_overlay()
	_build_workers_sheet()
	_build_missions_sheet()
	_build_build_sheet()
	_build_log_sheet()
	_build_villages_sheet()
	_build_dock()
	_build_place_bar()
	_build_inspect_bar()
	_build_pause_banner()
	_build_toast()
	_build_menu()
	_build_game_over()
	_build_start_screen()


func _build_top_bar() -> void:
	var top := _anchored_panel(Control.PRESET_TOP_WIDE)
	top.offset_left = 12
	top.offset_right = -12
	top.offset_top = 10
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	top.add_child(row)
	# settlement level badge (rightmost in RTL)
	var lvbox := HBoxContainer.new()
	lvbox.add_theme_constant_override("separation", 6)
	row.add_child(lvbox)
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(40, 40)
	badge.add_theme_stylebox_override("panel", _style(Color("#6b5a2a"), 20, C_GOLD, 2, 0))
	lvbox.add_child(badge)
	level_label = _label("1", 24, Color.WHITE)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.add_theme_constant_override("outline_size", 2)
	level_label.add_theme_color_override("font_outline_color", C_GOLD.darkened(0.5))
	badge.add_child(level_label)
	var lvcol := VBoxContainer.new()
	lvcol.add_theme_constant_override("separation", 2)
	lvcol.alignment = BoxContainer.ALIGNMENT_CENTER
	lvbox.add_child(lvcol)
	lvcol.add_child(_label("المخيم", 13, C_GOLD))
	xp_bar = _bar(C_GOLD, 60.0, 6.0)
	lvcol.add_child(xp_bar)
	for r in RES_TOP_BAR:
		row.add_child(_res_chip(r))
	var popc := VBoxContainer.new()
	popc.add_theme_constant_override("separation", -2)
	row.add_child(popc)
	popc.add_child(_label("السكان", 13, C_MUTED))
	pop_label = _label("5/6", 22, Color.WHITE)
	pop_label.add_theme_constant_override("outline_size", 1)
	pop_label.add_theme_color_override("font_outline_color", Color("#6a9a5a"))
	popc.add_child(pop_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)
	var dayc := VBoxContainer.new()
	dayc.add_theme_constant_override("separation", 2)
	dayc.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(dayc)
	day_label = _label("اليوم 1", 20, C_CREAM)
	day_label.add_theme_constant_override("outline_size", 1)
	day_label.add_theme_color_override("font_outline_color", C_BORDER.darkened(0.3))
	dayc.add_child(day_label)
	day_bar = _bar(Color("#e9a24a"), 65.0, 5.0)
	dayc.add_child(day_bar)
	var seac := VBoxContainer.new()
	seac.add_theme_constant_override("separation", 0)
	seac.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(seac)
	season_label = _label(SEASON_AR[0], 14, SEASON_COLOR[0])
	season_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	season_label.add_theme_constant_override("outline_size", 2)
	season_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.5))
	seac.add_child(season_label)
	var pb := _icon_button("pause", _toggle_pause)
	pause_icon = pb.get_child(0)
	row.add_child(pb)
	speed_btn = _button("×1", _cycle_speed, Vector2(50, 44), 18)
	row.add_child(speed_btn)
	row.add_child(_icon_button("menu", _open_menu))


func _res_chip(res: String) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	col.add_child(row)
	row.add_child(_dot(RES_COLORS[res], 10.0))
	var v := _label("0", 22, Color.WHITE)
	v.add_theme_constant_override("outline_size", 1)
	v.add_theme_color_override("font_outline_color", RES_COLORS[res].darkened(0.4))
	v.add_theme_font_size_override("bold_font_size", 22)
	row.add_child(v)
	res_value_labels[res] = v
	var tr := _label("", 13, RES_COLORS[res])
	tr.name = "trend_" + res
	row.add_child(tr)
	trend_labels[res] = tr
	var name_lbl := _label(RES_AR[res], 14, RES_COLORS[res].lightened(0.25))
	name_lbl.add_theme_constant_override("outline_size", 1)
	name_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.6))
	col.add_child(name_lbl)
	if res == "Food" or res == "Water":
		var dl := _label("", 11, C_MUTED)
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(dl)
		days_labels[res] = dl
	return col


func _build_goal_banner() -> void:
	var p := _anchored_panel(Control.PRESET_CENTER_TOP)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.offset_top = 92
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", _style(Color(0.09, 0.105, 0.075, 0.75), 18, C_BORDER, 1, 12))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(row)
	row.add_child(_label("الهدف:", 18, C_GOLD))
	goal_label = _label("", 18)
	row.add_child(goal_label)


func _sheet(preset: int) -> PanelContainer:
	var p := _anchored_panel(preset)
	p.visible = false
	return p


func _build_workers_sheet() -> void:
	workers_sheet = _sheet(Control.PRESET_CENTER_BOTTOM)
	workers_sheet.grow_horizontal = Control.GROW_DIRECTION_BOTH
	workers_sheet.grow_vertical = Control.GROW_DIRECTION_BEGIN
	workers_sheet.offset_bottom = -116
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(760, 0)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	workers_sheet.add_child(box)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 20)
	box.add_child(title_row)
	title_row.add_child(_label("العمال", 30, C_GOLD))
	var status_right := HBoxContainer.new()
	status_right.add_theme_constant_override("separation", 20)
	status_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(status_right)
	var mcol := VBoxContainer.new()
	mcol.add_child(_label("المعنويات", 16, C_MUTED))
	morale_bar = _bar(Color("#5aa0d0"), 130.0, 10.0)
	mcol.add_child(morale_bar)
	status_right.add_child(mcol)
	var hcol := VBoxContainer.new()
	hcol.add_child(_label("الصحة", 16, C_MUTED))
	health_bar = _bar(Color("#d0644a"), 130.0, 10.0)
	hcol.add_child(health_bar)
	status_right.add_child(hcol)
	var hope_col := VBoxContainer.new()
	hope_col.add_child(_label("الأمل", 16, C_MUTED))
	var hope_bar := _bar(Color("#7fc04f"), 130.0, 10.0)
	hope_bar.name = "HopeBar"
	hope_col.add_child(hope_bar)
	status_right.add_child(hope_col)
	var disc_col := VBoxContainer.new()
	disc_col.add_child(_label("السخط", 16, C_MUTED))
	var disc_bar := _bar(Color("#c04a3a"), 130.0, 10.0)
	disc_bar.name = "DiscontentBar"
	disc_col.add_child(disc_bar)
	status_right.add_child(disc_col)
	var jobs_row := HBoxContainer.new()
	jobs_row.add_theme_constant_override("separation", 14)
	box.add_child(jobs_row)
	for r in START_JOBS:
		jobs_row.add_child(_job_row(r))
	free_label = _label("", 20, Color("#cfe0a0"))
	box.add_child(free_label)


func _job_row(res: String) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.custom_minimum_size = Vector2(140, 0)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	col.add_child(top)
	top.add_child(_dot(RES_COLORS[res], 13.0))
	var name_l := _label(RES_AR[res], 20)
	top.add_child(name_l)
	var rate := _label("", 16, C_MUTED)
	rate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(rate)
	job_rate_labels[res] = rate
	var ctrl_row := HBoxContainer.new()
	ctrl_row.add_theme_constant_override("separation", 6)
	ctrl_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(ctrl_row)
	ctrl_row.add_child(_icon_button("minus", _change_job.bind(res, -1), 62.0))
	var cnt := _label("0", 28, Color.WHITE)
	cnt.custom_minimum_size = Vector2(40, 0)
	cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cnt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ctrl_row.add_child(cnt)
	job_count_labels[res] = cnt
	ctrl_row.add_child(_icon_button("plus", _change_job.bind(res, 1), 62.0))
	return col


func _build_missions_sheet() -> void:
	missions_sheet = _sheet(Control.PRESET_CENTER_BOTTOM)
	missions_sheet.grow_horizontal = Control.GROW_DIRECTION_BOTH
	missions_sheet.grow_vertical = Control.GROW_DIRECTION_BEGIN
	missions_sheet.offset_bottom = -116
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(520, 0)
	box.add_theme_constant_override("separation", 6)
	missions_sheet.add_child(box)
	box.add_child(_label("المهام", 28, C_GOLD))
	missions_list = VBoxContainer.new()
	missions_list.add_theme_constant_override("separation", 6)
	box.add_child(missions_list)


func _build_build_sheet() -> void:
	build_sheet = _sheet(Control.PRESET_CENTER_BOTTOM)
	build_sheet.grow_horizontal = Control.GROW_DIRECTION_BOTH
	build_sheet.grow_vertical = Control.GROW_DIRECTION_BEGIN
	build_sheet.offset_bottom = -116
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	build_sheet.add_child(box)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	box.add_child(tabs)
	tabs.add_child(_label("بناء", 26, C_GOLD))
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(20, 0)
	tabs.add_child(sp)
	for t in TABS:
		var b := _button(str(t[1]), _set_build_tab.bind(str(t[0])), Vector2(110, 46), 20)
		tabs.add_child(b)
		tab_buttons[str(t[0])] = b
	build_scroll = ScrollContainer.new()
	build_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	build_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	build_scroll.custom_minimum_size = Vector2(0, 172)
	build_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build_scroll.follow_focus = false
	box.add_child(build_scroll)
	cards_box = HBoxContainer.new()
	cards_box.add_theme_constant_override("separation", 10)
	cards_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build_scroll.add_child(cards_box)


func _build_dock() -> void:
	dock = _anchored_panel(Control.PRESET_CENTER_BOTTOM)
	dock.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dock.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dock.offset_bottom = -12
	dock.add_theme_stylebox_override("panel", _style(Color(0.09, 0.105, 0.075, 0.88), 26, C_BORDER, 2, 10))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	dock.add_child(row)
	row.add_child(_dock_button("build", "بناء", _toggle_sheet.bind("build")))
	row.add_child(_dock_button("workers", "العمال", _toggle_sheet.bind("workers")))
	row.add_child(_dock_button("missions2", "المهام", _toggle_sheet.bind("missions")))
	row.add_child(_dock_button("villages", "القرى", _toggle_sheet.bind("villages")))
	row.add_child(_dock_button("log", "السجل", _toggle_sheet.bind("log")))
	row.add_child(_dock_button("road", "مسارات", _toggle_road_mode))
	row.add_child(_dock_button("lv", "القيمة", _toggle_lv_overlay))


func _build_place_bar() -> void:
	place_bar = _sheet(Control.PRESET_CENTER_BOTTOM)
	place_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	place_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	place_bar.offset_bottom = -12
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	place_bar.add_child(row)
	confirm_btn = _button("تأكيد البناء", _confirm_build, Vector2(190, 70), 24, C_GREEN)
	row.add_child(confirm_btn)
	place_label = _label("", 19)
	place_label.custom_minimum_size = Vector2(380, 0)
	place_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	place_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(place_label)
	row.add_child(_button("إلغاء", _cancel_placement, Vector2(130, 70), 24, C_RED))


func _build_inspect_bar() -> void:
	inspect_bar = _sheet(Control.PRESET_CENTER_BOTTOM)
	inspect_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	inspect_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	inspect_bar.offset_bottom = -12
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	inspect_bar.add_child(row)
	inspect_label = _label("", 19)
	inspect_label.custom_minimum_size = Vector2(380, 0)
	inspect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspect_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(inspect_label)
	upgrade_btn = _button("ترقية", _upgrade_pressed, Vector2(160, 66), 19, Color("#4a7a9a"))
	upgrade_btn.visible = false
	row.add_child(upgrade_btn)
	council_btn = _button("إدارة الديوان", _show_council_panel, Vector2(190, 66), 18, Color("#8a6020"))
	council_btn.visible = false
	row.add_child(council_btn)
	demolish_btn = _button("هدم", _demolish_pressed, Vector2(170, 66), 21, C_RED)
	row.add_child(demolish_btn)
	row.add_child(_button("إغلاق", _close_inspect, Vector2(120, 66), 21))


func _build_pause_banner() -> void:
	pause_banner = _anchored_panel(Control.PRESET_CENTER)
	pause_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pause_banner.grow_vertical = Control.GROW_DIRECTION_BOTH
	pause_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_banner.visible = false
	pause_banner.add_theme_stylebox_override("panel", _style(Color(0.09, 0.105, 0.075, 0.7), 18, C_GOLD, 2, 16))
	var l := _label("متوقف مؤقتًا  —  يمكنك التخطيط والبناء", 24, C_GOLD)
	pause_banner.add_child(l)


func _build_toast() -> void:
	toast_panel = _anchored_panel(Control.PRESET_CENTER_TOP)
	toast_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast_panel.offset_top = 146
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.visible = false
	toast_panel.add_theme_stylebox_override("panel", _style(Color(0.16, 0.13, 0.07, 0.92), 18, C_GOLD, 1, 14))
	toast_label = _label("", 20)
	toast_label.custom_minimum_size = Vector2(440, 0)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_panel.add_child(toast_label)


func _modal() -> Array:
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.visible = false
	ui_root.add_child(layer)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.6)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(460, 0)
	vb.add_theme_constant_override("separation", 9)
	panel.add_child(vb)
	return [layer, vb]


func _build_menu() -> void:
	var m := _modal()
	menu_layer = m[0]
	var vb: VBoxContainer = m[1]
	var title := _label("الزيتون والحجر", 34, C_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var sub := _label("حكاية من فلسطين  —  الإصدار %s" % VERSION, 16, C_MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)
	vb.add_child(_button("متابعة", _close_menu, Vector2(0, 54), 22, C_GREEN))
	vb.add_child(_button("حفظ المخيم", _save_game, Vector2(0, 54), 22))
	vb.add_child(_button("تحميل المخيم المحفوظ", _load_game.bind(SAVE_PATH), Vector2(0, 54), 22))
	vb.add_child(_button("تحميل الحفظ التلقائي", _load_game.bind(AUTOSAVE_PATH), Vector2(0, 54), 22))
	text_size_btn = _button("حجم الخط: %s" % TEXT_SIZE_AR[text_size_index], _cycle_text_size, Vector2(0, 54), 22)
	vb.add_child(text_size_btn)
	new_btn = _button("مخيم جديد", _new_pressed, Vector2(0, 54), 22, Color("#6b4a2e"))
	vb.add_child(new_btn)


func _build_game_over() -> void:
	var m := _modal()
	over_layer = m[0]
	var vb: VBoxContainer = m[1]
	var title := _label("سقط المخيم", 34, Color("#e8806e"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	over_label = _label("", 20)
	over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	over_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(over_label)
	vb.add_child(_button("تحميل الحفظ التلقائي", _load_game.bind(AUTOSAVE_PATH), Vector2(0, 56), 22))
	vb.add_child(_button("مخيم جديد", _restart_game, Vector2(0, 60), 24, C_GREEN))


func _build_start_screen() -> void:
	# Full-screen start screen with gradient background
	start_screen = Control.new()
	start_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	start_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_root.add_child(start_screen)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.06, 0.03, 0.97)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	start_screen.add_child(bg)
	# Decorative olive branches (simple circles)
	for i in range(6):
		var dec := Panel.new()
		var a := float(i) / 6.0 * TAU
		dec.set_anchors_preset(Control.PRESET_CENTER)
		dec.custom_minimum_size = Vector2(120, 120)
		dec.offset_left = cos(a) * 340 - 60
		dec.offset_top = sin(a) * 200 - 60
		dec.add_theme_stylebox_override("panel", _style(Color(0.12, 0.22, 0.06, 0.18), 60, Color(0, 0, 0, 0), 0, 0))
		dec.mouse_filter = Control.MOUSE_FILTER_IGNORE
		start_screen.add_child(dec)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	start_screen.add_child(center)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(card)
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(520, 0)
	vb.add_theme_constant_override("separation", 18)
	card.add_child(vb)
	# Logo area
	var logo_col := VBoxContainer.new()
	logo_col.add_theme_constant_override("separation", 6)
	vb.add_child(logo_col)
	var olive_row := HBoxContainer.new()
	olive_row.alignment = BoxContainer.ALIGNMENT_CENTER
	olive_row.add_theme_constant_override("separation", 8)
	logo_col.add_child(olive_row)
	var olive_lbl := _label("🫒", 44)
	olive_row.add_child(olive_lbl)
	var title := _label("الزيتون والحجر", 48, C_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("outline_size", 3)
	title.add_theme_color_override("font_outline_color", Color("#6a4e14"))
	logo_col.add_child(title)
	var sub := _label("قصة نجاة من حيفا المحاصرة — ابنِ من جديد", 20, Color(0.72, 0.68, 0.58))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo_col.add_child(sub)
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", C_BORDER)
	vb.add_child(sep)
	# Buttons
	var has_save := FileAccess.file_exists(AUTOSAVE_PATH)
	if has_save:
		var cont_btn := _button("متابعة المخيم  ←", _ss_continue, Vector2(0, 72), 28, C_GREEN)
		cont_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vb.add_child(cont_btn)
		var new_btn2 := _button("مخيم جديد  (يمسح التقدم)", _ss_new, Vector2(0, 56), 19, Color(0.32, 0.22, 0.10, 0.92))
		new_btn2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vb.add_child(new_btn2)
	else:
		var play_btn := _button("ابدأ اللعب  ←", _ss_new, Vector2(0, 72), 28, C_GREEN)
		play_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vb.add_child(play_btn)
	var ver := _label("v%s — الزيتون والحجر" % VERSION, 14, C_MUTED)
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(ver)
	start_screen.visible = true
	menu_open = true


func _ss_continue() -> void:
	start_screen.visible = false
	menu_open = false
	_load_game(AUTOSAVE_PATH)
	_toast("مرحبًا بعودتك — متابعة المخيم.", 5.0)


func _ss_new() -> void:
	if FileAccess.file_exists(AUTOSAVE_PATH):
		_restart_game()
		return
	start_screen.visible = false
	menu_open = false
	_toast("مرحبًا بك قرب حيفا. خمسة ناجين ونار وخيمتان: كل شيء يُجمع باليد.", 7.0)


# ---------------------------------------------------------------- UI actions

func _hide_sheets() -> void:
	build_sheet.visible = false
	workers_sheet.visible = false
	missions_sheet.visible = false
	if is_instance_valid(log_sheet):
		log_sheet.visible = false
	if is_instance_valid(villages_sheet):
		villages_sheet.visible = false


func _toggle_sheet(which: String) -> void:
	var target: PanelContainer = build_sheet
	if which == "workers":
		target = workers_sheet
	elif which == "missions":
		target = missions_sheet
	elif which == "log":
		target = log_sheet
	elif which == "villages":
		target = villages_sheet
	var show := not target.visible
	_hide_sheets()
	_close_inspect()
	target.visible = show
	if show and which == "workers":
		workers_opened = true
	if show and which == "build":
		_rebuild_cards()
	if show and which == "log":
		_refresh_log_sheet()
	if show and which == "villages":
		_refresh_villages_sheet()
	_refresh_ui()


func _set_build_tab(tab: String) -> void:
	build_tab = tab
	_rebuild_cards()


func _rebuild_cards() -> void:
	for t in tab_buttons:
		var tb: Button = tab_buttons[t]
		var col := C_GREEN if t == build_tab else C_BTN
		tb.add_theme_stylebox_override("normal", _btn_style(col))
	for c in cards_box.get_children():
		c.queue_free()
	for bname in BUILDINGS:
		var def: Dictionary = BUILDINGS[bname]
		if str(def["tab"]) != build_tab:
			continue
		cards_box.add_child(_build_card(str(bname), def))


func _build_card(bname: String, def: Dictionary) -> Control:
	var locked := int(def["lv"]) > level
	var b := Button.new()
	b.custom_minimum_size = Vector2(190, 155)
	b.pressed.connect(_card_pressed.bind(bname))
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 10
	vb.offset_right = -10
	vb.offset_top = 8
	vb.offset_bottom = -8
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 2)
	b.add_child(vb)
	vb.add_child(_label(str(def["ar"]), 23, C_GOLD if not locked else C_MUTED))
	vb.add_child(_label("حجم %s" % PLOT_AR[str(def["cls"])], 14, C_MUTED))
	var desc := _label(str(def["desc"]) if not locked else "يُفتح في المستوى %d" % int(def["lv"]), 15, C_CREAM if not locked else Color("#ffb38a"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(desc)
	var cost_row := HBoxContainer.new()
	cost_row.add_theme_constant_override("separation", 5)
	cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cost: Dictionary = def["cost"]
	for r in cost:
		cost_row.add_child(_dot(RES_COLORS[r], 10.0))
		var enough := float(resources[r]) >= float(cost[r])
		cost_row.add_child(_label(str(int(cost[r])), 17, Color.WHITE if enough else Color("#ff9a8a")))
	vb.add_child(cost_row)
	if locked:
		b.modulate = Color(0.75, 0.75, 0.75, 0.9)
	return b


func _card_pressed(bname: String) -> void:
	var def: Dictionary = BUILDINGS[bname]
	if int(def["lv"]) > level:
		_toast("يُفتح «%s» عند بلوغ المخيم المستوى %d." % [def["ar"], int(def["lv"])])
		return
	var missing := _missing_resource(def["cost"])
	if missing != "":
		_toast("ينقصك %s لبناء «%s»." % [RES_AR[missing], def["ar"]])
		return
	_start_placing(bname)


func _open_menu() -> void:
	menu_open = true
	menu_layer.visible = true
	new_armed = false
	new_btn.text = "مخيم جديد"


func _close_menu() -> void:
	menu_open = false
	menu_layer.visible = false


func _toggle_pause() -> void:
	paused = not paused
	pause_banner.visible = paused
	pause_icon.kind = "play" if paused else "pause"
	pause_icon.queue_redraw()


func _cycle_speed() -> void:
	if game_speed < 1.5:
		game_speed = 2.0
	elif game_speed < 3.0:
		game_speed = 4.0
	else:
		game_speed = 1.0
	speed_btn.text = "×%d" % int(game_speed)


func _new_pressed() -> void:
	if not new_armed:
		new_armed = true
		new_btn.text = "اضغط مرة أخرى لبدء مخيم جديد"
		return
	_restart_game()


func _restart_game() -> void:
	var tree := get_tree()
	if tree.current_scene != null:
		tree.reload_current_scene()


func _toast(msg: String, seconds: float = 4.0) -> void:
	if not is_instance_valid(toast_label):
		return
	toast_label.text = msg
	toast_panel.visible = true
	toast_panel.modulate.a = 1.0
	toast_time = seconds


func _change_job(res: String, delta: int) -> void:
	var cur := int(jobs[res])
	if delta > 0:
		if _sum_jobs() >= survivors.size():
			_toast("كل الناجين لديهم عمل. أنقص موردًا آخر أولًا.")
			return
		jobs[res] = cur + 1
	else:
		if cur <= 0:
			return
		jobs[res] = cur - 1
	_assign_tasks()
	_refresh_ui()


func _refresh_ui() -> void:
	if not is_instance_valid(day_label):
		return
	day_label.text = "اليوم %d" % day
	level_label.text = str(level)
	if level >= MAX_LEVEL:
		xp_bar.value = 100.0
	else:
		var lo: float = LEVEL_XP[level - 1]
		var hi: float = LEVEL_XP[level]
		xp_bar.value = clampf((xp - lo) / (hi - lo) * 100.0, 0.0, 100.0)
	var n := float(survivors.size())
	if is_instance_valid(season_label):
		season_label.text = SEASON_AR[cur_season]
		season_label.add_theme_color_override("font_color", SEASON_COLOR[cur_season])
	for r in RES_TOP_BAR:
		var vl: Label = res_value_labels[r]
		vl.text = str(int(round(float(resources.get(r, 0.0)))))
		if trend_labels.has(r):
			var tl: Label = trend_labels[r]
			var arrow := _trend_arrow(r)
			tl.text = arrow
			if arrow == "▲":
				tl.add_theme_color_override("font_color", Color("#7fd36b"))
			elif arrow == "▼":
				tl.add_theme_color_override("font_color", Color("#ff8a7a"))
			else:
				tl.add_theme_color_override("font_color", C_MUTED)
	pop_label.text = "%d/%d" % [survivors.size(), _housing_capacity()]
	# Days-remaining labels for Food and Water
	if n > 0.0 and days_labels.size() > 0:
		var food_mul_r: float = (0.75 if kitchen_active else 1.0) * float(SEASON_FOOD_MUL[cur_season])
		var food_rate: float = n * FOOD_PER_VILLAGER * food_mul_r
		var water_rate: float = n * WATER_PER_VILLAGER * float(SEASON_WATER_MUL[cur_season])
		for res_d in [["Food", food_rate], ["Water", water_rate]]:
			if not days_labels.has(res_d[0]):
				continue
			var dl: Label = days_labels[res_d[0]]
			var rate := float(res_d[1])
			var days_left := float(resources.get(res_d[0], 0.0)) / maxf(0.1, rate)
			if days_left >= 10.0:
				dl.text = ""
			elif days_left < 3.0:
				dl.text = "~%dي" % int(days_left)
				dl.add_theme_color_override("font_color", Color("#ff7a60"))
			else:
				dl.text = "~%dي" % int(days_left)
				dl.add_theme_color_override("font_color", Color("#e0c060"))
	# Crisis overlay: pulse red if food or water < 2 days
	if is_instance_valid(crisis_overlay):
		var food_days := float(resources.get("Food", 0.0)) / maxf(1.0, n * FOOD_PER_VILLAGER)
		var water_days := float(resources.get("Water", 0.0)) / maxf(1.0, n * WATER_PER_VILLAGER)
		crisis_overlay.visible = (food_days < 2.0 or water_days < 2.0)
	# Update explore button in villages sheet
	if is_instance_valid(explore_btn):
		var cost2 := EXPLORE_BASE_COST + discovered_villages.size() * EXPLORE_COST_STEP
		if exploring:
			explore_btn.text = "يستكشف... يوم %d" % explore_done_day
			explore_btn.disabled = true
		elif discovered_villages.size() >= VILLAGES.size():
			explore_btn.text = "كل القرى مستكشفة"
			explore_btn.disabled = true
		else:
			explore_btn.text = "اكتشف قرية (%d دينار)" % cost2
			explore_btn.disabled = false
	morale_bar.value = morale
	health_bar.value = health
	if is_instance_valid(workers_sheet):
		var hb: Node = workers_sheet.find_child("HopeBar", true, false)
		if hb is ProgressBar:
			(hb as ProgressBar).value = hope
		var db: Node = workers_sheet.find_child("DiscontentBar", true, false)
		if db is ProgressBar:
			(db as ProgressBar).value = discontent
	var free := 0
	for v in survivors:
		if v.task == "idle":
			free += 1
	for r in jobs:
		if not job_count_labels.has(r):
			continue
		var cl: Label = job_count_labels[r]
		cl.text = str(int(jobs[r]))
		var net: float = float(last_income.get(r, 0.0))
		var food_mul := 0.75 if kitchen_active else 1.0
		if r == "Food":
			net -= n * FOOD_PER_VILLAGER * food_mul
		elif r == "Water":
			net -= n * WATER_PER_VILLAGER
		var rl: Label = job_rate_labels[r]
		if day > 1:
			rl.text = "%s%d / يوم" % ["+" if net >= 0.0 else "-", int(round(absf(net)))]
			rl.add_theme_color_override("font_color", Color("#9fd36b") if net >= 0.0 else Color("#ff8a7a"))
		else:
			rl.text = ""
	free_label.text = "ناجون بلا عمل: %d" % free
	if workers_sheet.visible:
		_refresh_villager_list()
	if missions_sheet.visible:
		_refresh_missions()


func _refresh_villager_list() -> void:
	if not is_instance_valid(villager_list):
		return
	while villager_labels.size() > survivors.size():
		var extra: Label = villager_labels.pop_back()
		extra.queue_free()
	while villager_labels.size() < survivors.size():
		var l := _label("", 17)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		villager_list.add_child(l)
		villager_labels.append(l)
	for i in range(survivors.size()):
		var v := survivors[i]
		villager_labels[i].text = "%s (%s): %s" % [v.vname, SKILL_AR[v.skill], _villager_status(v)]
		villager_labels[i].add_theme_color_override("font_color", SKILL_COLORS[v.skill].lightened(0.25))


func _refresh_missions() -> void:
	for c in missions_list.get_children():
		c.queue_free()
	for i in range(GOALS.size()):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var col := Color("#7fc04f") if i < goal_index else (C_GOLD if i == goal_index else Color(1, 1, 1, 0.25))
		row.add_child(_dot(col, 14.0))
		var t := str(GOALS[i]["text"])
		row.add_child(_label(t, 19, C_CREAM if i <= goal_index else C_MUTED))
		missions_list.add_child(row)


func _villager_status(v: Villager) -> String:
	match v.task:
		"build":
			if v.target != null:
				return "يبني %s" % str(BUILDINGS[v.target.type]["ar"])
		"gather":
			var carrying := ""
			if v.carry_amt > 0.0:
				carrying = "، يحمل %d %s" % [int(v.carry_amt), RES_AR[v.carry_res]]
			return "يجمع %s%s" % [RES_AR[v.job], carrying]
	return "يستريح عند النار"


func _goal_done(key: String) -> bool:
	match key:
		"workers": return workers_opened
		"well": return _has_done("Well")
		"tent": return _has_done("Tent")
		"storehouse": return _has_done("Storehouse")
		"farm": return _has_done("Farm")
		"pen": return _has_done("Pen")
		"level2": return level >= 2
		"kitchen": return kitchen_active
		"pop10": return survivors.size() >= 10
		"stone_house": return _has_done("Stone House")
		"level3": return level >= 3
		"olive_press": return _has_done("Olive Press")
		"caravan": return day >= CARAVAN_FIRST_DAY
		"diwan": return council_unlocked
		"pop20": return survivors.size() >= 20
		"day60": return day >= 60
		"fishing_dock": return _has_done("Fishing Dock")
		"level4": return level >= 4
		"khan": return _has_done("Khan")
		"mosque": return _has_done("Mosque")
		"clinic": return _has_done("Clinic")
		"town_square": return _has_done("Town Square")
		"day90": return day >= 90
	return false


# ---------------------------------------------------------------- survivors

func _create_survivors() -> void:
	for i in range(START_POP):
		_add_villager(NAMES[i], SKILLS[i % SKILLS.size()])


func _deliver(v: Villager) -> void:
	var res := v.carry_res
	var amt := v.carry_amt
	resources[res] = float(resources.get(res, 0.0)) + amt
	income_today[res] = float(income_today.get(res, 0.0)) + amt
	_pop_text(v.node.position, "+%d" % int(amt), RES_COLORS[res])
	var xp_bonus := 0.2 if _has_done("Library") else 0.1
	_add_xp(amt * xp_bonus)
	v.carry_amt = 0.0
	v.carry_res = ""
	v.carry_node.visible = false
	if v.releasing:
		_set_idle(v)
	else:
		v.state = "seek"
		v.wait = 0.0


func _hint_no_source(res: String) -> void:
	if int(no_source_day.get(res, -99)) == day:
		return
	no_source_day[res] = day
	var tip := ""
	match res:
		"Stone":
			tip = "ابنِ مقلعًا."
		"Scrap":
			tip = "ابنِ ورشة."
		"Food":
			tip = "ابنِ مزرعة أو بستان زيتون."
		"Water":
			tip = "ابنِ بئرًا."
		"Wood":
			tip = "الأشجار تنمو ببطء؛ انتظر أو انقل العمال."
	_toast("لم يبقَ %s قريب للجمع. %s" % [RES_AR[res], tip], 5.0)


func _pop_text(pos: Vector3, text: String, color: Color) -> void:
	if get_tree().get_nodes_in_group("pop_text").size() >= 4:
		return
	var l := Label3D.new()
	l.add_to_group("pop_text")
	l.text = text
	l.font = ar_font
	l.font_size = 40
	l.pixel_size = 0.8
	l.text_direction = TextServer.DIRECTION_LTR
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.outline_size = 10
	l.modulate = color.lightened(0.25)
	add_child(l)
	l.position = pos + Vector3(rng.randf_range(-22.0, 22.0), 55, rng.randf_range(-22.0, 22.0))
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y + 55.0, 1.2)
	tw.tween_property(l, "modulate:a", 0.0, 1.2)
	tw.chain().tween_callback(l.queue_free)


# ---------------------------------------------------------------- experience / levels

func _add_xp(amount: float) -> void:
	if level >= MAX_LEVEL:
		xp += amount
		return
	xp += amount
	while level < MAX_LEVEL and xp >= float(LEVEL_XP[level]):
		level += 1
		var names: Array[String] = []
		for bname in BUILDINGS:
			var def: Dictionary = BUILDINGS[bname]
			if int(def["lv"]) == level:
				names.append(str(def["ar"]))
		var opened := 0
		for p in plots:
			if p.lv == level:
				opened += 1
		var msg := "ارتقى المخيم إلى المستوى %d!" % level
		if not names.is_empty():
			msg += " فُتح: %s" % "، ".join(names)
		if opened > 0:
			msg += " و%d قطعة أرض جديدة." % opened
		_toast(msg, 6.0)
		_refresh_plots()
		if is_instance_valid(build_sheet) and build_sheet.visible:
			_rebuild_cards()


# ---------------------------------------------------------------- placing buildings on plots

func _start_placing(bname: String) -> void:
	_hide_sheets()
	_close_inspect()
	selected_building = bname
	dock.visible = false
	place_bar.visible = true
	# Start ghost at camp centre
	_update_ghost_placement(camp_pos)


func _update_ghost_placement(hp: Vector3) -> void:
	if selected_building == "":
		return
	var def: Dictionary = BUILDINGS[selected_building]
	var cls := str(def["cls"])
	var cell := _world_to_grid(hp.x, hp.z)
	var gx := cell.x
	var gz := cell.y
	var valid := _can_place(gx, gz, cls, selected_building)
	var sz: Vector2 = PLOT_SIZES[cls]
	var bm: BoxMesh = ghost_mesh.mesh
	bm.size = Vector3(sz.x * 0.88, 34.0, sz.y * 0.88)
	ghost_mesh.position = Vector3(0, 19, 0)
	ghost.position = _grid_to_world(gx, gz)
	ghost.visible = true
	var lv_here := _get_land_value(gx, gz)
	var min_lv_req := float(MIN_LAND_VALUE_REQ.get(selected_building, 0.0))
	if valid:
		var lv_frac := clampf(lv_here / 80.0, 0.0, 1.0)
		ghost_mat.albedo_color = Color(0.25 + (1.0 - lv_frac) * 0.15, 0.6 + lv_frac * 0.35, 0.25, 0.50)
	else:
		ghost_mat.albedo_color = Color(0.9, 0.3, 0.3, 0.45)
	pending_gx = gx
	pending_gz = gz
	pending_valid = valid
	var status: String
	if valid:
		var lv_info := (" — قيمة الأرض: %d/100" % int(lv_here)) if lv_here > 0.0 else ""
		status = "✓ موقع صالح%s — المس «تأكيد البناء»" % lv_info
	elif min_lv_req > 0.0 and lv_here < min_lv_req:
		status = "✗ قيمة الأرض منخفضة (تحتاج %d، لديك %d) — ابنِ مساجد وخدمات قريبة." % [int(min_lv_req), int(lv_here)]
	else:
		status = "✗ مشغول أو خارج الحدود"
	place_label.text = "%s — %s\n%s" % [def["ar"], _cost_text(def["cost"]), status]


func _cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for r in cost:
		parts.append("%s %d" % [RES_AR[r], int(cost[r])])
	return "، ".join(parts)


func _cancel_placement() -> void:
	selected_building = ""
	pending_gx = 0
	pending_gz = 0
	pending_valid = false
	if is_instance_valid(ghost):
		ghost.visible = false
	if is_instance_valid(place_bar):
		place_bar.visible = false
		if inspected == null:
			dock.visible = true


func _confirm_build() -> void:
	if selected_building == "" or not pending_valid:
		_toast("المس موقعًا صالحًا (أخضر) أولًا.")
		return
	var def: Dictionary = BUILDINGS[selected_building]
	var cost: Dictionary = def["cost"]
	var missing := _missing_resource(cost)
	if missing != "":
		_toast("ينقصك %s." % RES_AR[missing])
		return
	# Verify still valid (no race)
	if not _can_place(pending_gx, pending_gz, str(def["cls"]), selected_building):
		_toast("تغيّر الموقع، اختر مكانًا آخر.")
		_update_ghost_placement(ghost.position)
		return
	for r in cost:
		resources[r] = float(resources[r]) - float(cost[r])
	var cls := str(def["cls"])
	var p := _create_dynamic_plot(pending_gx, pending_gz, cls)
	var bname := selected_building
	_spawn_building(bname, p.idx, 0.0, false)
	_cancel_placement()
	_assign_tasks()
	_refresh_ui()
	_toast("وُضع أساس «%s». البنّاؤون في الطريق." % def["ar"])


func _spawn_building(type: String, plot_idx: int, progress: float, done: bool) -> Building:
	var p: Plot = plots[plot_idx]
	var def: Dictionary = BUILDINGS[type]
	var b := Building.new()
	b.type = type
	b.plot = plot_idx
	b.pos = p.pos
	b.progress = progress
	b.done = done
	b.base_scale = float(def["scale"])
	b.node = Node3D.new()
	b.node.position = b.pos
	building_root.add_child(b.node)
	b.model = _make_building_model(type)
	b.model.position.y = 2.0
	b.node.add_child(b.model)
	p.building = b
	if not done:
		b.model.scale = Vector3(b.base_scale, b.base_scale * lerpf(0.12, 1.0, progress), b.base_scale)
		b.scaffold = _make_scaffold(p.size.x, p.size.y)
		b.node.add_child(b.scaffold)
		b.label = Label3D.new()
		b.label.font = ar_font
		b.label.font_size = 36
		b.label.pixel_size = 0.9
		b.label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		b.label.no_depth_test = true
		b.label.outline_size = 12
		b.label.modulate = Color("#fff3c4")
		b.label.position = Vector3(0, 80, 0)
		b.node.add_child(b.label)
	else:
		b.model.scale = Vector3.ONE * b.base_scale
	buildings.append(b)
	if done:
		_add_building_source(b)
	_refresh_plots()
	return b


func _update_construction(dt: float) -> void:
	for b in buildings:
		if b.done:
			continue
		var rate := 0.0
		for v in survivors:
			if v.task == "build" and v.target == b and _flat_dist(v.node.position, b.pos) < 130.0:
				rate += 1.5 if v.skill == "Construction" else 1.0
		var def: Dictionary = BUILDINGS[b.type]
		b.progress = minf(1.0, b.progress + rate * dt / float(def["time"]))
		b.model.scale = Vector3(b.base_scale, b.base_scale * lerpf(0.12, 1.0, b.progress), b.base_scale)
		if rate > 0.0:
			b.label.text = "%s  %d%%" % [def["ar"], int(b.progress * 100.0)]
		else:
			b.label.text = "%s — بانتظار البنّائين" % def["ar"]
		if b.progress >= 1.0:
			_complete_building(b)


func _complete_building(b: Building) -> void:
	var def: Dictionary = BUILDINGS[b.type]
	b.done = true
	b.progress = 1.0
	if is_instance_valid(b.scaffold):
		b.scaffold.queue_free()
	if is_instance_valid(b.label):
		b.label.queue_free()
	b.model.scale = Vector3.ONE * b.base_scale
	var tw := create_tween()
	tw.tween_property(b.model, "scale", Vector3.ONE * b.base_scale, 0.35).from(Vector3.ONE * b.base_scale * 1.12)
	_add_building_source(b)
	_add_xp(float(def["xp"]))
	if def.get("kitchen", false):
		kitchen_active = true
		_toast("المطبخ جاهز — الاستهلاك اليومي للطعام انخفض 25%!", 5.0)
	elif def.get("council", false):
		council_unlocked = true
		_toast("افتُتح الديوان! يمكنك الآن فرض الضرائب وإصدار القرارات.", 6.0)
	_assign_tasks()
	_check_goals()
	_refresh_ui()
	_toast("اكتمل بناء «%s»!" % def["ar"])
	_log_event("🏗 يوم %d: اكتمل بناء %s." % [day, str(def["ar"])])


func _building_status(b: Building) -> String:
	var def: Dictionary = BUILDINGS[b.type]
	if not b.done:
		return "%s — قيد البناء (%d%%)" % [def["ar"], int(b.progress * 100.0)]
	var g: Dictionary = def["gather"]
	if not g.is_empty():
		var users := 0
		for s in sources:
			if s.building == b:
				users = _source_users(s, null)
		return "%s — %s\nالعاملون الآن: %d من %d" % [def["ar"], def["desc"], users, int(g["slots"])]
	return "%s — %s" % [def["ar"], def["desc"]]


func _inspect_building(b: Building) -> void:
	if selected_building != "":
		return
	_hide_sheets()
	inspected = b
	demolish_armed = false
	demolish_btn.text = "هدم (يعود نصف المواد)"
	dock.visible = false
	inspect_bar.visible = true
	inspect_label.text = _building_status(b)
	var def: Dictionary = BUILDINGS[b.type]
	if b.done and def.has("upgrade") and b.upgrade_level == 0:
		var upg: Dictionary = def["upgrade"]
		var cost_parts: Array = []
		for r in upg.get("cost", {}):
			cost_parts.append("%d %s" % [int(upg["cost"][r]), RES_AR.get(r, r)])
		upgrade_btn.text = "ترقية: %s\n(%s)" % [str(upg.get("ar", "")), ", ".join(cost_parts)]
		upgrade_btn.visible = true
	else:
		upgrade_btn.visible = false
	if is_instance_valid(council_btn):
		council_btn.visible = b.done and bool(def.get("council", false))


func _close_inspect() -> void:
	inspected = null
	demolish_armed = false
	if is_instance_valid(inspect_bar):
		inspect_bar.visible = false
		if selected_building == "":
			dock.visible = true


func _show_council_panel() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 19
	add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.65)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(580, 0)
	panel.layout_direction = Control.LAYOUT_DIRECTION_RTL
	panel.add_theme_stylebox_override("panel", _style(Color(0.08, 0.06, 0.03, 0.96), 18, C_GOLD, 2, 16))
	layer.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)
	vb.add_child(_label("الديوان — مجلس المستوطنة", 28, C_GOLD))
	# Dinar + discontent status
	var stat := HBoxContainer.new()
	stat.add_theme_constant_override("separation", 24)
	vb.add_child(stat)
	stat.add_child(_label("الدنانير: %d" % int(resources.get("Dinar", 0.0)), 20, C_GOLD))
	stat.add_child(_label("السخط: %d%%" % int(discontent), 20, Color("#e06040")))
	# Demand bars (CS-style RCI)
	vb.add_child(_label("الطلب:", 20, C_CREAM))
	var dem_box := VBoxContainer.new()
	dem_box.add_theme_constant_override("separation", 6)
	vb.add_child(dem_box)
	for drow in [
		["🏠 سكن",   demand_housing,    Color("#60a0e0")],
		["⛏ إنتاج", demand_production,  Color("#e0a040")],
		["🏛 خدمات", demand_services,    Color("#70c070")],
	]:
		var dr := HBoxContainer.new()
		dr.add_theme_constant_override("separation", 8)
		dem_box.add_child(dr)
		var dl := _label(str(drow[0]), 17, C_CREAM)
		dl.custom_minimum_size = Vector2(100, 0)
		dr.add_child(dl)
		var bar := ProgressBar.new()
		bar.min_value = 0; bar.max_value = 100
		bar.value = float(drow[1])
		bar.custom_minimum_size = Vector2(220, 18)
		bar.show_percentage = false
		var sty := StyleBoxFlat.new()
		sty.bg_color = Color(drow[2])
		sty.corner_radius_top_left = 3; sty.corner_radius_top_right = 3
		sty.corner_radius_bottom_left = 3; sty.corner_radius_bottom_right = 3
		bar.add_theme_stylebox_override("fill", sty)
		dr.add_child(bar)
		dr.add_child(_label("%d%%" % int(float(drow[1])), 17, C_MUTED))
	# Tax level selector
	vb.add_child(_label("مستوى الضريبة:", 20, C_CREAM))
	var tax_row := HBoxContainer.new()
	tax_row.add_theme_constant_override("separation", 10)
	vb.add_child(tax_row)
	for ti in range(TAX_LEVELS.size()):
		var tl: Dictionary = TAX_LEVELS[ti]
		var col := C_GREEN if ti == tax_level_idx else C_BTN
		var lyr := layer
		var ti_cap := ti
		var tb2 := _button(str(tl["ar"]), func():
			tax_level_idx = ti_cap
			lyr.queue_free()
			_toast("الضريبة الجديدة: %s (+%d دينار/يوم، سخط +%.1f/يوم)" % [str(TAX_LEVELS[ti_cap]["ar"]), int(TAX_LEVELS[ti_cap]["dinar"]), float(TAX_LEVELS[ti_cap]["discontent"])])
		, Vector2(130, 54), 17, col)
		tax_row.add_child(tb2)
	# Council actions
	vb.add_child(_label("قرارات المجلس:", 20, C_CREAM))
	var act_row := HBoxContainer.new()
	act_row.add_theme_constant_override("separation", 10)
	vb.add_child(act_row)
	# Feast: costs food, boosts morale
	var lyr2 := layer
	act_row.add_child(_button("وليمة عامة\n(−20 طعام، +20 معنويات)", func():
		if float(resources.get("Food", 0.0)) >= 20.0:
			resources["Food"] = float(resources["Food"]) - 20.0
			morale = minf(100.0, morale + 20.0)
			discontent = maxf(0.0, discontent - 10.0)
			_log_event("🍽 يوم %d: وليمة عامة — معنويات +20." % day)
			_toast("أُقيمت وليمة! المعنويات ترتفع +20. 🍽", 4.0)
			lyr2.queue_free()
			_refresh_ui()
		else:
			_toast("طعام غير كافٍ (يلزم 20).")
	, Vector2(190, 70), 16, Color("#8a4a20")))
	var lyr3 := layer
	act_row.add_child(_button("خطاب تشجيعي\n(−5 دينار، سخط −15)", func():
		if float(resources.get("Dinar", 0.0)) >= 5.0:
			resources["Dinar"] = float(resources["Dinar"]) - 5.0
			discontent = maxf(0.0, discontent - 15.0)
			hope = minf(100.0, hope + 10.0)
			_log_event("📜 يوم %d: خطاب تشجيعي — سخط −15." % day)
			_toast("خطاب المجلس رفع الأمل وخفّض السخط.", 4.0)
			lyr3.queue_free()
			_refresh_ui()
		else:
			_toast("لا تملك 5 دنانير.")
	, Vector2(190, 70), 16, Color("#4a6a9a")))
	vb.add_child(_button("إغلاق", layer.queue_free.bind(), Vector2(0, 54), 20))


func _upgrade_pressed() -> void:
	if inspected == null or not inspected.done:
		return
	var def: Dictionary = BUILDINGS[inspected.type]
	if not def.has("upgrade") or inspected.upgrade_level > 0:
		return
	var upg: Dictionary = def["upgrade"]
	for r in upg.get("cost", {}):
		if float(resources.get(r, 0.0)) < float(upg["cost"][r]):
			_toast("مواد غير كافية للترقية — تحتاج: %d %s" % [int(upg["cost"][r]), RES_AR.get(r, r)])
			return
	for r in upg.get("cost", {}):
		resources[r] = float(resources[r]) - float(upg["cost"][r])
	inspected.upgrade_level = 1
	for s in sources:
		if s.building == inspected:
			if upg.has("gather_yield"):
				s.yield_amt = float(upg["gather_yield"])
			if upg.has("gather_slots"):
				s.slots = int(upg["gather_slots"])
	_toast("ترقية «%s» → «%s» اكتملت!" % [def["ar"], str(upg.get("ar", ""))])
	_add_xp(20.0)
	_close_inspect()
	_assign_tasks()
	_refresh_ui()


func _demolish_pressed() -> void:
	if inspected == null:
		return
	var b := inspected
	var def: Dictionary = BUILDINGS[b.type]
	if b.done and int(def["housing"]) > 0 and survivors.size() > _housing_capacity() - int(def["housing"]):
		_toast("ما زال ناجون يسكنون هذا المبنى.")
		return
	if not demolish_armed:
		demolish_armed = true
		demolish_btn.text = "اضغط مرة أخرى للتأكيد"
		return
	var cost: Dictionary = def["cost"]
	for r in cost:
		resources[r] = float(resources[r]) + floorf(float(cost[r]) * 0.5)
	for i in range(sources.size() - 1, -1, -1):
		if sources[i].building == b:
			sources.remove_at(i)
	for v in survivors:
		if v.src != null and not sources.has(v.src):
			v.src = null
			if v.task == "gather" and v.state != "to_store":
				v.state = "seek"
				v.wait = 0.0
	var pp: Plot = plots[b.plot]
	for cell in _cells_for(pp.gx, pp.gz, pp.cls):
		occupied_cells.erase(cell)
	pp.node.queue_free()
	pp.node = null
	pp.slab = null
	pp.building = null
	buildings.erase(b)
	b.node.queue_free()
	_toast("هُدم «%s» واستُعيد نصف المواد." % def["ar"])
	_close_inspect()
	_refresh_plots()
	_assign_tasks()
	_refresh_ui()


# ---------------------------------------------------------------- days

func _advance_day() -> void:
	day += 1
	var n := float(survivors.size())

	# Season progression
	season_day += 1
	if season_day >= SEASON_DAYS:
		season_day = 0
		cur_season = (cur_season + 1) % 4
		_toast("بدأ فصل جديد: %s" % SEASON_AR[cur_season], 5.0)
		_log_event("🌿 يوم %d: بداية %s" % [day, SEASON_NAMES[cur_season]])
	# Autumn: olive harvest bonus every 5 days
	if cur_season == 2 and day % 5 == 0:
		var olive_count := 0
		for b in buildings:
			if b.done and b.type == "Olive Grove":
				olive_count += 1
		if olive_count > 0:
			var bonus := float(olive_count) * 6.0
			resources["Food"] = float(resources["Food"]) + bonus
			_toast("موسم الزيتون: حصاد %d وحدة طعام إضافية! 🫒" % int(bonus), 4.0)

	# CS systems — update before consumption calculations
	_update_land_value()
	_apply_service_coverage()
	_update_demand()

	# Check special buildings
	var has_mosque := false
	var has_clinic := false
	var has_plaza := false
	var has_library := false
	var has_watchtower := false
	for b in buildings:
		if not b.done: continue
		if b.type == "Mosque": has_mosque = true
		elif b.type == "Clinic": has_clinic = true
		elif b.type == "Plaza": has_plaza = true
		elif b.type == "Library": has_library = true
		elif b.type == "Watchtower": has_watchtower = true
	# Mosque: Friday morale boost (every 7 days)
	if has_mosque and day % 7 == 0:
		morale = minf(100.0, morale + 15.0)
		_toast("صلاة الجمعة في الجامع — المعنويات ترتفع +15 🕌", 4.0)
	# Plaza: small daily morale boost (global, stacks with coverage)
	if has_plaza:
		morale = minf(100.0, morale + 3.0)
	# Weather events (drought in summer, rain in spring/autumn)
	if cur_season == 1 and day % 6 == 0 and rng.randf() < 0.45:
		var dr_msg := "جفاف! الحرارة ترتفع — استهلاك الماء يزيد هذا اليوم. 🌵"
		if has_watchtower:
			dr_msg = "برج المراقبة رصد موجة حر مبكرًا — استعد للجفاف! 🏰"
			_toast(dr_msg, 5.0)
		else:
			resources["Water"] = maxf(0.0, float(resources["Water"]) - n * 0.6)
			_toast(dr_msg, 5.0)
		_log_event("☀ يوم %d: موجة حر وجفاف." % day)
	elif (cur_season == 0 or cur_season == 2) and day % 8 == 0 and rng.randf() < 0.35:
		var rain := 12.0 + rng.randf() * 10.0
		resources["Water"] = float(resources["Water"]) + rain
		_toast("أمطار ربيعية — ملأت الآبار (+%d ماء) 💧" % int(rain), 4.0)
		_log_event("🌧 يوم %d: أمطار (+%d ماء)." % [day, int(rain)])
	# Kitchen reduces food consumption by 25% if built
	var food_mul: float = (0.75 if kitchen_active else 1.0) * float(SEASON_FOOD_MUL[cur_season])
	resources["Food"] = float(resources["Food"]) - n * FOOD_PER_VILLAGER * food_mul
	resources["Water"] = float(resources["Water"]) - n * WATER_PER_VILLAGER * float(SEASON_WATER_MUL[cur_season])
	# Winter illness risk
	if cur_season == 3 and rng.randf() < 0.12:
		health = maxf(0.0, health - 5.0)
		if not paused:
			_toast("برد الشتاء أضعف بعض الناجين. (صحة −5)", 4.0)
	var shortage := float(resources["Food"]) < 0.0 or float(resources["Water"]) < 0.0
	for r in RES_NAMES:
		resources[r] = maxf(0.0, float(resources[r]))
	last_income = income_today.duplicate()
	res_trend_history.append(last_income.duplicate())
	if res_trend_history.size() > 5:
		res_trend_history.pop_front()
	for r in income_today:
		income_today[r] = 0.0

	# Production buildings generate a small daily Dinar income
	var prod_types := ["Farm", "Olive Grove", "Pen", "Quarry", "Workshop", "Fishing Dock", "Olive Press"]
	var prod_income := 0.0
	for b in buildings:
		if b.done and prod_types.has(b.type):
			prod_income += 0.5
	if prod_income > 0.0:
		resources["Dinar"] = float(resources["Dinar"]) + prod_income

	# Tax income (requires council_unlocked)
	if council_unlocked and tax_level_idx > 0:
		var tax: Dictionary = TAX_LEVELS[tax_level_idx]
		resources["Dinar"] = float(resources["Dinar"]) + float(tax["dinar"])
		discontent = minf(100.0, discontent + float(tax["discontent"]))

	# Regen finite natural sources
	for s in sources:
		if s.regen > 0.0 and not s.infinite:
			s.amount = minf(s.max_amount, s.amount + s.max_amount * s.regen)
			_update_source_visual(s)

	var medics := 0
	for v in survivors:
		if v.skill == "Medicine":
			medics += 1

	# Check exploration completion
	if exploring and day >= explore_done_day:
		exploring = false
		_finish_explore()
	if shortage:
		health = maxf(0.0, health - 8.0)
		morale = maxf(0.0, morale - 8.0)
		hope = maxf(0.0, hope - 5.0)
		discontent = minf(100.0, discontent + 4.0)
		_toast("نقص في المؤن! ضع عمالًا أكثر على الطعام والماء.", 5.0)
		_log_event("⚠ يوم %d: نقص في المؤن." % day)
		if health <= 0.0:
			_remove_villager()
			_remove_villager()
		elif health <= 25.0:
			_remove_villager()
	else:
		morale = minf(100.0, morale + 1.5)
		var base_heal := 2.0 + float(medics) + (3.0 if has_clinic else 0.0)
		var heal_rate := base_heal * service_heal_mult
		health = minf(100.0, health + heal_rate)
		hope = minf(100.0, hope + 1.0)
		discontent = maxf(0.0, discontent - 0.5)
		var xp_mul := (2.0 if has_library else 1.0) * service_xp_mult
		_add_xp(3.0 * xp_mul)

	# Hope/discontent swing morale
	morale = clampf(morale + (hope - 50.0) * 0.02 - discontent * 0.03, 0.0, 100.0)

	if survivors.is_empty():
		_trigger_game_over()
		return

	# Caravan arrives every CARAVAN_INTERVAL days after CARAVAN_FIRST_DAY
	if day >= CARAVAN_FIRST_DAY and (day - CARAVAN_FIRST_DAY) % CARAVAN_INTERVAL == 0:
		_trigger_caravan()

	# Random moral event every 7+ days (cooldown)
	if event_cooldown > 0:
		event_cooldown -= 1
	elif rng.randf() < 0.35 and MORAL_EVENTS.size() > 0:
		pending_event = rng.randi() % MORAL_EVENTS.size()
		_show_moral_event()
		event_cooldown = 7

	var fed := float(resources["Food"]) >= n * 3.0 and float(resources["Water"]) >= n * 3.0
	# Demand: good services → newcomers arrive more often; high service demand → slower arrival
	var newcomer_interval := 4
	if demand_services < 25.0:
		newcomer_interval = 3   # excellent services — attract newcomers faster
	elif demand_services > 70.0:
		newcomer_interval = 6   # poor services — newcomers hesitate
	if day % newcomer_interval == 0 and _housing_capacity() > survivors.size() and morale > 45.0 and fed and not shortage:
		var v := _add_villager(NAMES[survivors.size() % NAMES.size()], SKILLS[rng.randi() % SKILLS.size()])
		_add_xp(15.0)
		_toast("وصل ناجٍ جديد: %s (%s). امنحه عملًا." % [v.vname, SKILL_AR[v.skill]], 5.0)
		_log_event("👤 يوم %d: وصل %s (%s)." % [day, v.vname, SKILL_AR[v.skill]])
	elif day % newcomer_interval == 0 and _housing_capacity() <= survivors.size():
		_toast("ناجون يطلبون اللجوء، لكن لا مأوى. ابنِ خيمة.", 4.0)
	peak_pop = maxi(peak_pop, survivors.size())
	_check_goals()
	_assign_tasks()
	_refresh_ui()


func _trigger_caravan() -> void:
	_toast("وصلت القافلة! لديك 3 أيام للتجارة قبل رحيلها.", 7.0)
	_log_event("🐪 يوم %d: وصلت القافلة." % day)
	_spawn_caravan_visual()
	# Auto-trade Oil surplus
	var oil := float(resources.get("Oil", 0.0))
	if oil >= 10.0:
		var sold := floorf(oil * 0.5)
		var earned := sold * 2.0
		resources["Oil"] = oil - sold
		resources["Dinar"] = float(resources["Dinar"]) + earned
		_toast("القافلة اشترت %d وحدة زيت بـ%d دينار." % [int(sold), int(earned)], 5.0)
		_add_xp(10.0)
	caravan_day = day


func _show_moral_event() -> void:
	if pending_event < 0 or pending_event >= MORAL_EVENTS.size():
		return
	var ev: Dictionary = MORAL_EVENTS[pending_event]
	# Build a simple dialog panel
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(520, 0)
	panel.layout_direction = Control.LAYOUT_DIRECTION_RTL
	layer.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)
	var lbl := Label.new()
	lbl.text = ev["text"]
	lbl.add_theme_font_override("font", ar_font)
	lbl.add_theme_font_size_override("font_size", 17)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vb.add_child(lbl)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	vb.add_child(hb)
	var btn_a := Button.new()
	btn_a.text = ev["a"]
	btn_a.add_theme_font_override("font", ar_font)
	btn_a.add_theme_font_size_override("font_size", 15)
	btn_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(btn_a)
	var btn_b := Button.new()
	btn_b.text = ev["b"]
	btn_b.add_theme_font_override("font", ar_font)
	btn_b.add_theme_font_size_override("font_size", 15)
	btn_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(btn_b)
	var eff_a: String = ev["effect_a"]
	var eff_b: String = ev["effect_b"]
	btn_a.pressed.connect(func():
		_log_event("⚖ يوم %d: %s" % [day, ev["a"]])
		_apply_moral_effect(eff_a)
		layer.queue_free()
	)
	btn_b.pressed.connect(func():
		_log_event("⚖ يوم %d: %s" % [day, ev["b"]])
		_apply_moral_effect(eff_b)
		layer.queue_free()
	)
	pending_event = -1


func _apply_moral_effect(eff: String) -> void:
	match eff:
		"refugee_accept":
			if float(resources.get("Food", 0.0)) >= 20.0:
				resources["Food"] = float(resources["Food"]) - 20.0
				_add_villager(NAMES[survivors.size() % NAMES.size()], SKILLS[rng.randi() % SKILLS.size()])
				_add_villager(NAMES[(survivors.size() + 1) % NAMES.size()], SKILLS[rng.randi() % SKILLS.size()])
				_toast("استقبلت العائلة اللاجئة بحرارة.", 4.0)
				hope = minf(100.0, hope + 15.0)
			else:
				_toast("ليس لديك طعام كافٍ لاستقبالهم.", 3.0)
		"morale_boost":
			morale = minf(100.0, morale + 10.0)
			hope = minf(100.0, hope + 10.0)
			_toast("وُزِّع الكنز على الجميع — ارتفعت المعنوية.", 4.0)
		"dinar_bonus":
			resources["Dinar"] = float(resources["Dinar"]) + 25.0
			_toast("وُضع الكنز في الخزينة: +25 دينار.", 4.0)
		"sell_food":
			if float(resources.get("Food", 0.0)) >= 30.0:
				resources["Food"] = float(resources["Food"]) - 30.0
				resources["Dinar"] = float(resources["Dinar"]) + 20.0
				_toast("بعت الفائض بـ20 دينار.", 4.0)
			else:
				_toast("لا يوجد فائض للبيع.", 3.0)
		"treat_illness":
			if float(resources.get("Scrap", 0.0)) >= 15.0:
				resources["Scrap"] = float(resources["Scrap"]) - 15.0
				health = minf(100.0, health + 20.0)
				_toast("عُولج المرضى: الصحة ارتفعت.", 4.0)
			else:
				_toast("لا تملك خردة كافية.", 3.0)
		"rest_illness":
			health = maxf(0.0, health - 10.0)
			_toast("الراحة وحدها: الصحة انخفضت قليلًا.", 4.0)
		"train_craftsman":
			if float(resources.get("Scrap", 0.0)) >= 10.0:
				resources["Scrap"] = float(resources["Scrap"]) - 10.0
				_add_xp(30.0)
				_toast("تدرّب الشاب — XP +30.", 4.0)
			else:
				_toast("لا تملك خردة كافية للتدريب.", 3.0)
		"build_trench":
			if float(resources.get("Stone", 0.0)) >= 20.0:
				resources["Stone"] = float(resources["Stone"]) - 20.0
				hope = minf(100.0, hope + 8.0)
				_toast("حُفر الخندق — شعر الناجون بالأمان.", 4.0)
			else:
				_toast("لا حجر كافٍ للحفر.", 3.0)
		_:
			pass


func _check_goals() -> void:
	while goal_index < GOALS.size() and _goal_done(str(GOALS[goal_index]["key"])):
		_toast("أُنجز الهدف: %s" % str(GOALS[goal_index]["text"]), 4.0)
		_add_xp(15.0)
		goal_index += 1
	if is_instance_valid(goal_label):
		if goal_index < GOALS.size():
			goal_label.text = str(GOALS[goal_index]["text"])
		else:
			goal_label.text = "أنجزت كل الأهداف. المزيد قريبًا."


func _has_built(btype: String) -> bool:
	for b in buildings:
		if b.type == btype and b.done:
			return true
	return false


func _has_done(btype: String) -> bool:
	return _has_built(btype)


func _remove_villager() -> void:
	if survivors.is_empty():
		return
	var v: Villager = survivors[survivors.size() - 1]
	survivors.erase(v)
	v.node.queue_free()
	_clamp_jobs()
	_toast("غادر %s المخيم بسبب الجوع والعطش." % v.vname, 5.0)


func _trigger_game_over() -> void:
	game_over = true
	var built := 0
	for b in buildings:
		if b.done:
			built += 1
	over_label.text = "صمد ناجوك %d يومًا.\nمبانٍ مكتملة: %d   —   أعلى عدد سكان: %d   —   المستوى: %d" % [day, built, peak_pop, level]
	over_layer.visible = true


# ---------------------------------------------------------------- tapping the world

func _on_tap(pos: Vector2) -> void:
	var hit: Variant = _ray_to_terrain(pos)
	if hit == null:
		return
	var hp: Vector3 = hit
	if road_mode:
		_paint_trail_at(pos)
		return
	if selected_building != "":
		_update_ghost_placement(hp)
		return
	var best_v: Villager = null
	var best_d := 44.0
	for v in survivors:
		var d := _screen_dist(pos, v.node.position + Vector3(0, 20, 0))
		if d < best_d:
			best_d = d
			best_v = v
	if best_v != null:
		_toast("%s (%s): %s" % [best_v.vname, SKILL_AR[best_v.skill], _villager_status(best_v)], 3.5)
		return
	var p2 := _plot_at_point(hp, 4.0)
	if p2 != null and p2.building != null:
		_inspect_building(p2.building)
		return
	var best_s: Source = null
	best_d = 56.0
	for s in sources:
		if s.building != null or s.node == null:
			continue
		var d2 := _screen_dist(pos, s.pos + Vector3(0, 12, 0))
		if d2 < best_d:
			best_d = d2
			best_s = s
	if best_s != null:
		var left := "لا ينضب" if best_s.infinite else "بقي %d" % int(best_s.amount)
		_toast("%s (%s): %s" % [best_s.label, RES_AR[best_s.res], left], 3.5)
		return
	_close_inspect()
	_hide_sheets()


# ---------------------------------------------------------------- save / load

func _write_save(path: String, silent: bool) -> void:
	var blist: Array = []
	for b in buildings:
		var pp: Plot = plots[b.plot] if b.plot >= 0 and b.plot < plots.size() else null
		var entry := {"type": b.type, "gx": pp.gx if pp else 0, "gz": pp.gz if pp else 0, "progress": b.progress, "done": b.done, "upgrade": b.upgrade_level}
		blist.append(entry)
	var vlist: Array = []
	for v in survivors:
		vlist.append([v.vname, v.skill])
	var amounts: Array = []
	for s in sources:
		if s.building == null:
			amounts.append(s.amount)
	var data := {
		"version": SAVE_VERSION, "region": "Haifa", "resources": resources, "jobs": jobs, "day": day,
		"morale": morale, "health": health, "hope": hope, "discontent": discontent,
		"council_unlocked": council_unlocked, "tax_level_idx": tax_level_idx,
		"kitchen_active": kitchen_active, "event_cooldown": event_cooldown,
		"discovered_villages": discovered_villages, "exploring": exploring,
		"explore_done_day": explore_done_day, "event_log": event_log,
		"goal": goal_index, "peak": peak_pop, "level": level, "xp": xp,
		"workers_opened": workers_opened, "buildings": blist, "villagers": vlist, "sources": amounts,
		"cur_season": cur_season, "season_day": season_day
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		if not silent:
			_toast("تعذّر حفظ الملف.")
		return
	file.store_string(JSON.stringify(data))
	if not silent:
		_toast("حُفظ المخيم على هذا الجهاز.")


func _load_game(path: String) -> void:
	if not FileAccess.file_exists(path):
		_toast("لا يوجد حفظ هنا بعد.")
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_toast("تعذّر قراءة ملف الحفظ.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_toast("ملف الحفظ تالف.")
		return
	var d: Dictionary = parsed
	var save_ver := int(d.get("version", 0))
	if str(d.get("region", "")) != "Haifa" or save_ver < SAVE_VERSION:
		_toast("هذا الحفظ من إصدار أقدم (v2.2.0+)، سيبدأ مخيم جديد.")
		return
	_cancel_placement()
	_close_inspect()
	for b in buildings:
		b.node.queue_free()
	buildings.clear()
	for p in plots:
		if is_instance_valid(p.node):
			p.node.queue_free()
	plots.clear()
	occupied_cells.clear()
	for i in range(sources.size() - 1, -1, -1):
		if sources[i].building != null:
			sources.remove_at(i)
	for v in survivors:
		v.node.queue_free()
	survivors.clear()
	var saved_res: Dictionary = d.get("resources", {})
	for r in RES_NAMES:
		resources[r] = float(saved_res.get(r, resources[r]))
	var saved_jobs: Dictionary = d.get("jobs", {})
	for r in START_JOBS:
		jobs[r] = int(saved_jobs.get(r, 0))
	day = int(d.get("day", day))
	morale = float(d.get("morale", morale))
	health = float(d.get("health", health))
	hope = float(d.get("hope", 50.0))
	discontent = float(d.get("discontent", 0.0))
	council_unlocked = bool(d.get("council_unlocked", false))
	tax_level_idx = clampi(int(d.get("tax_level_idx", 0)), 0, TAX_LEVELS.size() - 1)
	kitchen_active = bool(d.get("kitchen_active", false))
	event_cooldown = int(d.get("event_cooldown", 0))
	discovered_villages.clear()
	var dv: Array = d.get("discovered_villages", [])
	for vi in dv:
		var vi_int := int(vi)
		if vi_int >= 0 and vi_int < VILLAGES.size() and not discovered_villages.has(vi_int):
			discovered_villages.append(vi_int)
	exploring = bool(d.get("exploring", false))
	explore_done_day = int(d.get("explore_done_day", -1))
	event_log.clear()
	var el: Array = d.get("event_log", [])
	for entry in el:
		event_log.append(str(entry))
	goal_index = clampi(int(d.get("goal", 0)), 0, GOALS.size())
	peak_pop = int(d.get("peak", START_POP))
	level = clampi(int(d.get("level", 1)), 1, MAX_LEVEL)
	xp = float(d.get("xp", 0.0))
	workers_opened = bool(d.get("workers_opened", false))
	cur_season = clampi(int(d.get("cur_season", 0)), 0, 3)
	season_day = clampi(int(d.get("season_day", 0)), 0, SEASON_DAYS - 1)
	day_timer = 0.0
	var amounts: Array = d.get("sources", [])
	var idx := 0
	for s in sources:
		if s.building == null:
			if idx < amounts.size():
				s.amount = float(amounts[idx])
				_update_source_visual(s)
			idx += 1
	var blist: Array = d.get("buildings", [])
	for e in blist:
		if typeof(e) != TYPE_DICTIONARY:
			continue
		var ed: Dictionary = e
		var t := str(ed.get("type", ""))
		if not BUILDINGS.has(t):
			continue
		var gx_b := int(ed.get("gx", 0))
		var gz_b := int(ed.get("gz", 0))
		var cls_b := str(BUILDINGS[t]["cls"])
		# Skip if cells already occupied
		if not _can_place(gx_b, gz_b, cls_b, t):
			continue
		var new_p := _create_dynamic_plot(gx_b, gz_b, cls_b)
		var new_b := _spawn_building(t, new_p.idx, float(ed.get("progress", 1.0)), bool(ed.get("done", true)))
		new_b.upgrade_level = int(ed.get("upgrade", 0))
		if new_b.upgrade_level > 0 and new_b.done and BUILDINGS[t].has("upgrade"):
			var upg: Dictionary = BUILDINGS[t]["upgrade"]
			for s in sources:
				if s.building == new_b:
					if upg.has("gather_yield"):
						s.yield_amt = float(upg["gather_yield"])
					if upg.has("gather_slots"):
						s.slots = int(upg["gather_slots"])
	var vlist: Array = d.get("villagers", [])
	for e in vlist:
		if typeof(e) == TYPE_ARRAY and e.size() >= 2 and SKILL_COLORS.has(str(e[1])):
			_add_villager(str(e[0]), str(e[1]))
	if survivors.is_empty():
		for i in range(START_POP):
			_add_villager(NAMES[i], SKILLS[i % SKILLS.size()])
	_clamp_jobs()
	game_over = false
	over_layer.visible = false
	_refresh_plots()
	_assign_tasks()
	_refresh_ui()
	_close_menu()
	_toast("تم تحميل المخيم.")


# ---------------------------------------------------------------- shared helpers (from v0.3)


func _coastline_x(gz: float) -> float:
	return 5.2 + 1.4 * sin(gz * 0.13) + 0.65 * sin(gz * 0.31 + 1.0)

func _is_land(gx: int, gz: int) -> bool:
	return gx >= 0 and gx < GRID and gz >= 0 and gz < GRID and float(gx) >= _coastline_x(float(gz)) + 1.0

func _build_heights() -> void:
	heights.resize(GRID * GRID)
	for z in range(GRID):
		for x in range(GRID):
			heights[z * GRID + x] = _terrain_height(float(x), float(z))

func _height_at_world(x: float, z: float) -> float:
	var gx := clampf(x / TILE_SIZE + GRID / 2.0 - 0.5, 0.0, float(GRID) - 1.001)
	var gz := clampf(z / TILE_SIZE + GRID / 2.0 - 0.5, 0.0, float(GRID) - 1.001)
	var ix := int(gx)
	var iz := int(gz)
	var fx := gx - float(ix)
	var fz := gz - float(iz)
	var h00 := heights[iz * GRID + ix]
	var h10 := heights[iz * GRID + ix + 1]
	var h01 := heights[(iz + 1) * GRID + ix]
	var h11 := heights[(iz + 1) * GRID + ix + 1]
	return lerpf(lerpf(h00, h10, fx), lerpf(h01, h11, fx), fz)

func _grid_vertex(gx: int, gz: int) -> Vector3:
	var x := (float(gx) - GRID / 2.0 + 0.5) * TILE_SIZE
	var z := (float(gz) - GRID / 2.0 + 0.5) * TILE_SIZE
	return Vector3(x, _terrain_height(float(gx), float(gz)), z)

func _cell_from_point(p: Vector3) -> Vector2i:
	return Vector2i(int(round(p.x / TILE_SIZE + GRID / 2.0 - 0.5)), int(round(p.z / TILE_SIZE + GRID / 2.0 - 0.5)))

func _footing_range(x: float, z: float) -> Vector2:
	var lo := _height_at_world(x, z)
	var hi := lo
	for ox in [-26.0, 26.0]:
		for oz in [-26.0, 26.0]:
			var h := _height_at_world(x + ox, z + oz)
			lo = minf(lo, h)
			hi = maxf(hi, h)
	return Vector2(lo, hi)

func _build_sea() -> void:
	var base := MeshInstance3D.new()
	var base_plane := PlaneMesh.new()
	base_plane.size = Vector2(14000.0, 14000.0)
	base.mesh = base_plane
	base.position = Vector3(0.0, -3.0, 0.0)
	base.material_override = _mat(Color("#a89a78"), 1.0)
	terrain_root.add_child(base)
	var sea := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(4000.0, 9000.0)
	sea.mesh = plane
	sea.position = Vector3(-3000.0, -1.0, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = SEA_COLOR
	mat.roughness = 0.32
	mat.metallic = 0.05
	sea.material_override = mat
	terrain_root.add_child(sea)

func _make_source_visual(res: String) -> Node3D:
	var n := Node3D.new()
	match res:
		"Wood":
			for p in [Vector3(-14, 0, 6), Vector3(10, 0, -8), Vector3(16, 0, 14)]:
				_cyl(n, 2.4, 3.0, 20.0, p + Vector3(0, 10, 0), Color("#6b4f33"))
				_cyl(n, 0.0, 15.0, 34.0, p + Vector3(0, 36, 0), Color("#4f6b3a"))
		"Stone":
			var rocks := [
				[Vector3(-10, 9, 0), Vector3(26, 18, 22), 20.0],
				[Vector3(14, 7, 8), Vector3(20, 14, 18), -25.0],
				[Vector3(6, 6, -14), Vector3(16, 12, 14), 40.0]
			]
			for rk in rocks:
				var rock := _box(n, rk[1], rk[0], Color("#ffffff"), true)
				rock.rotation_degrees.y = rk[2]
		"Water":
			_cyl(n, 20.0, 21.0, 5.0, Vector3(0, 2.5, 0), Color("#ffffff"), true)
			_cyl(n, 15.0, 15.0, 1.5, Vector3(0, 4.9, 0), Color("#4aa3d9"))
			for p in [Vector3(-18, 0, 12), Vector3(-12, 0, 18), Vector3(20, 0, -10)]:
				_box(n, Vector3(2, 18, 2), p + Vector3(0, 9, 0), Color("#6f8f3d"))
		"Food":
			for p in [Vector3(-14, 0, 4), Vector3(8, 0, -10), Vector3(14, 0, 12)]:
				_sphere(n, 9.0, p + Vector3(0, 7, 0), Color("#8a9a45"))
				_sphere(n, 2.4, p + Vector3(5, 12, 4), Color("#d9a441"))
				_sphere(n, 2.4, p + Vector3(-4, 10, 6), Color("#d9a441"))
		"Scrap":
			_box(n, Vector3(34, 16, 8), Vector3(-6, 8, -8), Color("#ffffff"), true)
			_box(n, Vector3(10, 26, 8), Vector3(14, 13, -8), Color("#ffffff"), true)
			_box(n, Vector3(8, 5, 8), Vector3(-14, 2.5, 8), Color("#ffffff"), true)
			var sheet := _box(n, Vector3(20, 3, 14), Vector3(2, 5, 10), Color("#8a5a3a"))
			sheet.rotation_degrees = Vector3(8, 25, 4)
	return n

func _update_source_visual(s: Source) -> void:
	if s.node == null or s.infinite:
		return
	var ratio := clampf(s.amount / maxf(1.0, s.max_amount), 0.0, 1.0)
	s.node.scale = Vector3(1.0, lerpf(0.3, 1.0, ratio), 1.0)

func _make_stone_texture() -> ImageTexture:
	var w := 256
	var img := Image.create(w, w, false, Image.FORMAT_RGB8)
	var sr := RandomNumberGenerator.new()
	sr.seed = 77
	var base := Color("#e8d9b4")
	var mortar := Color("#b9a47c")
	var rows := 8
	var row_h := w / rows
	img.fill(mortar)
	for r in range(rows):
		var y0 := r * row_h
		var x := -sr.randi_range(0, 60)
		while x < w:
			var bw := sr.randi_range(56, 104)
			var tone := sr.randf_range(0.93, 1.04)
			var c := Color(minf(1.0, base.r * tone), minf(1.0, base.g * tone), minf(1.0, base.b * tone * sr.randf_range(0.96, 1.03)))
			for yy in range(y0 + 2, y0 + row_h - 1):
				for xx in range(maxi(x + 2, 0), mini(x + bw - 1, w)):
					img.set_pixel(xx, yy, c)
			x += bw
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func _mat(color: Color, rough: float = 0.95) -> StandardMaterial3D:
	var key := "%s_%s" % [color.to_html(), rough]
	if mat_cache.has(key):
		return mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	mat_cache[key] = m
	return m


func _unlit_mat(color: Color) -> StandardMaterial3D:
	var key := "unlit_" + color.to_html()
	if mat_cache.has(key):
		return mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_cache[key] = m
	return m

func _stone_mat(tint: Color = Color.WHITE) -> StandardMaterial3D:
	var key := "stone_" + tint.to_html()
	if mat_cache.has(key):
		return mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_texture = stone_texture
	m.albedo_color = tint
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.022, 0.022, 0.022)
	m.roughness = 0.95
	mat_cache[key] = m
	return m

func _pick_mat(color: Color, stone: bool) -> StandardMaterial3D:
	return _stone_mat(color) if stone else _mat(color)

func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, stone: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = _pick_mat(color, stone)
	parent.add_child(mi)
	return mi

func _cyl(parent: Node3D, top_r: float, bottom_r: float, h: float, pos: Vector3, color: Color, stone: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bottom_r
	mesh.height = h
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = _pick_mat(color, stone)
	parent.add_child(mi)
	return mi

func _sphere(parent: Node3D, r: float, pos: Vector3, color: Color, stone: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = r
	mesh.height = r * 2.0
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = _pick_mat(color, stone)
	parent.add_child(mi)
	return mi

func _dome(parent: Node3D, r: float, pos: Vector3, color: Color = Color("#fff6e0")) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = r
	mesh.height = r
	mesh.is_hemisphere = true
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = _stone_mat(color)
	parent.add_child(mi)
	return mi

func _prism(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := PrismMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = _mat(color)
	parent.add_child(mi)
	return mi

func _parapet(parent: Node3D, w: float, d: float, y: float, h: float = 4.0) -> void:
	var t := 3.0
	var c := Color("#f4ead0")
	_box(parent, Vector3(w, h, t), Vector3(0, y + h * 0.5, d * 0.5 - t * 0.5), c, true)
	_box(parent, Vector3(w, h, t), Vector3(0, y + h * 0.5, -d * 0.5 + t * 0.5), c, true)
	_box(parent, Vector3(t, h, d - 2.0 * t), Vector3(w * 0.5 - t * 0.5, y + h * 0.5, 0), c, true)
	_box(parent, Vector3(t, h, d - 2.0 * t), Vector3(-w * 0.5 + t * 0.5, y + h * 0.5, 0), c, true)

func _arch(parent: Node3D, x: float, base_y: float, w: float, h: float, z: float, fill: Color) -> void:
	var r := w * 0.5
	var frame_col := Color("#f6edd2")
	var ring := _cyl(parent, r + 3.0, r + 3.0, 1.5, Vector3(x, base_y + h - r, z - 0.2), frame_col, true)
	ring.rotation_degrees.x = 90.0
	_box(parent, Vector3(w + 6.0, h - r, 1.5), Vector3(x, base_y + (h - r) * 0.5, z - 0.2), frame_col, true)
	var disc := _cyl(parent, r, r, 2.0, Vector3(x, base_y + h - r, z), fill)
	disc.rotation_degrees.x = 90.0
	_box(parent, Vector3(w, h - r, 2.0), Vector3(x, base_y + (h - r) * 0.5, z), fill)

func _update_camera() -> void:
	camera.position = camera_target + CAM_OFFSET
	camera.look_at(camera_target, Vector3.UP)

func _build_lighting() -> void:
	sun_node = DirectionalLight3D.new()
	sun_node.rotation_degrees = Vector3(-48, -35, 0)
	sun_node.light_energy = 1.15
	add_child(sun_node)
	var env_node := WorldEnvironment.new()
	world_env = Environment.new()
	world_env.background_mode = Environment.BG_COLOR
	world_env.background_color = Color("#9cc3d5")
	world_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world_env.ambient_light_color = Color("#b9c6c2")
	world_env.ambient_light_energy = 0.75
	env_node.environment = world_env
	add_child(env_node)

func _sum_jobs() -> int:
	var n := 0
	for r in jobs:
		n += int(jobs[r])
	return n

func _clamp_jobs() -> void:
	while _sum_jobs() > survivors.size():
		var worst := ""
		var most := -1
		for r in jobs:
			if int(jobs[r]) > most:
				most = int(jobs[r])
				worst = r
		if worst == "" or most <= 0:
			break
		jobs[worst] = most - 1

func _add_villager(vname: String, skill: String) -> Villager:
	var v := Villager.new()
	v.vname = vname
	v.skill = skill
	v.node = _make_villager_node(v, skill)
	var p := _random_point_around(camp_pos, 50.0, 140.0)
	v.node.position = p
	villager_root.add_child(v.node)
	v.goal = p
	v.phase = rng.randf() * TAU
	survivors.append(v)
	return v

func _make_villager_node(v: Villager, skill: String) -> Node3D:
	var root := Node3D.new()
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 6.5
	capsule.height = 26.0
	body.mesh = capsule
	body.position.y = 13.0
	body.material_override = _mat(SKILL_COLORS[skill])
	root.add_child(body)
	_sphere(root, 5.5, Vector3(0, 31, 0), Color("#e0b88a"))
	v.carry_node = _box(root, Vector3(10, 10, 10), Vector3(0, 46, 0), Color("#ffffff"))
	v.carry_node.visible = false
	return root

func _random_point_around(center: Vector3, rmin: float, rmax: float) -> Vector3:
	var a := rng.randf() * TAU
	var r := rng.randf_range(rmin, rmax)
	var p := center + Vector3(cos(a) * r, 0.0, sin(a) * r)
	p.y = _height_at_world(p.x, p.z)
	return p

func _flat_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

func _count_builders(b: Building) -> int:
	var n := 0
	for v in survivors:
		if v.task == "build" and v.target == b:
			n += 1
	return n

func _count_job(res: String) -> int:
	var n := 0
	for v in survivors:
		if v.task == "gather" and v.job == res and not v.releasing:
			n += 1
	return n

func _nearest_idle(pos: Vector3) -> Villager:
	var best: Villager = null
	var best_d := INF
	for v in survivors:
		if v.task != "idle":
			continue
		var d := _flat_dist(v.node.position, pos)
		if d < best_d:
			best_d = d
			best = v
	return best

func _steal_gatherer(pos: Vector3) -> Villager:
	var best: Villager = null
	var best_d := INF
	for v in survivors:
		if v.task != "gather" or v.releasing or v.carry_amt > 0.0:
			continue
		var d := _flat_dist(v.node.position, pos)
		if d < best_d:
			best_d = d
			best = v
	if best != null:
		_set_idle(best)
	return best

func _pick_release(res: String) -> Villager:
	var fallback: Villager = null
	for v in survivors:
		if v.task != "gather" or v.job != res or v.releasing:
			continue
		if v.carry_amt <= 0.0:
			return v
		fallback = v
	return fallback

func _release(v: Villager) -> void:
	if v.carry_amt > 0.0:
		v.releasing = true
	else:
		_set_idle(v)

func _set_idle(v: Villager) -> void:
	v.task = "idle"
	v.job = ""
	v.state = ""
	v.target = null
	v.src = null
	v.releasing = false
	v.carry_amt = 0.0
	v.carry_res = ""
	v.carry_node.visible = false
	v.wait = 0.0
	v.goal = _random_point_around(camp_pos, 50.0, 190.0)

func _start_gather(v: Villager, res: String) -> void:
	v.task = "gather"
	v.job = res
	v.state = "seek"
	v.target = null
	v.src = null
	v.releasing = false
	v.wait = 0.0

func _send_build(v: Villager, b: Building) -> void:
	v.task = "build"
	v.job = ""
	v.state = ""
	v.src = null
	v.target = b
	v.wait = 0.0
	v.goal = _random_point_around(b.pos, 45.0, 70.0)

func _assign_tasks() -> void:
	for v in survivors:
		if v.task == "build":
			var bad := v.target == null or not buildings.has(v.target)
			if not bad:
				bad = v.target.done
			if bad:
				_set_idle(v)
	for b in buildings:
		if b.done:
			continue
		var need := 2 - _count_builders(b)
		while need > 0:
			var v := _nearest_idle(b.pos)
			if v == null:
				v = _steal_gatherer(b.pos)
			if v == null:
				break
			_send_build(v, b)
			need -= 1
	for r in jobs:
		var want := int(jobs[r])
		var have := _count_job(r)
		while have < want:
			var v2 := _nearest_idle(camp_pos)
			if v2 == null:
				break
			_start_gather(v2, r)
			have += 1
		while have > want:
			var w := _pick_release(r)
			if w == null:
				break
			_release(w)
			have -= 1

func _source_ok(s: Source) -> bool:
	return sources.has(s) and (s.infinite or s.amount >= 1.0)

func _source_users(s: Source, except: Villager) -> int:
	var n := 0
	for v in survivors:
		if v != except and v.task == "gather" and v.src == s and (v.state == "to_source" or v.state == "gathering"):
			n += 1
	return n

func _nearest_storage(pos: Vector3) -> Vector3:
	var best := camp_pos
	var best_d := _flat_dist(pos, camp_pos)
	for b in buildings:
		if b.done and b.type == "Storehouse":
			var d := _flat_dist(pos, b.pos)
			if d < best_d:
				best_d = d
				best = b.pos
	return best

func _pick_source(v: Villager) -> Source:
	var best: Source = null
	var best_score := INF
	for s in sources:
		if s.res != v.job or not _source_ok(s):
			continue
		if _source_users(s, v) >= s.slots:
			continue
		var store := _nearest_storage(s.pos)
		var walk := (_flat_dist(v.node.position, s.pos) + 2.0 * _flat_dist(s.pos, store)) / WALK_SPEED
		var score := (walk + s.gather_time) / s.yield_amt
		if score < best_score:
			best_score = score
			best = s
	return best

func _move(v: Villager, dt: float, bob: bool = false) -> bool:
	var pos := v.node.position
	var flat := Vector3(pos.x, 0.0, pos.z)
	var g := Vector3(v.goal.x, 0.0, v.goal.z)
	var dist := flat.distance_to(g)
	var hop := 0.0
	var arrived := dist <= 3.0
	if not arrived:
		var step := minf(dist, WALK_SPEED * dt)
		flat += (g - flat).normalized() * step
		v.phase += dt * 12.0
		hop = absf(sin(v.phase)) * 5.0
		v.node.rotation.y = atan2(g.x - flat.x, g.z - flat.z)
		_note_step(flat, dt)
		arrived = flat.distance_to(g) <= 3.0
	elif bob:
		v.phase += dt * 14.0
		hop = absf(sin(v.phase)) * 6.0
	v.node.position = Vector3(flat.x, _height_at_world(flat.x, flat.z) + hop, flat.z)
	return arrived

func _update_villagers(dt: float) -> void:
	for v in survivors:
		match v.task:
			"idle":
				if _move(v, dt):
					v.wait -= dt
					if v.wait <= 0.0:
						v.goal = _random_point_around(camp_pos, 50.0, 190.0)
						v.wait = rng.randf_range(1.5, 4.5)
			"build":
				if _move(v, dt, true):
					v.wait -= dt
					if v.wait <= 0.0 and v.target != null:
						v.goal = _random_point_around(v.target.pos, 40.0, 70.0)
						v.wait = rng.randf_range(2.0, 5.0)
			"gather":
				_tick_gather(v, dt)

func _tick_gather(v: Villager, dt: float) -> void:
	match v.state:
		"seek":
			v.wait -= dt
			if v.wait > 0.0:
				_move(v, dt)
				return
			var s := _pick_source(v)
			if s == null:
				v.wait = 3.0
				v.goal = _random_point_around(camp_pos, 50.0, 120.0)
				_hint_no_source(v.job)
				return
			v.src = s
			v.state = "to_source"
			v.goal = s.pos + Vector3(rng.randf_range(-16.0, 16.0), 0.0, rng.randf_range(-16.0, 16.0))
		"to_source":
			if v.src == null or not _source_ok(v.src):
				v.state = "seek"
				v.wait = 0.0
				return
			if _move(v, dt):
				v.state = "gathering"
				v.timer = v.src.gather_time
		"gathering":
			if v.src == null or not _source_ok(v.src):
				v.state = "seek"
				v.wait = 0.0
				return
			_move(v, dt, true)
			v.timer -= dt
			if v.timer <= 0.0:
				_finish_gather(v)
		"to_store":
			if _move(v, dt):
				_deliver(v)
		_:
			v.state = "seek"

func _finish_gather(v: Villager) -> void:
	var s := v.src
	var take := s.yield_amt
	if not s.infinite:
		take = minf(take, s.amount)
		s.amount -= take
		_update_source_visual(s)
	if take < 1.0:
		v.state = "seek"
		v.wait = 0.0
		return
	v.carry_res = s.res
	v.carry_amt = take
	v.carry_node.material_override = _mat(RES_COLORS[s.res])
	v.carry_node.visible = true
	v.state = "to_store"
	var store := _nearest_storage(v.node.position)
	v.goal = store + Vector3(rng.randf_range(-14.0, 14.0), 0.0, rng.randf_range(-14.0, 14.0))

func _missing_resource(cost: Dictionary) -> String:
	for r in cost:
		if float(resources[r]) < float(cost[r]):
			return r
	return ""

func _housing_capacity() -> int:
	var capacity := BASE_HOUSING
	for b in buildings:
		if b.done:
			var def: Dictionary = BUILDINGS[b.type]
			capacity += int(def["housing"])
	return capacity

func _process(delta: float) -> void:
	if toast_time > 0.0:
		toast_time -= delta
		if toast_time <= 0.0:
			toast_panel.visible = false
		elif toast_time < 0.7:
			toast_panel.modulate.a = toast_time / 0.7
	if menu_open or game_over:
		return
	var dt := 0.0 if paused else delta * game_speed
	if dt > 0.0:
		day_timer += dt
		if day_timer >= DAY_LENGTH:
			day_timer -= DAY_LENGTH
			_advance_day()
			if game_over:
				return
		_update_construction(dt)
		_update_villagers(dt)
		assign_timer += delta
		if assign_timer >= 1.0:
			assign_timer = 0.0
			_assign_tasks()
		autosave_timer += delta
		if autosave_timer >= AUTOSAVE_EVERY:
			autosave_timer = 0.0
			_write_save(AUTOSAVE_PATH, true)
	ui_timer += delta
	if ui_timer >= 0.5:
		ui_timer = 0.0
		_refresh_ui()
	if is_instance_valid(day_bar):
		day_bar.value = day_timer / DAY_LENGTH * 100.0
	# Day/night ambient light follows day progress
	if is_instance_valid(world_env) and not paused:
		var t := day_timer / DAY_LENGTH
		var day_energy := 1.15 + 0.2 * sin(t * PI)
		if is_instance_valid(sun_node):
			sun_node.light_energy = day_energy
		var season_sky: Color = SEASON_SKY[cur_season]
		var amb: Color = season_sky.lerp(Color("#4a5a7a"), (1.0 - sin(t * PI)) * 0.5)
		world_env.ambient_light_color = amb
	# Crisis overlay pulse
	if is_instance_valid(crisis_overlay) and crisis_overlay.visible:
		crisis_alpha = absf(sin(Time.get_ticks_msec() * 0.003))
		crisis_overlay.color = Color(0.8, 0.1, 0.1, crisis_alpha * 0.25)
	# Caravan visual movement
	if is_instance_valid(caravan_node) and dt > 0.0:
		caravan_timer += delta
		var cx := camp_pos.x + 800.0 - caravan_timer * 40.0
		caravan_node.position.x = cx
		if caravan_timer > 40.0 or cx < camp_pos.x - 900.0:
			caravan_node.queue_free()
			caravan_node = null
			caravan_timer = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if menu_open or game_over:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			touches[event.index] = event.position
			drag_in_sheet = is_instance_valid(build_sheet) and build_sheet.visible \
				and build_sheet.get_global_rect().has_point(event.position)
		else:
			touches.erase(event.index)
			if touches.is_empty():
				drag_in_sheet = false
		if touches.size() >= 2:
			pinch_last = _pinch_distance()
			drag_moved = true
			drag_in_sheet = false
		return
	if event is InputEventScreenDrag:
		touches[event.index] = event.position
		if touches.size() >= 2:
			var d := _pinch_distance()
			if pinch_last > 0.0 and d > 0.0:
				_zoom(pinch_last / d)
			pinch_last = d
			return
		if road_mode and touches.size() == 1:
			_paint_trail_at(event.position)
			return
		if drag_in_sheet and is_instance_valid(build_scroll):
			var new_h := build_scroll.scroll_horizontal - int(event.relative.x)
			build_scroll.scroll_horizontal = clampi(new_h, 0, 99999)
			return
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom(0.88)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom(1.12)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			right_drag = event.pressed
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				drag_active = true
				drag_moved = false
				press_pos = event.position
			else:
				if drag_active and not drag_moved and touches.size() < 2:
					_on_tap(event.position)
				drag_active = false
	elif event is InputEventMouseMotion:
		if right_drag:
			_pan_camera(event.relative)
		elif drag_active and touches.size() < 2:
			if event.position.distance_to(press_pos) > 14.0:
				drag_moved = true
			if drag_moved:
				_pan_camera(event.relative)

func _pinch_distance() -> float:
	var pts: Array = touches.values()
	if pts.size() < 2:
		return 0.0
	var a: Vector2 = pts[0]
	var b: Vector2 = pts[1]
	return a.distance_to(b)

func _zoom(factor: float) -> void:
	camera.size = clampf(camera.size * factor, 300.0, 1800.0)

func _pan_camera(delta: Vector2) -> void:
	var vh := get_viewport().get_visible_rect().size.y
	var per_px := camera.size / vh
	var cb := camera.global_transform.basis
	var right := Vector3(cb.x.x, 0.0, cb.x.z).normalized()
	var fwd := Vector3(-cb.z.x, 0.0, -cb.z.z).normalized()
	var ground_scale := CAM_OFFSET.length() / CAM_OFFSET.y
	camera_target += (-right * delta.x + fwd * delta.y * ground_scale) * per_px
	var off := Vector2(camera_target.x - camp_pos.x, camera_target.z - camp_pos.z)
	if off.length() > 1100.0:
		off = off.normalized() * 1100.0
	camera_target.x = camp_pos.x + off.x
	camera_target.z = camp_pos.z + off.y
	_update_camera()

func _ray_to_terrain(screen_pos: Vector2) -> Variant:
	var origin := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	var prev_t := 0.0
	var t := 0.0
	while t < 9000.0:
		var p := origin + dir * t
		if p.y <= _height_at_world(p.x, p.z):
			var lo := prev_t
			var hi := t
			for i in range(12):
				var mid := (lo + hi) * 0.5
				var q := origin + dir * mid
				if q.y <= _height_at_world(q.x, q.z):
					hi = mid
				else:
					lo = mid
			return origin + dir * hi
		prev_t = t
		t += 20.0
	return null

func _screen_dist(pos: Vector2, world: Vector3) -> float:
	return camera.unproject_position(world).distance_to(pos)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and is_instance_valid(day_label) and not game_over:
		_write_save(AUTOSAVE_PATH, true)

func _save_game() -> void:
	_write_save(SAVE_PATH, false)


# ---------------------------------------------------------------- new v0.6 systems

func _trend_arrow(res: String) -> String:
	if res_trend_history.size() < 2:
		return ""
	var recent: Dictionary = res_trend_history[res_trend_history.size() - 1]
	var prev: Dictionary = res_trend_history[res_trend_history.size() - 2]
	var n := float(survivors.size())
	var net_recent := float(recent.get(res, 0.0))
	var net_prev := float(prev.get(res, 0.0))
	if res == "Food":
		var mul := 0.75 if kitchen_active else 1.0
		net_recent -= n * FOOD_PER_VILLAGER * mul
		net_prev -= n * FOOD_PER_VILLAGER * mul
	elif res == "Water":
		net_recent -= n * WATER_PER_VILLAGER
		net_prev -= n * WATER_PER_VILLAGER
	var avg := (net_recent + net_prev) * 0.5
	if avg > 0.5:
		return "▲"
	elif avg < -0.5:
		return "▼"
	return ""


func _log_event(msg: String) -> void:
	event_log.push_front(msg)
	if event_log.size() > 20:
		event_log.pop_back()


func _build_crisis_overlay() -> void:
	crisis_overlay = ColorRect.new()
	crisis_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	crisis_overlay.color = Color(0.8, 0.1, 0.1, 0.0)
	crisis_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crisis_overlay.visible = false
	ui_root.add_child(crisis_overlay)


func _build_log_sheet() -> void:
	log_sheet = _sheet(Control.PRESET_CENTER_BOTTOM)
	log_sheet.grow_horizontal = Control.GROW_DIRECTION_BOTH
	log_sheet.grow_vertical = Control.GROW_DIRECTION_BEGIN
	log_sheet.offset_bottom = -116
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(560, 0)
	box.add_theme_constant_override("separation", 6)
	log_sheet.add_child(box)
	box.add_child(_label("سجل الأحداث", 28, C_GOLD))
	log_list = VBoxContainer.new()
	log_list.add_theme_constant_override("separation", 5)
	box.add_child(log_list)


func _refresh_log_sheet() -> void:
	for c in log_list.get_children():
		c.queue_free()
	if event_log.is_empty():
		log_list.add_child(_label("لا أحداث بعد.", 18, C_MUTED))
		return
	for entry in event_log:
		var l := _label(str(entry), 18, C_CREAM)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		log_list.add_child(l)


func _has_building(type: String) -> bool:
	for b in buildings:
		if b.type == type and b.done:
			return true
	return false


func _build_villages_sheet() -> void:
	villages_sheet = _sheet(Control.PRESET_CENTER_BOTTOM)
	villages_sheet.grow_horizontal = Control.GROW_DIRECTION_BOTH
	villages_sheet.grow_vertical = Control.GROW_DIRECTION_BEGIN
	villages_sheet.offset_bottom = -116
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(660, 0)
	box.add_theme_constant_override("separation", 10)
	villages_sheet.add_child(box)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	box.add_child(header)
	header.add_child(_label("القرى المستكشفة", 28, C_GOLD))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(sp)
	explore_btn = _button("اكتشف قرية (%d دينار)" % EXPLORE_BASE_COST, _on_explore_pressed, Vector2(260, 52), 18, C_BTN)
	header.add_child(explore_btn)
	villages_content = VBoxContainer.new()
	villages_content.add_theme_constant_override("separation", 10)
	box.add_child(villages_content)


func _refresh_villages_sheet() -> void:
	if not is_instance_valid(villages_content):
		return
	for c in villages_content.get_children():
		c.queue_free()
	var cost := EXPLORE_BASE_COST + discovered_villages.size() * EXPLORE_COST_STEP
	if is_instance_valid(explore_btn):
		if exploring:
			explore_btn.text = "يستكشف... يوم %d" % explore_done_day
			explore_btn.disabled = true
		elif discovered_villages.size() >= VILLAGES.size():
			explore_btn.text = "كل القرى مستكشفة"
			explore_btn.disabled = true
		else:
			explore_btn.text = "اكتشف قرية (%d دينار)" % cost
			explore_btn.disabled = false
	if discovered_villages.is_empty():
		villages_content.add_child(_label("أرسل مجموعة استكشاف لاكتشاف القرى المجاورة.", 19, C_MUTED))
		return
	var stable := _has_building("Stable")
	for idx in discovered_villages:
		var v: Dictionary = VILLAGES[idx]
		var vsell: Array = v["sells"]
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		villages_content.add_child(vbox)
		var name_lbl := _label("🏘 %s" % str(v["ar"]), 22, C_CREAM)
		vbox.add_child(name_lbl)
		if stable:
			vbox.add_child(_label("الإسطبل يضاعف الكميات", 14, Color("#a0c870")))
		var items_row := HBoxContainer.new()
		items_row.add_theme_constant_override("separation", 14)
		vbox.add_child(items_row)
		for item in vsell:
			var item_d: Dictionary = item
			var res: String = str(item_d["res"])
			var qty: int = int(item_d["qty"]) * (2 if stable else 1)
			var dinar: int = int(item_d["dinar"]) * (2 if stable else 1)
			var col := VBoxContainer.new()
			col.add_theme_constant_override("separation", 4)
			var top_row := HBoxContainer.new()
			top_row.add_theme_constant_override("separation", 5)
			top_row.add_child(_dot(RES_COLORS[res], 11.0))
			top_row.add_child(_label("%d %s" % [qty, RES_AR[res]], 20))
			col.add_child(top_row)
			var vi := idx
			var buy_btn := _button("%d دينار" % dinar, func():
				if float(resources.get("Dinar", 0.0)) >= float(dinar):
					resources["Dinar"] = float(resources["Dinar"]) - float(dinar)
					resources[res] = float(resources.get(res, 0.0)) + float(qty)
					_log_event("💰 يوم %d: اشتريت %d %s من %s." % [day, qty, RES_AR[res], str(VILLAGES[vi]["ar"])])
					_toast("اشتريت %d %s." % [qty, RES_AR[res]], 3.0)
					_refresh_ui()
				else:
					_toast("لا تملك %d دينار." % dinar)
			, Vector2(130, 48), 18, C_GREEN)
			col.add_child(buy_btn)
			items_row.add_child(col)
		var sep2 := HSeparator.new()
		villages_content.add_child(sep2)


func _on_explore_pressed() -> void:
	if exploring:
		_toast("مجموعة الاستكشاف في الطريق. انتظر حتى اليوم %d." % explore_done_day)
		return
	if discovered_villages.size() >= VILLAGES.size():
		_toast("اكتُشفت كل القرى المحيطة.")
		return
	var cost := EXPLORE_BASE_COST + discovered_villages.size() * EXPLORE_COST_STEP
	if float(resources.get("Dinar", 0.0)) < float(cost):
		_toast("ينقصك %d دينار لإرسال مجموعة الاستكشاف." % cost)
		return
	resources["Dinar"] = float(resources["Dinar"]) - float(cost)
	exploring = true
	explore_done_day = day + EXPLORE_DAYS
	_toast("انطلقت مجموعة الاستكشاف! ستعود في اليوم %d." % explore_done_day, 5.0)
	_log_event("🔍 يوم %d: بدأ الاستكشاف (تكلفة %d دينار)." % [day, cost])
	_refresh_ui()


func _finish_explore() -> void:
	var available: Array[int] = []
	for i in range(VILLAGES.size()):
		if not discovered_villages.has(i):
			available.append(i)
	if available.is_empty():
		_toast("عادت المجموعة. لم تجد قرى جديدة.")
		return
	var idx := available[rng.randi() % available.size()]
	discovered_villages.append(idx)
	var v: Dictionary = VILLAGES[idx]
	_toast("اكتُشفت قرية: %s! افتح «القرى» للتجارة معهم." % str(v["ar"]), 7.0)
	_log_event("🏘 يوم %d: اكتُشفت قرية %s." % [day, str(v["ar"])])
	_add_xp(20.0)
	_refresh_villages_sheet()
	_refresh_ui()


func _show_village_trade(village_idx: int) -> void:
	var v: Dictionary = VILLAGES[village_idx]
	var sells: Array = v["sells"]
	var buys: Array = v.get("buys", [])
	var layer := CanvasLayer.new()
	layer.layer = 18
	add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.65)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(600, 0)
	panel.layout_direction = Control.LAYOUT_DIRECTION_RTL
	layer.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	vb.add_child(_label("تجارة مع %s" % str(v["ar"]), 28, C_GOLD))
	vb.add_child(_label("دينارك: %d" % int(resources.get("Dinar", 0.0)), 18, C_MUTED))
	# --- BUY section ---
	vb.add_child(_label("شراء من القرية:", 20, C_CREAM))
	for item in sells:
		var item_d: Dictionary = item
		var res: String = str(item_d["res"])
		var qty: int = int(item_d["qty"])
		var dinar: int = int(item_d["dinar"])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		vb.add_child(row)
		row.add_child(_dot(RES_COLORS[res], 14.0))
		row.add_child(_label("%d %s" % [qty, RES_AR[res]], 22))
		var sp := Control.new()
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(sp)
		row.add_child(_label("← %d دينار" % dinar, 20, C_GOLD))
		var buy_btn := _button("شراء", func():
			if float(resources.get("Dinar", 0.0)) >= float(dinar):
				resources["Dinar"] = float(resources["Dinar"]) - float(dinar)
				resources[res] = float(resources.get(res, 0.0)) + float(qty)
				_log_event("💰 يوم %d: اشتريت %d %s من %s." % [day, qty, RES_AR[res], str(v["ar"])])
				_toast("اشتريت %d %s." % [qty, RES_AR[res]], 3.0)
				_refresh_ui()
			else:
				_toast("لا تملك %d دينار." % dinar)
		, Vector2(120, 50), 19, C_GREEN)
		row.add_child(buy_btn)
	# --- SELL section ---
	if buys.size() > 0:
		var sep := HSeparator.new()
		vb.add_child(sep)
		vb.add_child(_label("بيع للقرية:", 20, C_CREAM))
		for item2 in buys:
			var item_d2: Dictionary = item2
			var res2: String = str(item_d2["res"])
			var qty2: int = int(item_d2["qty"])
			var dinar2: int = int(item_d2["dinar"])
			var row2 := HBoxContainer.new()
			row2.add_theme_constant_override("separation", 12)
			vb.add_child(row2)
			row2.add_child(_dot(RES_COLORS[res2], 14.0))
			row2.add_child(_label("%d %s" % [qty2, RES_AR[res2]], 22))
			var sp2 := Control.new()
			sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row2.add_child(sp2)
			row2.add_child(_label("%d دينار ←" % dinar2, 20, C_GOLD))
			var sell_btn := _button("بيع", func():
				if float(resources.get(res2, 0.0)) >= float(qty2):
					resources[res2] = float(resources.get(res2, 0.0)) - float(qty2)
					resources["Dinar"] = float(resources.get("Dinar", 0.0)) + float(dinar2)
					_log_event("💰 يوم %d: بعت %d %s لـ%s بـ%d دينار." % [day, qty2, RES_AR[res2], str(v["ar"]), dinar2])
					_toast("بعت %d %s بـ%d دينار." % [qty2, RES_AR[res2], dinar2], 3.0)
					_refresh_ui()
				else:
					_toast("لا تملك كمية كافية من %s." % RES_AR[res2])
			, Vector2(120, 50), 19, Color("#c8a820"))
			row2.add_child(sell_btn)
	vb.add_child(_button("إغلاق", layer.queue_free.bind(), Vector2(0, 54), 22))


func _spawn_caravan_visual() -> void:
	if is_instance_valid(caravan_node):
		caravan_node.queue_free()
	caravan_node = Node3D.new()
	var start_x := camp_pos.x + 800.0
	caravan_node.position = Vector3(start_x, _height_at_world(start_x, camp_pos.z), camp_pos.z)
	add_child(caravan_node)
	caravan_timer = 0.0
	# 3 camels (simple capsule + sphere)
	for i in range(3):
		var camel := Node3D.new()
		camel.position = Vector3(float(i) * -80.0, 0.0, float(i % 2) * 30.0 - 15.0)
		caravan_node.add_child(camel)
		var body := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 14.0
		cap.height = 38.0
		body.mesh = cap
		body.rotation_degrees.z = 90.0
		body.position.y = 24.0
		body.material_override = _mat(Color("#c8a86a"))
		camel.add_child(body)
		var neck := MeshInstance3D.new()
		var ncap := CapsuleMesh.new()
		ncap.radius = 7.0
		ncap.height = 28.0
		neck.mesh = ncap
		neck.position = Vector3(22.0, 38.0, 0.0)
		neck.rotation_degrees.z = -30.0
		neck.material_override = _mat(Color("#c8a86a"))
		camel.add_child(neck)
		var head := MeshInstance3D.new()
		var hsph := SphereMesh.new()
		hsph.radius = 9.0
		head.mesh = hsph
		head.position = Vector3(34.0, 50.0, 0.0)
		head.material_override = _mat(Color("#d8b87a"))
		camel.add_child(head)
		# cargo
		var cargo := MeshInstance3D.new()
		var cbox := BoxMesh.new()
		cbox.size = Vector3(24, 14, 20)
		cargo.mesh = cbox
		cargo.position.y = 44.0
		cargo.material_override = _mat(Color("#8a5a3a"))
		camel.add_child(cargo)
