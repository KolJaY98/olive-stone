extends Node3D

# الزيتون والحجر (Olive & Stone) v0.4 - colony survival prototype rooted in Palestine.
# A brand-new colony right after a disaster near Haifa: 5 survivors, a fire and two
# patched tents on a small levelled terrace. Nothing grows by itself - villagers walk
# to resource points, gather, and carry loads back. Experience unlocks buildings and
# building plots. Arabic, right-to-left interface.

const VERSION := "3.1.0"
const GRID := 48
const TILE_SIZE := 75.0
const START_POP := 5
const BASE_HOUSING := 6
const SAVE_PATH := "user://olive_stone_save.json"
const AUTOSAVE_PATH := "user://olive_stone_autosave.json"
const SETTINGS_PATH := "user://settings.cfg"
const SAVE_VERSION := 8
const MIN_SAVE_VERSION := 6
const WORLD_SEED := 987654
const SEA_COLOR := Color("#477f91")
const DAY_LENGTH := 25.0
const WALK_SPEED := 70.0
const FOOD_PER_VILLAGER := 1.6
const WATER_PER_VILLAGER := 1.7
const AUTOSAVE_EVERY := 150.0
const CAM_OFFSET := Vector3(1800, 2200, 2100)
const CAMP_CELL := Vector2i(15, 24)
const PLATEAU_R0 := 5.2
const PLATEAU_R1 := 7.6
const TRAIL_CELL := 26.0
const TRAIL_MAX := 900
const MAX_LEVEL := 5
const LEVEL_XP := [0.0, 180.0, 650.0, 1500.0, 2700.0]
const SEASON_DAYS := 20
const SEASON_NAMES := ["ربيع", "صيف", "خريف", "شتاء"]
const SEASON_AR := ["🌱 الربيع", "☀ الصيف", "🍂 الخريف", "❄ الشتاء"]
const SEASON_WATER_MUL := [1.0, 1.4, 1.0, 1.0]
const SEASON_FOOD_MUL := [1.0, 1.0, 1.0, 1.2]
const SEASON_SKY := [Color("#c8dff0"), Color("#d8eed0"), Color("#e8c870"), Color("#9ab8d0")]
const SEASON_COLOR := [Color("#7acc60"), Color("#ffc840"), Color("#e87030"), Color("#80b0e0")]
const PLACE_CELL := 64.0      # square grid cell for free placement (S=1x1, M=2x2, L=3x3)
const OLD_PLACE_CELL := 88.0  # v2/v3.0 grid, used to convert old saves
const LV_UNIT := 88.0         # land-value radii are expressed in these units
const CLASS_FILL := {"S": 1.0, "M": 1.15, "L": 1.3}
# Buildable territory radius per settlement level; roads extend it (see _in_territory).
const TERRITORY_R := [430.0, 560.0, 700.0, 840.0, 980.0]
const ROAD_REACH := 150.0     # building cells within this distance of a road are in territory
const MAX_SLOPE := 70.0       # max height difference under a footprint
const DAY_XP := 3.0

# ── City Skylines systems ──────────────────────────────────────────────────────
# Land value is recomputed every day as the sum of what nearby buildings radiate.
const LAND_VALUE_SOURCES := {
	"Camp":        {"radius": 3, "delta": 22.0},
	"Mosque":      {"radius": 3, "delta": 28.0},
	"Town Square": {"radius": 4, "delta": 24.0},
	"Diwan":       {"radius": 3, "delta": 22.0},
	"Market":      {"radius": 2, "delta": 14.0},
	"School":      {"radius": 3, "delta": 16.0},
	"Library":     {"radius": 3, "delta": 16.0},
	"Clinic":      {"radius": 2, "delta": 14.0},
	"Plaza":       {"radius": 3, "delta": 14.0},
	"Well":        {"radius": 2, "delta":  8.0},
	"Stone House": {"radius": 1, "delta":  5.0},
	"Large House": {"radius": 1, "delta":  6.0},
	"Khan":        {"radius": 2, "delta": 10.0},
	"Quarry":      {"radius": 2, "delta": -24.0},
	"Workshop":    {"radius": 2, "delta": -16.0},
	"Small Quarry":{"radius": 1, "delta": -12.0},
	"Woodcutter":  {"radius": 1, "delta":  -6.0},
	"Olive Press": {"radius": 1, "delta":  -8.0},
	"Pen":         {"radius": 1, "delta": -10.0},
	"Barracks":    {"radius": 1, "delta":  -6.0},
}
# Service coverage: radius in world units; benefit scales with the share of housing covered.
const SERVICE_COVERAGE := {
	"Mosque":      {"radius": 260.0, "morale": 1.2},
	"Town Square": {"radius": 220.0, "morale": 0.8, "discontent": -0.5},
	"Plaza":       {"radius": 180.0, "morale": 0.6},
	"Clinic":      {"radius": 240.0, "heal_bonus": 1.0},
	"School":      {"radius": 240.0, "xp_bonus": 0.5},
	"Library":     {"radius": 240.0, "xp_bonus": 1.0},
}
const MIN_LAND_VALUE_REQ := {
	"Stone House": 12.0,
	"Large House": 18.0,
	"Khan":        22.0,
	"Library":     10.0,
	"School":      8.0,
	"Diwan":       15.0,
}
# Zoning (painted on placement cells). Each building has a "cat".
const ZONE_AR := {1: "سكنية", 2: "تجارية", 3: "صناعية", 4: "زراعية"}
const ZONE_COLORS := {1: Color(0.35, 0.75, 0.35, 0.38), 2: Color(0.35, 0.6, 0.95, 0.38), 3: Color(0.95, 0.65, 0.2, 0.38), 4: Color(0.85, 0.85, 0.3, 0.38)}
const ZONE_MATCH := {1: "res", 2: "com", 3: "ind", 4: "agri"}
const ZONE_FORBID := {1: ["ind", "agri"], 2: ["ind", "agri"], 3: ["res"], 4: ["res", "ind"]}
const ZONE_BONUS := 0.2
# Roads painted by the player (TRAIL_CELL grid). Speed multipliers for walkers.
const ROAD_DIRT := 1
const ROAD_PAVED := 2
const ROAD_SPEED := {0: 1.0, 1: 1.45, 2: 1.9}
const TRAIL_SPEED := 1.15
const PAVED_COST := 2.0       # stone per paved cell
const ROAD_MAX := 1400

# Winter/autumn firewood per villager per day (index = season).
const HEAT_WOOD := [0.0, 0.0, 0.15, 0.4]
const SOLDIER_FOOD := 0.5     # extra food per soldier on top of normal ration

# Army (Whiteout-Survival style troop types, adapted).
const UNITS := {
	"guard":  {"ar": "حارس",  "power": 10.0, "cost": {"Scrap": 6.0, "Dinar": 4.0}, "wage": 0.3, "lv": 2, "color": Color("#8a3a2e")},
	"archer": {"ar": "رامٍ",  "power": 15.0, "cost": {"Wood": 10.0, "Scrap": 6.0, "Dinar": 6.0}, "wage": 0.5, "lv": 3, "color": Color("#3a5a8a")},
	"rider":  {"ar": "فارس",  "power": 26.0, "cost": {"Scrap": 10.0, "Food": 12.0, "Dinar": 12.0}, "wage": 0.9, "lv": 4, "color": Color("#5a3a7a"), "needs": "Stable"},
}
const UNIT_ORDER := ["guard", "archer", "rider"]
const MILITIA_POWER := 1.5    # every non-soldier villager defends a little
const RAID_FIRST_DAY := 20
const RAID_MIN_GAP := 9
const RAID_MAX_GAP := 13
const BANDIT_LAIRS := [
	{"ar": "وكر وادي النسناس", "power": 45.0, "loot": {"Dinar": 25.0, "Scrap": 20.0}},
	{"ar": "مغارة الكرمل",      "power": 80.0, "loot": {"Dinar": 40.0, "Stone": 40.0}},
	{"ar": "معسكر السهل الساحلي", "power": 130.0, "loot": {"Dinar": 70.0, "Wood": 60.0, "Scrap": 30.0}},
	{"ar": "قلعة قطّاع الطرق",   "power": 200.0, "loot": {"Dinar": 120.0, "Oil": 20.0, "Scrap": 50.0}},
]
# Diwan policies (Cities: Skylines style). Effects are applied in _advance_day / gathering.
const POLICIES := {
	"water_ration": {"ar": "تقنين المياه",   "desc": "استهلاك الماء −25%، المعنويات −0.6/يوم"},
	"long_shifts":  {"ar": "نوبات عمل طويلة", "desc": "الجمع أسرع 20%، الصحة −0.6/يوم"},
	"militia":      {"ar": "التعبئة الشعبية", "desc": "دفاع الأهالي ×2، السخط +0.4/يوم"},
	"forest_care":  {"ar": "حماية الأحراش",   "desc": "تجدد الخشب ×2، غلة الخشب −15%"},
	"relief":       {"ar": "إعفاء الفقراء",   "desc": "الضريبة −50%، السخط −0.5/يوم"},
}
# Village trade tuning
const TRADE_STOCK := 3        # times each offer can be used per day
const CONTRACT_EVERY := 3     # days between contract deliveries
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
const START_RESOURCES := {"Food": 60.0, "Water": 70.0, "Wood": 60.0, "Stone": 40.0, "Scrap": 20.0, "Oil": 0.0, "Dinar": 10.0}
const START_JOBS := {"Food": 2, "Water": 2, "Wood": 1, "Stone": 0, "Scrap": 0, "Oil": 0}
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
const PLOT_SIZES := {"S": Vector2(60, 60), "M": Vector2(124, 124), "L": Vector2(188, 188)}
const PLOT_AR := {"S": "صغيرة", "M": "متوسطة", "L": "كبيرة"}
# v2.0.0: Free placement — no fixed plots. Buildings placed freely on flat plateau, grid-snapped.
# Zone painting is a separate layer: zones give bonuses, not restrictions.

const BUILDINGS := {
	# ── سكن ──
	"Tent": {
		"ar": "خيمة", "cls": "S", "lv": 1, "tab": "home", "cat": "res", "cost": {"Wood": 12.0, "Scrap": 4.0},
		"time": 6.0, "housing": 3, "gather": {}, "xp": 20.0, "scale": 1.0, "upkeep": {}, "hidden": true,
		"desc": "مأوى مرتجل يتسع لـ3 ناجين."
	},
	"Shack": {
		"ar": "كوخ خشبي", "cls": "S", "lv": 1, "tab": "home", "cat": "res", "cost": {"Wood": 14.0, "Scrap": 3.0},
		"time": 7.0, "housing": 3, "gather": {}, "xp": 20.0, "scale": 1.0, "upkeep": {"Wood": 0.05}, "soft": true,
		"desc": "أول بيت بعد الخيام: خشب وصفيح لـ3 ناجين."
	},
	"Small House": {
		"ar": "منزل صغير", "cls": "S", "lv": 1, "tab": "home", "cat": "res", "cost": {"Wood": 16.0, "Stone": 10.0},
		"time": 10.0, "housing": 4, "gather": {}, "xp": 28.0, "scale": 1.2, "upkeep": {"Wood": 0.05}, "soft": true,
		"desc": "بيت فلاحي من الطين والجير، باب أزرق وطابون — لـ4 ناجين."
	},
	"Stone House": {
		"ar": "بيت حجري", "cls": "M", "lv": 2, "tab": "home", "cat": "res", "cost": {"Wood": 20.0, "Stone": 22.0},
		"time": 16.0, "housing": 6, "gather": {}, "xp": 45.0, "scale": 1.9, "upkeep": {"Stone": 0.1}, "soft": true,
		"desc": "بيت من حجر القدس بقبة ودرج خارجي لـ6 ناجين. يحتاج قيمة أرض جيدة."
	},
	"Large House": {
		"ar": "دار بحوش", "cls": "L", "lv": 3, "tab": "home", "cat": "res", "cost": {"Stone": 35.0, "Wood": 16.0},
		"time": 22.0, "housing": 10, "gather": {}, "xp": 55.0, "scale": 2.15, "upkeep": {"Stone": 0.15}, "soft": true,
		"desc": "دار من طابقين حول حوش فيه زيتونة ونافورة — لعائلة من 10."
	},
	"Khan": {
		"ar": "الخان", "cls": "L", "lv": 4, "tab": "home", "cat": "com", "cost": {"Stone": 45.0, "Wood": 22.0, "Dinar": 20.0},
		"time": 28.0, "housing": 15, "gather": {}, "xp": 80.0, "scale": 2.3, "upkeep": {"Stone": 0.2, "Wood": 0.2}, "soft": true,
		"trade_bonus": 0.1,
		"desc": "مأوى لـ15 ناجيًا وتجارًا — يحسّن أسعار التجارة 10%."
	},
	# ── زراعة ──
	"Well": {
		"ar": "بئر", "cls": "S", "lv": 1, "tab": "agri", "cat": "any", "cost": {"Stone": 16.0, "Wood": 8.0},
		"time": 10.0, "housing": 0, "xp": 25.0, "scale": 1.4, "upkeep": {},
		"gather": {"res": "Water", "yield": 4.0, "time": 5.0, "slots": 3},
		"desc": "ماء قريب لا ينضب (3 سقّائين)."
	},
	"Farm": {
		"ar": "مزرعة", "cls": "L", "lv": 1, "tab": "agri", "cat": "agri", "cost": {"Wood": 14.0, "Stone": 6.0},
		"time": 12.0, "housing": 0, "xp": 30.0, "scale": 2.05, "upkeep": {"Water": 1.5},
		"gather": {"res": "Food", "yield": 5.0, "time": 7.5, "slots": 2},
		"desc": "طعام ثابت (مزارعان). تستهلك ماء الري يوميًا."
	},
	"Olive Grove": {
		"ar": "بستان زيتون", "cls": "L", "lv": 2, "tab": "agri", "cat": "agri", "cost": {"Wood": 16.0, "Stone": 5.0},
		"time": 12.0, "housing": 0, "xp": 35.0, "scale": 2.1, "upkeep": {},
		"gather": {"res": "Food", "yield": 3.5, "time": 6.0, "slots": 3},
		"desc": "زيتون وطعام (3 قطّافين). حصاد إضافي في الخريف."
	},
	"Pen": {
		"ar": "حظيرة", "cls": "M", "lv": 2, "tab": "agri", "cat": "agri", "cost": {"Wood": 22.0, "Stone": 10.0},
		"time": 14.0, "housing": 0, "xp": 35.0, "scale": 1.85, "upkeep": {"Water": 0.6},
		"gather": {"res": "Food", "yield": 3.0, "time": 8.0, "slots": 2},
		"desc": "ماعز ودجاج — بيض ولحم (راعيان). تشرب الماشية يوميًا."
	},
	"Fishing Dock": {
		"ar": "رصيف الصيد", "cls": "L", "lv": 2, "tab": "agri", "cat": "agri", "cost": {"Wood": 28.0, "Stone": 16.0},
		"time": 18.0, "housing": 0, "xp": 50.0, "scale": 2.1, "upkeep": {"Wood": 0.2},
		"gather": {"res": "Food", "yield": 5.0, "time": 7.0, "slots": 3},
		"coastal": true,
		"desc": "على شاطئ البحر فقط — مدّ طريقًا إلى الساحل غربًا (3 صيادين)."
	},
	# ── صناعة ──
	"Woodcutter": {
		"ar": "كوخ الحطّاب", "cls": "S", "lv": 1, "tab": "ind", "cat": "ind", "cost": {"Wood": 10.0, "Stone": 6.0},
		"time": 8.0, "housing": 0, "xp": 22.0, "scale": 1.2, "upkeep": {},
		"gather": {"res": "Wood", "yield": 3.0, "time": 6.0, "slots": 2},
		"desc": "يزرع الأحراش ويقطعها — حطب لا ينضب (حطّابان)."
	},
	"Small Quarry": {
		"ar": "مقلع صغير", "cls": "S", "lv": 1, "tab": "ind", "cat": "ind", "cost": {"Wood": 8.0, "Scrap": 4.0},
		"time": 8.0, "housing": 0, "xp": 22.0, "scale": 1.25, "upkeep": {},
		"gather": {"res": "Stone", "yield": 2.0, "time": 5.0, "slots": 1},
		"desc": "حجر مبكر من الأنقاض (عامل واحد). مزعج للجيران."
	},
	"Storehouse": {
		"ar": "مخزن", "cls": "M", "lv": 1, "tab": "ind", "cat": "any", "cost": {"Wood": 22.0, "Stone": 8.0},
		"time": 10.0, "housing": 0, "gather": {}, "xp": 30.0, "scale": 1.75, "upkeep": {"Wood": 0.1},
		"desc": "نقطة تسليم تقصّر رحلات الجمع."
	},
	"Quarry": {
		"ar": "مقلع", "cls": "L", "lv": 3, "tab": "ind", "cat": "ind", "cost": {"Wood": 22.0, "Scrap": 6.0},
		"time": 16.0, "housing": 0, "xp": 50.0, "scale": 2.05, "upkeep": {"Scrap": 0.2},
		"gather": {"res": "Stone", "yield": 3.5, "time": 5.0, "slots": 3},
		"desc": "حجر لا ينضب (3 قلّاعين). تستهلك الأدوات (خردة)."
	},
	"Workshop": {
		"ar": "ورشة", "cls": "M", "lv": 3, "tab": "ind", "cat": "ind", "cost": {"Wood": 20.0, "Stone": 14.0, "Scrap": 8.0},
		"time": 18.0, "housing": 0, "xp": 60.0, "scale": 1.9, "upkeep": {"Wood": 0.3},
		"gather": {"res": "Scrap", "yield": 2.5, "time": 5.0, "slots": 2},
		"desc": "خردة وأدوات (عاملان). وقودها الخشب."
	},
	"Olive Press": {
		"ar": "معصرة زيتون", "cls": "M", "lv": 3, "tab": "ind", "cat": "ind", "cost": {"Wood": 20.0, "Stone": 16.0},
		"time": 14.0, "housing": 0, "xp": 40.0, "scale": 1.8, "upkeep": {"Wood": 0.2},
		"gather": {"res": "Oil", "yield": 3.0, "time": 6.0, "slots": 2},
		"desc": "زيت الزيتون: يضيء الجامع والمكتبة، يلزم العيادة والمطبخ، ويُباع غاليًا."
	},
	# ── خدمات ──
	"Kitchen": {
		"ar": "مطبخ", "cls": "M", "lv": 2, "tab": "serv", "cat": "any", "cost": {"Wood": 16.0, "Stone": 12.0, "Scrap": 5.0},
		"time": 12.0, "housing": 0, "gather": {}, "xp": 35.0, "scale": 1.8, "upkeep": {"Wood": 0.8},
		"kitchen": true,
		"desc": "وجبات مشتركة — استهلاك الطعام −25%. يحتاج حطبًا للطبخ."
	},
	"Clinic": {
		"ar": "عيادة", "cls": "M", "lv": 2, "tab": "serv", "cat": "any", "cost": {"Stone": 22.0, "Wood": 12.0, "Scrap": 8.0},
		"time": 16.0, "housing": 0, "gather": {}, "xp": 50.0, "scale": 1.85, "upkeep": {"Oil": 0.3, "Dinar": 0.4},
		"clinic": true,
		"desc": "شفاء أسرع لمن يسكن قربها. تحتاج زيتًا ودنانير."
	},
	"School": {
		"ar": "مدرسة", "cls": "M", "lv": 3, "tab": "serv", "cat": "any", "cost": {"Stone": 30.0, "Wood": 18.0},
		"time": 20.0, "housing": 0, "gather": {}, "xp": 60.0, "scale": 1.9, "upkeep": {"Dinar": 0.6, "Wood": 0.2},
		"school": true,
		"desc": "خبرة أكثر لمن يسكن قربها. أجور المعلمين بالدينار."
	},
	"Library": {
		"ar": "مكتبة", "cls": "M", "lv": 3, "tab": "serv", "cat": "any", "cost": {"Stone": 26.0, "Wood": 16.0, "Dinar": 10.0},
		"time": 18.0, "housing": 0, "gather": {}, "xp": 55.0, "scale": 1.85, "upkeep": {"Dinar": 0.5, "Oil": 0.2},
		"library": true,
		"desc": "تضاعف الخبرة من التسليم. قناديلها بالزيت."
	},
	"Diwan": {
		"ar": "الديوان", "cls": "L", "lv": 3, "tab": "serv", "cat": "any", "cost": {"Stone": 35.0, "Wood": 20.0, "Dinar": 30.0},
		"time": 20.0, "housing": 0, "gather": {}, "xp": 80.0, "scale": 2.2, "upkeep": {},
		"council": true,
		"desc": "مجلس المستوطنة: ضرائب وسياسات وقرارات."
	},
	# ── ترفيه ──
	"Plaza": {
		"ar": "ساحة عامة", "cls": "S", "lv": 2, "tab": "fun", "cat": "any", "cost": {"Stone": 14.0, "Wood": 8.0},
		"time": 10.0, "housing": 0, "gather": {}, "xp": 28.0, "scale": 0.85, "upkeep": {},
		"plaza": true,
		"desc": "فضاء مفتوح يرفع المعنويات ويرفع قيمة الأرض."
	},
	"Mosque": {
		"ar": "جامع", "cls": "M", "lv": 2, "tab": "fun", "cat": "any", "cost": {"Stone": 28.0, "Wood": 14.0},
		"time": 18.0, "housing": 0, "gather": {}, "xp": 55.0, "scale": 1.95, "upkeep": {"Oil": 0.2},
		"mosque": true,
		"desc": "معنويات يومية لمن حوله، وصلاة الجمعة +15. قناديله بالزيت."
	},
	"Town Square": {
		"ar": "ساحة المدينة", "cls": "L", "lv": 3, "tab": "fun", "cat": "any", "cost": {"Stone": 35.0, "Wood": 16.0, "Dinar": 15.0},
		"time": 22.0, "housing": 0, "gather": {}, "xp": 70.0, "scale": 2.1, "upkeep": {"Dinar": 0.3},
		"town_square": true,
		"desc": "قلب المدينة: معنويات، سخط أقل، وافدون أسرع."
	},
	# ── تجارة ──
	"Market": {
		"ar": "السوق", "cls": "M", "lv": 2, "tab": "com", "cat": "com", "cost": {"Wood": 20.0, "Stone": 14.0, "Dinar": 8.0},
		"time": 14.0, "housing": 0, "gather": {}, "xp": 45.0, "scale": 1.85, "upkeep": {},
		"market": true, "trade_bonus": 0.1,
		"desc": "دخل يومي بالدينار من حركة السكان + أسعار أفضل + عقود تجارية."
	},
	"Stable": {
		"ar": "إسطبل", "cls": "M", "lv": 2, "tab": "com", "cat": "com", "cost": {"Wood": 20.0, "Stone": 14.0},
		"time": 14.0, "housing": 0, "gather": {}, "xp": 40.0, "scale": 1.9, "upkeep": {"Food": 0.6, "Water": 0.4},
		"stable": true,
		"desc": "خيول: كميات تجارة مضاعفة، عقود تجارية، وفرسان للجيش."
	},
	# ── دفاع ──
	"Watchtower": {
		"ar": "برج المراقبة", "cls": "S", "lv": 1, "tab": "def", "cat": "any", "cost": {"Stone": 18.0, "Wood": 14.0},
		"time": 10.0, "housing": 0, "gather": {}, "xp": 30.0, "scale": 1.3, "upkeep": {"Wood": 0.15},
		"watchtower": true, "defense": 8.0,
		"desc": "يكشف الغارات قبل يوم ويعطي دفاعًا +8. ناره بالحطب."
	},
	"Barracks": {
		"ar": "الثكنة", "cls": "M", "lv": 2, "tab": "def", "cat": "any", "cost": {"Wood": 20.0, "Stone": 18.0, "Scrap": 6.0},
		"time": 16.0, "housing": 0, "gather": {}, "xp": 45.0, "scale": 1.9, "upkeep": {"Dinar": 0.2},
		"barracks": true,
		"desc": "تجنيد حرّاس ورماة وفرسان (6 جنود لكل مستوى)."
	},
	"Wall": {
		"ar": "سور حجري", "cls": "S", "lv": 3, "tab": "def", "cat": "any", "cost": {"Stone": 20.0},
		"time": 8.0, "housing": 0, "gather": {}, "xp": 18.0, "scale": 0.72, "upkeep": {"Stone": 0.05}, "soft": true,
		"defense": 12.0,
		"desc": "قطعة سور: دفاع +12 (حتى 8 قطع)."
	},
}
const TABS := [["home", "سكن"], ["agri", "زراعة"], ["ind", "صناعة"], ["serv", "خدمات"], ["fun", "ترفيه"], ["com", "تجارة"], ["def", "دفاع"]]

const GOALS := [
	{"key": "workers", "text": "افتح «العمال» وقرّر من يجمع ماذا."},
	{"key": "well", "text": "ابنِ بئرًا لماء قريب."},
	{"key": "home", "text": "ابنِ أول بيت حقيقي: كوخ خشبي أو بيت فلاحي."},
	{"key": "road", "text": "افتح «التخطيط» وارسم طريقًا ترابيًا (المشي عليه أسرع)."},
	{"key": "storehouse", "text": "ابنِ مخزنًا لتقصير رحلات الجمع."},
	{"key": "farm", "text": "ابنِ مزرعة لطعام ثابت (تحتاج ماء ري)."},
	{"key": "zone", "text": "حدّد منطقة سكنية من «التخطيط» — البيوت فيها أوسع."},
	{"key": "level2", "text": "ارتقِ بالمستوطنة إلى المستوى 2."},
	{"key": "explore", "text": "اكتشف قرية ناجين من «القرى»."},
	{"key": "trade", "text": "بِع فائضًا لقرية مقابل دنانير."},
	{"key": "barracks", "text": "ابنِ ثكنة وجنّد حارسين — الغارات تبدأ اليوم 20."},
	{"key": "market", "text": "ابنِ سوقًا لدخل يومي من الدنانير."},
	{"key": "kitchen", "text": "ابنِ مطبخًا لخفض استهلاك الطعام."},
	{"key": "pop10", "text": "اجمع 10 ناجين."},
	{"key": "defend", "text": "اصمد أمام أول غارة."},
	{"key": "stone_house", "text": "ابنِ أول بيت من حجر القدس."},
	{"key": "level3", "text": "ارتقِ إلى المستوى 3."},
	{"key": "olive_press", "text": "ابنِ معصرة — الزيت يُضيء ويُداوي ويُباع."},
	{"key": "diwan", "text": "ابنِ الديوان: مجلس المستوطنة."},
	{"key": "contract", "text": "وقّع عقدًا تجاريًا مع قرية."},
	{"key": "upgrade", "text": "رقِّ أي مبنى إلى المستوى 2."},
	{"key": "pop20", "text": "اجمع 20 ناجيًا."},
	{"key": "fishing_dock", "text": "مدّ طريقًا إلى الساحل وابنِ رصيف الصيد."},
	{"key": "lair", "text": "طهّر وكرًا للّصوص بجيشك."},
	{"key": "level4", "text": "ارتقِ إلى المستوى 4."},
	{"key": "mosque", "text": "ابنِ جامعًا قرب البيوت."},
	{"key": "clinic", "text": "ابنِ عيادة لحماية صحة الناجين."},
	{"key": "khan", "text": "ابنِ الخان — مأوى للمسافرين والتجار."},
	{"key": "town_square", "text": "ابنِ ساحة المدينة."},
	{"key": "upgrade3", "text": "رقِّ مبنى إلى المستوى 3."},
	{"key": "day60", "text": "اصمد حتى اليوم 60."},
	{"key": "level5", "text": "ارتقِ إلى المستوى 5."},
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
	var lvl := 1
	var rot := 0.0
	var active := true
	var zone_bonus := false


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
	var unit := ""
	var away := false
	var anim: AnimationPlayer = null
	var cur_anim := ""


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
			"army":
				# Shield with a spear
				draw_colored_polygon(PackedVector2Array([c + Vector2(-8, -9) * u, c + Vector2(8, -9) * u, c + Vector2(8, 1) * u, c + Vector2(0, 10) * u, c + Vector2(-8, 1) * u]), color)
				draw_line(c + Vector2(0, -7) * u, c + Vector2(0, 7) * u, Color(0.15, 0.17, 0.1), 2.0)
				draw_line(c + Vector2(-6, -2) * u, c + Vector2(6, -2) * u, Color(0.15, 0.17, 0.1), 2.0)
			"coins":
				for ci in range(3):
					draw_circle(c + Vector2(-5 + ci * 5, 4 - ci * 5) * u, 5.5 * u, color.darkened(0.08 * ci))
					draw_arc(c + Vector2(-5 + ci * 5, 4 - ci * 5) * u, 3.4 * u, 0, TAU, 16, Color(0.15, 0.17, 0.1, 0.6), 1.2)
			"plan":
				# Map grid with a pin
				draw_rect(Rect2(c + Vector2(-10, -8) * u, Vector2(20, 16) * u), color, false, 2.0)
				draw_line(c + Vector2(-3, -8) * u, c + Vector2(-3, 8) * u, color, 1.4)
				draw_line(c + Vector2(4, -8) * u, c + Vector2(4, 8) * u, color, 1.4)
				draw_line(c + Vector2(-10, 0) * u, c + Vector2(10, 0) * u, color, 1.4)
				draw_circle(c + Vector2(4, -3) * u, 3.2 * u, Color("#e85040"))
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
var ruin_nodes: Array = []
var camp_tents_node: Node3D
var camp_tents_up := true

# ── CS systems state ──────────────────────────────────────────────────────────
var land_value: Dictionary = {}   # Vector2i(gx,gz) → float 0-100
var demand_housing   := 50.0
var demand_production := 50.0
var demand_services  := 50.0
var lv_overlay       := false
var lv_overlay_root: Node3D = null
var service_xp_mult  := 1.0
var service_heal_mult := 1.0
var coverage_morale := 0.0
var zones: Dictionary = {}        # Vector2i placement cell → zone id
var zone_overlay_root: Node3D = null
var roads: Dictionary = {}        # Vector2i trail cell → ROAD_DIRT / ROAD_PAVED
var road_mm := {}                 # road type → MultiMesh
var plan_mode := ""               # "", road_dirt, road_paved, road_erase, zone_1..4, zone_erase
var plan_sheet: PanelContainer
var plan_bar: PanelContainer
var plan_bar_label: Label
var plan_buttons := {}
var territory_ring: MultiMeshInstance3D
var coverage_ring: MultiMeshInstance3D

# ── economy ──
var last_consumption: Dictionary = {}
var budget_lines: Array = []      # [label, amount] Dinar flows of the last day
var unpaid_notes: Array[String] = []
var economy_sheet: PanelContainer
var economy_list: VBoxContainer
var policies: Dictionary = {}     # key → true when enabled
var happiness_notes: Array = []   # [label, delta] last day morale factors

# ── trade ──
var village_state: Dictionary = {}  # idx → {"rel": float, "used": {offer_key: int}}
var contracts: Array = []           # {"v": idx, "kind": "export"/"import", "res", "qty", "dinar", "next": day}
var requests: Array = []            # {"v": idx, "res", "qty", "reward", "until": day}
var trade_modal_village := -1
var trades_done := 0
var contracts_signed := 0

# ── army ──
var army_sheet: PanelContainer
var army_list: VBoxContainer
var raid_next_day := RAID_FIRST_DAY
var raid_strength := 0.0
var raid_warned := false
var raid_node: Node3D = null
var raid_timer := 0.0
var raids_won := 0
var raids_lost := 0
var lairs_cleared := 0
var expedition_day := -1
var expedition_lair := -1

# ── touch scrolling for sheets ──
var scroll_targets: Array = []    # ScrollContainers that follow finger drags
var scroll_active: ScrollContainer = null
var scroll_press := Vector2.ZERO
var scroll_dragged := false
var scroll_pressing := false

var ui_font: Font
var ui_font_bold: Font
var title_font: Font
var shadows_on := true
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

var council_btn: Button
var army_btn: Button
var trade_btn: Button
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
var shadow_btn: Button
var sfx_btn: Button
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
	var cairo: Font = load("res://fonts/Cairo.ttf")
	ui_font = _font_weight(cairo, 600)
	ui_font_bold = _font_weight(cairo, 800)
	ar_font = ui_font_bold
	title_font = load("res://fonts/Amiri-Regular.ttf")
	_load_settings()
	stone_texture = _make_stone_texture()
	plateau_h = _natural_height(float(CAMP_CELL.x), float(CAMP_CELL.y))
	_build_heights()
	camp_pos = _grid_vertex(CAMP_CELL.x, CAMP_CELL.y)
	_build_world()
	_build_plots()
	_generate_sources()
	_build_camp()
	_add_vegetation()
	_build_trails()
	_build_roads()
	_build_camera()
	_build_lighting()
	_build_fx()
	_build_ghost()
	_build_ui()
	_create_survivors()
	_assign_tasks()
	_check_goals()
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
	_prop(camp, "nature/campfire_stones", 6.0, Vector3.ZERO)
	_cyl(camp, 10.0, 11.0, 2.0, Vector3(0, 1, 0), Color("#3d3530"))
	var flame := _cyl(camp, 0.0, 7.0, 20.0, Vector3(0, 12, 0), Color("#ff9a3c"))
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color("#ff9a3c")
	fm.emission_enabled = true
	fm.emission = Color("#ff7a1a")
	fm.emission_energy_multiplier = 1.4
	flame.material_override = fm
	# two patched starting tents (folded away once everyone lives in a real house)
	camp_tents_node = Node3D.new()
	camp_tents_node.set_meta("nobake", true)
	camp.add_child(camp_tents_node)
	for sx in [-100.0, 100.0]:
		var t := _make_tent_model()
		t.position = Vector3(sx, 0, -75)
		t.rotation_degrees.y = 180.0
		camp_tents_node.add_child(t)
	_bake_static(camp_tents_node)
	# salvaged supplies by the fire
	_prop(camp, "survival/box-large", 14.0, Vector3(34, 0, 28), 20.0)
	_prop(camp, "survival/box", 9.0, Vector3(46, 0, 22), -15.0)
	_prop(camp, "survival/barrel", 15.0, Vector3(-32, 0, 30))
	_prop(camp, "survival/barrel-open", 13.0, Vector3(-44, 0, 22))
	_prop(camp, "survival/bedroll", 5.0, Vector3(-26, 0, -30), 70.0)
	_prop(camp, "survival/bedroll", 5.0, Vector3(24, 0, -34), -60.0)
	_prop(camp, "survival/resource-wood", 10.0, Vector3(18, 0, 40), 35.0)
	_prop(camp, "survival/signpost", 22.0, Vector3(60, 0, -10), -30.0)
	_bake_static(camp)
	_smoke_puffs(camp, Vector3(0, 22, 0), 10, Color("#bdb6aa"), 10.0, 4.5, false)
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
		ruin_nodes.append(piece)
		if i % 4 == 1:
			_prop(piece, "nature/statue_columnDamaged", 30.0, Vector3(22, 0, 10))
			_prop(piece, "nature/statue_block", 9.0, Vector3(-18, 0, -6), 25.0)
		elif i % 4 == 3:
			_prop(piece, "nature/statue_column", 44.0, Vector3(-16, 0, 14))
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
		_bake_static(piece)


func _make_tent_model() -> Node3D:
	var m := Node3D.new()
	if _asset_scene("nature/tent_detailedOpen") != null:
		_prop(m, "nature/tent_detailedOpen", 34.0, Vector3.ZERO, 0.0, TENT_TINT)
		_prop(m, "survival/bedroll", 4.0, Vector3(14, 0, 26), 80.0)
		_prop(m, "survival/bucket", 5.0, Vector3(-18, 0, 24))
		return m
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
		if p.building == null:
			continue
		if absf(pt.x - p.pos.x) <= p.size.x * 0.5 + margin and absf(pt.z - p.pos.z) <= p.size.y * 0.5 + margin:
			return p
	return null


# ─── Free Placement helpers ─────────────────────────────────────────────────

func _world_to_grid(wx: float, wz: float) -> Vector2i:
	return Vector2i(roundi((wx - camp_pos.x) / PLACE_CELL), roundi((wz - camp_pos.z) / PLACE_CELL))


func _cell_world(cell: Vector2i) -> Vector2:
	return Vector2(camp_pos.x + float(cell.x) * PLACE_CELL, camp_pos.z + float(cell.y) * PLACE_CELL)


func _grid_to_world(gx: int, gz: int) -> Vector3:
	var c := _cell_world(Vector2i(gx, gz))
	return Vector3(c.x, _height_at_world(c.x, c.y), c.y)


# Footprints: S = 1 cell, M = 2×1 (along x), L = 2×2. The anchor is the lowest cell.
func _fp_size(cls: String) -> int:
	return 1 if cls == "S" else (2 if cls == "M" else 3)


func _fp_offset(cls: String) -> Vector2:
	var o := float(_fp_size(cls) - 1) * 0.5
	return Vector2(o, o)


func _anchor_from_world(wx: float, wz: float, cls: String) -> Vector2i:
	var o := _fp_offset(cls)
	return Vector2i(roundi((wx - camp_pos.x) / PLACE_CELL - o.x), roundi((wz - camp_pos.z) / PLACE_CELL - o.y))


func _footprint_center(gx: int, gz: int, cls: String) -> Vector2:
	var o := _fp_offset(cls)
	return Vector2(camp_pos.x + (float(gx) + o.x) * PLACE_CELL, camp_pos.z + (float(gz) + o.y) * PLACE_CELL)


# (lowest, highest) terrain height under a rectangle.
func _footprint_heights(center: Vector2, size: Vector2) -> Vector2:
	var lo := INF
	var hi := -INF
	for fx in [-0.5, 0.0, 0.5]:
		for fz in [-0.5, 0.0, 0.5]:
			var h := _height_at_world(center.x + fx * size.x, center.y + fz * size.y)
			lo = minf(lo, h)
			hi = maxf(hi, h)
	return Vector2(lo, hi)


func _cells_for(gx: int, gz: int, cls: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var n := _fp_size(cls)
	for dx in range(n):
		for dz in range(n):
			cells.append(Vector2i(gx + dx, gz + dz))
	return cells


func _cells_free(gx: int, gz: int, cls: String) -> bool:
	for cell in _cells_for(gx, gz, cls):
		if occupied_cells.has(cell):
			return false
	return true


func _territory_radius() -> float:
	return float(TERRITORY_R[clampi(level - 1, 0, TERRITORY_R.size() - 1)])


func _road_center(k: Vector2i) -> Vector2:
	return Vector2((float(k.x) + 0.5) * TRAIL_CELL, (float(k.y) + 0.5) * TRAIL_CELL)


func _near_road(wx: float, wz: float, reach: float) -> bool:
	var p := Vector2(wx, wz)
	for k in roads:
		if _road_center(k).distance_to(p) <= reach:
			return true
	return false


func _in_territory(wx: float, wz: float) -> bool:
	if Vector2(wx - camp_pos.x, wz - camp_pos.z).length() <= _territory_radius():
		return true
	return _near_road(wx, wz, ROAD_REACH)


# Distance (in terrain tiles) east of the shoreline; negative means sea.
func _coast_tiles(wx: float, wz: float) -> float:
	var tgx := wx / TILE_SIZE + GRID / 2.0 - 0.5
	var tgz := wz / TILE_SIZE + GRID / 2.0 - 0.5
	return tgx - _coastline_x(tgz)


func _is_land_world(wx: float, wz: float) -> bool:
	return _coast_tiles(wx, wz) >= 0.9


func _place_problem(gx: int, gz: int, cls: String, type: String) -> String:
	var def: Dictionary = BUILDINGS[type]
	var cat := str(def.get("cat", "any"))
	var coastal := bool(def.get("coastal", false))
	var cells := _cells_for(gx, gz, cls)
	var center := _footprint_center(gx, gz, cls)
	var size: Vector2 = PLOT_SIZES[cls]
	for cell in cells:
		if occupied_cells.has(cell):
			return "المكان مشغول بمبنى آخر."
		var cw := _cell_world(cell)
		if not _in_territory(cw.x, cw.y):
			return "خارج حدود المستوطنة — مدّ طريقًا من «التخطيط» أو ارتقِ بالمستوى."
		if not coastal and not _is_land_world(cw.x, cw.y):
			return "لا يمكن البناء على الماء."
		var z := int(zones.get(cell, 0))
		if z > 0 and (ZONE_FORBID[z] as Array).has(cat):
			return "«%s» ممنوع في المنطقة %s." % [def["ar"], ZONE_AR[z]]
	if coastal:
		var ct := _coast_tiles(center.x, center.y)
		if ct > 2.6 or ct < 0.2:
			return "رصيف الصيد يجب أن يكون على خط الشاطئ تمامًا (غرب المخيم)."
	else:
		var hr := _footprint_heights(center, size)
		if hr.y - hr.x > MAX_SLOPE:
			return "المنحدر شديد جدًا هنا — اختر سفحًا ألطف."
	var min_lv := float(MIN_LAND_VALUE_REQ.get(type, 0.0))
	if min_lv > 0.0:
		var lv_here := _footprint_land_value(gx, gz, cls)
		if lv_here < min_lv:
			return "قيمة الأرض منخفضة (تحتاج %d، هنا %d) — ابنِ قرب المخيم أو جامع أو ساحة." % [int(min_lv), int(lv_here)]
	return ""


func _can_place(gx: int, gz: int, cls: String, type: String = "") -> bool:
	if type == "":
		return _cells_free(gx, gz, cls)
	return _place_problem(gx, gz, cls, type) == ""


func _footprint_land_value(gx: int, gz: int, cls: String) -> float:
	var cells := _cells_for(gx, gz, cls)
	var total := 0.0
	for cell in cells:
		total += _get_land_value(cell.x, cell.y)
	return total / float(cells.size())


func _zone_matches(gx: int, gz: int, cls: String, cat: String) -> bool:
	if cat == "any":
		return false
	for cell in _cells_for(gx, gz, cls):
		var z := int(zones.get(cell, 0))
		if z == 0 or ZONE_MATCH[z] != cat:
			return false
	return true


# Door (+z of every model) turns toward the nearest road, otherwise toward the camp fire.
func _facing_for(center: Vector2, cls: String) -> float:
	var target := Vector2(camp_pos.x, camp_pos.z)
	var best := 340.0
	for k in roads:
		var rc := _road_center(k)
		var d := rc.distance_to(center)
		if d < best and d > 20.0:
			best = d
			target = rc
	var dir := target - center
	if dir.length() < 1.0:
		return 0.0
	if absf(dir.x) > absf(dir.y):
		return 90.0 if dir.x > 0.0 else 270.0
	return 0.0 if dir.y >= 0.0 else 180.0


func _clear_ruins_near(center: Vector2, size: Vector2) -> void:
	for r in ruin_nodes:
		var rn: Node3D = r
		if is_instance_valid(rn) and rn.visible:
			if absf(rn.position.x - center.x) < size.x * 0.5 + 30.0 and absf(rn.position.z - center.y) < size.y * 0.5 + 30.0:
				rn.visible = false
	_hide_scatter_near(center, size)
func _create_dynamic_plot(gx: int, gz: int, cls: String) -> Plot:
	var p := Plot.new()
	p.idx = plots.size()
	p.cls = cls
	p.lv = 1
	p.gx = gx
	p.gz = gz
	p.size = PLOT_SIZES[cls]
	var c := _footprint_center(gx, gz, cls)
	var hr := _footprint_heights(c, p.size)
	p.pos = Vector3(c.x, hr.y, c.y)
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
	# On a slope the building stands on a stone terrace (podium) down to the lowest ground.
	var drop := hr.y - hr.x
	if drop > 1.5:
		var pod := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(p.size.x + 6.0, drop + 4.0, p.size.y + 6.0)
		pod.mesh = pm
		pod.position = Vector3(0, -(drop + 4.0) * 0.5 + 1.0, 0)
		pod.material_override = _stone_mat(Color("#cdbf9c"))
		p.node.add_child(pod)
	p.lock_label = Label3D.new()
	p.lock_label.visible = false
	p.node.add_child(p.lock_label)
	plots.append(p)
	for cell in _cells_for(gx, gz, cls):
		occupied_cells[cell] = true
	_clear_ruins_near(c, p.size)
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


func _lvl_mult(b: Building) -> float:
	return 1.0 + 0.4 * float(b.lvl - 1)


# Recomputed from scratch every day: the sum of what each source radiates (no build-up).
func _update_land_value() -> void:
	land_value.clear()
	var srcs: Array = [["Camp", Vector2(camp_pos.x, camp_pos.z), 1.0]]
	for b in buildings:
		if b.done and LAND_VALUE_SOURCES.has(b.type):
			var positive := float(LAND_VALUE_SOURCES[b.type]["delta"]) > 0.0
			if positive and not b.active:
				continue
			srcs.append([b.type, Vector2(b.pos.x, b.pos.z), _lvl_mult(b) if positive else 1.0])
	for s in srcs:
		var d: Dictionary = LAND_VALUE_SOURCES[s[0]]
		var radius := int(d["radius"])
		var delta := float(d["delta"]) * float(s[2])
		var sp: Vector2 = s[1]
		var cc := _world_to_grid(sp.x, sp.y)
		var rc := int(ceil(float(radius + 1) * LV_UNIT / PLACE_CELL))
		for dx in range(-rc, rc + 1):
			for dz in range(-rc, rc + 1):
				var cell := cc + Vector2i(dx, dz)
				var dist := _cell_world(cell).distance_to(sp) / LV_UNIT
				var falloff := 1.0 - dist / (float(radius) + 1.0)
				if falloff <= 0.0:
					continue
				land_value[cell] = float(land_value.get(cell, 0.0)) + delta * falloff
	var road_bonus := {}
	for k in roads:
		var rc := _road_center(k)
		var cell := _world_to_grid(rc.x, rc.y)
		road_bonus[cell] = maxf(float(road_bonus.get(cell, 0.0)), 6.0 if int(roads[k]) == ROAD_PAVED else 3.0)
	for cell in road_bonus:
		land_value[cell] = float(land_value.get(cell, 0.0)) + float(road_bonus[cell])
	for cell in land_value.keys():
		land_value[cell] = clampf(float(land_value[cell]), 0.0, 100.0)
	if lv_overlay:
		_refresh_lv_overlay()


func _housing_of(b: Building) -> int:
	var base := int(BUILDINGS[b.type]["housing"])
	if base <= 0 or not b.done:
		return 0
	var h := float(base) * (1.0 + 0.5 * float(b.lvl - 1))
	if b.zone_bonus:
		h *= 1.0 + ZONE_BONUS
	return int(round(h))


func _housing_points() -> Array:
	var pts: Array = [[Vector2(camp_pos.x, camp_pos.z), BASE_HOUSING]]
	for b in buildings:
		var h := _housing_of(b)
		if h > 0:
			pts.append([Vector2(b.pos.x, b.pos.z), h])
	return pts


func _coverage_radius(b: Building) -> float:
	return float(SERVICE_COVERAGE[b.type]["radius"]) * (1.0 + 0.2 * float(b.lvl - 1))


# Share of all housing (people's homes) inside a service building's radius.
func _coverage_share(b: Building, pts: Array, total: float) -> float:
	var rad := _coverage_radius(b)
	var covered := 0.0
	var bp := Vector2(b.pos.x, b.pos.z)
	for pt in pts:
		if (pt[0] as Vector2).distance_to(bp) <= rad:
			covered += float(pt[1])
	return covered / maxf(1.0, total)


func _apply_service_coverage() -> void:
	service_xp_mult = 1.0
	service_heal_mult = 1.0
	coverage_morale = 0.0
	if survivors.is_empty():
		return
	var pts := _housing_points()
	var total := 0.0
	for pt in pts:
		total += float(pt[1])
	var discont_add := 0.0
	var xp_add := 0.0
	var heal_add := 0.0
	for b in buildings:
		if not b.done or not b.active or not SERVICE_COVERAGE.has(b.type):
			continue
		var cov: Dictionary = SERVICE_COVERAGE[b.type]
		var share := _coverage_share(b, pts, total) * _lvl_mult(b)
		coverage_morale += float(cov.get("morale", 0.0)) * share
		discont_add += float(cov.get("discontent", 0.0)) * share
		heal_add += float(cov.get("heal_bonus", 0.0)) * share
		xp_add += float(cov.get("xp_bonus", 0.0)) * share
	coverage_morale = minf(coverage_morale, 4.0)
	morale = clampf(morale + coverage_morale, 0.0, 100.0)
	discontent = clampf(discontent + discont_add, 0.0, 100.0)
	service_heal_mult = 1.0 + minf(heal_add, 1.5)
	service_xp_mult = 1.0 + minf(xp_add, 2.0)


func _update_demand() -> void:
	var n := float(survivors.size())
	if n == 0.0:
		demand_housing = 0.0
		demand_production = 0.0
		demand_services = 0.0
		return
	var cap := float(_housing_capacity())
	demand_housing = clampf((n + 3.0 - cap) / maxf(3.0, n * 0.4) * 100.0, 0.0, 100.0)
	var shortage_score := 0.0
	var cons := _compute_consumption()
	for r in ["Food", "Water"]:
		var use := maxf(0.1, float(cons.get(r, 0.0)))
		var days_left := float(resources.get(r, 0.0)) / use
		if days_left < 5.0:
			shortage_score += 35.0 * (1.0 - days_left / 5.0)
	for r in ["Wood", "Stone"]:
		if float(resources.get(r, 0.0)) < 25.0:
			shortage_score += 15.0
	demand_production = clampf(shortage_score, 0.0, 100.0)
	var pts := _housing_points()
	var total := 0.0
	for pt in pts:
		total += float(pt[1])
	var best := 0.0
	for b in buildings:
		if b.done and b.active and SERVICE_COVERAGE.has(b.type):
			best += _coverage_share(b, pts, total)
	var ideal := 1.0 + n / 12.0
	demand_services = clampf((1.0 - best / ideal) * 100.0, 0.0, 100.0)


# ---------------------------------------------------------------- overlays (land value, zones, rings)

func _overlay_mm(parent_old: Node3D, items: Array) -> Node3D:
	# items: [Vector2 world xz, Color]
	if is_instance_valid(parent_old):
		parent_old.queue_free()
	var root := Node3D.new()
	terrain_root.add_child(root)
	if items.is_empty():
		return root
	var mesh := BoxMesh.new()
	mesh.size = Vector3(PLACE_CELL * 0.9, 1.0, PLACE_CELL * 0.9)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = items.size()
	for i in range(items.size()):
		var p: Vector2 = items[i][0]
		var fr := _footing_range(p.x, p.y)
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(p.x, fr.y + 4.5, p.y)))
		mm.set_instance_color(i, items[i][1])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	return root


func _territory_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var r := int(ceil(_territory_radius() / PLACE_CELL)) + 1
	for gx in range(-r, r + 1):
		for gz in range(-r, r + 1):
			var cw := _cell_world(Vector2i(gx, gz))
			if Vector2(cw.x - camp_pos.x, cw.y - camp_pos.z).length() <= _territory_radius() and _is_land_world(cw.x, cw.y):
				out.append(Vector2i(gx, gz))
	return out


func _toggle_lv_overlay() -> void:
	lv_overlay = not lv_overlay
	if lv_overlay:
		_refresh_lv_overlay()
		_toast("قيمة الأرض: أخضر = مرغوبة للسكن، أحمر = ضجيج ومنخفضة.", 4.0)
	else:
		if is_instance_valid(lv_overlay_root):
			lv_overlay_root.queue_free()
		lv_overlay_root = null
	_refresh_plan_buttons()


func _refresh_lv_overlay() -> void:
	var items: Array = []
	var seen := {}
	for cell in _territory_cells():
		seen[cell] = true
	for cell in land_value:
		seen[cell] = true
	for cell in seen:
		var raw := float(land_value.get(cell, 0.0))
		var t := clampf(raw / 60.0, 0.0, 1.0)
		var col := Color(0.9, 0.25, 0.2, 0.42).lerp(Color(0.25, 0.85, 0.3, 0.5), t)
		if raw <= 0.5:
			col = Color(0.85, 0.3, 0.25, 0.22)
		items.append([_cell_world(cell), col])
	lv_overlay_root = _overlay_mm(lv_overlay_root, items)


func _refresh_zone_overlay() -> void:
	var show := plan_mode.begins_with("zone")
	if not show:
		if is_instance_valid(zone_overlay_root):
			zone_overlay_root.queue_free()
		zone_overlay_root = null
		return
	var items: Array = []
	for cell in zones:
		items.append([_cell_world(cell), ZONE_COLORS[int(zones[cell])]])
	zone_overlay_root = _overlay_mm(zone_overlay_root, items)


func _make_ring(center: Vector3, radius: float, color: Color, posts: int = 72) -> MultiMeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(10, 7, 10)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = posts
	for i in range(posts):
		var a := TAU * float(i) / float(posts)
		var x := center.x + cos(a) * radius
		var z := center.z + sin(a) * radius
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(x, _height_at_world(x, z) + 4.0, z)))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = _unlit_mat(color)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	terrain_root.add_child(mi)
	return mi


func _show_territory(on: bool) -> void:
	if is_instance_valid(territory_ring):
		territory_ring.queue_free()
		territory_ring = null
	if on:
		territory_ring = _make_ring(camp_pos, _territory_radius(), Color(1.0, 0.92, 0.55, 0.85), 96)


func _show_coverage_ring(b: Building) -> void:
	if is_instance_valid(coverage_ring):
		coverage_ring.queue_free()
	coverage_ring = null
	if b == null or not SERVICE_COVERAGE.has(b.type):
		return
	coverage_ring = _make_ring(b.pos, _coverage_radius(b), Color(0.45, 0.85, 1.0, 0.9), 60)


# ---------------------------------------------------------------- roads & zones (planning)

func _build_roads() -> void:
	for t in [ROAD_DIRT, ROAD_PAVED]:
		var mesh := BoxMesh.new()
		mesh.size = Vector3(TRAIL_CELL + 4.0, 1.2 if t == ROAD_DIRT else 1.8, TRAIL_CELL + 4.0)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = ROAD_MAX
		mm.visible_instance_count = 0
		var node := MultiMeshInstance3D.new()
		node.multimesh = mm
		node.material_override = _mat(Color("#86704c")) if t == ROAD_DIRT else _stone_mat(Color("#d6cbb0"))
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		terrain_root.add_child(node)
		road_mm[t] = mm


func _road_transform(k: Vector2i, t: int) -> Transform3D:
	var c := _road_center(k)
	var fr := _footing_range(c.x, c.y)
	return Transform3D(Basis(), Vector3(c.x, (fr.x + fr.y) * 0.5 + (0.7 if t == ROAD_DIRT else 1.1), c.y))


func _rebuild_road_meshes() -> void:
	for t in [ROAD_DIRT, ROAD_PAVED]:
		var mm: MultiMesh = road_mm[t]
		var i := 0
		for k in roads:
			if int(roads[k]) == t and i < ROAD_MAX:
				mm.set_instance_transform(i, _road_transform(k, t))
				i += 1
		mm.visible_instance_count = i


func _road_type_at(x: float, z: float) -> int:
	return int(roads.get(Vector2i(int(floor(x / TRAIL_CELL)), int(floor(z / TRAIL_CELL))), 0))


func _speed_at(flat: Vector3) -> float:
	var key := Vector2i(int(floor(flat.x / TRAIL_CELL)), int(floor(flat.z / TRAIL_CELL)))
	var rt := int(roads.get(key, 0))
	if rt > 0:
		return float(ROAD_SPEED[rt])
	if float(trail_counts.get(key, 0.0)) < 0.0:
		return TRAIL_SPEED
	return 1.0


const PLAN_AR := {
	"road_dirt": "طريق ترابي — اسحب إصبعك على الأرض (مجاني، المشي أسرع 45%)",
	"road_paved": "طريق مرصوف — اسحب على الأرض (2 حجر لكل قطعة، أسرع 90%)",
	"road_erase": "إزالة الطرق — اسحب فوق الطريق",
	"zone_1": "منطقة سكنية — اسحب لتلوين الأرض بالأخضر",
	"zone_2": "منطقة تجارية — اسحب لتلوين الأرض بالأزرق",
	"zone_3": "منطقة صناعية — اسحب لتلوين الأرض بالبرتقالي",
	"zone_4": "منطقة زراعية — اسحب لتلوين الأرض بالأصفر",
	"zone_erase": "مسح المناطق — اسحب فوق المنطقة",
}


func _set_plan_mode(mode: String) -> void:
	plan_mode = "" if plan_mode == mode else mode
	if plan_mode == "road_paved" and level < 3:
		plan_mode = ""
		_toast("الطرق المرصوفة تُفتح في المستوى 3.")
	_show_territory(plan_mode != "" or (is_instance_valid(plan_sheet) and plan_sheet.visible))
	_refresh_zone_overlay()
	_refresh_plan_buttons()
	if not is_instance_valid(plan_bar):
		return
	if plan_mode != "":
		# Painting: free the whole screen except a slim tool bar.
		plan_sheet.visible = false
		dock.visible = false
		plan_bar.visible = true
		plan_bar_label.text = str(PLAN_AR.get(plan_mode, ""))
	else:
		plan_bar.visible = false
		if selected_building == "" and inspected == null:
			dock.visible = true


func _plan_change_tool() -> void:
	if plan_mode != "":
		_set_plan_mode(plan_mode)
	plan_sheet.visible = true
	_fit_sheet(plan_sheet)
	_show_territory(true)
	_refresh_plan_buttons()


func _plan_done() -> void:
	if plan_mode != "":
		_set_plan_mode(plan_mode)
	plan_sheet.visible = false
	plan_bar.visible = false
	_show_territory(false)
	dock.visible = true


var _plan_toast_time := 0


func _plan_toast(msg: String) -> void:
	var now := Time.get_ticks_msec()
	if now - _plan_toast_time > 2500:
		_plan_toast_time = now
		_toast(msg, 3.0)


func _paint_at(screen_pos: Vector2) -> void:
	var hit: Variant = _ray_to_terrain(screen_pos)
	if hit == null:
		return
	var wp: Vector3 = hit
	if plan_mode.begins_with("road"):
		_paint_road(wp)
	elif plan_mode.begins_with("zone"):
		_paint_zone(wp)


func _paint_road(wp: Vector3) -> void:
	var key := Vector2i(int(floor(wp.x / TRAIL_CELL)), int(floor(wp.z / TRAIL_CELL)))
	var c := _road_center(key)
	if plan_mode == "road_erase":
		if roads.has(key):
			roads.erase(key)
			_rebuild_road_meshes()
		return
	if not _is_land_world(c.x, c.y):
		return
	var cur := int(roads.get(key, 0))
	var want := ROAD_PAVED if plan_mode == "road_paved" else ROAD_DIRT
	if cur >= want:
		return
	var p := _plot_at_point(Vector3(c.x, 0.0, c.y), -6.0)
	if p != null:
		return
	var from_camp := Vector2(c.x - camp_pos.x, c.y - camp_pos.z).length()
	var allowed := from_camp <= _territory_radius() + 60.0 or _near_road(c.x, c.y, TRAIL_CELL * 1.6)
	if not allowed:
		_plan_toast("ابدأ الطريق من داخل المستوطنة أو امدده من طريق قائم.")
		return
	if roads.size() >= ROAD_MAX:
		_plan_toast("بلغت الحد الأقصى للطرق.")
		return
	if want == ROAD_PAVED:
		if float(resources["Stone"]) < PAVED_COST:
			_plan_toast("لا يوجد حجر كافٍ لرصف الطريق.")
			return
		resources["Stone"] = float(resources["Stone"]) - PAVED_COST
	roads[key] = want
	trail_counts[key] = -1.0
	if cur == 0 and want == ROAD_DIRT:
		var mm: MultiMesh = road_mm[ROAD_DIRT]
		var i := mm.visible_instance_count
		if i < ROAD_MAX:
			mm.set_instance_transform(i, _road_transform(key, ROAD_DIRT))
			mm.visible_instance_count = i + 1
	else:
		_rebuild_road_meshes()
	_check_goals()


func _paint_zone(wp: Vector3) -> void:
	var cell := _world_to_grid(wp.x, wp.z)
	var cw := _cell_world(cell)
	if plan_mode == "zone_erase":
		if zones.has(cell):
			zones.erase(cell)
			_refresh_zone_bonus()
			_refresh_zone_overlay()
		return
	if not _in_territory(cw.x, cw.y) or not _is_land_world(cw.x, cw.y):
		_plan_toast("المناطق تُحدَّد داخل حدود المستوطنة فقط.")
		return
	var z := int(plan_mode.substr(5))
	if int(zones.get(cell, 0)) == z:
		return
	zones[cell] = z
	_refresh_zone_bonus()
	_refresh_zone_overlay()
	_check_goals()


func _refresh_zone_bonus() -> void:
	for b in buildings:
		var p: Plot = plots[b.plot]
		b.zone_bonus = _zone_matches(p.gx, p.gz, p.cls, str(BUILDINGS[b.type].get("cat", "any")))
		for s in sources:
			if s.building == b:
				_apply_source_stats(s, b)
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
			_bake_static(s.node)
			s.node.position = s.pos
			source_root.add_child(s.node)
			sources.append(s)
			placed += 1





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
		"Stone House":
			# Village stone house: cube with a big dome, outside stair to the roof, walled front yard
			var green_door := Color("#2f6b5a")
			_box(m, Vector3(40, 24, 36), Vector3(-4, 12, -6), Color.WHITE, true)
			_box(m, Vector3(42, 2.5, 38), Vector3(-4, 25, -6), cream, true)
			_dome(m, 14.0, Vector3(-4, 26, -6))
			_cyl(m, 2.0, 2.0, 4.0, Vector3(-4, 40, -6), cream, true)
			for k in range(6):
				_box(m, Vector3(8, 4.0 * float(k + 1), 5.5), Vector3(20, 2.0 * float(k + 1), 10.0 - 5.5 * float(k)), Color.WHITE, true)
			_arch(m, -12, 0, 11, 17, 12.2, green_door)
			_arch(m, 6, 9, 7, 10, 12.2, window)
			_box(m, Vector3(3, 10, 1.2), Vector3(1.0, 13.5, 12.6), green_door)
			_box(m, Vector3(3, 10, 1.2), Vector3(11.0, 13.5, 12.6), green_door)
			_box(m, Vector3(20, 6, 2.5), Vector3(-17, 3, 26), Color.WHITE, true)
			_box(m, Vector3(20, 6, 2.5), Vector3(13, 3, 26), Color.WHITE, true)
			_box(m, Vector3(2.5, 6, 14), Vector3(-26, 3, 19), Color.WHITE, true)
			_prop(m, "nature/tree_oak", 16.0, Vector3(-18, 0, 19), 30.0, OLIVE_TINT)
			_prop(m, "nature/pot_large", 4.0, Vector3(4, 0, 18))
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
			# Fellahin house: lime-plastered mud walls, blue door, taboon oven, rooftop water tank
			var plaster := Color("#e7d2a6")
			var plaster2 := Color("#d6ba86")
			var blue := Color("#3b6f93")
			_box(m, Vector3(34, 19, 28), Vector3(0, 9.5, -4), plaster)
			_box(m, Vector3(36, 1.8, 30), Vector3(0, 19.6, -4), plaster2)
			for side in [-1.0, 1.0]:
				_box(m, Vector3(36, 2.5, 1.6), Vector3(0, 21.5, -4.0 + side * 14.2), plaster2)
				_box(m, Vector3(1.6, 2.5, 30), Vector3(side * 17.2, 21.5, -4), plaster2)
			_box(m, Vector3(8, 13, 1.4), Vector3(-6, 6.5, 10.3), blue)
			_box(m, Vector3(10, 1.5, 1.6), Vector3(-6, 13.6, 10.4), plaster2)
			_box(m, Vector3(5, 5, 1.4), Vector3(9, 11, 10.3), blue)
			_cyl(m, 3.4, 3.4, 6.0, Vector3(9, 23.8, -10), Color("#2f3438"))
			var taboon := _sphere(m, 6.0, Vector3(13, 0, 19), Color("#a8744a"))
			taboon.scale = Vector3(1.0, 0.75, 1.0)
			_box(m, Vector3(3, 3, 1.5), Vector3(13, 2, 24.5), Color("#3a2a20"))
			_sphere(m, 3.2, Vector3(-14, 3.2, 17), Color("#b5703f"))
			_sphere(m, 2.6, Vector3(-9, 2.6, 19), Color("#b5703f"))
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
			# Courtyard house (dar with hosh): two-storey back wing, side wings, arcade, courtyard olive and fountain
			var mash := Color("#6b4a2e")
			_box(m, Vector3(62, 30, 16), Vector3(0, 15, -23), Color.WHITE, true)
			_box(m, Vector3(64, 2.5, 18), Vector3(0, 31, -23), cream, true)
			_box(m, Vector3(15, 20, 30), Vector3(-23.5, 10, 0), Color.WHITE, true)
			_box(m, Vector3(15, 20, 30), Vector3(23.5, 10, 0), Color.WHITE, true)
			_box(m, Vector3(16, 2, 31), Vector3(-23.5, 20.8, 0), cream, true)
			_box(m, Vector3(16, 2, 31), Vector3(23.5, 20.8, 0), cream, true)
			_dome(m, 7.0, Vector3(-23.5, 21.5, 0))
			_dome(m, 7.0, Vector3(23.5, 21.5, 0))
			_box(m, Vector3(22, 10, 3), Vector3(-20, 5, 28), Color.WHITE, true)
			_box(m, Vector3(22, 10, 3), Vector3(20, 5, 28), Color.WHITE, true)
			_arch(m, 0, 0, 13, 15, 29.6, door)
			_box(m, Vector3(32, 1, 30), Vector3(0, 0.6, 2), Color("#d9c9a2"))
			for k in range(4):
				_cyl(m, 1.5, 1.5, 13.0, Vector3(-13.5 + 9.0 * float(k), 6.5, -13.5), Color.WHITE, true)
			_box(m, Vector3(34, 3, 3), Vector3(0, 14, -13.5), cream, true)
			for k2 in range(3):
				_box(m, Vector3(8, 8, 3), Vector3(-18.0 + 18.0 * float(k2), 22, -14.5), mash)
				_box(m, Vector3(9, 1.2, 4), Vector3(-18.0 + 18.0 * float(k2), 26.6, -14.0), mash)
			for k3 in range(3):
				_arch(m, -20.0 + 20.0 * float(k3), 4, 6, 9, -31.2, window)
			_prop(m, "nature/tree_default", 18.0, Vector3(-7, 1, 6), 0.0, OLIVE_TINT)
			_cyl(m, 4.5, 4.5, 3.0, Vector3(8, 2, 9), Color.WHITE, true)
			_cyl(m, 3.6, 3.6, 0.8, Vector3(8, 3.6, 9), Color("#4aa3d9"))
			_cyl(m, 3.0, 3.0, 6.0, Vector3(22, 35, -26), Color("#2f3438"))
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
		"Shack":
			# Wooden shack with a tin roof and porch
			var plank := Color("#8a6844")
			var plank2 := Color("#a07c50")
			var tin := Color("#98a1a6")
			_box(m, Vector3(38, 17, 28), Vector3(0, 8.5, -4), plank)
			for k in range(5):
				_box(m, Vector3(1.1, 17.2, 28.4), Vector3(-15.0 + 7.5 * float(k), 8.5, -4), plank2)
			var roof := _box(m, Vector3(44, 1.8, 36), Vector3(0, 20, -3), tin)
			roof.rotation_degrees.x = -9.0
			var patch := _box(m, Vector3(11, 2.0, 9), Vector3(-10, 20.6, 2), Color("#a0583a"))
			patch.rotation_degrees.x = -9.0
			_box(m, Vector3(8, 12, 1.4), Vector3(-6, 6, 10.3), door)
			_box(m, Vector3(7, 5, 1.4), Vector3(9, 10, 10.3), window)
			_box(m, Vector3(38, 1.4, 9), Vector3(0, 0.7, 15), plank2)
			_cyl(m, 0.8, 0.8, 14.0, Vector3(-17, 7, 19), plank)
			_cyl(m, 0.8, 0.8, 14.0, Vector3(17, 7, 19), plank)
			var awn := _box(m, Vector3(40, 1.0, 10), Vector3(0, 14.5, 15.5), tin)
			awn.rotation_degrees.x = 10.0
			_prop(m, "survival/barrel", 9.0, Vector3(19, 0, 2))
			_prop(m, "survival/bucket", 4.0, Vector3(-14, 1.4, 16))
		"Woodcutter":
			_box(m, Vector3(30, 16, 24), Vector3(0, 8, -6), wood)
			var wroof := _prism(m, Vector3(36, 12, 30), Vector3(0, 22, -6), Color("#6b4f33"))
			wroof.rotation_degrees.y = 90.0
			_arch(m, 0, 0, 8, 12, 6.2, door)
			for lg in range(4):
				var log := _cyl(m, 2.6, 2.6, 22.0, Vector3(-8.0 + float(lg % 2) * 5.0, 2.6 + float(lg / 2) * 5.0, 14.0), Color("#8a6a40"))
				log.rotation_degrees.z = 90.0
			_cyl(m, 3.5, 3.5, 4.0, Vector3(14, 2, 12), Color("#7a5a35"))
			for tp2 in [Vector3(-16, 0, 14), Vector3(17, 0, -14)]:
				_cyl(m, 1.4, 1.8, 12.0, tp2 + Vector3(0, 6, 0), Color("#6b553c"))
				_cyl(m, 0.0, 8.0, 18.0, tp2 + Vector3(0, 20, 0), Color("#4f6b3a"))
		"Market":
			# Covered souq hall with an arcade, a small dome and striped stalls in front
			_box(m, Vector3(56, 18, 28), Vector3(0, 9, -8), Color.WHITE, true)
			_box(m, Vector3(60, 2.5, 32), Vector3(0, 19.2, -8), cream, true)
			_parapet(m, 60.0, 32.0, 20.5, 3.0)
			_dome(m, 9.0, Vector3(0, 21, -8))
			for ax in [-21.0, -7.0, 7.0, 21.0]:
				_arch(m, ax, 0, 10, 14, 6.5, door)
			var awn_cols := [Color("#b8402e"), Color("#2f7a3a"), Color("#d89a2a")]
			for si in range(3):
				var sx := -19.0 + 19.0 * float(si)
				_box(m, Vector3(13, 6, 8), Vector3(sx, 3, 17), wood)
				var aw := _box(m, Vector3(15, 1.2, 11), Vector3(sx, 13.5, 17), awn_cols[si])
				aw.rotation_degrees.x = -12.0
				_cyl(m, 0.8, 0.8, 13.0, Vector3(sx - 6.5, 6.5, 21.5), wood)
				_cyl(m, 0.8, 0.8, 13.0, Vector3(sx + 6.5, 6.5, 21.5), wood)
				for gi in range(3):
					_sphere(m, 2.2, Vector3(sx - 4.0 + 4.0 * float(gi), 7.2, 17.0), [Color("#e0ac4a"), Color("#8fb04a"), Color("#c8b84a")][gi])
		"Barracks":
			# Fortified hall with crenellations, a training yard, spear rack and banner
			_box(m, Vector3(52, 22, 28), Vector3(0, 11, -8), Color.WHITE, true)
			_box(m, Vector3(56, 3, 32), Vector3(0, 23.5, -8), cream, true)
			for k in range(7):
				_box(m, Vector3(5, 5, 4), Vector3(-24.0 + 8.0 * float(k), 27.5, 7.0), Color.WHITE, true)
				_box(m, Vector3(5, 5, 4), Vector3(-24.0 + 8.0 * float(k), 27.5, -23.0), Color.WHITE, true)
			_arch(m, 0, 0, 14, 18, 6.5, door)
			_arch(m, -17, 9, 6, 9, 6.5, window)
			_arch(m, 17, 9, 6, 9, 6.5, window)
			_box(m, Vector3(54, 1, 16), Vector3(0, 0.6, 16), Color("#b8a070"))
			for k2 in range(4):
				var sp := _cyl(m, 0.7, 0.7, 22.0, Vector3(-22.0 + float(k2) * 3.0, 11.0, 20.0), wood)
				sp.rotation_degrees.z = 8.0
				_cyl(m, 0.0, 1.4, 4.0, Vector3(-20.5 + float(k2) * 3.0, 23.0, 20.0), Color("#9aa0a6"))
			_cyl(m, 1.2, 1.2, 14.0, Vector3(16, 7, 17), wood)
			_sphere(m, 4.0, Vector3(16, 16, 17), Color("#c8b48c"))
			_cyl(m, 1.0, 1.0, 34.0, Vector3(24, 34, -20), wood)
			_box(m, Vector3(13, 8, 1.2), Vector3(30.5, 46, -20), Color("#2f6f3a"))
		"Wall":
			var cw := _stone_asset("castle/wall", 30.0)
			cw.scale = Vector3(64.0, 30.0 / 1.31, 16.0)
			m.add_child(cw)
			_box(m, Vector3(14, 34, 17), Vector3(-34, 17, 0), cream, true)
			_box(m, Vector3(14, 34, 17), Vector3(34, 17, 0), cream, true)
			_arch(m, 0, 2, 4, 8, 6.2, window)
	_decorate_building(m, type)
	return m


# Props from the CC0 kits on top of the procedural stone architecture (positions in model units).
func _decorate_building(m: Node3D, type: String) -> void:
	match type:
		"Farm":
			for i in range(3):
				var h := 4.0 + 4.0 * float(i)
				var z := 18.0 - 18.0 * float(i)
				for k in range(-2, 3):
					_prop(m, "nature/crops_wheatStageB", 7.0, Vector3(float(k) * 10.5, h + 2.0, z), float(k) * 37.0)
			_prop(m, "survival/bucket", 4.0, Vector3(-22, 0, 27))
		"Olive Grove":
			var spots := [Vector3(-17, 0, -13), Vector3(17, 0, -13), Vector3(0, 0, 0), Vector3(-17, 0, 13), Vector3(17, 0, 13)]
			for si in range(spots.size()):
				_prop(m, ["nature/tree_default", "nature/tree_oak", "nature/tree_fat"][si % 3], 19.0, spots[si], float(si) * 71.0, OLIVE_TINT)
			_prop(m, "survival/box-open", 5.0, Vector3(22, 0, 24), 15.0)
		"Pen":
			_prop(m, "nature/plant_bushLarge", 6.0, Vector3(14, 2, 8))
			_prop(m, "survival/bucket", 4.0, Vector3(6, 2, -4))
			_prop(m, "survival/resource-planks", 4.0, Vector3(-4, 2, 12), 30.0)
		"Storehouse":
			_prop(m, "survival/barrel", 9.0, Vector3(-22, 0, 28))
			_prop(m, "survival/barrel", 9.0, Vector3(-14, 0, 31))
			_prop(m, "survival/box-large", 9.0, Vector3(22, 0, 29), 10.0)
			_prop(m, "survival/box", 6.0, Vector3(14, 0, 32), -20.0)
		"Small Quarry":
			_prop(m, "nature/rock_largeB", 7.0, Vector3(-4, 0, 6), 20.0)
			_prop(m, "survival/tool-pickaxe", 7.0, Vector3(10, 0, 12), 60.0)
			_prop(m, "survival/resource-stone", 5.0, Vector3(-14, 0, 12))
		"Quarry":
			_prop(m, "nature/rock_largeA", 9.0, Vector3(-16, 0, 6), 30.0)
			_prop(m, "nature/rock_tallA", 14.0, Vector3(20, 0, -6), -10.0)
			_prop(m, "survival/resource-stone-large", 7.0, Vector3(4, 0, 16))
			_prop(m, "survival/tool-pickaxe", 7.0, Vector3(-4, 0, 20), 40.0)
		"Woodcutter":
			_prop(m, "nature/log_stackLarge", 9.0, Vector3(-10, 0, 16), 90.0)
			_prop(m, "nature/stump_round", 4.0, Vector3(13, 0, 14))
			_prop(m, "survival/tool-axe", 7.0, Vector3(13, 4, 14), 20.0)
		"Workshop":
			_prop(m, "survival/workbench-anvil", 9.0, Vector3(-16, 0, 26), 180.0)
			_prop(m, "survival/metal-panel-screws", 10.0, Vector3(18, 0, 24), 160.0)
			_prop(m, "survival/barrel", 8.0, Vector3(24, 0, 18))
		"Olive Press":
			_prop(m, "survival/barrel", 8.0, Vector3(-16, 0, 22))
			_prop(m, "survival/barrel", 8.0, Vector3(-9, 0, 24))
			_prop(m, "nature/pot_large", 7.0, Vector3(16, 0, 22))
		"Kitchen":
			_prop(m, "nature/pot_large", 7.0, Vector3(-18, 0, 24))
			_prop(m, "survival/barrel-open", 8.0, Vector3(20, 0, 22))
		"Market":
			_prop(m, "nature/pot_large", 6.0, Vector3(-27, 0, 20))
			_prop(m, "nature/pot_small", 4.0, Vector3(27, 0, 21))
			_prop(m, "survival/box", 5.0, Vector3(-28, 0, 12), 20.0)
			_prop(m, "survival/barrel", 7.0, Vector3(28, 0, 12))
		"Fishing Dock":
			_prop(m, "nature/canoe", 4.0, Vector3(-18, 0, -36), 10.0)
			_prop(m, "nature/canoe", 4.0, Vector3(18, 0, -40), -15.0)
			_prop(m, "survival/fish-large", 3.0, Vector3(6, 3, -14), 40.0)
			_prop(m, "survival/barrel", 7.0, Vector3(-4, 3, -10))
		"Barracks":
			for k in range(3):
				_prop(m, "survival/fence-fortified", 10.0, Vector3(-18.0 + float(k) * 18.0, 0, 24), 0.0)
			_prop(m, "castle/flag-banner-long", 22.0, Vector3(-24, 23, -20))
		"Watchtower":
			_prop(m, "castle/flag-pennant", 16.0, Vector3(-6, 76, -6))
		"Mosque":
			_prop(m, "nature/tree_palmTall", 34.0, Vector3(24, 0, 20))
			_prop(m, "nature/pot_large", 5.0, Vector3(-10, 0, 24))
			_prop(m, "nature/pot_large", 5.0, Vector3(10, 0, 24))
		"Clinic":
			_prop(m, "nature/pot_small", 4.0, Vector3(-9, 0, 23))
			_prop(m, "nature/pot_small", 4.0, Vector3(9, 0, 23))
		"Diwan":
			_prop(m, "nature/tree_palmTall", 34.0, Vector3(-34, 0, 30))
			_prop(m, "nature/tree_palmTall", 34.0, Vector3(34, 0, 30))
		"School":
			_prop(m, "nature/tree_oak", 18.0, Vector3(-18, 0, 14), 0.0, OLIVE_TINT)
		"Town Square":
			for tp in [Vector3(-20, 0, -16), Vector3(20, 0, -16), Vector3(-20, 0, 16), Vector3(20, 0, 16)]:
				_prop(m, "nature/tree_default", 18.0, tp + Vector3(0, 2, 0), tp.x * 3.0, OLIVE_TINT)
		"Plaza":
			for ta in [45, 135, 225, 315]:
				var tx := sin(deg_to_rad(float(ta))) * 26.0
				var tz := cos(deg_to_rad(float(ta))) * 26.0
				_prop(m, "nature/tree_oak", 15.0, Vector3(tx, 2, tz), float(ta), OLIVE_TINT)
			for fa in range(8):
				var fx := sin(float(fa) * TAU / 8.0) * 14.0
				var fz := cos(float(fa) * TAU / 8.0) * 14.0
				_prop(m, "nature/flower_redA", 3.0, Vector3(fx, 3, fz), float(fa) * 40.0, ANEMONE_TINT)
		"Well":
			_prop(m, "survival/bucket", 4.0, Vector3(14, 0, 14))


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
		shadows_on = bool(cf.get_value("gfx", "shadows", true))
		sfx_on = bool(cf.get_value("audio", "sfx", true))
	_apply_text_size()


func _apply_text_size() -> void:
	get_tree().root.content_scale_factor = float(TEXT_SIZES[text_size_index])


func _save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("ui", "text_size", text_size_index)
	cf.set_value("gfx", "shadows", shadows_on)
	cf.set_value("audio", "sfx", sfx_on)
	cf.save(SETTINGS_PATH)


func _toggle_shadows() -> void:
	shadows_on = not shadows_on
	if is_instance_valid(sun_node):
		sun_node.shadow_enabled = shadows_on
	shadow_btn.text = "الظلال: %s" % ("تعمل" if shadows_on else "مطفأة")
	_save_settings()


func _cycle_text_size() -> void:
	text_size_index = (text_size_index + 1) % TEXT_SIZES.size()
	_apply_text_size()
	_save_settings()
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
	t.default_font = ui_font
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
	b.pressed.connect(_guarded.bind(cb))
	return b


func _guarded(cb: Callable) -> void:
	if scroll_dragged:
		return
	_sfx("click", -12.0)
	cb.call()


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
	b.custom_minimum_size = Vector2(116, 80)
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
	_build_army_sheet()
	_build_economy_sheet()
	_build_plan_sheet()
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
	col.custom_minimum_size = Vector2(122, 0)
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
	var mh := HBoxContainer.new()
	mh.add_theme_constant_override("separation", 16)
	box.add_child(mh)
	var mt := _label_b("المهام", 28, C_GOLD)
	mt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mh.add_child(mt)
	mh.add_child(_button("سجل الأحداث", _toggle_sheet.bind("log"), Vector2(170, 50), 18))
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
	build_scroll.custom_minimum_size = Vector2(0, 196)
	build_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build_scroll.follow_focus = false
	build_scroll.scroll_deadzone = 100000
	scroll_targets.append(build_scroll)
	box.add_child(build_scroll)
	cards_box = HBoxContainer.new()
	cards_box.add_theme_constant_override("separation", 10)
	cards_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build_scroll.add_child(cards_box)





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
	var title := _label("الزيتون والحجر", 40, C_GOLD)
	title.add_theme_font_override("font", title_font)
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
	shadow_btn = _button("الظلال: %s" % ("تعمل" if shadows_on else "مطفأة"), _toggle_shadows, Vector2(0, 54), 22)
	vb.add_child(shadow_btn)
	sfx_btn = _button("الأصوات: %s" % ("تعمل" if sfx_on else "مطفأة"), _toggle_sfx, Vector2(0, 54), 22)
	vb.add_child(sfx_btn)
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
	var title := _label("الزيتون والحجر", 56, C_GOLD)
	title.add_theme_font_override("font", title_font)
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
		if bool(def.get("hidden", false)):
			continue
		cards_box.add_child(_build_card(str(bname), def))
	_scroll_to_start.call_deferred(build_scroll)


func _build_card(bname: String, def: Dictionary) -> Control:
	var locked := int(def["lv"]) > level
	var b := Button.new()
	b.custom_minimum_size = Vector2(200, 172)
	b.pressed.connect(_guarded.bind(_card_pressed.bind(bname)))
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
	menu_layer.visible = true
	_sync_menu_open()
	new_armed = false
	new_btn.text = "مخيم جديد"


func _close_menu() -> void:
	menu_layer.visible = false
	_sync_menu_open()


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
		if _sum_jobs() >= _worker_count():
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
	var cons_all := _compute_consumption()
	if n > 0.0 and days_labels.size() > 0:
		for res_d in [["Food", float(cons_all.get("Food", 0.0))], ["Water", float(cons_all.get("Water", 0.0))]]:
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
		var food_days := float(resources.get("Food", 0.0)) / maxf(1.0, float(cons_all.get("Food", 1.0)))
		var water_days := float(resources.get("Water", 0.0)) / maxf(1.0, float(cons_all.get("Water", 1.0)))
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
		var net: float = float(last_income.get(r, 0.0)) - float(cons_all.get(r, 0.0))
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
	if v.unit != "":
		return "في الجيش (%s)%s" % [UNITS[v.unit]["ar"], " — في حملة" if v.away else " — يحرس المخيم"]
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
		"home": return _has_done("Shack") or _has_done("Small House") or _has_done("Stone House") or _has_done("Large House")
		"road": return roads.size() >= 4
		"storehouse": return _has_done("Storehouse")
		"farm": return _has_done("Farm")
		"zone":
			var nz := 0
			for c in zones:
				if int(zones[c]) == 1:
					nz += 1
			return nz >= 2
		"level2": return level >= 2
		"explore": return not discovered_villages.is_empty()
		"trade": return trades_done > 0
		"barracks": return _has_done("Barracks") and _soldier_count() >= 2
		"market": return _has_done("Market")
		"kitchen": return _has_done("Kitchen")
		"pop10": return survivors.size() >= 10
		"defend": return raids_won + raids_lost >= 1
		"stone_house": return _has_done("Stone House")
		"level3": return level >= 3
		"olive_press": return _has_done("Olive Press")
		"diwan": return council_unlocked
		"contract": return contracts_signed > 0
		"upgrade", "upgrade3":
			var need := 2 if key == "upgrade" else 3
			for b in buildings:
				if b.done and b.lvl >= need:
					return true
			return false
		"pop20": return survivors.size() >= 20
		"fishing_dock": return _has_done("Fishing Dock")
		"lair": return lairs_cleared >= 1
		"level4": return level >= 4
		"mosque": return _has_done("Mosque")
		"clinic": return _has_done("Clinic")
		"khan": return _has_done("Khan")
		"town_square": return _has_done("Town Square")
		"day60": return day >= 60
		"level5": return level >= 5
		"day90": return day >= 90
	return false


# v2/v3.0 saves used an 88-unit grid with 2x1 medium plots.
func _convert_old_anchor(gx: int, gz: int, cls: String) -> Vector2i:
	var off := Vector2(0.0 if cls == "S" else 0.5, 0.5 if cls == "L" else 0.0)
	var wx := camp_pos.x + (float(gx) + off.x) * OLD_PLACE_CELL
	var wz := camp_pos.z + (float(gz) + off.y) * OLD_PLACE_CELL
	return _anchor_from_world(wx, wz, cls)


func _old_cell_to_new(cell: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var cx := float(cell.x) * OLD_PLACE_CELL
	var cz := float(cell.y) * OLD_PLACE_CELL
	var r := int(ceil(OLD_PLACE_CELL / PLACE_CELL))
	var c0 := Vector2i(roundi(cx / PLACE_CELL), roundi(cz / PLACE_CELL))
	for dx in range(-r, r + 1):
		for dz in range(-r, r + 1):
			var n := c0 + Vector2i(dx, dz)
			if absf(float(n.x) * PLACE_CELL - cx) <= OLD_PLACE_CELL * 0.5 and absf(float(n.y) * PLACE_CELL - cz) <= OLD_PLACE_CELL * 0.5:
				out.append(n)
	return out


func _nearest_free(gx: int, gz: int, cls: String, max_r: int) -> Vector2i:
	for r in range(1, max_r + 1):
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				if maxi(absi(dx), absi(dz)) == r and _cells_free(gx + dx, gz + dz, cls):
					return Vector2i(gx + dx, gz + dz)
	return Vector2i(99999, 99999)


func _add_trail_patch(key: Vector2i) -> void:
	if trail_used >= TRAIL_MAX:
		return
	var cx := (float(key.x) + 0.5) * TRAIL_CELL
	var cz := (float(key.y) + 0.5) * TRAIL_CELL
	var fr := _footing_range(cx, cz)
	trail_mm.set_instance_transform(trail_used, Transform3D(Basis(), Vector3(cx, (fr.x + fr.y) * 0.5 + 0.35, cz)))
	trail_used += 1
	trail_mm.visible_instance_count = trail_used
	trail_counts[key] = -1.0


func _write_save(path: String, silent: bool) -> void:
	var blist: Array = []
	for b in buildings:
		var pp: Plot = plots[b.plot]
		blist.append({"type": b.type, "gx": pp.gx, "gz": pp.gz, "progress": b.progress, "done": b.done, "lvl": b.lvl, "rot": b.rot, "active": b.active})
	var vlist: Array = []
	for v in survivors:
		vlist.append([v.vname, v.skill, v.unit])
	var amounts: Array = []
	for s in sources:
		if s.building == null:
			amounts.append(s.amount)
	var zl: Array = []
	for c in zones:
		zl.append([c.x, c.y, int(zones[c])])
	var rl: Array = []
	for k in roads:
		rl.append([k.x, k.y, int(roads[k])])
	var tl: Array = []
	for k2 in trail_counts:
		if float(trail_counts[k2]) < 0.0 and not roads.has(k2):
			tl.append([k2.x, k2.y])
	var vs := {}
	for idx in village_state:
		vs[str(idx)] = float(village_state[idx]["rel"])
	var data := {
		"version": SAVE_VERSION, "region": "Haifa", "resources": resources, "jobs": jobs, "day": day,
		"morale": morale, "health": health, "hope": hope, "discontent": discontent,
		"council_unlocked": council_unlocked, "tax_level_idx": tax_level_idx,
		"event_cooldown": event_cooldown,
		"discovered_villages": discovered_villages, "exploring": exploring,
		"explore_done_day": explore_done_day, "event_log": event_log,
		"goal": goal_index, "peak": peak_pop, "level": level, "xp": xp,
		"workers_opened": workers_opened, "buildings": blist, "villagers": vlist, "sources": amounts,
		"cur_season": cur_season, "season_day": season_day,
		"zones": zl, "roads": rl, "trails": tl, "village_rel": vs, "contracts": contracts, "requests": requests,
		"policies": policies.keys(), "raid_next_day": raid_next_day, "raids_won": raids_won, "raids_lost": raids_lost,
		"lairs_cleared": lairs_cleared, "trades_done": trades_done, "contracts_signed": contracts_signed,
		"day_timer": day_timer, "camp_tents_up": camp_tents_up
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
	if str(d.get("region", "")) != "Haifa" or save_ver < MIN_SAVE_VERSION:
		_toast("هذا الحفظ من إصدار قديم جدًا، سيبدأ مخيم جديد.")
		return
	_cancel_placement()
	_close_inspect()
	_close_all_modals()
	if plan_mode != "":
		_set_plan_mode(plan_mode)
	for b in buildings:
		b.node.queue_free()
	buildings.clear()
	for p in plots:
		if is_instance_valid(p.node):
			p.node.queue_free()
	plots.clear()
	occupied_cells.clear()
	for r in ruin_nodes:
		if is_instance_valid(r):
			(r as Node3D).visible = true
	for i in range(sources.size() - 1, -1, -1):
		if sources[i].building != null:
			sources.remove_at(i)
	for v in survivors:
		v.node.queue_free()
	survivors.clear()
	if is_instance_valid(raid_node):
		raid_node.queue_free()
	raid_node = null
	var saved_res: Dictionary = d.get("resources", {})
	for r in RES_NAMES:
		resources[r] = float(saved_res.get(r, resources[r]))
	var saved_jobs: Dictionary = d.get("jobs", {})
	for r in START_JOBS:
		jobs[r] = int(saved_jobs.get(r, 0))
	day = int(d.get("day", day))
	day_timer = clampf(float(d.get("day_timer", 0.0)), 0.0, DAY_LENGTH - 0.1)
	morale = float(d.get("morale", morale))
	health = float(d.get("health", health))
	hope = float(d.get("hope", 50.0))
	discontent = float(d.get("discontent", 0.0))
	council_unlocked = bool(d.get("council_unlocked", false))
	tax_level_idx = clampi(int(d.get("tax_level_idx", 0)), 0, TAX_LEVELS.size() - 1)
	event_cooldown = int(d.get("event_cooldown", 0))
	discovered_villages.clear()
	for vi in d.get("discovered_villages", []):
		var vi_int := int(vi)
		if vi_int >= 0 and vi_int < VILLAGES.size() and not discovered_villages.has(vi_int):
			discovered_villages.append(vi_int)
	exploring = bool(d.get("exploring", false))
	explore_done_day = int(d.get("explore_done_day", -1))
	event_log.clear()
	for entry in d.get("event_log", []):
		event_log.append(str(entry))
	peak_pop = int(d.get("peak", START_POP))
	level = clampi(int(d.get("level", 1)), 1, MAX_LEVEL)
	xp = float(d.get("xp", 0.0))
	workers_opened = bool(d.get("workers_opened", false))
	cur_season = clampi(int(d.get("cur_season", 0)), 0, 3)
	season_day = clampi(int(d.get("season_day", 0)), 0, SEASON_DAYS - 1)
	# planning layers
	zones.clear()
	for z in d.get("zones", []):
		if typeof(z) == TYPE_ARRAY and z.size() >= 3 and ZONE_AR.has(int(z[2])):
			if save_ver >= 8:
				zones[Vector2i(int(z[0]), int(z[1]))] = int(z[2])
			else:
				for nc in _old_cell_to_new(Vector2i(int(z[0]), int(z[1]))):
					zones[nc] = int(z[2])
	roads.clear()
	trail_counts.clear()
	trail_used = 0
	trail_mm.visible_instance_count = 0
	for rd in d.get("roads", []):
		if typeof(rd) == TYPE_ARRAY and rd.size() >= 3:
			var k := Vector2i(int(rd[0]), int(rd[1]))
			roads[k] = clampi(int(rd[2]), ROAD_DIRT, ROAD_PAVED)
			trail_counts[k] = -1.0
	_rebuild_road_meshes()
	for tr in d.get("trails", []):
		if typeof(tr) == TYPE_ARRAY and tr.size() >= 2:
			_add_trail_patch(Vector2i(int(tr[0]), int(tr[1])))
	# trade & army state
	village_state.clear()
	var vrel: Dictionary = d.get("village_rel", {})
	for key in vrel:
		village_state[int(key)] = {"rel": float(vrel[key]), "used": {}}
	for vi2 in discovered_villages:
		_vstate(vi2)
	contracts.clear()
	for c in d.get("contracts", []):
		if typeof(c) == TYPE_DICTIONARY and c.has("v") and RES_AR.has(str(c.get("res", ""))):
			contracts.append({"v": int(c["v"]), "kind": str(c["kind"]), "res": str(c["res"]), "qty": int(c["qty"]), "dinar": int(c["dinar"]), "next": int(c["next"])})
	requests.clear()
	for rq in d.get("requests", []):
		if typeof(rq) == TYPE_DICTIONARY and rq.has("v") and RES_AR.has(str(rq.get("res", ""))):
			requests.append({"v": int(rq["v"]), "res": str(rq["res"]), "qty": int(rq["qty"]), "reward": int(rq["reward"]), "until": int(rq["until"])})
	policies.clear()
	for pk in d.get("policies", []):
		if POLICIES.has(str(pk)):
			policies[str(pk)] = true
	raid_next_day = maxi(int(d.get("raid_next_day", maxi(RAID_FIRST_DAY, day + 4))), day + 1)
	raid_warned = false
	raids_won = int(d.get("raids_won", 0))
	raids_lost = int(d.get("raids_lost", 0))
	lairs_cleared = clampi(int(d.get("lairs_cleared", 0)), 0, BANDIT_LAIRS.size())
	trades_done = int(d.get("trades_done", 0))
	contracts_signed = int(d.get("contracts_signed", contracts.size()))
	camp_tents_up = bool(d.get("camp_tents_up", true))
	if is_instance_valid(camp_tents_node):
		camp_tents_node.visible = camp_tents_up
	expedition_day = -1
	expedition_lair = -1
	caravan_until = -1
	caravan_deals.clear()
	var amounts: Array = d.get("sources", [])
	var idx := 0
	for s in sources:
		if s.building == null:
			if idx < amounts.size():
				s.amount = float(amounts[idx])
				_update_source_visual(s)
			idx += 1
	for e in d.get("buildings", []):
		if typeof(e) != TYPE_DICTIONARY:
			continue
		var ed: Dictionary = e
		var t := str(ed.get("type", ""))
		if not BUILDINGS.has(t):
			continue
		var gx_b := int(ed.get("gx", 0))
		var gz_b := int(ed.get("gz", 0))
		var cls_b := str(BUILDINGS[t]["cls"])
		if save_ver < 8:
			var conv := _convert_old_anchor(gx_b, gz_b, cls_b)
			gx_b = conv.x
			gz_b = conv.y
		if not _cells_free(gx_b, gz_b, cls_b):
			var spot := _nearest_free(gx_b, gz_b, cls_b, 3)
			if spot.x == 99999:
				continue
			gx_b = spot.x
			gz_b = spot.y
		var lvl_b := int(ed.get("lvl", int(ed.get("upgrade", 0)) + 1))
		var new_p := _create_dynamic_plot(gx_b, gz_b, cls_b)
		var new_b := _spawn_building(t, new_p.idx, float(ed.get("progress", 1.0)), bool(ed.get("done", true)), float(ed.get("rot", -1.0)), lvl_b)
		new_b.active = bool(ed.get("active", true))
		for s2 in sources:
			if s2.building == new_b:
				_apply_source_stats(s2, new_b)
		if new_b.done and BUILDINGS[t].get("council", false):
			council_unlocked = true
	for e2 in d.get("villagers", []):
		if typeof(e2) == TYPE_ARRAY and e2.size() >= 2 and SKILL_COLORS.has(str(e2[1])):
			var nv := _add_villager(str(e2[0]), str(e2[1]))
			if e2.size() >= 3 and UNITS.has(str(e2[2])):
				nv.unit = str(e2[2])
				nv.task = "guard"
				nv.goal = _patrol_point()
				_refresh_villager_look(nv)
	if survivors.is_empty():
		for i in range(START_POP):
			_add_villager(NAMES[i], SKILLS[i % SKILLS.size()])
	if save_ver >= SAVE_VERSION:
		goal_index = clampi(int(d.get("goal", 0)), 0, GOALS.size())
	else:
		goal_index = 0
		while goal_index < GOALS.size() and _goal_done(str(GOALS[goal_index]["key"])):
			goal_index += 1
	_clamp_jobs()
	_update_land_value()
	game_over = false
	over_layer.visible = false
	_refresh_plots()
	_assign_tasks()
	_check_goals()
	_refresh_ui()
	_close_menu()
	_toast("تم تحميل المخيم.")


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
			tip = "ابنِ «كوخ الحطّاب» لحطب لا ينضب."
		"Oil":
			tip = "ابنِ معصرة زيتون."
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
		var msg := "ارتقى المخيم إلى المستوى %d! اتسعت حدود البناء." % level
		if is_instance_valid(territory_ring):
			_show_territory(true)
		if not names.is_empty():
			msg += " فُتح: %s" % "، ".join(names)
		if opened > 0:
			msg += " و%d قطعة أرض جديدة." % opened
		_toast(msg, 6.0)
		_sfx("levelup", -3.0)
		_refresh_plots()
		if is_instance_valid(build_sheet) and build_sheet.visible:
			_rebuild_cards()


# ---------------------------------------------------------------- placing buildings on plots

func _start_placing(bname: String) -> void:
	_hide_sheets()
	_close_inspect()
	if plan_mode != "":
		_set_plan_mode(plan_mode)
	selected_building = bname
	dock.visible = false
	place_bar.visible = true
	_show_territory(true)
	var start := camera_target
	if bool(BUILDINGS[bname].get("coastal", false)):
		_toast("رصيف الصيد يُبنى على خط الشاطئ فقط. مدّ طريقًا غربًا إلى البحر ثم المس الشاطئ.", 6.0)
	_update_ghost_placement(start)


func _noise_warning(center: Vector2, cat: String) -> String:
	var noisy := ["Quarry", "Workshop", "Small Quarry", "Pen", "Olive Press", "Barracks"]
	for b in buildings:
		var bp := Vector2(b.pos.x, b.pos.z)
		if bp.distance_to(center) > 190.0:
			continue
		if cat == "res" and noisy.has(b.type):
			return "تنبيه: «%s» قريب — ضجيج يخفض قيمة الأرض ومعنويات السكان." % BUILDINGS[b.type]["ar"]
		if (cat == "ind" or cat == "agri") and _housing_of(b) > 0:
			return "تنبيه: بيوت قريبة — سيزعج هذا المبنى الجيران."
	return ""


func _update_ghost_placement(hp: Vector3) -> void:
	if selected_building == "":
		return
	var def: Dictionary = BUILDINGS[selected_building]
	var cls := str(def["cls"])
	var anchor := _anchor_from_world(hp.x, hp.z, cls)
	var gx := anchor.x
	var gz := anchor.y
	var problem := _place_problem(gx, gz, cls, selected_building)
	var valid := problem == ""
	var sz: Vector2 = PLOT_SIZES[cls]
	var c := _footprint_center(gx, gz, cls)
	var hr := _footprint_heights(c, sz)
	var bm: BoxMesh = ghost_mesh.mesh
	bm.size = Vector3(sz.x * 0.9, 34.0, sz.y * 0.9)
	ghost_mesh.position = Vector3(0, 19, 0)
	ghost.position = Vector3(c.x, hr.y, c.y)
	ghost.rotation_degrees.y = _facing_for(c, cls)
	ghost.visible = true
	var lv_here := _footprint_land_value(gx, gz, cls)
	if valid:
		var lv_frac := clampf(lv_here / 60.0, 0.0, 1.0)
		ghost_mat.albedo_color = Color(0.3, 0.62 + lv_frac * 0.3, 0.3, 0.5)
	else:
		ghost_mat.albedo_color = Color(0.9, 0.3, 0.3, 0.45)
	pending_gx = gx
	pending_gz = gz
	pending_valid = valid
	var status: String
	if valid:
		var extras: Array[String] = ["قيمة الأرض %d" % int(lv_here)]
		var cat := str(def.get("cat", "any"))
		if _zone_matches(gx, gz, cls, cat):
			extras.append("منطقة مناسبة +20%")
		if hr.y - hr.x > 1.5:
			extras.append("على مصطبة حجرية")
		status = "✓ موقع صالح (%s) — المس «تأكيد البناء»" % "، ".join(extras)
		var warn := _noise_warning(c, cat)
		if warn != "":
			status += "\n" + warn
	else:
		status = "✗ " + problem
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
	if plan_mode == "":
		_show_territory(false)
	if is_instance_valid(place_bar):
		place_bar.visible = false
		if inspected == null and plan_mode == "":
			dock.visible = true


func _confirm_build() -> void:
	if selected_building == "" or not pending_valid:
		_sfx("error")
		_toast("المس موقعًا صالحًا (أخضر) أولًا.")
		return
	var def: Dictionary = BUILDINGS[selected_building]
	var cost: Dictionary = def["cost"]
	var missing := _missing_resource(cost)
	if missing != "":
		_toast("ينقصك %s." % RES_AR[missing])
		return
	var problem := _place_problem(pending_gx, pending_gz, str(def["cls"]), selected_building)
	if problem != "":
		_toast(problem)
		return
	if def.has("defense") and selected_building == "Wall" and _count_type("Wall") >= 8:
		_toast("الحد الأقصى 8 قطع سور.")
		return
	for r in cost:
		resources[r] = float(resources[r]) - float(cost[r])
	var cls := str(def["cls"])
	var p := _create_dynamic_plot(pending_gx, pending_gz, cls)
	var bname := selected_building
	_spawn_building(bname, p.idx, 0.0, false)
	_dust_burst(p.pos)
	_sfx("build", -3.0)
	_cancel_placement()
	_assign_tasks()
	_refresh_ui()
	_toast("وُضع أساس «%s». البنّاؤون في الطريق." % def["ar"])


func _count_type(t: String) -> int:
	var n := 0
	for b in buildings:
		if b.type == t:
			n += 1
	return n


const LEVEL_NAMES := {
	"Tent": ["خيمة", "خيمة مرقّعة", "بيت شعر"],
	"Well": ["بئر", "بئر معقودة", "بئر بناعورة"],
	"Farm": ["مزرعة", "مزرعة مسقية", "مزرعة مدرّجات"],
	"Fishing Dock": ["رصيف الصيد", "ميناء صيد", "ميناء حيفا"],
	"Mosque": ["جامع", "جامع بقبتين", "الجامع الكبير"],
	"Market": ["السوق", "سوق مسقوف", "السوق الكبير"],
	"Barracks": ["الثكنة", "حامية", "قلعة الحامية"],
	"Watchtower": ["برج المراقبة", "برج حجري", "برج الحرس"],
}
const MAX_BLD_LEVEL := 3


func _bld_name(b: Building) -> String:
	if LEVEL_NAMES.has(b.type):
		return str(LEVEL_NAMES[b.type][b.lvl - 1])
	var base := str(BUILDINGS[b.type]["ar"])
	return base if b.lvl == 1 else "%s (م%d)" % [base, b.lvl]


func _spawn_building(type: String, plot_idx: int, progress: float, done: bool, rot: float = -1.0, lvl: int = 1) -> Building:
	var p: Plot = plots[plot_idx]
	var def: Dictionary = BUILDINGS[type]
	var b := Building.new()
	b.type = type
	b.plot = plot_idx
	b.pos = p.pos
	b.progress = progress
	b.done = done
	b.lvl = clampi(lvl, 1, MAX_BLD_LEVEL)
	b.rot = rot if rot >= 0.0 else _facing_for(Vector2(p.pos.x, p.pos.z), p.cls)
	b.zone_bonus = _zone_matches(p.gx, p.gz, p.cls, str(def.get("cat", "any")))
	b.base_scale = float(def["scale"]) * float(CLASS_FILL[p.cls])
	b.node = Node3D.new()
	b.node.position = b.pos
	b.node.rotation_degrees.y = b.rot
	building_root.add_child(b.node)
	b.model = _make_building_model(type)
	_bake_static(b.model)
	b.model.position.y = 2.0
	b.node.add_child(b.model)
	p.building = b
	if not done:
		b.model.scale = Vector3(b.base_scale, b.base_scale * lerpf(0.12, 1.0, progress), b.base_scale)
		b.scaffold = _make_scaffold(p.size.x, p.size.y)
		_bake_static(b.scaffold)
		b.node.add_child(b.scaffold)
		b.label = Label3D.new()
		b.label.font = ui_font_bold
		b.label.font_size = 36
		b.label.pixel_size = 0.9
		b.label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		b.label.no_depth_test = true
		b.label.outline_size = 12
		b.label.modulate = Color("#fff3c4")
		b.label.position = Vector3(0, 80, 0)
		b.node.add_child(b.label)
	else:
		_apply_level_visual(b)
	buildings.append(b)
	_add_building_fx(b)
	if done:
		_add_building_source(b)
	_refresh_plots()
	return b


# Visual growth per building level: slightly larger, then planters and a banner, then a fence and lanterns.
func _apply_level_visual(b: Building) -> void:
	var s := b.base_scale * (1.0 + 0.06 * float(b.lvl - 1))
	b.model.scale = Vector3.ONE * s
	var old := b.node.get_node_or_null("Decor")
	if old != null:
		old.free()
	if b.lvl < 2:
		return
	var p: Plot = plots[b.plot]
	var d := Node3D.new()
	d.name = "Decor"
	b.node.add_child(d)
	var hx := p.size.x * 0.5 - 8.0
	var hz := p.size.y * 0.5 - 8.0
	for sx in [-1.0, 1.0]:
		_box(d, Vector3(9, 5, 9), Vector3(sx * hx, 4.5, hz), Color.WHITE, true)
		_cyl(d, 1.0, 1.4, 8.0, Vector3(sx * hx, 10, hz), Color("#6b553c"))
		_sphere(d, 5.0, Vector3(sx * hx, 16, hz), Color("#6f8a4a"))
	_cyl(d, 0.9, 0.9, 40.0, Vector3(hx, 22, -hz), Color("#8a6a40"))
	_box(d, Vector3(12, 7, 1.0), Vector3(hx - 6.5, 37, -hz), C_GOLD)
	if b.lvl < 3:
		_bake_static(d)
		return
	for side in [-1.0, 1.0]:
		_box(d, Vector3(p.size.x, 5, 2.5), Vector3(0, 4.5, side * (p.size.y * 0.5 - 1.5)), Color("#efe4c8"), true)
		_box(d, Vector3(2.5, 5, p.size.y), Vector3(side * (p.size.x * 0.5 - 1.5), 4.5, 0), Color("#efe4c8"), true)
	var lamp := StandardMaterial3D.new()
	lamp.albedo_color = Color("#ffd27a")
	lamp.emission_enabled = true
	lamp.emission = Color("#ffb347")
	lamp.emission_energy_multiplier = 1.6
	for sx2 in [-0.25, 0.25]:
		_cyl(d, 0.7, 0.7, 16.0, Vector3(sx2 * p.size.x, 10, hz + 4.0), Color("#3a3530"))
		var l := _sphere(d, 2.6, Vector3(sx2 * p.size.x, 19, hz + 4.0), Color.WHITE)
		l.material_override = lamp
	_bake_static(d)


func _apply_source_stats(s: Source, b: Building) -> void:
	var g: Dictionary = BUILDINGS[b.type]["gather"]
	if g.is_empty():
		return
	var mult := _lvl_mult(b) * ((1.0 + ZONE_BONUS) if b.zone_bonus else 1.0)
	s.yield_amt = float(g["yield"]) * mult
	s.gather_time = float(g["time"])
	s.slots = (int(g["slots"]) + b.lvl - 1) if b.active else 0


func _add_building_source(b: Building) -> void:
	var def: Dictionary = BUILDINGS[b.type]
	var g: Dictionary = def["gather"]
	if g.is_empty():
		return
	var p: Plot = plots[b.plot]
	var s := Source.new()
	s.res = str(g["res"])
	s.label = str(def["ar"])
	var depth := p.size.y if (is_equal_approx(b.rot, 0.0) or is_equal_approx(b.rot, 180.0)) else p.size.x
	var off := Basis(Vector3.UP, deg_to_rad(b.rot)) * Vector3(0, 0, depth * 0.5 + 12.0)
	s.pos = b.pos + off
	s.pos.y = _height_at_world(s.pos.x, s.pos.z)
	s.infinite = true
	s.building = b
	_apply_source_stats(s, b)
	sources.append(s)


func _complete_building(b: Building) -> void:
	var def: Dictionary = BUILDINGS[b.type]
	b.done = true
	b.progress = 1.0
	if is_instance_valid(b.scaffold):
		b.scaffold.queue_free()
	if is_instance_valid(b.label):
		b.label.queue_free()
	_apply_level_visual(b)
	var target_scale := b.model.scale
	var tw := create_tween()
	tw.tween_property(b.model, "scale", target_scale, 0.35).from(target_scale * 1.12)
	_add_building_source(b)
	_add_building_fx(b)
	_dust_burst(b.pos)
	_sfx("complete", -4.0)
	_add_xp(float(def["xp"]))
	if def.get("council", false) and not council_unlocked:
		council_unlocked = true
		_toast("افتُتح الديوان! المسه لإدارة الضرائب والسياسات.", 6.0)
	if def.get("barracks", false):
		_toast("الثكنة جاهزة — افتح «الجيش» لتجنيد المدافعين.", 6.0)
	if def.get("market", false):
		_toast("السوق مفتوح — دخل يومي من الدنانير، وصار بإمكانك توقيع عقود تجارية.", 6.0)
	_update_land_value()
	_assign_tasks()
	_check_goals()
	_refresh_ui()
	if not def.get("council", false) and not def.get("barracks", false) and not def.get("market", false):
		_toast("اكتمل بناء «%s»!" % def["ar"])
	_log_event("🏗 يوم %d: اكتمل بناء %s." % [day, str(def["ar"])])


func _upkeep_text(type: String) -> String:
	var up: Dictionary = BUILDINGS[type].get("upkeep", {})
	if up.is_empty():
		return "بلا تكلفة يومية"
	var parts: Array[String] = []
	for r in up:
		parts.append("%s %s" % [_fmt(float(up[r])), RES_AR[r]])
	return "تكلفة يومية: " + "، ".join(parts)


func _fmt(v: float) -> String:
	if absf(v - round(v)) < 0.05:
		return str(int(round(v)))
	return "%.1f" % v


func _building_status(b: Building) -> String:
	var def: Dictionary = BUILDINGS[b.type]
	if not b.done:
		return "%s — قيد البناء (%d%%)" % [def["ar"], int(b.progress * 100.0)]
	var lines: Array[String] = []
	lines.append("%s  •  المستوى %d" % [_bld_name(b), b.lvl])
	if not b.active:
		lines.append("⚠ متوقف: لم تُدفع التكلفة اليومية (%s)" % _upkeep_text(b.type).replace("تكلفة يومية: ", ""))
	var g: Dictionary = def["gather"]
	if not g.is_empty():
		var users := 0
		var slots := 0
		var yld := 0.0
		for s in sources:
			if s.building == b:
				users = _source_users(s, null)
				slots = s.slots
				yld = s.yield_amt
		lines.append("العاملون: %d من %d — %s %s لكل جولة" % [users, slots, _fmt(yld), RES_AR[str(g["res"])]])
	var h := _housing_of(b)
	if h > 0:
		lines.append("يسكنه حتى %d ناجين" % h)
	if SERVICE_COVERAGE.has(b.type):
		var pts := _housing_points()
		var total := 0.0
		for pt in pts:
			total += float(pt[1])
		lines.append("يغطي %d%% من بيوت المستوطنة (الدائرة الزرقاء)" % int(_coverage_share(b, pts, total) * 100.0))
	if def.has("defense"):
		lines.append("دفاع +%d" % int(float(def["defense"]) * _lvl_mult(b)))
	if def.get("barracks", false):
		lines.append("سعة الجنود: %d" % (6 * b.lvl))
	if b.zone_bonus:
		lines.append("✓ في منطقته المناسبة: +20%")
	lines.append(_upkeep_text(b.type))
	return "\n".join(lines)


func _upgrade_cost(b: Building) -> Dictionary:
	var base: Dictionary = BUILDINGS[b.type]["cost"]
	var f := 0.8 if b.lvl == 1 else 1.4
	var out := {}
	for r in base:
		out[r] = ceilf(float(base[r]) * f)
	if b.lvl == 2:
		out["Dinar"] = float(out.get("Dinar", 0.0)) + 10.0
	return out


func _upgrade_req_level(b: Building) -> int:
	return 2 if b.lvl == 1 else 4


func _inspect_building(b: Building) -> void:
	if selected_building != "" or plan_mode != "":
		return
	_hide_sheets()
	inspected = b
	demolish_armed = false
	demolish_btn.text = "هدم"
	dock.visible = false
	inspect_bar.visible = true
	inspect_label.text = _building_status(b)
	var def: Dictionary = BUILDINGS[b.type]
	if b.done and b.lvl < MAX_BLD_LEVEL:
		var cost := _upgrade_cost(b)
		var parts: Array[String] = []
		for r in cost:
			parts.append("%d %s" % [int(cost[r]), RES_AR[r]])
		var req := _upgrade_req_level(b)
		if level < req:
			upgrade_btn.text = "ترقية للمستوى %d\n(يتطلب المخيم م%d)" % [b.lvl + 1, req]
		else:
			upgrade_btn.text = "ترقية للمستوى %d\n%s" % [b.lvl + 1, "، ".join(parts)]
		upgrade_btn.visible = true
	else:
		upgrade_btn.visible = false
	council_btn.visible = b.done and bool(def.get("council", false))
	army_btn.visible = b.done and bool(def.get("barracks", false))
	trade_btn.visible = b.done and (bool(def.get("market", false)) or bool(def.get("stable", false)))
	_show_coverage_ring(b if b.done else null)


func _close_inspect() -> void:
	inspected = null
	demolish_armed = false
	_show_coverage_ring(null)
	if is_instance_valid(inspect_bar):
		inspect_bar.visible = false
		if selected_building == "" and plan_mode == "":
			dock.visible = true


func _upgrade_pressed() -> void:
	if inspected == null or not inspected.done or inspected.lvl >= MAX_BLD_LEVEL:
		return
	var req := _upgrade_req_level(inspected)
	if level < req:
		_toast("الترقية إلى المستوى %d تتطلب بلوغ المخيم المستوى %d." % [inspected.lvl + 1, req])
		return
	var cost := _upgrade_cost(inspected)
	var missing := _missing_resource(cost)
	if missing != "":
		_toast("ينقصك %s للترقية (%d مطلوب)." % [RES_AR[missing], int(cost[missing])])
		return
	for r in cost:
		resources[r] = float(resources[r]) - float(cost[r])
	var b := inspected
	b.lvl += 1
	_apply_level_visual(b)
	var tw := create_tween()
	tw.tween_property(b.model, "scale", b.model.scale, 0.4).from(b.model.scale * 1.15)
	for s in sources:
		if s.building == b:
			_apply_source_stats(s, b)
	_toast("رُقّي «%s» إلى المستوى %d!" % [str(BUILDINGS[b.type]["ar"]), b.lvl], 4.0)
	_sfx("upgrade")
	_dust_burst(b.pos)
	_log_event("⬆ يوم %d: ترقية %s إلى م%d." % [day, str(BUILDINGS[b.type]["ar"]), b.lvl])
	_add_xp(15.0 + 10.0 * float(b.lvl))
	_update_land_value()
	_check_goals()
	_inspect_building(b)
	_assign_tasks()
	_refresh_ui()


func _demolish_pressed() -> void:
	if inspected == null:
		return
	var b := inspected
	var def: Dictionary = BUILDINGS[b.type]
	var h := _housing_of(b)
	if h > 0 and survivors.size() > _housing_capacity() - h:
		_toast("ما زال ناجون يسكنون هذا المبنى. ابنِ مأوى بديلًا أولًا.")
		return
	if def.get("barracks", false) and b.done and _soldier_count() > _barracks_capacity() - 6 * b.lvl:
		_toast("سرّح بعض الجنود أولًا — الثكنة ممتلئة.")
		return
	if not demolish_armed:
		demolish_armed = true
		demolish_btn.text = "تأكيد الهدم؟"
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
	if is_instance_valid(pp.node):
		pp.node.queue_free()
	pp.node = null
	pp.slab = null
	pp.building = null
	buildings.erase(b)
	b.node.queue_free()
	if def.get("council", false) and not _has_done("Diwan"):
		council_unlocked = false
		tax_level_idx = 0
		policies.clear()
	_toast("هُدم «%s» واستُعيد نصف المواد." % def["ar"])
	_close_inspect()
	_update_land_value()
	_refresh_plots()
	_assign_tasks()
	_refresh_ui()


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

















# ---------------------------------------------------------------- days

# ---------------------------------------------------------------- economy: needs, upkeep, budget

const TAX_PER_HEAD := [0.0, 0.2, 0.45, 0.8]
const TAX_DISCONTENT := [0.0, 0.0, 0.8, 2.5]
var dinar_today: Dictionary = {}
var army_unpaid := false


func _add_dinar(amount: float, label: String) -> void:
	resources["Dinar"] = float(resources.get("Dinar", 0.0)) + amount
	dinar_today[label] = float(dinar_today.get(label, 0.0)) + amount


func _kitchen_on() -> bool:
	for b in buildings:
		if b.done and b.active and bool(BUILDINGS[b.type].get("kitchen", false)):
			return true
	return false


func _people_needs() -> Dictionary:
	var n := float(survivors.size())
	var soldiers := float(_soldier_count())
	var food_mul := (0.75 if _kitchen_on() else 1.0) * float(SEASON_FOOD_MUL[cur_season])
	var water_mul := float(SEASON_WATER_MUL[cur_season]) * (0.75 if policies.get("water_ration", false) else 1.0)
	return {
		"Food": (n * FOOD_PER_VILLAGER + soldiers * SOLDIER_FOOD) * food_mul,
		"Water": n * WATER_PER_VILLAGER * water_mul,
		"Wood": n * float(HEAT_WOOD[cur_season]),
	}


func _building_upkeep(b: Building) -> Dictionary:
	var up: Dictionary = BUILDINGS[b.type].get("upkeep", {})
	var out := {}
	var f := 1.0 + 0.3 * float(b.lvl - 1)
	for r in up:
		out[r] = float(up[r]) * f
	return out


func _wages() -> float:
	var w := 0.0
	for v in survivors:
		if v.unit != "":
			w += float(UNITS[v.unit]["wage"])
	return w


func _compute_consumption() -> Dictionary:
	var c := _people_needs()
	c["Dinar"] = _wages()
	for b in buildings:
		if not b.done:
			continue
		var up := _building_upkeep(b)
		for r in up:
			c[r] = float(c.get(r, 0.0)) + float(up[r])
	return c


func _market_income() -> float:
	var total := 0.0
	var n := float(survivors.size())
	for b in buildings:
		if b.done and b.active and bool(BUILDINGS[b.type].get("market", false)):
			var p: Plot = plots[b.plot]
			var lv := _footprint_land_value(p.gx, p.gz, p.cls)
			total += 0.12 * n * (1.0 + lv / 100.0) * _lvl_mult(b) * ((1.0 + ZONE_BONUS) if b.zone_bonus else 1.0)
	return total


func _tax_income() -> float:
	if not council_unlocked or tax_level_idx <= 0:
		return 0.0
	var t := float(TAX_PER_HEAD[tax_level_idx]) * float(survivors.size() - _soldier_count())
	if policies.get("relief", false):
		t *= 0.5
	return t


# Pays people's needs, wages and building upkeep; returns {"shortage": bool, "cold": bool}.
func _pay_daily_costs() -> Dictionary:
	last_consumption = {}
	unpaid_notes.clear()
	var needs := _people_needs()
	var shortage := false
	for r in ["Food", "Water"]:
		var need := float(needs[r])
		if float(resources[r]) < need:
			shortage = true
		resources[r] = float(resources[r]) - need
		last_consumption[r] = need
	var cold := false
	var wood_need := float(needs["Wood"])
	if wood_need > 0.0:
		if float(resources["Wood"]) >= wood_need:
			resources["Wood"] = float(resources["Wood"]) - wood_need
		else:
			resources["Wood"] = 0.0
			cold = true
			unpaid_notes.append("لا حطب للتدفئة — الناجون يبردون.")
		last_consumption["Wood"] = wood_need
	var wages := _wages()
	army_unpaid = false
	if wages > 0.0:
		if float(resources["Dinar"]) >= wages:
			_add_dinar(-wages, "أجور الجنود")
		else:
			_add_dinar(-float(resources["Dinar"]), "أجور الجنود")
			army_unpaid = true
			unpaid_notes.append("أجور الجنود لم تُدفع كاملة — قوتهم نصفها والسخط يرتفع.")
		last_consumption["Dinar"] = wages
	var soft_unpaid := 0
	for b in buildings:
		if not b.done:
			continue
		var up := _building_upkeep(b)
		if up.is_empty():
			b.active = true
			continue
		var ok := true
		for r in up:
			if float(resources.get(r, 0.0)) < float(up[r]):
				ok = false
		var soft := bool(BUILDINGS[b.type].get("soft", false))
		var was := b.active
		if ok:
			for r in up:
				if r == "Dinar":
					_add_dinar(-float(up[r]), "صيانة وخدمات")
				else:
					resources[r] = float(resources[r]) - float(up[r])
				last_consumption[r] = float(last_consumption.get(r, 0.0)) + float(up[r])
			b.active = true
		elif soft:
			soft_unpaid += 1
			b.active = true
		else:
			b.active = false
			var need_parts: Array[String] = []
			for r in up:
				need_parts.append(RES_AR[r])
			unpaid_notes.append("«%s» متوقف — يحتاج %s." % [BUILDINGS[b.type]["ar"], "، ".join(need_parts)])
			if was:
				_toast("توقف «%s» لنقص %s." % [BUILDINGS[b.type]["ar"], "، ".join(need_parts)], 5.0)
		if was != b.active:
			for s in sources:
				if s.building == b:
					_apply_source_stats(s, b)
	if soft_unpaid > 0:
		unpaid_notes.append("%d بيوت/أسوار بلا صيانة (حجر/خشب) — المعنويات تنخفض." % soft_unpaid)
	return {"shortage": shortage, "cold": cold, "soft_unpaid": soft_unpaid}


# Share of people living in the camp's patched tents or in tents rather than real houses.
func _tent_share() -> float:
	var tent_cap := float(BASE_HOUSING) if camp_tents_up else 0.0
	var total := tent_cap
	for b in buildings:
		var h := float(_housing_of(b))
		total += h
		if b.type == "Tent":
			tent_cap += h
	var n := float(survivors.size())
	var in_houses := maxf(0.0, total - tent_cap)
	return clampf((n - in_houses) / maxf(1.0, n), 0.0, 1.0)


func _noise_penalty() -> float:
	var noisy := ["Quarry", "Workshop", "Small Quarry", "Pen", "Olive Press", "Barracks", "Woodcutter"]
	var pen := 0.0
	for h in buildings:
		if _housing_of(h) <= 0:
			continue
		var hp := Vector2(h.pos.x, h.pos.z)
		for b in buildings:
			if b.done and noisy.has(b.type) and Vector2(b.pos.x, b.pos.z).distance_to(hp) <= 170.0:
				pen += 0.3
	return minf(pen, 3.0)


func _note_happy(label: String, delta: float) -> void:
	if absf(delta) >= 0.05:
		happiness_notes.append([label, delta])


func _advance_day() -> void:
	day += 1
	happiness_notes.clear()
	var n := float(survivors.size())
	var morale0 := morale

	# Season progression
	season_day += 1
	if season_day >= SEASON_DAYS:
		season_day = 0
		cur_season = (cur_season + 1) % 4
		var tip := ""
		if cur_season == 2:
			tip = " اجمع الحطب: التدفئة تبدأ."
		elif cur_season == 3:
			tip = " الشتاء: كل ناجٍ يحتاج حطبًا للتدفئة."
		elif cur_season == 1:
			tip = " الصيف: استهلاك الماء أعلى."
		_toast("بدأ فصل جديد: %s.%s" % [SEASON_AR[cur_season], tip], 6.0)
		_log_event("🌿 يوم %d: بداية %s" % [day, SEASON_NAMES[cur_season]])
	if cur_season == 2 and day % 5 == 0:
		var olive_count := 0
		for b in buildings:
			if b.done and b.active and b.type == "Olive Grove":
				olive_count += b.lvl
		if olive_count > 0:
			var bonus := float(olive_count) * 6.0
			resources["Food"] = float(resources["Food"]) + bonus
			_toast("موسم الزيتون: حصاد %d وحدة طعام إضافية! 🫒" % int(bonus), 4.0)

	# City systems
	_update_land_value()
	_refresh_zone_bonus()
	var m_before := morale
	_apply_service_coverage()
	_note_happy("خدمات قريبة من البيوت", morale - m_before)
	_update_demand()

	var has_watchtower := false
	var has_plaza := false
	var has_mosque := false
	var has_clinic := false
	var has_library := false
	var has_square := false
	for b in buildings:
		if not b.done or not b.active:
			continue
		match b.type:
			"Mosque": has_mosque = true
			"Clinic": has_clinic = true
			"Plaza": has_plaza = true
			"Library": has_library = true
			"Watchtower": has_watchtower = true
			"Town Square": has_square = true
	if has_mosque and day % 7 == 0:
		morale = minf(100.0, morale + 15.0)
		_note_happy("صلاة الجمعة", 15.0)
		_toast("صلاة الجمعة في الجامع — المعنويات +15 🕌", 4.0)
	if has_plaza:
		morale = minf(100.0, morale + 1.5)
		_note_happy("الساحة العامة", 1.5)
	# Weather
	if cur_season == 1 and day % 6 == 0 and rng.randf() < 0.45:
		if has_watchtower:
			_toast("برج المراقبة رصد موجة حر مبكرًا — خُزّن الماء في الظل. 🏰", 5.0)
		else:
			resources["Water"] = maxf(0.0, float(resources["Water"]) - n * 0.6)
			_toast("جفاف! موجة حر بخّرت جزءًا من الماء. 🌵", 5.0)
		_log_event("☀ يوم %d: موجة حر وجفاف." % day)
	elif (cur_season == 0 or cur_season == 2 or cur_season == 3) and day % 8 == 0 and rng.randf() < 0.4:
		var rain := 12.0 + rng.randf() * 10.0
		resources["Water"] = float(resources["Water"]) + rain
		_start_rain(DAY_LENGTH * 0.7)
		_toast("أمطار — امتلأت الجرار (+%d ماء) 💧" % int(rain), 4.0)
		_log_event("🌧 يوم %d: أمطار (+%d ماء)." % [day, int(rain)])

	# Daily costs: food, water, heating, wages, building upkeep
	var paid := _pay_daily_costs()
	var shortage: bool = paid["shortage"]
	var cold: bool = paid["cold"]
	if cold:
		health = maxf(0.0, health - 3.0)
		morale = maxf(0.0, morale - 3.0)
		_note_happy("البرد (لا حطب)", -3.0)
	if int(paid["soft_unpaid"]) > 0:
		var sp := minf(3.0, 0.4 * float(paid["soft_unpaid"]))
		morale = maxf(0.0, morale - sp)
		_note_happy("بيوت بلا صيانة", -sp)
	if army_unpaid:
		discontent = minf(100.0, discontent + 1.5)
	var noise := _noise_penalty()
	if noise > 0.0:
		morale = maxf(0.0, morale - noise)
		_note_happy("ضجيج قرب البيوت", -noise)
	if cur_season == 3 and rng.randf() < 0.12:
		health = maxf(0.0, health - 5.0)
		_toast("برد الشتاء أضعف بعض الناجين. (صحة −5)", 4.0)
	for r in RES_NAMES:
		resources[r] = maxf(0.0, float(resources[r]))
	last_income = income_today.duplicate()
	res_trend_history.append(last_income.duplicate())
	if res_trend_history.size() > 5:
		res_trend_history.pop_front()
	for r in income_today:
		income_today[r] = 0.0

	# Dinar income
	var prod_types := ["Farm", "Olive Grove", "Pen", "Quarry", "Workshop", "Fishing Dock", "Olive Press"]
	var prod_income := 0.0
	for b in buildings:
		if b.done and b.active and prod_types.has(b.type):
			prod_income += 0.3
	if prod_income > 0.0:
		_add_dinar(prod_income, "بيع الفائض محليًا")
	var mk := _market_income()
	if mk > 0.0:
		_add_dinar(mk, "السوق")
	var tax := _tax_income()
	if tax > 0.0:
		_add_dinar(tax, "الضرائب")
		discontent = minf(100.0, discontent + float(TAX_DISCONTENT[tax_level_idx]))

	# Policies
	if policies.get("water_ration", false):
		morale = maxf(0.0, morale - 0.6)
		_note_happy("سياسة تقنين المياه", -0.6)
	if policies.get("long_shifts", false):
		health = maxf(0.0, health - 0.6)
	if policies.get("militia", false):
		discontent = minf(100.0, discontent + 0.4)
	if policies.get("relief", false):
		discontent = maxf(0.0, discontent - 0.5)

	# Natural regrowth
	var regen_mul := 2.0 if policies.get("forest_care", false) else 1.0
	for s in sources:
		if s.regen > 0.0 and not s.infinite:
			var rm := regen_mul if s.res == "Wood" else 1.0
			s.amount = minf(s.max_amount, s.amount + s.max_amount * s.regen * rm)
			_update_source_visual(s)

	var medics := 0
	for v in survivors:
		if v.skill == "Medicine" and v.unit == "":
			medics += 1
	if exploring and day >= explore_done_day:
		exploring = false
		_finish_explore()
	if shortage:
		health = maxf(0.0, health - 8.0)
		morale = maxf(0.0, morale - 8.0)
		_note_happy("نقص الطعام أو الماء", -8.0)
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
		morale = minf(100.0, morale + 0.6)
		_note_happy("مؤن كافية", 0.6)
		var base_heal := 2.0 + float(medics) + (3.0 if has_clinic else 0.0)
		health = minf(100.0, health + base_heal * service_heal_mult)
		hope = minf(100.0, hope + (0.6 if hope < 65.0 else 0.1))
		discontent = maxf(0.0, discontent - 0.5)
		_add_xp(DAY_XP * (2.0 if has_library else 1.0) * service_xp_mult)

	morale = maxf(0.0, morale - 1.0)
	_note_happy("قسوة الحياة بعد الكارثة", -1.0)
	var cap_now := float(_housing_capacity())
	if float(survivors.size()) > cap_now * 0.9:
		morale = maxf(0.0, morale - 1.2)
		_note_happy("اكتظاظ المساكن", -1.2)
	var tent_share := _tent_share()
	if tent_share > 0.0:
		morale = maxf(0.0, morale - 1.2 * tent_share)
		_note_happy("العيش في الخيام", -1.2 * tent_share)
	var swing := clampf((hope - 50.0) * 0.02, -0.6, 0.6) - discontent * 0.03
	morale = clampf(morale + swing, 0.0, 100.0)
	_note_happy("الأمل والسخط", swing)
	if tax > 0.0:
		_note_happy("الضرائب (سخط)", -float(TAX_DISCONTENT[tax_level_idx]) * 0.03)

	if survivors.is_empty():
		_trigger_game_over()
		return

	# Trade, contracts, requests, caravan
	_trade_day()
	if day >= CARAVAN_FIRST_DAY and (day - CARAVAN_FIRST_DAY) % CARAVAN_INTERVAL == 0:
		_trigger_caravan()

	# Army: raids and expeditions
	_army_day(has_watchtower)

	# Random moral event (cooldown)
	if event_cooldown > 0:
		event_cooldown -= 1
	elif rng.randf() < 0.3 and MORAL_EVENTS.size() > 0 and not _modal_open():
		pending_event = rng.randi() % MORAL_EVENTS.size()
		_show_moral_event()
		event_cooldown = 7

	# Newcomers: services and the town square attract people (CS demand)
	var cons := _people_needs()
	var fed := float(resources["Food"]) >= float(cons["Food"]) * 3.0 and float(resources["Water"]) >= float(cons["Water"]) * 3.0
	var interval := 4
	if demand_services < 25.0:
		interval = 3
	elif demand_services > 70.0:
		interval = 6
	if has_square:
		interval = maxi(2, interval - 1)
	if day % interval == 0:
		if _housing_capacity() > survivors.size() and morale > 45.0 and fed and not shortage:
			var v := _add_villager(_new_name(), SKILLS[rng.randi() % SKILLS.size()])
			_add_xp(15.0)
			_toast("وصل ناجٍ جديد: %s (%s). امنحه عملًا." % [v.vname, SKILL_AR[v.skill]], 5.0)
			_log_event("👤 يوم %d: وصل %s (%s)." % [day, v.vname, SKILL_AR[v.skill]])
		elif _housing_capacity() <= survivors.size():
			_toast("ناجون يطلبون اللجوء، لكن لا مأوى. ابنِ بيتًا.", 4.0)
	peak_pop = maxi(peak_pop, survivors.size())
	_check_camp_tents()
	budget_lines.clear()
	for k in dinar_today:
		budget_lines.append([k, float(dinar_today[k])])
	dinar_today.clear()
	_note_happy("المجموع", morale - morale0)
	_check_goals()
	_assign_tasks()
	_refresh_ui()
	if is_instance_valid(economy_sheet) and economy_sheet.visible:
		_refresh_economy_sheet()
	if is_instance_valid(army_sheet) and army_sheet.visible:
		_refresh_army_sheet()
	if is_instance_valid(villages_sheet) and villages_sheet.visible:
		_refresh_villages_sheet()


func _check_camp_tents() -> void:
	if not camp_tents_up:
		return
	var houses := _housing_capacity() - BASE_HOUSING
	if houses >= survivors.size() + 2:
		camp_tents_up = false
		if is_instance_valid(camp_tents_node):
			camp_tents_node.visible = false
		morale = minf(100.0, morale + 5.0)
		_toast("انتقلت العائلات من الخيام إلى بيوت حقيقية — طُويت خيام المخيم. المعنويات +5", 6.0)
		_log_event("🏠 يوم %d: طُويت خيام المخيم." % day)


func _new_name() -> String:
	var used := {}
	for v in survivors:
		used[v.vname] = true
	for nm in NAMES:
		if not used.has(nm):
			return nm
	return "%s %d" % [NAMES[rng.randi() % NAMES.size()], survivors.size()]








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
		_sfx("goal", -6.0)
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
	if plan_mode != "":
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
	plane.subdivide_width = 60
	plane.subdivide_depth = 120
	sea.mesh = plane
	sea.position = Vector3(-3000.0, -1.0, 0.0)
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/sea.gdshader")
	sea.material_override = sm
	sea.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	terrain_root.add_child(sea)

func _make_source_visual(res: String) -> Node3D:
	var n := Node3D.new()
	match res:
		"Wood":
			_prop(n, "nature/tree_cone", 58.0, Vector3(-14, 0, 6), 10.0, PINE_TINT)
			_prop(n, "nature/tree_fat", 42.0, Vector3(12, 0, -10), 80.0, OLIVE_TINT)
			_prop(n, "nature/tree_cone", 48.0, Vector3(18, 0, 16), 200.0, PINE_TINT)
			_prop(n, "nature/log", 6.0, Vector3(-4, 0, 24), 40.0)
		"Stone":
			_prop(n, "nature/rock_largeA", 16.0, Vector3(-10, 0, 0), 20.0)
			_prop(n, "nature/rock_tallA", 26.0, Vector3(14, 0, 6), -25.0)
			_prop(n, "nature/rock_largeC", 12.0, Vector3(4, 0, -16), 70.0)
		"Water":
			_cyl(n, 20.0, 21.0, 5.0, Vector3(0, 2.5, 0), Color("#ffffff"), true)
			_cyl(n, 15.0, 15.0, 1.5, Vector3(0, 4.9, 0), Color("#4aa3d9"))
			_prop(n, "nature/stone_smallA", 6.0, Vector3(-20, 0, -8))
			_prop(n, "nature/stone_smallB", 5.0, Vector3(18, 0, 12))
			for p in [Vector3(-18, 0, 12), Vector3(-12, 0, 18), Vector3(20, 0, -10)]:
				_prop(n, "nature/grass_large", 14.0, p, p.x * 5.0)
		"Food":
			for p in [Vector3(-14, 0, 4), Vector3(8, 0, -10), Vector3(14, 0, 12)]:
				_prop(n, "nature/plant_bushDetailed", 16.0, p, p.z * 9.0)
				_sphere(n, 2.4, p + Vector3(5, 12, 4), Color("#7a3f5a"))
				_sphere(n, 2.4, p + Vector3(-4, 10, 6), Color("#7a3f5a"))
			_prop(n, "nature/crop_melon", 7.0, Vector3(0, 0, 18))
		"Scrap":
			_prop(n, "survival/metal-panel", 22.0, Vector3(-6, 0, -8), 15.0)
			_prop(n, "survival/metal-panel-screws", 18.0, Vector3(12, 0, -4), -40.0)
			_prop(n, "survival/barrel", 13.0, Vector3(-16, 0, 10))
			_prop(n, "survival/box-open", 9.0, Vector3(8, 0, 12), 30.0)
			var sheet := _box(n, Vector3(20, 3, 14), Vector3(2, 2, 18), Color("#8a5a3a"))
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
	if not stone and color == WINDOW_COLOR:
		return _window_mat()
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
	mesh.radial_segments = 12
	mesh.rings = 1
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
	mesh.radial_segments = 14
	mesh.rings = 7
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
	mesh.radial_segments = 20
	mesh.rings = 6
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
	sun_node.light_energy = 1.0
	sun_node.light_color = Color("#fff1dc")
	sun_node.shadow_enabled = shadows_on
	sun_node.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun_node.directional_shadow_max_distance = 7000.0
	sun_node.shadow_bias = 0.06
	sun_node.shadow_normal_bias = 1.2
	sun_node.shadow_opacity = 0.75
	add_child(sun_node)
	var env_node := WorldEnvironment.new()
	world_env = Environment.new()
	world_env.background_mode = Environment.BG_COLOR
	world_env.background_color = Color("#9cc3d5")
	world_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world_env.ambient_light_color = Color("#b9c6c2")
	world_env.ambient_light_energy = 0.5
	env_node.environment = world_env
	add_child(env_node)

func _sum_jobs() -> int:
	var n := 0
	for r in jobs:
		n += int(jobs[r])
	return n

func _clamp_jobs() -> void:
	while _sum_jobs() > _worker_count():
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

const FEMALE_NAMES := ["مريم", "ليلى", "سلمى", "نور", "رنا", "أمل", "هدى", "دينا", "لين", "حنان", "ريم", "سارة", "إيناس", "لينا", "فرح"]
const CHAR_HEIGHT := 34.0


func _character_path(vname: String) -> String:
	var g := "female" if FEMALE_NAMES.has(vname.split(" ")[0]) else "male"
	var letters := ["a", "b", "c", "d", "e", "f"]
	var h := absi(vname.hash()) % letters.size()
	return "characters/character-%s-%s" % [g, letters[h]]


func _make_villager_node(v: Villager, skill: String) -> Node3D:
	var root := Node3D.new()
	var body := _asset(_character_path(v.vname), CHAR_HEIGHT)
	body.name = "Body"
	root.add_child(body)
	v.anim = _find_anim(body)
	var disc := _cyl(root, 7.5, 7.5, 0.8, Vector3(0, 0.6, 0), SKILL_COLORS[skill])
	disc.name = "Disc"
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	v.carry_node = _box(root, Vector3(10, 10, 10), Vector3(0, CHAR_HEIGHT + 9.0, 0), Color("#ffffff"))
	v.carry_node.visible = false
	_play(v, "idle")
	return root


func _find_anim(n: Node) -> AnimationPlayer:
	var aps := n.find_children("*", "AnimationPlayer", true, false)
	return aps[0] if not aps.is_empty() else null


func _play(v: Villager, anim_name: String) -> void:
	if v.anim == null or v.cur_anim == anim_name:
		return
	if not v.anim.has_animation(anim_name):
		return
	v.cur_anim = anim_name
	var a := v.anim.get_animation(anim_name)
	if a != null:
		a.loop_mode = Animation.LOOP_LINEAR
	v.anim.play(anim_name, 0.2)


func _refresh_villager_look(v: Villager) -> void:
	var disc: MeshInstance3D = v.node.get_node_or_null("Disc")
	var old := v.node.get_node_or_null("Gear")
	if old != null:
		old.free()
	if v.unit == "":
		if disc != null:
			disc.material_override = _mat(SKILL_COLORS[v.skill])
		return
	if disc != null:
		disc.material_override = _mat(UNITS[v.unit]["color"])
	var gear := Node3D.new()
	gear.name = "Gear"
	v.node.add_child(gear)
	_cyl(gear, 0.8, 0.8, 46.0, Vector3(9, 23, 2), Color("#6b4f33"))
	_cyl(gear, 0.0, 2.2, 6.0, Vector3(9, 49, 2), Color("#b0b6bb"))
	var helm := _sphere(gear, 7.0, Vector3(0, CHAR_HEIGHT - 4.0, 0), Color("#6f747a"))
	helm.scale = Vector3(1.0, 0.55, 1.0)
	if v.unit == "archer":
		var bow := _cyl(gear, 1.0, 1.0, 26.0, Vector3(-9, 18, 0), Color("#5a3e22"))
		bow.rotation_degrees.z = 12.0
	if v.unit == "rider":
		var horse := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 8.0
		cap.height = 34.0
		horse.mesh = cap
		horse.rotation_degrees.x = 90.0
		horse.position = Vector3(0, 9, 0)
		horse.material_override = _mat(Color("#6b4a32"))
		gear.add_child(horse)


func _raider_figure() -> Node3D:
	var r := _asset("characters/character-male-%s" % ["a", "c", "e"][rng.randi() % 3], CHAR_HEIGHT)
	for c in r.find_children("*", "MeshInstance3D", true, false):
		(c as MeshInstance3D).material_override = _mat(Color("#2b2522"))
	var ap := _find_anim(r)
	if ap != null and ap.has_animation("walk"):
		ap.get_animation("walk").loop_mode = Animation.LOOP_LINEAR
		ap.play("walk")
	var wrap := Node3D.new()
	wrap.add_child(r)
	_cyl(wrap, 0.8, 0.8, 30.0, Vector3(8, 18, 0), Color("#4a3b2e"))
	var scarf := _sphere(wrap, 6.6, Vector3(0, CHAR_HEIGHT - 6.0, 0), Color("#7a1f1f"))
	scarf.scale = Vector3(1.0, 0.7, 1.0)
	return wrap


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
		var step := minf(dist, WALK_SPEED * dt * _speed_at(flat))
		flat += (g - flat).normalized() * step
		v.phase += dt * 12.0
		hop = 0.0 if v.anim != null else absf(sin(v.phase)) * 5.0
		v.node.rotation.y = atan2(g.x - flat.x, g.z - flat.z)
		_play(v, "walk")
		_note_step(flat, dt)
		arrived = flat.distance_to(g) <= 3.0
	elif bob:
		v.phase += dt * 14.0
		if v.anim != null:
			_play(v, "interact-right" if v.task == "gather" else "interact-left")
		else:
			hop = absf(sin(v.phase)) * 6.0
	else:
		_play(v, "idle")
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
			"guard":
				if not v.away and _move(v, dt):
					v.wait -= dt
					if v.wait <= 0.0:
						v.goal = _patrol_point()
						v.wait = rng.randf_range(3.0, 7.0)

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
			v.timer -= dt * (1.25 if policies.get("long_shifts", false) else 1.0)
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
	if s.res == "Wood" and s.building == null and policies.get("forest_care", false):
		take *= 0.85
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
	var capacity := BASE_HOUSING if camp_tents_up else 0
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
		_update_raid(dt)
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
		var daylight := smoothstep(0.0, 0.35, sin(t * PI))
		if rain_time > 0.0:
			daylight *= 0.75
		var day_energy := lerpf(0.22, 1.05, daylight)
		if is_instance_valid(sun_node):
			sun_node.light_energy = day_energy
			sun_node.light_color = Color("#9fb0d8").lerp(Color("#fff1dc"), daylight)
		_update_fx(delta * game_speed, t)
		var season_sky: Color = SEASON_SKY[cur_season]
		var amb: Color = Color("#2c3550").lerp(season_sky.darkened(0.12), daylight)
		world_env.background_color = Color("#1d2438").lerp(Color("#9cc3d5"), daylight)
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
		caravan_node.position.y = _height_at_world(cx, caravan_node.position.z)
		if caravan_timer > 40.0 or cx < camp_pos.x - 900.0:
			caravan_node.queue_free()
			caravan_node = null
			caravan_timer = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if menu_open or game_over:
		return
	var touch_dev := DisplayServer.is_touchscreen_available()
	if event is InputEventScreenTouch:
		if event.pressed:
			touches[event.index] = event.position
			if plan_mode != "" and touches.size() == 1:
				_paint_at(event.position)
		else:
			touches.erase(event.index)
		if touches.size() >= 2:
			pinch_last = _pinch_distance()
			drag_moved = true
		return
	if event is InputEventScreenDrag:
		touches[event.index] = event.position
		if touches.size() >= 2:
			var d := _pinch_distance()
			if pinch_last > 0.0 and d > 0.0:
				_zoom(pinch_last / d)
			pinch_last = d
			_pan_camera(event.relative * 0.5)
			return
		if plan_mode != "":
			_paint_at(event.position)
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
				if plan_mode != "" and not touch_dev:
					_paint_at(event.position)
			else:
				if drag_active and not drag_moved and touches.size() < 2 and plan_mode == "":
					_on_tap(event.position)
				drag_active = false
	elif event is InputEventMouseMotion:
		if right_drag:
			_pan_camera(event.relative)
		elif drag_active and touches.size() < 2:
			if plan_mode != "":
				if not touch_dev:
					_paint_at(event.position)
				return
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
	var use := float(_compute_consumption().get(res, 0.0))
	var recent: Dictionary = res_trend_history[res_trend_history.size() - 1]
	var prev: Dictionary = res_trend_history[res_trend_history.size() - 2]
	var avg := (float(recent.get(res, 0.0)) + float(prev.get(res, 0.0))) * 0.5 - use
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


# ---------------------------------------------------------------- trade: relations, prices, contracts

var caravan_deals: Array = []     # {"kind": "buy"/"sell", "res", "qty", "dinar", "left"}
var caravan_until := -1


func _vstate(idx: int) -> Dictionary:
	if not village_state.has(idx):
		village_state[idx] = {"rel": 30.0, "used": {}}
	return village_state[idx]


func _trade_bonus() -> float:
	var t := 0.0
	for b in buildings:
		if b.done and b.active and BUILDINGS[b.type].has("trade_bonus"):
			t += float(BUILDINGS[b.type]["trade_bonus"]) * _lvl_mult(b)
	return minf(t, 0.35)


func _stable_on() -> bool:
	for b in buildings:
		if b.done and b.active and bool(BUILDINGS[b.type].get("stable", false)):
			return true
	return false


func _rel_ar(rel: float) -> String:
	if rel >= 75.0:
		return "حليف"
	if rel >= 50.0:
		return "صديق"
	if rel >= 30.0:
		return "محايد"
	return "متحفّظ"


func _offer_qty(item: Dictionary) -> int:
	return int(item["qty"]) * (2 if _stable_on() else 1)


func _buy_price(idx: int, item: Dictionary) -> int:
	var rel := float(_vstate(idx)["rel"])
	var p := float(item["dinar"]) * (1.3 - rel / 250.0) * (1.0 - _trade_bonus())
	return maxi(1, int(round(p * (2.0 if _stable_on() else 1.0))))


func _sell_price(idx: int, item: Dictionary) -> int:
	var rel := float(_vstate(idx)["rel"])
	var p := float(item["dinar"]) * (0.7 + rel / 250.0) * (1.0 + _trade_bonus())
	return maxi(1, int(round(p * (2.0 if _stable_on() else 1.0))))


func _change_rel(idx: int, delta: float) -> void:
	var st := _vstate(idx)
	st["rel"] = clampf(float(st["rel"]) + delta, 0.0, 100.0)


func _do_trade(idx: int, kind: String, i: int) -> void:
	var v: Dictionary = VILLAGES[idx]
	var item: Dictionary = (v["sells"] if kind == "buy" else v["buys"])[i]
	var st := _vstate(idx)
	var key := "%s%d" % [kind, i]
	var used: Dictionary = st["used"]
	if int(used.get(key, 0)) >= TRADE_STOCK:
		_toast("نفدت الكمية اليوم — عُد غدًا.")
		return
	var res := str(item["res"])
	var qty := _offer_qty(item)
	if kind == "buy":
		var price := _buy_price(idx, item)
		if float(resources["Dinar"]) < float(price):
			_toast("لا تملك %d دينار." % price)
			return
		_add_dinar(-float(price), "مشتريات من القرى")
		resources[res] = float(resources[res]) + float(qty)
		_change_rel(idx, 1.5)
		_log_event("💰 يوم %d: اشتريت %d %s من %s بـ%d." % [day, qty, RES_AR[res], v["ar"], price])
	else:
		var gain := _sell_price(idx, item)
		if float(resources[res]) < float(qty):
			_toast("لا تملك %d %s." % [qty, RES_AR[res]])
			return
		resources[res] = float(resources[res]) - float(qty)
		_add_dinar(float(gain), "مبيعات للقرى")
		_change_rel(idx, 2.0)
		trades_done += 1
		_log_event("💰 يوم %d: بعت %d %s لـ%s بـ%d دينار." % [day, qty, RES_AR[res], v["ar"], gain])
	used[key] = int(used.get(key, 0)) + 1
	_sfx("coins")
	_check_goals()
	_refresh_ui()
	_open_trade(idx)


func _gift(idx: int) -> void:
	var v: Dictionary = VILLAGES[idx]
	var want: Dictionary = v["buys"][0]
	var res := str(want["res"])
	var amt := 10.0
	if float(resources[res]) < amt:
		_toast("الهدية تحتاج 10 %s." % RES_AR[res])
		return
	resources[res] = float(resources[res]) - amt
	_change_rel(idx, 8.0)
	_toast("قبلت %s هديتك — العلاقة تتحسن." % v["ar"], 3.5)
	_refresh_ui()
	_open_trade(idx)


func _max_contracts() -> int:
	var n := 0
	for b in buildings:
		if b.done and (b.type == "Market" or b.type == "Stable"):
			n += 1
	return n


func _sign_contract(idx: int, kind: String, i: int) -> void:
	if _max_contracts() == 0:
		_toast("العقود تحتاج سوقًا أو إسطبلًا.")
		return
	if contracts.size() >= _max_contracts():
		_toast("بلغت حد العقود (%d) — ابنِ سوقًا أو إسطبلًا إضافيًا أو ألغِ عقدًا." % _max_contracts())
		return
	if float(_vstate(idx)["rel"]) < 45.0:
		_toast("العلاقة يجب أن تبلغ 45 على الأقل لتوقيع عقد.")
		return
	var v: Dictionary = VILLAGES[idx]
	var item: Dictionary = (v["buys"] if kind == "export" else v["sells"])[i]
	var qty := _offer_qty(item) * 2
	var dinar := int(round(float(_sell_price(idx, item)) * 2.0 * 1.15)) if kind == "export" else int(round(float(_buy_price(idx, item)) * 2.0 * 0.9))
	contracts.append({"v": idx, "kind": kind, "res": str(item["res"]), "qty": qty, "dinar": dinar, "next": day + 1})
	contracts_signed += 1
	_toast("وُقّع عقد %s مع %s: %d %s كل %d أيام مقابل %d دينار." % ["تصدير" if kind == "export" else "استيراد", v["ar"], qty, RES_AR[item["res"]], CONTRACT_EVERY, dinar], 6.0)
	_log_event("📜 يوم %d: عقد مع %s." % [day, v["ar"]])
	_check_goals()
	_open_trade(idx)


func _cancel_contract(ci: int) -> void:
	if ci < 0 or ci >= contracts.size():
		return
	var c: Dictionary = contracts[ci]
	_change_rel(int(c["v"]), -4.0)
	contracts.remove_at(ci)
	_toast("أُلغي العقد (العلاقة −4).")
	_open_trade(int(c["v"]))


func _trade_day() -> void:
	for idx in village_state:
		var st: Dictionary = village_state[idx]
		st["used"] = {}
		if float(st["rel"]) > 25.0:
			st["rel"] = float(st["rel"]) - 0.15
	for c in contracts:
		if day < int(c["next"]):
			continue
		c["next"] = day + CONTRACT_EVERY
		var vname := str(VILLAGES[int(c["v"])]["ar"])
		var res := str(c["res"])
		if c["kind"] == "export":
			if float(resources[res]) >= float(c["qty"]):
				resources[res] = float(resources[res]) - float(c["qty"])
				_add_dinar(float(c["dinar"]), "عقود تجارية")
				_change_rel(int(c["v"]), 1.0)
				_log_event("🐫 يوم %d: سُلّم عقد %s (+%d دينار)." % [day, vname, int(c["dinar"])])
			else:
				_change_rel(int(c["v"]), -6.0)
				_toast("فشل تسليم عقد %s: ينقص %s (العلاقة −6)." % [vname, RES_AR[res]], 5.0)
		else:
			if float(resources["Dinar"]) >= float(c["dinar"]):
				_add_dinar(-float(c["dinar"]), "عقود تجارية")
				resources[res] = float(resources[res]) + float(c["qty"])
				_change_rel(int(c["v"]), 1.0)
				_log_event("🐫 يوم %d: وصلت شحنة %s (%d %s)." % [day, vname, int(c["qty"]), RES_AR[res]])
			else:
				_change_rel(int(c["v"]), -6.0)
				_toast("لم تدفع ثمن شحنة %s (العلاقة −6)." % vname, 5.0)
		_spawn_caravan_visual(true)
	for i in range(requests.size() - 1, -1, -1):
		var rq: Dictionary = requests[i]
		if day > int(rq["until"]):
			_change_rel(int(rq["v"]), -6.0)
			_toast("انتهت مهلة طلب %s (العلاقة −6)." % VILLAGES[int(rq["v"])]["ar"], 4.0)
			requests.remove_at(i)
	if requests.is_empty() and not discovered_villages.is_empty() and day % 7 == 3:
		var vi: int = discovered_villages[rng.randi() % discovered_villages.size()]
		var want: Array = VILLAGES[vi]["buys"]
		var item: Dictionary = want[rng.randi() % want.size()]
		var qty := 12 + rng.randi() % 16
		requests.append({"v": vi, "res": str(item["res"]), "qty": qty, "reward": int(qty * 0.9) + 4, "until": day + 5})
		_toast("طلب من %s: يحتاجون %d %s خلال 5 أيام. افتح «القرى»." % [VILLAGES[vi]["ar"], qty, RES_AR[item["res"]]], 6.0)
	if caravan_until >= 0 and day > caravan_until:
		caravan_until = -1
		caravan_deals.clear()


func _fulfill_request(i: int) -> void:
	if i < 0 or i >= requests.size():
		return
	var rq: Dictionary = requests[i]
	var res := str(rq["res"])
	if float(resources[res]) < float(rq["qty"]):
		_toast("تحتاج %d %s." % [int(rq["qty"]), RES_AR[res]])
		return
	resources[res] = float(resources[res]) - float(rq["qty"])
	_add_dinar(float(rq["reward"]), "مكافآت الطلبات")
	_change_rel(int(rq["v"]), 12.0)
	_add_xp(15.0)
	_toast("سلّمت الطلب لـ%s: +%d دينار والعلاقة +12." % [VILLAGES[int(rq["v"])]["ar"], int(rq["reward"])], 4.0)
	requests.remove_at(i)
	_refresh_ui()
	_refresh_villages_sheet()


func _trigger_caravan() -> void:
	_toast("وصلت قافلة التجار من الشرق! افتح «القرى» للتجارة معها (3 أيام).", 7.0)
	_log_event("🐪 يوم %d: وصلت القافلة." % day)
	_spawn_caravan_visual(false)
	caravan_day = day
	caravan_until = day + 3
	caravan_deals.clear()
	var pool := [
		{"kind": "sell", "res": "Oil", "qty": 5, "dinar": 9},
		{"kind": "sell", "res": "Food", "qty": 15, "dinar": 6},
		{"kind": "sell", "res": "Stone", "qty": 12, "dinar": 6},
		{"kind": "sell", "res": "Wood", "qty": 12, "dinar": 5},
		{"kind": "buy", "res": "Scrap", "qty": 10, "dinar": 7},
		{"kind": "buy", "res": "Oil", "qty": 6, "dinar": 8},
		{"kind": "buy", "res": "Food", "qty": 20, "dinar": 9},
		{"kind": "buy", "res": "Stone", "qty": 15, "dinar": 8},
	]
	pool.shuffle()
	for k in range(4):
		var d: Dictionary = pool[k].duplicate()
		d["left"] = 2
		caravan_deals.append(d)


func _caravan_trade(i: int) -> void:
	var d: Dictionary = caravan_deals[i]
	if int(d["left"]) <= 0:
		return
	var res := str(d["res"])
	if d["kind"] == "sell":
		if float(resources[res]) < float(d["qty"]):
			_toast("لا تملك %d %s." % [int(d["qty"]), RES_AR[res]])
			return
		resources[res] = float(resources[res]) - float(d["qty"])
		_add_dinar(float(d["dinar"]), "القافلة")
		trades_done += 1
	else:
		if float(resources["Dinar"]) < float(d["dinar"]):
			_toast("لا تملك %d دينار." % int(d["dinar"]))
			return
		_add_dinar(-float(d["dinar"]), "القافلة")
		resources[res] = float(resources[res]) + float(d["qty"])
	d["left"] = int(d["left"]) - 1
	_sfx("coins")
	_check_goals()
	_refresh_ui()
	_refresh_villages_sheet()


# ── villages sheet & trade dialog ──

func _build_villages_sheet() -> void:
	villages_sheet = _sheet(Control.PRESET_CENTER_BOTTOM)
	villages_sheet.grow_horizontal = Control.GROW_DIRECTION_BOTH
	villages_sheet.grow_vertical = Control.GROW_DIRECTION_BEGIN
	villages_sheet.offset_bottom = -116
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(820, 0)
	box.add_theme_constant_override("separation", 10)
	villages_sheet.add_child(box)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	box.add_child(header)
	header.add_child(_label_b("القرى والتجارة", 28, C_GOLD))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(sp)
	explore_btn = _button("اكتشف قرية", _on_explore_pressed, Vector2(260, 52), 18, C_BTN)
	header.add_child(explore_btn)
	var scroll := _vscroll(380.0)
	box.add_child(scroll)
	villages_content = VBoxContainer.new()
	villages_content.add_theme_constant_override("separation", 10)
	villages_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(villages_content)


func _refresh_villages_sheet() -> void:
	if not is_instance_valid(villages_content):
		return
	for c in villages_content.get_children():
		c.queue_free()
	var cost := EXPLORE_BASE_COST + discovered_villages.size() * EXPLORE_COST_STEP
	if is_instance_valid(explore_btn):
		if exploring:
			explore_btn.text = "يستكشف... يعود يوم %d" % explore_done_day
			explore_btn.disabled = true
		elif discovered_villages.size() >= VILLAGES.size():
			explore_btn.text = "كل القرى مستكشفة"
			explore_btn.disabled = true
		else:
			explore_btn.text = "اكتشف قرية (%d دينار)" % cost
			explore_btn.disabled = false
	var info := _label("السوق والخان يحسّنان الأسعار %d%%، والإسطبل يضاعف الكميات. العقود: %d/%d." % [int(_trade_bonus() * 100.0), contracts.size(), _max_contracts()], 16, C_MUTED)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	villages_content.add_child(info)
	if caravan_until >= day and not caravan_deals.is_empty():
		var card := _card_panel(Color(0.22, 0.16, 0.06, 0.9))
		villages_content.add_child(card)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 6)
		card.add_child(cv)
		cv.add_child(_label_b("🐪 قافلة التجار — ترحل يوم %d" % (caravan_until + 1), 21, C_GOLD))
		var row := HFlowContainer.new()
		row.add_theme_constant_override("h_separation", 10)
		row.add_theme_constant_override("v_separation", 8)
		cv.add_child(row)
		for i in range(caravan_deals.size()):
			var d: Dictionary = caravan_deals[i]
			var txt := ("بِع %d %s ← %d دينار" if d["kind"] == "sell" else "اشترِ %d %s ← %d دينار") % [int(d["qty"]), RES_AR[d["res"]], int(d["dinar"])]
			var b := _button("%s (%d)" % [txt, int(d["left"])], _caravan_trade.bind(i), Vector2(250, 50), 16, C_GREEN if d["kind"] == "buy" else Color("#9a7a1a"))
			b.disabled = int(d["left"]) <= 0
			row.add_child(b)
	for ri in range(requests.size()):
		var rq: Dictionary = requests[ri]
		var rrow := HBoxContainer.new()
		rrow.add_theme_constant_override("separation", 10)
		villages_content.add_child(rrow)
		var rl := _label("📦 %s تطلب %d %s حتى يوم %d — مكافأة %d دينار" % [VILLAGES[int(rq["v"])]["ar"], int(rq["qty"]), RES_AR[rq["res"]], int(rq["until"]), int(rq["reward"])], 17, Color("#ffd98a"))
		rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rrow.add_child(rl)
		rrow.add_child(_button("سلّم", _fulfill_request.bind(ri), Vector2(110, 48), 18, C_GREEN))
	if discovered_villages.is_empty():
		villages_content.add_child(_label("أرسل مجموعة استكشاف لاكتشاف قرى الناجين المجاورة.", 19, C_MUTED))
		return
	for idx in discovered_villages:
		var v: Dictionary = VILLAGES[idx]
		var st := _vstate(idx)
		var card2 := _card_panel(Color(1, 1, 1, 0.05))
		villages_content.add_child(card2)
		var row2 := HBoxContainer.new()
		row2.add_theme_constant_override("separation", 12)
		card2.add_child(row2)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row2.add_child(col)
		col.add_child(_label_b("🏘 %s" % v["ar"], 21, C_CREAM))
		var rel_row := HBoxContainer.new()
		rel_row.add_theme_constant_override("separation", 8)
		col.add_child(rel_row)
		rel_row.add_child(_label("العلاقة: %s" % _rel_ar(float(st["rel"])), 16, C_MUTED))
		var rb := _bar(Color("#7fc04f"), 160.0, 9.0)
		rb.value = float(st["rel"])
		rb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		rel_row.add_child(rb)
		var sells_txt: Array[String] = []
		for it in v["sells"]:
			sells_txt.append(RES_AR[it["res"]])
		var buys_txt: Array[String] = []
		for it2 in v["buys"]:
			buys_txt.append(RES_AR[it2["res"]])
		col.add_child(_label("تبيع: %s  —  تشتري: %s" % ["، ".join(sells_txt), "، ".join(buys_txt)], 16, C_CREAM))
		row2.add_child(_button("تجارة", _open_trade.bind(idx), Vector2(130, 56), 20, C_GREEN))


func _open_trade(idx: int) -> void:
	_close_all_modals()
	var v: Dictionary = VILLAGES[idx]
	var st := _vstate(idx)
	var body := _open_modal("تجارة مع %s" % v["ar"], 720.0)
	body.add_child(_label("دينارك: %d  •  العلاقة: %d (%s)  •  كل عرض متاح %d مرات يوميًا" % [int(resources["Dinar"]), int(st["rel"]), _rel_ar(float(st["rel"])), TRADE_STOCK], 17, C_MUTED))
	var used: Dictionary = st["used"]
	body.add_child(_label_b("شراء من القرية", 20, C_GOLD))
	for i in range(v["sells"].size()):
		var it: Dictionary = v["sells"][i]
		var left := TRADE_STOCK - int(used.get("buy%d" % i, 0))
		var row := _trade_row(it, "← %d دينار" % _buy_price(idx, it), "شراء", _do_trade.bind(idx, "buy", i), C_GREEN, left)
		body.add_child(row)
	body.add_child(_label_b("بيع للقرية", 20, C_GOLD))
	for i2 in range(v["buys"].size()):
		var it2: Dictionary = v["buys"][i2]
		var left2 := TRADE_STOCK - int(used.get("sell%d" % i2, 0))
		body.add_child(_trade_row(it2, "→ %d دينار" % _sell_price(idx, it2), "بيع", _do_trade.bind(idx, "sell", i2), Color("#9a7a1a"), left2))
	var g_row := HBoxContainer.new()
	g_row.add_theme_constant_override("separation", 10)
	body.add_child(g_row)
	var want := str(v["buys"][0]["res"])
	g_row.add_child(_button("هدية (10 %s، العلاقة +8)" % RES_AR[want], _gift.bind(idx), Vector2(300, 52), 17, Color("#6a4a8a")))
	body.add_child(HSeparator.new())
	body.add_child(_label_b("العقود التجارية (تسليم تلقائي كل %d أيام)" % CONTRACT_EVERY, 20, C_GOLD))
	if _max_contracts() == 0:
		body.add_child(_label("تحتاج سوقًا أو إسطبلًا لتوقيع العقود.", 17, C_MUTED))
	elif float(st["rel"]) < 45.0:
		body.add_child(_label("ارفع العلاقة إلى 45 بالتجارة والهدايا لتوقيع العقود.", 17, C_MUTED))
	else:
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 8)
		flow.add_theme_constant_override("v_separation", 8)
		body.add_child(flow)
		for i3 in range(v["buys"].size()):
			var it3: Dictionary = v["buys"][i3]
			flow.add_child(_button("تصدير %s" % RES_AR[it3["res"]], _sign_contract.bind(idx, "export", i3), Vector2(180, 48), 16, Color("#2f6a8a")))
		for i4 in range(v["sells"].size()):
			var it4: Dictionary = v["sells"][i4]
			flow.add_child(_button("استيراد %s" % RES_AR[it4["res"]], _sign_contract.bind(idx, "import", i4), Vector2(180, 48), 16, Color("#2f6a8a")))
	for ci in range(contracts.size()):
		var c: Dictionary = contracts[ci]
		if int(c["v"]) != idx:
			continue
		var crow := HBoxContainer.new()
		crow.add_theme_constant_override("separation", 10)
		body.add_child(crow)
		var cl := _label("%s %d %s ↔ %d دينار — التسليم التالي يوم %d" % ["تصدير" if c["kind"] == "export" else "استيراد", int(c["qty"]), RES_AR[c["res"]], int(c["dinar"]), int(c["next"])], 17, C_CREAM)
		cl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		crow.add_child(cl)
		crow.add_child(_button("إلغاء", _cancel_contract.bind(ci), Vector2(100, 46), 16, C_RED))


func _trade_row(item: Dictionary, price_txt: String, verb: String, cb: Callable, col: Color, left: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var res := str(item["res"])
	row.add_child(_dot(RES_COLORS[res], 14.0))
	row.add_child(_label_b("%d %s" % [_offer_qty(item), RES_AR[res]], 21))
	row.add_child(_label("(لديك %d)" % int(resources[res]), 15, C_MUTED))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp)
	row.add_child(_label_b(price_txt, 20, C_GOLD))
	var b := _button("%s (%d)" % [verb, maxi(0, left)], cb, Vector2(130, 50), 18, col)
	b.disabled = left <= 0
	row.add_child(b)
	return row


func _on_explore_pressed() -> void:
	if exploring:
		_toast("مجموعة الاستكشاف في الطريق. تعود يوم %d." % explore_done_day)
		return
	if discovered_villages.size() >= VILLAGES.size():
		_toast("اكتُشفت كل القرى المحيطة.")
		return
	var cost := EXPLORE_BASE_COST + discovered_villages.size() * EXPLORE_COST_STEP
	if float(resources.get("Dinar", 0.0)) < float(cost):
		_toast("ينقصك %d دينار لإرسال مجموعة الاستكشاف." % cost)
		return
	_add_dinar(-float(cost), "الاستكشاف")
	exploring = true
	explore_done_day = day + EXPLORE_DAYS
	_toast("انطلقت مجموعة الاستكشاف! تعود يوم %d." % explore_done_day, 5.0)
	_log_event("🔍 يوم %d: بدأ الاستكشاف (%d دينار)." % [day, cost])
	_refresh_villages_sheet()
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
	_vstate(idx)
	var v: Dictionary = VILLAGES[idx]
	_toast("اكتُشفت قرية: %s! افتح «القرى» للبيع والشراء." % str(v["ar"]), 7.0)
	_log_event("🏘 يوم %d: اكتُشفت قرية %s." % [day, str(v["ar"])])
	_add_xp(20.0)
	_check_goals()
	_refresh_villages_sheet()
	_refresh_ui()


func _spawn_caravan_visual(small: bool = false) -> void:
	if is_instance_valid(caravan_node):
		caravan_node.queue_free()
	caravan_node = Node3D.new()
	var start_x := camp_pos.x + 800.0
	caravan_node.position = Vector3(start_x, _height_at_world(start_x, camp_pos.z), camp_pos.z)
	add_child(caravan_node)
	caravan_timer = 0.0
	for i in range(1 if small else 3):
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


# ---------------------------------------------------------------- army: recruitment, raids, expeditions

func _soldier_count(unit: String = "") -> int:
	var n := 0
	for v in survivors:
		if v.unit != "" and (unit == "" or v.unit == unit):
			n += 1
	return n


func _worker_count() -> int:
	return survivors.size() - _soldier_count()


func _barracks_capacity() -> int:
	var cap := 0
	for b in buildings:
		if b.done and bool(BUILDINGS[b.type].get("barracks", false)):
			cap += 6 * b.lvl
	return cap


func _army_power(include_away: bool = false) -> float:
	var p := 0.0
	for v in survivors:
		if v.unit != "" and (include_away or not v.away):
			p += float(UNITS[v.unit]["power"])
	if army_unpaid:
		p *= 0.5
	return p * (0.7 + morale / 333.0)


func _structure_defense() -> float:
	var d := 0.0
	for b in buildings:
		if b.done and b.active and BUILDINGS[b.type].has("defense"):
			d += float(BUILDINGS[b.type]["defense"]) * _lvl_mult(b)
	return d


func _militia_power() -> float:
	var m := 0.0
	for v in survivors:
		if v.unit == "":
			m += MILITIA_POWER
	return m * (2.0 if policies.get("militia", false) else 1.0)


func _defense_total() -> float:
	return _army_power() + _militia_power() + _structure_defense()


func _raid_strength() -> float:
	var base := 10.0 + float(maxi(0, day - RAID_FIRST_DAY)) * 1.45 + float(survivors.size()) * 2.0
	base *= maxf(0.4, 1.0 - 0.12 * float(lairs_cleared))
	if raids_won + raids_lost == 0:
		base *= 0.75
	return base * rng.randf_range(0.85, 1.15)


func _recruit(unit: String) -> void:
	var u: Dictionary = UNITS[unit]
	if _barracks_capacity() == 0:
		_toast("ابنِ ثكنة أولًا (تبويب «دفاع»).")
		return
	if level < int(u["lv"]):
		_toast("«%s» يُفتح في المستوى %d." % [u["ar"], int(u["lv"])])
		return
	if u.has("needs") and not _has_done(str(u["needs"])):
		_toast("«%s» يحتاج %s." % [u["ar"], BUILDINGS[u["needs"]]["ar"]])
		return
	if _soldier_count() >= _barracks_capacity():
		_toast("الثكنة ممتلئة (%d) — رقّها أو ابنِ ثكنة أخرى." % _barracks_capacity())
		return
	var missing := _missing_resource(u["cost"])
	if missing != "":
		_toast("ينقصك %s لتجنيد %s." % [RES_AR[missing], u["ar"]])
		return
	var pick: Villager = null
	for pass_i in range(3):
		for v in survivors:
			if v.unit != "" or v.away:
				continue
			if pass_i == 0 and v.task == "idle":
				pick = v
			elif pass_i == 1 and v.task == "gather" and v.carry_amt <= 0.0:
				pick = v
			elif pass_i == 2 and v.task != "build":
				pick = v
			if pick != null:
				break
		if pick != null:
			break
	if pick == null:
		_toast("لا يوجد ناجٍ متاح للتجنيد.")
		return
	for r in u["cost"]:
		if r == "Dinar":
			_add_dinar(-float(u["cost"][r]), "تجنيد")
		else:
			resources[r] = float(resources[r]) - float(u["cost"][r])
	_set_idle(pick)
	pick.unit = unit
	pick.task = "guard"
	pick.goal = _patrol_point()
	_refresh_villager_look(pick)
	_clamp_jobs()
	_assign_tasks()
	_toast("انضم %s إلى الجيش كـ%s." % [pick.vname, u["ar"]], 3.5)
	_sfx("recruit")
	_check_goals()
	_refresh_ui()
	_refresh_army_sheet()


func _dismiss(unit: String) -> void:
	for v in survivors:
		if v.unit == unit and not v.away:
			v.unit = ""
			_refresh_villager_look(v)
			_set_idle(v)
			_toast("عاد %s إلى العمل المدني." % v.vname, 3.0)
			_assign_tasks()
			_refresh_ui()
			_refresh_army_sheet()
			return
	_toast("لا يوجد %s متاح للتسريح." % UNITS[unit]["ar"])


func _patrol_point() -> Vector3:
	var r := _territory_radius() * rng.randf_range(0.45, 0.7)
	return _random_point_around(camp_pos, r * 0.9, r)





func _army_day(has_watchtower: bool) -> void:
	if expedition_day >= 0 and day >= expedition_day:
		_resolve_expedition()
	if day < RAID_FIRST_DAY - 1 or is_instance_valid(raid_node):
		return
	if day == raid_next_day - 1 and has_watchtower and not raid_warned:
		raid_warned = true
		raid_strength = _raid_strength()
		_show_raid_warning()
	elif day >= raid_next_day:
		if not raid_warned:
			raid_strength = _raid_strength()
		raid_warned = false
		raid_next_day = day + RAID_MIN_GAP + rng.randi() % (RAID_MAX_GAP - RAID_MIN_GAP + 1)
		_start_raid()


func _show_raid_warning() -> void:
	var tribute := int(ceil(raid_strength * 0.6))
	var body := _open_modal("🏰 إنذار من برج المراقبة")
	var l := _label("رصد الحرّاس عصابة تقترب من الشرق وستهاجم غدًا.\nقوة المهاجمين المقدّرة: %d  —  دفاعك الحالي: %d" % [int(raid_strength), int(_defense_total())], 20, C_CREAM)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(l)
	var tip := _label("جنّد جنودًا الآن، أو ادفع إتاوة لتجنّب القتال.", 17, C_MUTED)
	body.add_child(tip)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	body.add_child(row)
	var prep := _button("نستعد للقتال", _close_all_modals, Vector2(220, 60), 20, C_GREEN)
	prep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(prep)
	var pay := _button("ادفع إتاوة (%d دينار)" % tribute, _pay_tribute.bind(tribute), Vector2(220, 60), 20, Color("#8a6020"))
	pay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(pay)


func _pay_tribute(amount: int) -> void:
	if float(resources["Dinar"]) < float(amount):
		_toast("لا تملك %d دينار." % amount)
		return
	_add_dinar(-float(amount), "إتاوة")
	raid_warned = false
	raid_next_day = day + RAID_MIN_GAP + rng.randi() % (RAID_MAX_GAP - RAID_MIN_GAP + 1)
	discontent = minf(100.0, discontent + 3.0)
	_log_event("💸 يوم %d: دفعت إتاوة %d دينار لتجنب غارة." % [day, amount])
	_toast("أخذوا المال ورحلوا... هذه المرة.", 4.0)
	_close_all_modals()


func _start_raid() -> void:
	if is_instance_valid(raid_node):
		raid_node.queue_free()
	raid_node = Node3D.new()
	var z0 := camp_pos.z + rng.randf_range(-250.0, 250.0)
	var x0 := camp_pos.x + 950.0
	raid_node.position = Vector3(x0, _height_at_world(x0, z0), z0)
	add_child(raid_node)
	var count := clampi(int(raid_strength / 10.0) + 2, 3, 12)
	for i in range(count):
		var r := _raider_figure()
		r.position = Vector3(float(i % 4) * 22.0, 0.0, float(i / 4) * 22.0 - 22.0)
		r.rotation_degrees.y = -90.0
		raid_node.add_child(r)
	raid_timer = 0.0
	_sfx("raid", -2.0)
	_toast("⚔ غارة! عصابة من %d رجال تهاجم من الشرق (قوة %d مقابل دفاعك %d)." % [count, int(raid_strength), int(_defense_total())], 6.0)
	_log_event("⚔ يوم %d: غارة بقوة %d." % [day, int(raid_strength)])
	for v in survivors:
		if v.unit != "" and not v.away:
			v.goal = _random_point_around(Vector3(camp_pos.x + 260.0, 0.0, z0), 10.0, 60.0)
			v.wait = 6.0


func _update_raid(dt: float) -> void:
	if not is_instance_valid(raid_node):
		return
	raid_timer += dt
	var target := Vector3(camp_pos.x + 230.0, 0.0, raid_node.position.z)
	var flat := Vector3(raid_node.position.x, 0.0, raid_node.position.z)
	var step := 55.0 * dt
	if flat.distance_to(target) > step:
		flat += (target - flat).normalized() * step
		raid_node.position = Vector3(flat.x, _height_at_world(flat.x, flat.z), flat.z)
		return
	_resolve_raid()


func _resolve_raid() -> void:
	_sfx("clash", -2.0)
	var def := _defense_total()
	var s := raid_strength
	var report: Array[String] = []
	var won := def >= s
	if won:
		raids_won += 1
		var loot := ceilf(s * 0.3)
		_add_dinar(loot, "غنائم")
		morale = minf(100.0, morale + 6.0)
		hope = minf(100.0, hope + 6.0)
		_add_xp(25.0)
		report.append("انتصرنا! دفاعنا %d أمام هجوم بقوة %d." % [int(def), int(s)])
		report.append("الغنائم: %d دينار  •  المعنويات +6" % int(loot))
		if def < s * 1.25 and _soldier_count() > 0 and rng.randf() < 0.35:
			var lost := _lose_soldier()
			if lost != "":
				report.append("سقط %s في المعركة. رحمه الله." % lost)
		_log_event("🛡 يوم %d: صُدّت الغارة (+%d دينار)." % [day, int(loot)])
	else:
		raids_lost += 1
		var frac := clampf(0.15 + (s - def) / maxf(1.0, s) * 0.4, 0.15, 0.5)
		var stolen: Array[String] = []
		for r in ["Food", "Wood", "Stone", "Scrap", "Oil", "Dinar"]:
			var take := floorf(float(resources[r]) * frac)
			if take >= 1.0:
				resources[r] = float(resources[r]) - take
				stolen.append("%d %s" % [int(take), RES_AR[r]])
		morale = maxf(0.0, morale - 12.0)
		hope = maxf(0.0, hope - 8.0)
		report.append("هُزمنا: دفاعنا %d أمام هجوم بقوة %d." % [int(def), int(s)])
		if not stolen.is_empty():
			report.append("نُهب: " + "، ".join(stolen))
		report.append("المعنويات −12")
		if s > def * 1.6 and survivors.size() > 1:
			var victim: Villager = survivors[rng.randi() % survivors.size()]
			report.append("قُتل %s أثناء الغارة." % victim.vname)
			survivors.erase(victim)
			victim.node.queue_free()
			_clamp_jobs()
		_log_event("💔 يوم %d: نجحت الغارة ونُهبت المؤن." % day)
	if is_instance_valid(raid_node):
		var rn := raid_node
		raid_node = null
		var tw := create_tween()
		tw.tween_property(rn, "position:x", rn.position.x + (900.0 if won else 300.0), 3.0)
		tw.tween_callback(rn.queue_free)
	for v in survivors:
		if v.unit != "":
			v.goal = _patrol_point()
	_check_goals()
	_refresh_ui()
	var body := _open_modal("⚔ تقرير المعركة")
	for line in report:
		var l := _label(line, 20, Color("#a8e07a") if won else Color("#ff9a8a"))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(l)
	body.add_child(_label("الغارة القادمة متوقعة بعد %d–%d أيام. سجلّك: %d انتصار / %d هزيمة." % [RAID_MIN_GAP, RAID_MAX_GAP, raids_won, raids_lost], 17, C_MUTED))
	body.add_child(_button("حسنًا", _close_all_modals, Vector2(0, 56), 22, C_GREEN))


func _lose_soldier() -> String:
	for v in survivors:
		if v.unit != "" and not v.away:
			var nm := v.vname
			survivors.erase(v)
			v.node.queue_free()
			_clamp_jobs()
			return nm
	return ""


func _start_expedition() -> void:
	if lairs_cleared >= BANDIT_LAIRS.size():
		_toast("طُهّرت كل الأوكار المعروفة.")
		return
	if expedition_day >= 0:
		_toast("الجيش في حملة بالفعل.")
		return
	if _soldier_count() == 0:
		_toast("لا جنود لإرسالهم.")
		return
	expedition_lair = lairs_cleared
	expedition_day = day + 1
	for v in survivors:
		if v.unit != "":
			v.away = true
			v.node.visible = false
	_toast("انطلق الجيش نحو «%s». يعود غدًا — المخيم أضعف في غيابه." % BANDIT_LAIRS[expedition_lair]["ar"], 5.0)
	_refresh_army_sheet()
	_refresh_ui()


func _resolve_expedition() -> void:
	var lair: Dictionary = BANDIT_LAIRS[expedition_lair]
	var power := _army_power(true)
	var ratio := power / float(lair["power"])
	var success := ratio >= 1.0 or rng.randf() < clampf(ratio * ratio, 0.05, 0.95)
	var lines: Array[String] = []
	if success:
		for r in lair["loot"]:
			if r == "Dinar":
				_add_dinar(float(lair["loot"][r]), "غنائم")
			else:
				resources[r] = float(resources[r]) + float(lair["loot"][r])
		lairs_cleared += 1
		_add_xp(40.0)
		morale = minf(100.0, morale + 8.0)
		var parts: Array[String] = []
		for r2 in lair["loot"]:
			parts.append("%d %s" % [int(lair["loot"][r2]), RES_AR[r2]])
		lines.append("طُهّر «%s»! الغنائم: %s." % [lair["ar"], "، ".join(parts)])
		lines.append("الغارات القادمة أضعف بـ12%.")
		_log_event("🏴 يوم %d: طُهّر %s." % [day, lair["ar"]])
	else:
		var losses := maxi(1, int(ceil(float(_soldier_count()) * 0.3)))
		var names: Array[String] = []
		for i in range(losses):
			for v in survivors:
				if v.unit != "":
					names.append(v.vname)
					survivors.erase(v)
					v.node.queue_free()
					break
		morale = maxf(0.0, morale - 6.0)
		lines.append("فشلت الحملة على «%s» (قوتنا %d من %d مطلوبة)." % [lair["ar"], int(power), int(lair["power"])])
		if not names.is_empty():
			lines.append("فقدنا: " + "، ".join(names))
	for v in survivors:
		if v.away:
			v.away = false
			v.node.visible = true
			v.node.position = _random_point_around(camp_pos, 200.0, 260.0)
			v.goal = _patrol_point()
	expedition_day = -1
	expedition_lair = -1
	_clamp_jobs()
	_check_goals()
	var body := _open_modal("🏴 عودة الحملة")
	for line in lines:
		var l := _label(line, 20, Color("#a8e07a") if success else Color("#ff9a8a"))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(l)
	body.add_child(_button("حسنًا", _close_all_modals, Vector2(0, 56), 22, C_GREEN))


func _build_army_sheet() -> void:
	army_sheet = _sheet(Control.PRESET_CENTER_BOTTOM)
	army_sheet.grow_horizontal = Control.GROW_DIRECTION_BOTH
	army_sheet.grow_vertical = Control.GROW_DIRECTION_BEGIN
	army_sheet.offset_bottom = -116
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(820, 0)
	box.add_theme_constant_override("separation", 8)
	army_sheet.add_child(box)
	box.add_child(_label_b("الجيش والدفاع", 28, C_GOLD))
	var scroll := _vscroll(380.0)
	box.add_child(scroll)
	army_list = VBoxContainer.new()
	army_list.add_theme_constant_override("separation", 8)
	army_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(army_list)


func _refresh_army_sheet() -> void:
	if not is_instance_valid(army_list):
		return
	for c in army_list.get_children():
		c.queue_free()
	var def_row := HBoxContainer.new()
	def_row.add_theme_constant_override("separation", 22)
	army_list.add_child(def_row)
	def_row.add_child(_stat_box("الدفاع الكلي", str(int(_defense_total())), C_GOLD))
	def_row.add_child(_stat_box("الجيش", str(int(_army_power())), Color("#e08a7a")))
	def_row.add_child(_stat_box("الأهالي", str(int(_militia_power())), C_CREAM))
	def_row.add_child(_stat_box("أسوار وأبراج", str(int(_structure_defense())), Color("#d8d0bb")))
	def_row.add_child(_stat_box("الجنود", "%d/%d" % [_soldier_count(), _barracks_capacity()], Color("#9fc0e0")))
	var raid_txt := ""
	if day < RAID_FIRST_DAY:
		raid_txt = "الغارات تبدأ نحو اليوم %d. ابنِ ثكنة وبرج مراقبة." % RAID_FIRST_DAY
	elif _has_done("Watchtower"):
		raid_txt = "برج المراقبة: الغارة القادمة متوقعة يوم %d تقريبًا." % raid_next_day
	else:
		raid_txt = "لا نعرف موعد الغارة القادمة — برج المراقبة يكشفها قبل يوم."
	if army_unpaid:
		raid_txt += "\n⚠ الأجور غير مدفوعة: قوة الجيش نصفها."
	var rl := _label(raid_txt, 17, Color("#ffd98a"))
	rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	army_list.add_child(rl)
	if _barracks_capacity() == 0:
		army_list.add_child(_label("ابنِ «الثكنة» من تبويب «دفاع» لتجنيد الجنود.", 18, C_MUTED))
	for key in UNIT_ORDER:
		var u: Dictionary = UNITS[key]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		army_list.add_child(row)
		row.add_child(_dot(u["color"], 16.0))
		var nm := _label_b("%s ×%d" % [u["ar"], _soldier_count(key)], 21)
		nm.custom_minimum_size = Vector2(120, 0)
		row.add_child(nm)
		var parts: Array[String] = []
		for r in u["cost"]:
			parts.append("%d %s" % [int(u["cost"][r]), RES_AR[r]])
		var req := ""
		if level < int(u["lv"]):
			req = " — يُفتح م%d" % int(u["lv"])
		elif u.has("needs") and not _has_done(str(u["needs"])):
			req = " — يحتاج %s" % BUILDINGS[u["needs"]]["ar"]
		var dl := _label("قوة %d، أجر %s/يوم — %s%s" % [int(u["power"]), _fmt(float(u["wage"])), "، ".join(parts), req], 16, C_MUTED)
		dl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(dl)
		row.add_child(_button("جنّد", _recruit.bind(key), Vector2(100, 50), 18, C_GREEN))
		row.add_child(_button("سرّح", _dismiss.bind(key), Vector2(90, 50), 17, C_BTN))
	army_list.add_child(HSeparator.new())
	if lairs_cleared < BANDIT_LAIRS.size():
		var lair: Dictionary = BANDIT_LAIRS[lairs_cleared]
		var lr := HBoxContainer.new()
		lr.add_theme_constant_override("separation", 10)
		army_list.add_child(lr)
		var ll := _label("🏴 الهدف التالي: «%s» — قوة مطلوبة %d (جيشك %d)" % [lair["ar"], int(lair["power"]), int(_army_power(true))], 18, C_CREAM)
		ll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lr.add_child(ll)
		var eb := _button("أرسل الحملة" if expedition_day < 0 else "الحملة في الطريق", _start_expedition, Vector2(190, 52), 18, Color("#8a3a2e"))
		eb.disabled = expedition_day >= 0 or _soldier_count() == 0
		lr.add_child(eb)
	else:
		army_list.add_child(_label("طُهّرت كل أوكار اللصوص المعروفة. الطرق آمنة أكثر.", 18, Color("#a8e07a")))
	army_list.add_child(_label("السجل: %d انتصار  •  %d هزيمة  •  %d أوكار مطهّرة" % [raids_won, raids_lost, lairs_cleared], 16, C_MUTED))


# ---------------------------------------------------------------- UI v3: modals, panels, planning

var modal_layers: Array = []


func _font_weight(base: Font, w: int) -> Font:
	var fv := FontVariation.new()
	fv.base_font = base
	var ts := TextServerManager.get_primary_interface()
	if ts != null:
		fv.variation_opentype = {ts.name_to_tag("wght"): w}
	return fv


func _label_b(text: String, size: int, color: Color = C_CREAM) -> Label:
	var l := _label(text, size, color)
	l.add_theme_font_override("font", ui_font_bold)
	return l


func _vscroll(max_h: float) -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	s.custom_minimum_size = Vector2(0, max_h)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.scroll_deadzone = 100000
	scroll_targets.append(s)
	return s


func _card_panel(bg: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _style(bg, 16, Color(1, 1, 1, 0.1), 1, 12))
	return p


func _stat_box(title: String, value: String, color: Color) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", -2)
	col.add_child(_label(title, 15, C_MUTED))
	col.add_child(_label_b(value, 26, color))
	return col


func _modal_open() -> bool:
	return not modal_layers.is_empty()


func _sync_menu_open() -> void:
	var m := not modal_layers.is_empty()
	if is_instance_valid(menu_layer) and menu_layer.visible:
		m = true
	if is_instance_valid(start_screen) and start_screen.visible:
		m = true
	menu_open = m


func _open_modal(title: String, width: float = 640.0) -> VBoxContainer:
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_root.add_child(layer)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var panel := PanelContainer.new()
	var st := _panel_style()
	st.border_color = Color(C_GOLD, 0.55)
	st.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", st)
	center.add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	outer.add_child(head)
	var t := _label_b(title, 27, C_GOLD)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(_button("إغلاق", _close_all_modals, Vector2(110, 50), 19, C_RED))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 100000
	outer.add_child(scroll)
	var body := VBoxContainer.new()
	body.custom_minimum_size = Vector2(width, 0)
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)
	scroll_targets.append(scroll)
	modal_layers.append(layer)
	_sync_menu_open()
	_fit_modal.call_deferred(scroll, body)
	return body


func _fit_modal(scroll: ScrollContainer, body: VBoxContainer) -> void:
	if not is_instance_valid(scroll) or not is_instance_valid(body):
		return
	var max_h := ui_root.size.y * 0.7
	scroll.custom_minimum_size = Vector2(body.custom_minimum_size.x + 10.0, minf(body.get_combined_minimum_size().y + 6.0, max_h))


func _close_all_modals() -> void:
	for l in modal_layers:
		if is_instance_valid(l):
			(l as Node).queue_free()
	modal_layers.clear()
	var keep: Array = []
	for s in scroll_targets:
		if is_instance_valid(s) and not (s as Node).is_queued_for_deletion():
			var inside_modal := false
			var n: Node = s
			while n != null:
				if n.is_queued_for_deletion():
					inside_modal = true
					break
				n = n.get_parent()
			if not inside_modal:
				keep.append(s)
	scroll_targets = keep
	_sync_menu_open()


# ── Diwan: taxes, policies, decisions, demand, happiness ──

func _show_council_panel() -> void:
	_close_all_modals()
	var body := _open_modal("الديوان — مجلس المستوطنة", 780.0)
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 28)
	body.add_child(stats)
	stats.add_child(_stat_box("الدنانير", str(int(resources["Dinar"])), C_GOLD))
	stats.add_child(_stat_box("المعنويات", str(int(morale)), Color("#7fc0e8")))
	stats.add_child(_stat_box("الأمل", str(int(hope)), Color("#9fd36b")))
	stats.add_child(_stat_box("السخط", str(int(discontent)), Color("#ff8a6a")))
	body.add_child(_label_b("الطلب في المستوطنة", 20, C_GOLD))
	for drow in [["سكن", demand_housing, Color("#60a0e0"), "ابنِ بيوتًا"], ["إنتاج", demand_production, Color("#e0a040"), "زد عمال الطعام والماء"], ["خدمات", demand_services, Color("#70c070"), "ابنِ جامعًا/عيادة/ساحة قرب البيوت"]]:
		var dr := HBoxContainer.new()
		dr.add_theme_constant_override("separation", 10)
		body.add_child(dr)
		var dl := _label_b(str(drow[0]), 18)
		dl.custom_minimum_size = Vector2(80, 0)
		dr.add_child(dl)
		var bar := _bar(drow[2], 260.0, 16.0)
		bar.value = float(drow[1])
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dr.add_child(bar)
		dr.add_child(_label("%d%%" % int(float(drow[1])), 17, C_MUTED))
		if float(drow[1]) > 60.0:
			dr.add_child(_label("← " + str(drow[3]), 16, Color("#ffd98a")))
	if not happiness_notes.is_empty():
		body.add_child(_label_b("ما الذي حرّك المعنويات أمس؟", 20, C_GOLD))
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 16)
		body.add_child(flow)
		for hn in happiness_notes:
			var d := float(hn[1])
			flow.add_child(_label("%s %s%s" % [hn[0], "+" if d >= 0.0 else "", _fmt(d)], 16, Color("#a8e07a") if d >= 0.0 else Color("#ff9a8a")))
	body.add_child(_label_b("الضريبة (لكل ناجٍ يوميًا)", 20, C_GOLD))
	var tax_row := HBoxContainer.new()
	tax_row.add_theme_constant_override("separation", 10)
	body.add_child(tax_row)
	var workers := float(_worker_count())
	for ti in range(TAX_LEVELS.size()):
		var est := float(TAX_PER_HEAD[ti]) * workers * (0.5 if policies.get("relief", false) else 1.0)
		var txt := "%s\n+%s دينار/يوم" % [str(TAX_LEVELS[ti]["ar"]), _fmt(est)]
		var tb := _button(txt, _set_tax.bind(ti), Vector2(170, 62), 16, C_GREEN if ti == tax_level_idx else C_BTN)
		tax_row.add_child(tb)
	body.add_child(_label("الضريبة الأعلى تزيد السخط يوميًا: %s" % "، ".join(["0", "0", "+0.8", "+2.5"]), 15, C_MUTED))
	body.add_child(_label_b("السياسات", 20, C_GOLD))
	for key in POLICIES:
		var pol: Dictionary = POLICIES[key]
		var on := bool(policies.get(key, false))
		var pr := HBoxContainer.new()
		pr.add_theme_constant_override("separation", 10)
		body.add_child(pr)
		var pl := _label("%s — %s" % [pol["ar"], pol["desc"]], 17, C_CREAM if on else C_MUTED)
		pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pr.add_child(pl)
		pr.add_child(_button("مفعّلة" if on else "تفعيل", _toggle_policy.bind(key), Vector2(120, 48), 17, C_GREEN if on else C_BTN))
	body.add_child(_label_b("قرارات المجلس", 20, C_GOLD))
	var act := HBoxContainer.new()
	act.add_theme_constant_override("separation", 10)
	body.add_child(act)
	act.add_child(_button("وليمة عامة\n−20 طعام، معنويات +20", _council_feast, Vector2(240, 66), 16, Color("#8a4a20")))
	act.add_child(_button("خطاب تشجيعي\n−5 دينار، سخط −15", _council_speech, Vector2(240, 66), 16, Color("#4a6a9a")))


func _set_tax(i: int) -> void:
	tax_level_idx = i
	_show_council_panel()


func _toggle_policy(key: String) -> void:
	policies[key] = not bool(policies.get(key, false))
	if not policies[key]:
		policies.erase(key)
	_show_council_panel()


func _council_feast() -> void:
	if float(resources["Food"]) < 20.0:
		_toast("طعام غير كافٍ (يلزم 20).")
		return
	resources["Food"] = float(resources["Food"]) - 20.0
	morale = minf(100.0, morale + 20.0)
	discontent = maxf(0.0, discontent - 10.0)
	_log_event("🍽 يوم %d: وليمة عامة." % day)
	_toast("أُقيمت وليمة! المعنويات +20.", 4.0)
	_show_council_panel()


func _council_speech() -> void:
	if float(resources["Dinar"]) < 5.0:
		_toast("لا تملك 5 دنانير.")
		return
	_add_dinar(-5.0, "قرارات المجلس")
	discontent = maxf(0.0, discontent - 15.0)
	hope = minf(100.0, hope + 10.0)
	_log_event("📜 يوم %d: خطاب تشجيعي." % day)
	_toast("خطاب المجلس رفع الأمل وخفّض السخط.", 4.0)
	_show_council_panel()


func _show_moral_event() -> void:
	if pending_event < 0 or pending_event >= MORAL_EVENTS.size():
		return
	var ev: Dictionary = MORAL_EVENTS[pending_event]
	pending_event = -1
	var body := _open_modal("قرار صعب")
	var lbl := _label(str(ev["text"]), 20, C_CREAM)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(lbl)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	body.add_child(hb)
	for side in ["a", "b"]:
		var b := _button(str(ev[side]), _moral_choice.bind(str(ev[side]), str(ev["effect_" + side])), Vector2(0, 66), 17, C_GREEN if side == "a" else C_BTN)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hb.add_child(b)


func _moral_choice(text: String, eff: String) -> void:
	_log_event("⚖ يوم %d: %s" % [day, text])
	_close_all_modals()
	_apply_moral_effect(eff)
	_refresh_ui()


# ── economy sheet (Cities: Skylines style budget & flows) ──

func _build_economy_sheet() -> void:
	economy_sheet = _sheet(Control.PRESET_CENTER_BOTTOM)
	economy_sheet.grow_horizontal = Control.GROW_DIRECTION_BOTH
	economy_sheet.grow_vertical = Control.GROW_DIRECTION_BEGIN
	economy_sheet.offset_bottom = -116
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(860, 0)
	box.add_theme_constant_override("separation", 8)
	economy_sheet.add_child(box)
	box.add_child(_label_b("الاقتصاد — من أين تأتي الموارد وأين تذهب", 26, C_GOLD))
	var scroll := _vscroll(390.0)
	box.add_child(scroll)
	economy_list = VBoxContainer.new()
	economy_list.add_theme_constant_override("separation", 8)
	economy_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(economy_list)


const RES_USES := {
	"Food": "أكل الناجين والجنود، المطبخ يوفر 25%، الإسطبل يطعم الخيول.",
	"Water": "شرب الناجين (+40% صيفًا)، ري المزارع، سقاية الحظائر.",
	"Wood": "البناء، تدفئة الخريف والشتاء، حطب المطبخ والورشة والمعصرة.",
	"Stone": "البناء، صيانة البيوت الحجرية والأسوار، رصف الطرق.",
	"Scrap": "البناء، أدوات المقلع، أسلحة الجنود.",
	"Oil": "قناديل الجامع والمكتبة، دواء العيادة، وأغلى سلعة للبيع.",
	"Dinar": "أجور الجنود والمعلمين، التجارة، الاستكشاف، الترقيات.",
}


func _refresh_economy_sheet() -> void:
	if not is_instance_valid(economy_list):
		return
	for c in economy_list.get_children():
		c.queue_free()
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 26)
	grid.add_theme_constant_override("v_separation", 6)
	economy_list.add_child(grid)
	for h in ["المورد", "المخزون", "دخل أمس", "استهلاك/يوم", "الصافي", "يكفي"]:
		grid.add_child(_label_b(h, 17, C_MUTED))
	var cons := _compute_consumption()
	for r in RES_NAMES:
		var stock := float(resources[r])
		var inc := float(last_income.get(r, 0.0))
		if r == "Dinar":
			inc = 0.0
			for bl in budget_lines:
				if float(bl[1]) > 0.0:
					inc += float(bl[1])
		var use := float(cons.get(r, 0.0))
		var net := inc - use
		var nm := HBoxContainer.new()
		nm.add_theme_constant_override("separation", 6)
		nm.add_child(_dot(RES_COLORS[r], 12.0))
		nm.add_child(_label_b(RES_AR[r], 19, RES_COLORS[r].lightened(0.2)))
		grid.add_child(nm)
		grid.add_child(_label_b(str(int(stock)), 19))
		grid.add_child(_label("+" + _fmt(inc), 18, Color("#a8e07a")))
		grid.add_child(_label("−" + _fmt(use), 18, Color("#ff9a8a") if use > 0.0 else C_MUTED))
		grid.add_child(_label_b(("+" if net >= 0.0 else "") + _fmt(net), 18, Color("#a8e07a") if net >= 0.0 else Color("#ff9a8a")))
		var days_txt := "∞" if use <= 0.01 else ("%d يوم" % int(stock / use))
		grid.add_child(_label(days_txt, 17, Color("#ff9a8a") if use > 0.01 and stock / use < 3.0 else C_CREAM))
	economy_list.add_child(HSeparator.new())
	economy_list.add_child(_label_b("ميزانية الدينار (أمس)", 20, C_GOLD))
	if budget_lines.is_empty():
		economy_list.add_child(_label("لا حركة بعد — بِع للقرى، ابنِ سوقًا، أو فعّل الضرائب في الديوان.", 17, C_MUTED))
	else:
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 20)
		economy_list.add_child(flow)
		var total := 0.0
		for bl in budget_lines:
			total += float(bl[1])
			flow.add_child(_label("%s %s%s" % [bl[0], "+" if float(bl[1]) >= 0.0 else "", _fmt(float(bl[1]))], 17, Color("#a8e07a") if float(bl[1]) >= 0.0 else Color("#ff9a8a")))
		economy_list.add_child(_label_b("الصافي: %s%s دينار/يوم" % ["+" if total >= 0.0 else "", _fmt(total)], 18, Color("#a8e07a") if total >= 0.0 else Color("#ff9a8a")))
	if not unpaid_notes.is_empty():
		economy_list.add_child(_label_b("تنبيهات", 20, Color("#ff9a8a")))
		for un in unpaid_notes:
			var ul := _label("• " + str(un), 17, Color("#ffc0a8"))
			ul.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			economy_list.add_child(ul)
	economy_list.add_child(HSeparator.new())
	economy_list.add_child(_label_b("لكل مورد قيمة", 20, C_GOLD))
	for r2 in RES_USES:
		var l := _label("%s: %s" % [RES_AR[r2], RES_USES[r2]], 16, C_CREAM)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		economy_list.add_child(l)


# ── planning toolbar (roads, zones, land value) ──

func _build_plan_sheet() -> void:
	plan_sheet = _sheet(Control.PRESET_CENTER_BOTTOM)
	plan_sheet.grow_horizontal = Control.GROW_DIRECTION_BOTH
	plan_sheet.grow_vertical = Control.GROW_DIRECTION_BEGIN
	plan_sheet.offset_bottom = -116
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	plan_sheet.add_child(box)
	var rows := [
		["الطرق", [["road_dirt", "ترابي (مجاني)"], ["road_paved", "مرصوف (حجر)"], ["road_erase", "إزالة طريق"]]],
		["المناطق", [["zone_1", "سكنية"], ["zone_2", "تجارية"], ["zone_3", "صناعية"], ["zone_4", "زراعية"], ["zone_erase", "مسح"]]],
	]
	for row_def in rows:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		box.add_child(row)
		var t := _label_b(str(row_def[0]), 20, C_GOLD)
		t.custom_minimum_size = Vector2(90, 0)
		row.add_child(t)
		for item in row_def[1]:
			var b := _button(str(item[1]), _set_plan_mode.bind(str(item[0])), Vector2(140, 52), 17)
			row.add_child(b)
			plan_buttons[str(item[0])] = b
	var row3 := HBoxContainer.new()
	row3.add_theme_constant_override("separation", 8)
	box.add_child(row3)
	var t3 := _label_b("عرض", 20, C_GOLD)
	t3.custom_minimum_size = Vector2(90, 0)
	row3.add_child(t3)
	var lvb := _button("قيمة الأرض", _toggle_lv_overlay, Vector2(160, 52), 17)
	row3.add_child(lvb)
	plan_buttons["lv"] = lvb
	var help := _label("اختر أداة ثم اسحب على الأرض. المناطق تمنع خلط البيوت بالمصانع، والمبنى في منطقته يحصل +20%.", 15, C_MUTED)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.custom_minimum_size = Vector2(420, 0)
	row3.add_child(help)
	plan_bar = _sheet(Control.PRESET_CENTER_BOTTOM)
	plan_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	plan_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	plan_bar.offset_bottom = -12
	var pb := HBoxContainer.new()
	pb.add_theme_constant_override("separation", 12)
	plan_bar.add_child(pb)
	plan_bar_label = _label_b("", 18, C_CREAM)
	plan_bar_label.custom_minimum_size = Vector2(430, 0)
	plan_bar_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	plan_bar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pb.add_child(plan_bar_label)
	pb.add_child(_button("تغيير الأداة", _plan_change_tool, Vector2(160, 62), 18))
	pb.add_child(_button("تم", _plan_done, Vector2(110, 62), 20, C_GREEN))


func _refresh_plan_buttons() -> void:
	for k in plan_buttons:
		var b: Button = plan_buttons[k]
		var ks := str(k)
		var on: bool = (ks == plan_mode) or (ks == "lv" and lv_overlay)
		var col := C_GREEN if on else C_BTN
		if ks.begins_with("zone_") and ks != "zone_erase":
			var z := int(ks.substr(5))
			col = Color(ZONE_COLORS[z], 1.0).darkened(0.35 if on else 0.62)
		b.add_theme_stylebox_override("normal", _btn_style(col))
		b.add_theme_stylebox_override("hover", _btn_style(col.lightened(0.1)))


func _build_dock() -> void:
	dock = _anchored_panel(Control.PRESET_CENTER_BOTTOM)
	dock.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dock.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dock.offset_bottom = -12
	dock.add_theme_stylebox_override("panel", _style(Color(0.09, 0.105, 0.075, 0.88), 26, C_BORDER, 2, 10))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	dock.add_child(row)
	row.add_child(_dock_button("build", "بناء", _toggle_sheet.bind("build")))
	row.add_child(_dock_button("plan", "تخطيط", _toggle_sheet.bind("plan")))
	row.add_child(_dock_button("workers", "العمال", _toggle_sheet.bind("workers")))
	row.add_child(_dock_button("army", "الجيش", _toggle_sheet.bind("army")))
	row.add_child(_dock_button("villages", "التجارة", _toggle_sheet.bind("villages")))
	row.add_child(_dock_button("coins", "الاقتصاد", _toggle_sheet.bind("economy")))
	row.add_child(_dock_button("missions2", "المهام", _toggle_sheet.bind("missions")))


func _build_inspect_bar() -> void:
	inspect_bar = _sheet(Control.PRESET_CENTER_BOTTOM)
	inspect_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	inspect_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	inspect_bar.offset_bottom = -12
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	inspect_bar.add_child(row)
	inspect_label = _label("", 18)
	inspect_label.custom_minimum_size = Vector2(420, 0)
	inspect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspect_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(inspect_label)
	upgrade_btn = _button("ترقية", _upgrade_pressed, Vector2(190, 70), 17, Color("#4a7a9a"))
	upgrade_btn.visible = false
	row.add_child(upgrade_btn)
	council_btn = _button("إدارة الديوان", _show_council_panel, Vector2(170, 70), 18, Color("#8a6020"))
	council_btn.visible = false
	row.add_child(council_btn)
	army_btn = _button("الجيش", _inspect_open_sheet.bind("army"), Vector2(130, 70), 18, Color("#8a3a2e"))
	army_btn.visible = false
	row.add_child(army_btn)
	trade_btn = _button("التجارة", _inspect_open_sheet.bind("villages"), Vector2(130, 70), 18, Color("#2f6a8a"))
	trade_btn.visible = false
	row.add_child(trade_btn)
	demolish_btn = _button("هدم", _demolish_pressed, Vector2(130, 70), 19, C_RED)
	row.add_child(demolish_btn)
	row.add_child(_button("إغلاق", _close_inspect, Vector2(110, 70), 19))


func _inspect_open_sheet(which: String) -> void:
	_close_inspect()
	_toggle_sheet(which)


func _hide_sheets() -> void:
	for s in [build_sheet, workers_sheet, missions_sheet, log_sheet, villages_sheet, army_sheet, economy_sheet, plan_sheet, plan_bar]:
		if is_instance_valid(s):
			(s as Control).visible = false


func _toggle_sheet(which: String) -> void:
	var map := {"build": build_sheet, "workers": workers_sheet, "missions": missions_sheet, "log": log_sheet,
		"villages": villages_sheet, "army": army_sheet, "economy": economy_sheet, "plan": plan_sheet}
	var target: PanelContainer = map.get(which, build_sheet)
	var show := not target.visible
	_hide_sheets()
	_close_inspect()
	if which != "plan" and plan_mode != "":
		_set_plan_mode(plan_mode)
	if which == "plan" and not show and plan_mode != "":
		_set_plan_mode(plan_mode)
	target.visible = show
	if show:
		_fit_sheet(target)
		_sfx("open", -12.0)
	match which:
		"workers":
			if show:
				workers_opened = true
				_check_goals()
		"build":
			if show:
				_rebuild_cards()
		"log":
			if show:
				_refresh_log_sheet()
		"villages":
			if show:
				_refresh_villages_sheet()
		"army":
			if show:
				_refresh_army_sheet()
		"economy":
			if show:
				_refresh_economy_sheet()
		"plan":
			_show_territory(show)
			_refresh_plan_buttons()
	_refresh_ui()


# ── touch scrolling that works over buttons (Godot gives drags to the button, not the ScrollContainer) ──

func _scroll_to_start(sc: ScrollContainer) -> void:
	await get_tree().process_frame
	if is_instance_valid(sc):
		sc.scroll_horizontal = int(sc.get_h_scroll_bar().max_value)


# Sheets must stay between the top bar and the dock whatever the screen/text size.
func _fit_sheet(sheet: PanelContainer) -> void:
	var h := clampf(ui_root.size.y - 372.0, 150.0, 420.0)
	for s in scroll_targets:
		if is_instance_valid(s) and sheet.is_ancestor_of(s) and (s as ScrollContainer).vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
			(s as ScrollContainer).custom_minimum_size.y = h
	# Collapse to the bottom edge; the minimum size then grows the panel upward (grow_vertical = BEGIN).
	sheet.offset_top = sheet.offset_bottom


func _scroll_under(pos: Vector2) -> ScrollContainer:
	for i in range(scroll_targets.size() - 1, -1, -1):
		var s = scroll_targets[i]
		if not is_instance_valid(s):
			continue
		var sc: ScrollContainer = s
		if sc.is_visible_in_tree() and sc.get_global_rect().has_point(pos):
			return sc
	return null


func _input(event: InputEvent) -> void:
	var touch := DisplayServer.is_touchscreen_available()
	var pos := Vector2.ZERO
	var phase := ""
	var rel := Vector2.ZERO
	if event is InputEventScreenTouch and event.index == 0:
		pos = event.position
		phase = "down" if event.pressed else "up"
	elif event is InputEventScreenDrag and event.index == 0:
		pos = event.position
		rel = event.relative
		phase = "move"
	elif not touch and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
		phase = "down" if event.pressed else "up"
	elif not touch and event is InputEventMouseMotion and scroll_pressing:
		pos = event.position
		rel = event.relative
		phase = "move"
	elif not touch and event is InputEventMouseButton and event.pressed and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		var sw := _scroll_under(event.position)
		if sw != null:
			var dir := -60 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 60
			if sw.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
				sw.scroll_horizontal += dir
			else:
				sw.scroll_vertical += dir
			get_viewport().set_input_as_handled()
		return
	else:
		return
	match phase:
		"down":
			scroll_active = _scroll_under(pos)
			scroll_press = pos
			scroll_dragged = false
			scroll_pressing = scroll_active != null
		"move":
			if scroll_active == null or not is_instance_valid(scroll_active):
				return
			if pos.distance_to(scroll_press) > 12.0:
				scroll_dragged = true
			if scroll_dragged:
				if scroll_active.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
					scroll_active.scroll_horizontal -= int(rel.x)
				else:
					scroll_active.scroll_vertical -= int(rel.y)
		"up":
			scroll_pressing = false
			scroll_active = null


# ---------------------------------------------------------------- 3D assets (Kenney, CC0) and world dressing

const KN := "res://assets/kenney/"
# Nature Kit ships teal/orange colours; re-tint to a Mediterranean palette by material name.
const MED_TINT := {
	"leafsGreen": Color("#6f7d48"), "woodBark": Color("#6e5a44"), "grass": Color("#8f9b58"),
	"dirt": Color("#c2ad84"), "stone": Color("#ddd2b8"), "stoneDark": Color("#bfb397"),
	"wood": Color("#8c6c47"), "woodInner": Color("#d8c094"), "leafsFall": Color("#a87a3c"),
	"_defaultMat": Color("#cdb98c"), "colorRed": Color("#c8323a"),
}
const OLIVE_TINT := {"leafsGreen": Color("#8a9670"), "woodBark": Color("#7a6650")}
const PINE_TINT := {"leafsGreen": Color("#4c6236"), "woodBark": Color("#6a5440")}
const CACTUS_TINT := {"leafsGreen": Color("#6f9150")}
const ANEMONE_TINT := {"grass": Color("#7f9150"), "colorRed": Color("#d0242e")}
const TENT_TINT := {"colorRed": Color("#e2d6b6"), "colorRedDark": Color("#c4b48c"), "wood": Color("#7a5c3c")}

var asset_cache := {}
var asset_mesh_cache := {}
var scatter_items: Array = []     # [MultiMesh, index, Vector2 xz, Transform3D]


func _asset_scene(path: String) -> PackedScene:
	if asset_cache.has(path):
		return asset_cache[path]
	var full := KN + path + ".glb"
	var ps: PackedScene = load(full) if ResourceLoader.exists(full) else null
	asset_cache[path] = ps
	return ps


func _tint_node(n: Node, tint: Dictionary) -> void:
	for c in n.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = c
		for i in range(mi.mesh.get_surface_count()):
			var m: Material = mi.mesh.surface_get_material(i)
			var key := m.resource_name if m != null else ""
			if tint.has(key):
				mi.set_surface_override_material(i, _mat(tint[key]))
			elif MED_TINT.has(key):
				mi.set_surface_override_material(i, _mat(MED_TINT[key]))


func _node_height(n: Node) -> float:
	var top := 0.0
	for c in n.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = c
		var a := mi.mesh.get_aabb()
		top = maxf(top, a.position.y + a.size.y)
	return maxf(top, 0.001)


# Instance a model scaled to a target height (in the parent's units), recoloured.
func _asset(path: String, height: float, tint: Dictionary = {}) -> Node3D:
	var ps := _asset_scene(path)
	if ps == null:
		return Node3D.new()
	var n: Node3D = ps.instantiate()
	_tint_node(n, tint)
	n.scale = Vector3.ONE * (height / _node_height(n))
	return n


func _prop(parent: Node3D, path: String, height: float, pos: Vector3, rot_y: float = 0.0, tint: Dictionary = {}) -> Node3D:
	var n := _asset(path, height, tint)
	n.position = pos
	n.rotation_degrees.y = rot_y
	parent.add_child(n)
	return n


# Stone-textured version of a model (castle pieces become Jerusalem limestone).
func _stone_asset(path: String, height: float) -> Node3D:
	var n := _asset(path, height)
	for c in n.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = c
		for i in range(mi.mesh.get_surface_count()):
			mi.set_surface_override_material(i, _stone_mat(Color.WHITE))
	return n


# Single recoloured mesh for MultiMesh scattering.
func _asset_mesh(path: String, tint: Dictionary) -> Mesh:
	var key := path + str(tint.keys())
	if asset_mesh_cache.has(key):
		return asset_mesh_cache[key]
	var ps := _asset_scene(path)
	if ps == null:
		return null
	var n: Node = ps.instantiate()
	var mis := n.find_children("*", "MeshInstance3D", true, false)
	var out: Mesh = null
	if not mis.is_empty():
		var src: Mesh = (mis[0] as MeshInstance3D).mesh
		out = src.duplicate()
		for i in range(out.get_surface_count()):
			var m: Material = out.surface_get_material(i)
			var nm := m.resource_name if m != null else ""
			if tint.has(nm):
				out.surface_set_material(i, _mat(tint[nm]))
			elif MED_TINT.has(nm):
				out.surface_set_material(i, _mat(MED_TINT[nm]))
	n.free()
	asset_mesh_cache[key] = out
	return out


# points: Array of [Vector3 pos, float height, float yaw]; one draw call per model type.
func _scatter(path: String, tint: Dictionary, points: Array, hideable: bool, shadows: bool = true) -> void:
	if points.is_empty():
		return
	var mesh := _asset_mesh(path, tint)
	if mesh == null:
		return
	var base_h := maxf(0.001, mesh.get_aabb().position.y + mesh.get_aabb().size.y)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = points.size()
	for i in range(points.size()):
		var p: Vector3 = points[i][0]
		var s := float(points[i][1]) / base_h
		var xf := Transform3D(Basis(Vector3.UP, float(points[i][2])).scaled(Vector3.ONE * s), p)
		mm.set_instance_transform(i, xf)
		if hideable:
			scatter_items.append([mm, i, Vector2(p.x, p.z)])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	if not shadows:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	terrain_root.add_child(mi)


func _hide_scatter_near(center: Vector2, size: Vector2) -> void:
	for it in scatter_items:
		var p: Vector2 = it[2]
		if absf(p.x - center.x) < size.x * 0.5 + 14.0 and absf(p.y - center.y) < size.y * 0.5 + 14.0:
			var mm: MultiMesh = it[0]
			mm.set_instance_transform(int(it[1]), Transform3D(Basis().scaled(Vector3.ONE * 0.0001), Vector3(p.x, -500.0, p.y)))


func _add_vegetation() -> void:
	var wr := RandomNumberGenerator.new()
	wr.seed = WORLD_SEED + 1
	var olives: Dictionary = {"nature/tree_default": [], "nature/tree_oak": [], "nature/tree_fat": []}
	var pines: Array = []
	var palms: Dictionary = {"nature/tree_palmTall": [], "nature/tree_palmBend": []}
	var cacti: Dictionary = {"nature/cactus_short": [], "nature/cactus_tall": []}
	var cover: Dictionary = {"nature/grass_large": [], "nature/grass": [], "nature/flower_redA": [], "nature/flower_yellowA": [],
		"nature/plant_bush": [], "nature/stone_smallA": [], "nature/stone_smallB": []}
	var groves := 0
	var tries := 0
	while groves < 14 and tries < 600:
		tries += 1
		var gx := wr.randi_range(7, GRID - 6)
		var gz := wr.randi_range(2, GRID - 3)
		if not _is_land(gx, gz) or Vector2(Vector2i(gx, gz) - CAMP_CELL).length() < PLATEAU_R1 + 1.5:
			continue
		var v := _grid_vertex(gx, gz)
		if v.y > 330.0:
			continue
		groves += 1
		var keys := olives.keys()
		for k in range(wr.randi_range(6, 11)):
			var px := v.x + wr.randf_range(-95.0, 95.0)
			var pz := v.z + wr.randf_range(-95.0, 95.0)
			(olives[keys[wr.randi() % keys.size()]] as Array).append([Vector3(px, _height_at_world(px, pz), pz), wr.randf_range(30.0, 44.0), wr.randf() * TAU])
	for i in range(70):
		var px2 := wr.randf_range(-1700.0, 1700.0)
		var pz2 := wr.randf_range(-1700.0, 1700.0)
		var h2 := _height_at_world(px2, pz2)
		if not _is_land_world(px2, pz2) or h2 < 60.0 or Vector2(px2 - camp_pos.x, pz2 - camp_pos.z).length() < 600.0:
			continue
		pines.append([Vector3(px2, h2, pz2), wr.randf_range(46.0, 70.0), wr.randf() * TAU])
	for gz2 in range(2, GRID - 2):
		if wr.randf() < 0.55:
			var cx := _coastline_x(float(gz2)) + wr.randf_range(1.2, 2.6)
			var wx := (cx - GRID / 2.0 + 0.5) * TILE_SIZE
			var wz := (float(gz2) - GRID / 2.0 + 0.5) * TILE_SIZE + wr.randf_range(-30.0, 30.0)
			var pk: Array = palms.keys()
			(palms[pk[wr.randi() % 2]] as Array).append([Vector3(wx, _height_at_world(wx, wz), wz), wr.randf_range(48.0, 66.0), wr.randf() * TAU])
	for r in ruin_nodes:
		var rp: Vector3 = (r as Node3D).position
		for k2 in range(wr.randi_range(1, 3)):
			var ox := rp.x + wr.randf_range(-45.0, 45.0)
			var oz := rp.z + wr.randf_range(-45.0, 45.0)
			var ck: Array = cacti.keys()
			(cacti[ck[wr.randi() % 2]] as Array).append([Vector3(ox, _height_at_world(ox, oz), oz), wr.randf_range(14.0, 24.0), wr.randf() * TAU])
	var ckeys := cover.keys()
	for i2 in range(900):
		var px3 := camp_pos.x + wr.randf_range(-1500.0, 1500.0)
		var pz3 := camp_pos.z + wr.randf_range(-1500.0, 1500.0)
		if not _is_land_world(px3, pz3):
			continue
		var d := Vector2(px3 - camp_pos.x, pz3 - camp_pos.z).length()
		if d < 90.0 or (d < 380.0 and wr.randf() < 0.55):
			continue
		var kind: String = ckeys[wr.randi() % ckeys.size()]
		var hh := 9.0
		match kind:
			"nature/grass_large": hh = 10.0
			"nature/grass": hh = 7.0
			"nature/plant_bush": hh = 12.0
			"nature/stone_smallA", "nature/stone_smallB": hh = 6.0
			_: hh = 8.0
		(cover[kind] as Array).append([Vector3(px3, _height_at_world(px3, pz3), pz3), hh * wr.randf_range(0.8, 1.3), wr.randf() * TAU])
	for k3 in olives:
		_scatter(k3, OLIVE_TINT, olives[k3], true)
	_scatter("nature/tree_cone", PINE_TINT, pines, true)
	for k4 in palms:
		_scatter(k4, {}, palms[k4], true)
	for k5 in cacti:
		_scatter(k5, CACTUS_TINT, cacti[k5], true)
	for k6 in cover:
		_scatter(k6, ANEMONE_TINT if k6 == "nature/flower_redA" else {}, cover[k6], true, false)


# Merge every static MeshInstance3D under `root` into one mesh per material (+ vertex format).
# Cuts a building from ~30 draw calls to a handful — essential on phones.
# Merge every static MeshInstance3D under `root` into very few meshes:
# all plain-coloured parts → one vertex-coloured mesh, all limestone parts → one stone mesh,
# textured model parts → one mesh per texture material. A building drops to ~3-4 draw calls.
func _bake_static(root: Node3D) -> void:
	var flat := {"v": PackedVector3Array(), "n": PackedVector3Array(), "c": PackedColorArray(), "i": PackedInt32Array()}
	var stone := {"v": PackedVector3Array(), "n": PackedVector3Array(), "c": PackedColorArray(), "i": PackedInt32Array()}
	var groups := {}
	var order: Array = []
	var done: Array = []
	for c in root.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = c
		if mi.mesh == null or mi.skin != null or _under_nobake(root, mi):
			continue
		var xf := _rel_xform(root, mi)
		for i in range(mi.mesh.get_surface_count()):
			var mat: Material = mi.get_surface_override_material(i)
			if mat == null:
				mat = mi.material_override
			if mat == null:
				mat = mi.mesh.surface_get_material(i)
			var kind := _bake_kind(mat)
			if kind == "flat" or kind == "stone":
				_append_colored(flat if kind == "flat" else stone, mi.mesh.surface_get_arrays(i), xf, (mat as StandardMaterial3D).albedo_color if mat != null else Color.WHITE)
				continue
			var arrs: Array = mi.mesh.surface_get_arrays(i)
			var sig := ""
			for ai in [Mesh.ARRAY_NORMAL, Mesh.ARRAY_TANGENT, Mesh.ARRAY_COLOR, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2]:
				sig += "1" if arrs[ai] != null else "0"
			var key := "%d_%s" % [mat.get_instance_id() if mat != null else 0, sig]
			if not groups.has(key):
				groups[key] = {"mat": mat, "parts": []}
				order.append(key)
			(groups[key]["parts"] as Array).append([mi.mesh, i, xf])
		done.append(mi)
	for d in done:
		if is_instance_valid(d):
			(d as Node).get_parent().remove_child(d)
			(d as Node).free()
	_emit_colored(root, flat, _baked_mat(false))
	_emit_colored(root, stone, _baked_mat(true))
	for key in order:
		var g: Dictionary = groups[key]
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for part in g["parts"]:
			st.append_from(part[0], int(part[1]), part[2])
		var am := st.commit()
		if am == null or am.get_surface_count() == 0:
			continue
		if g["mat"] != null:
			am.surface_set_material(0, g["mat"])
		var out := MeshInstance3D.new()
		out.mesh = am
		root.add_child(out)


func _bake_kind(mat: Material) -> String:
	if mat == null:
		return "flat"
	if not (mat is StandardMaterial3D):
		return "other"
	var sm: StandardMaterial3D = mat
	if sm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or sm.emission_enabled or sm.shading_mode != BaseMaterial3D.SHADING_MODE_PER_PIXEL:
		return "other"
	if sm.albedo_texture == null:
		return "flat"
	if sm.albedo_texture == stone_texture:
		return "stone"
	return "other"


func _append_colored(acc: Dictionary, arrs: Array, xf: Transform3D, col: Color) -> void:
	var verts: PackedVector3Array = arrs[Mesh.ARRAY_VERTEX]
	if verts.is_empty():
		return
	var norms: Variant = arrs[Mesh.ARRAY_NORMAL]
	var nb := xf.basis.inverse().transposed()
	var base := (acc["v"] as PackedVector3Array).size()
	var v: PackedVector3Array = acc["v"]
	var n: PackedVector3Array = acc["n"]
	var cc: PackedColorArray = acc["c"]
	for k in range(verts.size()):
		v.append(xf * verts[k])
		n.append((nb * (norms as PackedVector3Array)[k]).normalized() if norms != null else Vector3.UP)
		cc.append(col)
	acc["v"] = v
	acc["n"] = n
	acc["c"] = cc
	var idx: Variant = arrs[Mesh.ARRAY_INDEX]
	var ii: PackedInt32Array = acc["i"]
	if idx != null:
		for k2 in (idx as PackedInt32Array):
			ii.append(base + k2)
	else:
		for k3 in range(verts.size()):
			ii.append(base + k3)
	acc["i"] = ii


func _emit_colored(root: Node3D, acc: Dictionary, mat: Material) -> void:
	if (acc["v"] as PackedVector3Array).is_empty():
		return
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = acc["v"]
	arrays[Mesh.ARRAY_NORMAL] = acc["n"]
	arrays[Mesh.ARRAY_COLOR] = acc["c"]
	arrays[Mesh.ARRAY_INDEX] = acc["i"]
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	am.surface_set_material(0, mat)
	var out := MeshInstance3D.new()
	out.mesh = am
	root.add_child(out)


func _baked_mat(stone: bool) -> StandardMaterial3D:
	var key := "baked_stone" if stone else "baked_flat"
	if mat_cache.has(key):
		return mat_cache[key]
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.roughness = 0.95
	if stone:
		m.albedo_texture = stone_texture
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(0.022, 0.022, 0.022)
	mat_cache[key] = m
	return m


func _under_nobake(root: Node, n: Node) -> bool:
	var p := n.get_parent()
	while p != null and p != root:
		if p.has_meta("nobake"):
			return true
		p = p.get_parent()
	return false


func _rel_xform(root: Node3D, n: Node3D) -> Transform3D:
	var xf := n.transform
	var p := n.get_parent()
	while p != null and p != root:
		if p is Node3D:
			xf = (p as Node3D).transform * xf
		p = p.get_parent()
	return xf


# ---------------------------------------------------------------- atmosphere: sound, smoke, rain, night windows

const WINDOW_COLOR := Color("#34444f")
const SMOKE_SPOTS := {
	"Kitchen": Vector3(-16, 40, -16), "Workshop": Vector3(15, 46, -9), "Olive Press": Vector3(10, 30, 6),
	"Small House": Vector3(13, 8, 19), "Shack": Vector3(16, 24, -12),
}
var sfx_on := true
var sfx_players: Array = []
var sfx_streams := {}
var rain_node: CPUParticles3D
var rain_time := 0.0


func _build_fx() -> void:
	for i in range(6):
		var ap := AudioStreamPlayer.new()
		add_child(ap)
		sfx_players.append(ap)
	rain_node = CPUParticles3D.new()
	rain_node.emitting = false
	rain_node.amount = 500
	rain_node.lifetime = 1.1
	rain_node.local_coords = false
	rain_node.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain_node.emission_box_extents = Vector3(1100, 10, 1100)
	rain_node.direction = Vector3(0.12, -1, 0.05)
	rain_node.spread = 2.0
	rain_node.gravity = Vector3(0, -400, 0)
	rain_node.initial_velocity_min = 520.0
	rain_node.initial_velocity_max = 620.0
	var drop := BoxMesh.new()
	drop.size = Vector3(2.6, 26.0, 2.6)
	rain_node.mesh = drop
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(0.78, 0.84, 0.95, 0.6)
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rain_node.material_override = rm
	rain_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rain_node)


func _sfx(sound: String, vol_db: float = -6.0) -> void:
	if not sfx_on or sfx_players.is_empty():
		return
	if not sfx_streams.has(sound):
		var path := "res://assets/sfx/%s.ogg" % sound
		sfx_streams[sound] = load(path) if ResourceLoader.exists(path) else null
	var st: AudioStream = sfx_streams[sound]
	if st == null:
		return
	for ap in sfx_players:
		var p: AudioStreamPlayer = ap
		if not p.playing:
			p.stream = st
			p.volume_db = vol_db
			p.play()
			return


func _toggle_sfx() -> void:
	sfx_on = not sfx_on
	sfx_btn.text = "الأصوات: %s" % ("تعمل" if sfx_on else "مطفأة")
	_save_settings()


func _window_mat() -> StandardMaterial3D:
	if mat_cache.has("window_glow"):
		return mat_cache["window_glow"]
	var m := StandardMaterial3D.new()
	m.albedo_color = WINDOW_COLOR
	m.emission_enabled = true
	m.emission = Color("#ffb54d")
	m.emission_energy_multiplier = 0.0
	mat_cache["window_glow"] = m
	return m


func _smoke_puffs(parent: Node3D, pos: Vector3, amount: int, color: Color, size: float, life: float, burst: bool) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.one_shot = burst
	p.explosiveness = 0.85 if burst else 0.0
	p.local_coords = false
	p.position = pos
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 2.0 if not burst else 30.0
	p.direction = Vector3(0, 1, 0)
	p.spread = 18.0 if not burst else 70.0
	p.gravity = Vector3(4, 3, 0) if not burst else Vector3(0, -10, 0)
	p.initial_velocity_min = 8.0 if not burst else 25.0
	p.initial_velocity_max = 14.0 if not burst else 45.0
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.3
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.3))
	curve.add_point(Vector2(0.7, 1.4))
	curve.add_point(Vector2(1, 0.0))
	p.scale_amount_curve = curve
	var q := SphereMesh.new()
	q.radius = size * 0.5
	q.height = size
	q.radial_segments = 8
	q.rings = 4
	p.mesh = q
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(color, 0.32)
	p.material_override = m
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	p.emitting = true
	return p


func _add_building_fx(b: Building) -> void:
	if not b.done or not SMOKE_SPOTS.has(b.type) or b.node.get_node_or_null("Smoke") != null:
		return
	var s := _smoke_puffs(b.node, SMOKE_SPOTS[b.type] * b.base_scale, 8, Color("#d8d4cc"), 9.0, 4.0, false)
	s.name = "Smoke"


func _dust_burst(pos: Vector3) -> void:
	var p := _smoke_puffs(self, pos + Vector3(0, 6, 0), 26, Color("#c8b48c"), 16.0, 1.4, true)
	get_tree().create_timer(2.5).timeout.connect(p.queue_free)


func _start_rain(seconds: float) -> void:
	rain_time = seconds
	if is_instance_valid(rain_node):
		rain_node.emitting = true


func _update_fx(delta: float, t_day: float) -> void:
	if rain_time > 0.0:
		rain_time -= delta
		rain_node.position = camera_target + Vector3(0, 650, 0)
		if rain_time <= 0.0:
			rain_node.emitting = false
	var night := 1.0 - smoothstep(0.0, 0.35, sin(t_day * PI))
	_window_mat().emission_energy_multiplier = night * 2.2
