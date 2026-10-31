extends Node3D

# الزيتون والحجر (Olive & Stone) v0.4 - colony survival prototype rooted in Palestine.
# A brand-new colony right after a disaster near Haifa: 5 survivors, a fire and two
# patched tents on a small levelled terrace. Nothing grows by itself - villagers walk
# to resource points, gather, and carry loads back. Experience unlocks buildings and
# building plots. Arabic, right-to-left interface.

const VERSION := "0.5.0"
const GRID := 48
const TILE_SIZE := 75.0
const START_POP := 5
const BASE_HOUSING := 6
const SAVE_PATH := "user://olive_stone_save.json"
const AUTOSAVE_PATH := "user://olive_stone_autosave.json"
const SETTINGS_PATH := "user://settings.cfg"
const SAVE_VERSION := 4
const WORLD_SEED := 987654
const SEA_COLOR := Color("#477f91")
const DAY_LENGTH := 12.0
const WALK_SPEED := 70.0
const FOOD_PER_VILLAGER := 1.0
const WATER_PER_VILLAGER := 1.2
const AUTOSAVE_EVERY := 120.0
const CAM_OFFSET := Vector3(1800, 2200, 2100)
const CAMP_CELL := Vector2i(15, 24)
const PLATEAU_R0 := 5.2
const PLATEAU_R1 := 7.6
const TRAIL_CELL := 26.0
const TRAIL_MAX := 900
const MAX_LEVEL := 5
const LEVEL_XP := [0.0, 60.0, 180.0, 400.0, 750.0]

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
const TEXT_SIZES := [0.9, 1.0, 1.12]
const TEXT_SIZE_AR := ["صغير", "متوسط", "كبير"]
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
	"Food": {"count": 5, "min": 6.0, "max": 9.5, "yield": 6.0, "time": 3.0, "amount": 160.0, "regen": 0.10, "infinite": false, "label": "تين وأعشاب برية"},
	"Water": {"count": 3, "min": 6.0, "max": 9.5, "yield": 7.0, "time": 2.0, "amount": 0.0, "regen": 0.0, "infinite": true, "label": "نبع"},
	"Wood": {"count": 6, "min": 6.0, "max": 10.5, "yield": 6.0, "time": 3.5, "amount": 220.0, "regen": 0.06, "infinite": false, "label": "صنوبر وخروب"},
	"Stone": {"count": 5, "min": 6.0, "max": 10.5, "yield": 5.0, "time": 4.0, "amount": 260.0, "regen": 0.0, "infinite": false, "label": "صخور كلسية"},
	"Scrap": {"count": 3, "min": 6.0, "max": 10.0, "yield": 4.0, "time": 4.0, "amount": 120.0, "regen": 0.0, "infinite": false, "label": "أنقاض قديمة"}
}

# Plot classes (footprints in world units) and the fixed plots of the terrace.
const PLOT_SIZES := {"S": Vector2(76, 76), "M": Vector2(124, 100), "L": Vector2(156, 116)}
const PLOT_AR := {"S": "صغيرة", "M": "متوسطة", "L": "كبيرة"}
# All plots unlocked from level 1 — building costs gate progression, not plot locks.
# zone: "home"=inner residential, "service"=mid ring, "production"=outer ring
const PLOTS := [
	{"x": -135.0, "z": 45.0, "cls": "S", "lv": 1, "zone": "home"},
	{"x": 135.0, "z": 45.0, "cls": "S", "lv": 1, "zone": "home"},
	{"x": -135.0, "z": 135.0, "cls": "S", "lv": 1, "zone": "home"},
	{"x": 135.0, "z": 135.0, "cls": "S", "lv": 1, "zone": "home"},
	{"x": -255.0, "z": -40.0, "cls": "M", "lv": 1, "zone": "service"},
	{"x": 255.0, "z": -40.0, "cls": "M", "lv": 1, "zone": "service"},
	{"x": 0.0, "z": 175.0, "cls": "M", "lv": 1, "zone": "service"},
	{"x": -200.0, "z": -200.0, "cls": "L", "lv": 1, "zone": "production"},
	{"x": 200.0, "z": -200.0, "cls": "L", "lv": 1, "zone": "production"},
	{"x": 0.0, "z": -235.0, "cls": "L", "lv": 1, "zone": "production"}
]
const ZONE_COLORS := {
	"home": Color("#6a9a5a", 0.35),
	"service": Color("#4a8aaa", 0.35),
	"production": Color("#aa8a4a", 0.35)
}
const ZONE_AR := {"home": "سكن", "service": "خدمة", "production": "إنتاج"}

const BUILDINGS := {
	"Tent": {
		"ar": "خيمة", "cls": "S", "lv": 1, "tab": "home", "cost": {"Wood": 12.0, "Scrap": 4.0},
		"time": 6.0, "housing": 3, "gather": {}, "storage": false, "xp": 20.0, "scale": 1.0,
		"desc": "مأوى مرتجل يتسع لـ3 ناجين."
	},
	"Well": {
		"ar": "بئر", "cls": "S", "lv": 1, "tab": "res", "cost": {"Stone": 16.0, "Wood": 8.0},
		"time": 10.0, "housing": 0, "storage": false, "xp": 25.0, "scale": 1.4,
		"gather": {"res": "Water", "yield": 6.0, "time": 4.0, "slots": 3},
		"desc": "ماء قريب لا ينضب (3 سقّائين)."
	},
	"Storehouse": {
		"ar": "مخزن", "cls": "M", "lv": 1, "tab": "serv", "cost": {"Wood": 22.0, "Stone": 8.0},
		"time": 10.0, "housing": 0, "gather": {}, "storage": true, "xp": 30.0, "scale": 1.75,
		"desc": "نقطة تسليم تقصّر رحلات الجمع."
	},
	"Farm": {
		"ar": "مزرعة", "cls": "L", "lv": 1, "tab": "res", "cost": {"Wood": 14.0, "Stone": 6.0},
		"time": 12.0, "housing": 0, "storage": false, "xp": 30.0, "scale": 2.05,
		"gather": {"res": "Food", "yield": 8.0, "time": 5.0, "slots": 2},
		"desc": "طعام لا ينضب بمحصول كبير (مزارعان)."
	},
	"Olive Grove": {
		"ar": "بستان زيتون", "cls": "L", "lv": 2, "tab": "res", "cost": {"Wood": 16.0, "Stone": 5.0},
		"time": 12.0, "housing": 0, "storage": false, "xp": 35.0, "scale": 2.1,
		"gather": {"res": "Food", "yield": 6.0, "time": 4.0, "slots": 3},
		"desc": "طعام لا ينضب بقطاف سريع (3 قطّافين)."
	},
	"Stone House": {
		"ar": "بيت حجري", "cls": "M", "lv": 2, "tab": "home", "cost": {"Wood": 20.0, "Stone": 22.0},
		"time": 16.0, "housing": 6, "gather": {}, "storage": false, "xp": 45.0, "scale": 1.9,
		"desc": "بيت من حجر القدس يتسع لـ6 ناجين."
	},
	"Pen": {
		"ar": "حظيرة", "cls": "S", "lv": 2, "tab": "res", "cost": {"Wood": 18.0, "Stone": 4.0},
		"time": 10.0, "housing": 0, "storage": false, "xp": 28.0, "scale": 1.3,
		"gather": {"res": "Food", "yield": 3.0, "time": 6.0, "slots": 1},
		"desc": "ماعز ودجاج — بيض ولحم يومي (راعٍ واحد)."
	},
	"Kitchen": {
		"ar": "مطبخ", "cls": "M", "lv": 2, "tab": "serv", "cost": {"Wood": 16.0, "Stone": 12.0, "Scrap": 5.0},
		"time": 12.0, "housing": 0, "storage": false, "xp": 35.0, "scale": 1.7,
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
		"gather": {"res": "Stone", "yield": 6.0, "time": 5.0, "slots": 3},
		"desc": "حجر لا ينضب (3 قلّاعين)."
	},
	"Workshop": {
		"ar": "ورشة", "cls": "M", "lv": 3, "tab": "serv", "cost": {"Wood": 20.0, "Stone": 14.0, "Scrap": 8.0},
		"time": 18.0, "housing": 0, "storage": false, "xp": 60.0, "scale": 1.9,
		"gather": {"res": "Scrap", "yield": 4.0, "time": 5.0, "slots": 2},
		"desc": "خردة لا تنضب: تفكيك وإصلاح (عاملان)."
	},
	"Diwan": {
		"ar": "الديوان", "cls": "L", "lv": 3, "tab": "serv", "cost": {"Stone": 35.0, "Wood": 20.0, "Dinar": 30.0},
		"time": 20.0, "housing": 0, "storage": false, "xp": 80.0, "scale": 2.2,
		"gather": {}, "council": true,
		"desc": "مجلس المستوطنة — يفعّل الضرائب والقرارات الجماعية."
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
	{"key": "day60", "text": "اصمد حتى اليوم 60."}
]

# UI palette
const C_PANEL := Color(0.09, 0.105, 0.075, 0.9)
const C_BORDER := Color("#8c7b4a")
const C_GOLD := Color("#e8c872")
const C_CREAM := Color("#f2e8cc")
const C_MUTED := Color("#b8ad8a")
const C_BTN := Color("#4d5e35")
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


class Plot:
	var idx := 0
	var cls := "S"
	var lv := 1
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
var ghost_plot := -1
var inspected: Building = null
var demolish_armed := false
var new_armed := false
var council_unlocked := false
var tax_level_idx := 0
var caravan_day := 0
var event_cooldown := 0
var kitchen_active := false
var pending_event := -1
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
	_toast("مرحبًا بك قرب حيفا. خمسة ناجين ونار وخيمتان: كل شيء يُجمع باليد.", 7.0)


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


# ---------------------------------------------------------------- plots (fixed building spots)

func _build_plots() -> void:
	plot_mats["locked"] = _mat_alpha(Color(0.3, 0.26, 0.2, 0.3))
	plot_mats["empty"] = _mat_alpha(Color(0.95, 0.89, 0.72, 0.4))
	plot_mats["target"] = _mat_alpha(Color(0.45, 0.9, 0.4, 0.6))
	plot_mats["chosen"] = _mat_alpha(Color(1.0, 0.85, 0.3, 0.75))
	for i in range(PLOTS.size()):
		var d: Dictionary = PLOTS[i]
		var p := Plot.new()
		p.idx = i
		p.cls = str(d["cls"])
		p.lv = int(d["lv"])
		p.size = PLOT_SIZES[p.cls]
		p.pos = Vector3(camp_pos.x + float(d["x"]), plateau_h, camp_pos.z + float(d["z"]))
		p.node = Node3D.new()
		p.node.position = p.pos
		building_root.add_child(p.node)
		p.slab = MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(p.size.x, 2.0, p.size.y)
		p.slab.mesh = bm
		p.slab.position = Vector3(0, 1.0, 0)
		p.node.add_child(p.slab)
		p.lock_label = Label3D.new()
		p.lock_label.font = ar_font
		p.lock_label.font_size = 26
		p.lock_label.pixel_size = 0.8
		p.lock_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		p.lock_label.outline_size = 8
		p.lock_label.modulate = Color(1, 0.95, 0.85, 0.9)
		p.lock_label.position = Vector3(0, 14, 0)
		p.node.add_child(p.lock_label)
		plots.append(p)
	_refresh_plots()


func _mat_alpha(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _plot_state(p: Plot) -> String:
	if p.building != null:
		return "built"
	if p.lv > level:
		return "locked" if selected_building != "" else "hidden"
	if selected_building != "":
		var def: Dictionary = BUILDINGS[selected_building]
		if str(def["cls"]) == p.cls:
			return "chosen" if p.idx == ghost_plot else "target"
	return "empty"


func _refresh_plots() -> void:
	for p in plots:
		var st := _plot_state(p)
		var zone_key: String = PLOTS[p.idx].get("zone", "home")
		if st == "built":
			p.slab.visible = true
			p.slab.material_override = _stone_mat(Color("#e2d6b8"))
			p.lock_label.visible = false
			continue
		p.slab.visible = st != "hidden"
		if st == "hidden":
			p.lock_label.visible = false
			continue
		if st == "empty":
			# Show zone color hint on empty plots
			var zc: Color = ZONE_COLORS.get(zone_key, Color(0.5, 0.5, 0.5, 0.3))
			p.slab.material_override = _unlit_mat(zc)
		else:
			p.slab.material_override = plot_mats[st]
		p.lock_label.visible = st == "locked"
		if st == "locked":
			p.lock_label.text = "منطقة %s" % ZONE_AR.get(zone_key, "")


func _plot_at_point(pt: Vector3, margin: float = 18.0) -> Plot:
	for p in plots:
		if absf(pt.x - p.pos.x) <= p.size.x * 0.5 + margin and absf(pt.z - p.pos.z) <= p.size.y * 0.5 + margin:
			return p
	return null


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
	var s := _style(C_PANEL, 20, C_BORDER, 2, 14)
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 3)
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
	_build_workers_sheet()
	_build_missions_sheet()
	_build_build_sheet()
	_build_dock()
	_build_place_bar()
	_build_inspect_bar()
	_build_pause_banner()
	_build_toast()
	_build_menu()
	_build_game_over()


func _build_top_bar() -> void:
	var top := _anchored_panel(Control.PRESET_TOP_WIDE)
	top.offset_left = 12
	top.offset_right = -12
	top.offset_top = 10
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	top.add_child(row)
	# settlement level badge (rightmost in RTL)
	var lvbox := HBoxContainer.new()
	lvbox.add_theme_constant_override("separation", 8)
	row.add_child(lvbox)
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(50, 50)
	badge.add_theme_stylebox_override("panel", _style(Color("#6b5a2a"), 25, C_GOLD, 2, 0))
	lvbox.add_child(badge)
	level_label = _label("1", 24, Color.WHITE)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(level_label)
	var lvcol := VBoxContainer.new()
	lvcol.add_theme_constant_override("separation", 2)
	lvcol.alignment = BoxContainer.ALIGNMENT_CENTER
	lvbox.add_child(lvcol)
	lvcol.add_child(_label("المخيم", 15, C_GOLD))
	xp_bar = _bar(C_GOLD, 70.0, 7.0)
	lvcol.add_child(xp_bar)
	for r in RES_TOP_BAR:
		row.add_child(_res_chip(r))
	var popc := VBoxContainer.new()
	popc.add_theme_constant_override("separation", -4)
	row.add_child(popc)
	popc.add_child(_label("السكان", 15, C_MUTED))
	pop_label = _label("5/6", 25, Color.WHITE)
	popc.add_child(pop_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)
	var dayc := VBoxContainer.new()
	dayc.add_theme_constant_override("separation", 2)
	dayc.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(dayc)
	day_label = _label("اليوم 1", 21, C_CREAM)
	dayc.add_child(day_label)
	day_bar = _bar(Color("#e9a24a"), 76.0, 6.0)
	dayc.add_child(day_bar)
	var pb := _icon_button("pause", _toggle_pause)
	pause_icon = pb.get_child(0)
	row.add_child(pb)
	speed_btn = _button("×1", _cycle_speed, Vector2(58, 52), 22)
	row.add_child(speed_btn)
	row.add_child(_icon_button("menu", _open_menu))


func _res_chip(res: String) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", -4)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 5)
	top.add_child(_dot(RES_COLORS[res], 11.0))
	top.add_child(_label(RES_AR[res], 15, C_MUTED))
	col.add_child(top)
	var v := _label("0", 25, Color.WHITE)
	col.add_child(v)
	res_value_labels[res] = v
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
	workers_sheet = _sheet(Control.PRESET_RIGHT_WIDE)
	workers_sheet.offset_left = -470
	workers_sheet.offset_right = -12
	workers_sheet.offset_top = 140
	workers_sheet.offset_bottom = -116
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	workers_sheet.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	scroll.add_child(box)
	box.add_child(_label("العمال", 28, C_GOLD))
	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 16)
	box.add_child(status)
	var mcol := VBoxContainer.new()
	mcol.add_child(_label("المعنويات", 15, C_MUTED))
	morale_bar = _bar(Color("#5aa0d0"), 150.0, 9.0)
	mcol.add_child(morale_bar)
	status.add_child(mcol)
	var hcol := VBoxContainer.new()
	hcol.add_child(_label("الصحة", 15, C_MUTED))
	health_bar = _bar(Color("#d0644a"), 150.0, 9.0)
	hcol.add_child(health_bar)
	status.add_child(hcol)
	var hope_col := VBoxContainer.new()
	hope_col.add_child(_label("الأمل", 15, C_MUTED))
	var hope_bar := _bar(Color("#7fc04f"), 150.0, 9.0)
	hope_bar.name = "HopeBar"
	hope_col.add_child(hope_bar)
	status.add_child(hope_col)
	var disc_col := VBoxContainer.new()
	disc_col.add_child(_label("السخط", 15, C_MUTED))
	var disc_bar := _bar(Color("#c04a3a"), 150.0, 9.0)
	disc_bar.name = "DiscontentBar"
	disc_col.add_child(disc_bar)
	status.add_child(disc_col)
	var hint := _label("اختر عدد من يجمع كل مورد. الأرقام الخضراء صافي الأمس.", 15, C_MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(380, 0)
	box.add_child(hint)
	for r in START_JOBS:
		box.add_child(_job_row(r))
	free_label = _label("", 19, Color("#cfe0a0"))
	box.add_child(free_label)
	var sep := HSeparator.new()
	box.add_child(sep)
	box.add_child(_label("الناجون", 22, C_GOLD))
	villager_list = VBoxContainer.new()
	villager_list.add_theme_constant_override("separation", 4)
	box.add_child(villager_list)


func _job_row(res: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(_dot(RES_COLORS[res], 14.0))
	var name_l := _label(RES_AR[res], 22)
	name_l.custom_minimum_size = Vector2(70, 0)
	row.add_child(name_l)
	var rate := _label("", 16, C_MUTED)
	rate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(rate)
	job_rate_labels[res] = rate
	row.add_child(_icon_button("plus", _change_job.bind(res, 1), 50.0))
	var cnt := _label("0", 25, Color.WHITE)
	cnt.custom_minimum_size = Vector2(34, 0)
	cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(cnt)
	job_count_labels[res] = cnt
	row.add_child(_icon_button("minus", _change_job.bind(res, -1), 50.0))
	return row


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
	cards_box = HBoxContainer.new()
	cards_box.add_theme_constant_override("separation", 10)
	box.add_child(cards_box)


func _build_dock() -> void:
	dock = _anchored_panel(Control.PRESET_CENTER_BOTTOM)
	dock.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dock.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dock.offset_bottom = -12
	dock.add_theme_stylebox_override("panel", _style(Color(0.09, 0.105, 0.075, 0.82), 26, C_BORDER, 2, 10))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	dock.add_child(row)
	row.add_child(_dock_button("build", "بناء", _toggle_sheet.bind("build")))
	row.add_child(_dock_button("workers", "العمال", _toggle_sheet.bind("workers")))
	row.add_child(_dock_button("missions", "المهام", _toggle_sheet.bind("missions")))


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


# ---------------------------------------------------------------- UI actions

func _hide_sheets() -> void:
	build_sheet.visible = false
	workers_sheet.visible = false
	missions_sheet.visible = false


func _toggle_sheet(which: String) -> void:
	var target: PanelContainer = build_sheet
	if which == "workers":
		target = workers_sheet
	elif which == "missions":
		target = missions_sheet
	var show := not target.visible
	_hide_sheets()
	_close_inspect()
	target.visible = show
	if show and which == "workers":
		workers_opened = true
	if show and which == "build":
		_rebuild_cards()
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
	b.custom_minimum_size = Vector2(210, 170)
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
	vb.add_child(_label("قطعة %s" % PLOT_AR[str(def["cls"])], 14, C_MUTED))
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
	for r in RES_TOP_BAR:
		var vl: Label = res_value_labels[r]
		vl.text = str(int(round(float(resources.get(r, 0.0)))))
	pop_label.text = "%d/%d" % [survivors.size(), _housing_capacity()]
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
	_add_xp(amt * 0.1)
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

func _eligible_plots(bname: String) -> Array[Plot]:
	var def: Dictionary = BUILDINGS[bname]
	var out: Array[Plot] = []
	for p in plots:
		if p.building == null and p.lv <= level and p.cls == str(def["cls"]):
			out.append(p)
	return out


func _start_placing(bname: String) -> void:
	var def: Dictionary = BUILDINGS[bname]
	var free_plots := _eligible_plots(bname)
	if free_plots.is_empty():
		_toast("لا توجد قطعة أرض %s فارغة. ارتقِ بالمخيم لفتح المزيد أو اهدم مبنى." % PLOT_AR[str(def["cls"])], 5.0)
		return
	_hide_sheets()
	_close_inspect()
	selected_building = bname
	dock.visible = false
	place_bar.visible = true
	var best: Plot = free_plots[0]
	var best_d := INF
	for p in free_plots:
		var d := _flat_dist(p.pos, camera_target)
		if d < best_d:
			best_d = d
			best = p
	_set_ghost_plot(best.idx)


func _set_ghost_plot(idx: int) -> void:
	ghost_plot = idx
	var p: Plot = plots[idx]
	var def: Dictionary = BUILDINGS[selected_building]
	var bm: BoxMesh = ghost_mesh.mesh
	bm.size = Vector3(p.size.x * 0.82, 34.0, p.size.y * 0.82)
	ghost_mesh.position = Vector3(0, 19, 0)
	ghost.position = p.pos
	ghost.visible = true
	_refresh_plots()
	place_label.text = "%s — %s\nالمس قطعة خضراء لاختيار المكان." % [def["ar"], _cost_text(def["cost"])]


func _cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for r in cost:
		parts.append("%s %d" % [RES_AR[r], int(cost[r])])
	return "، ".join(parts)


func _cancel_placement() -> void:
	selected_building = ""
	ghost_plot = -1
	if is_instance_valid(ghost):
		ghost.visible = false
	if is_instance_valid(place_bar):
		place_bar.visible = false
		if inspected == null:
			dock.visible = true
	_refresh_plots()


func _confirm_build() -> void:
	if selected_building == "" or ghost_plot < 0:
		return
	var p: Plot = plots[ghost_plot]
	if p.building != null:
		return
	var def: Dictionary = BUILDINGS[selected_building]
	var cost: Dictionary = def["cost"]
	var missing := _missing_resource(cost)
	if missing != "":
		_toast("ينقصك %s." % RES_AR[missing])
		return
	for r in cost:
		resources[r] = float(resources[r]) - float(cost[r])
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


func _close_inspect() -> void:
	inspected = null
	demolish_armed = false
	if is_instance_valid(inspect_bar):
		inspect_bar.visible = false
		if selected_building == "":
			dock.visible = true


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
	plots[b.plot].building = null
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

	# Kitchen reduces food consumption by 25% if built
	var food_mul := 0.75 if kitchen_active else 1.0
	resources["Food"] = float(resources["Food"]) - n * FOOD_PER_VILLAGER * food_mul
	resources["Water"] = float(resources["Water"]) - n * WATER_PER_VILLAGER
	var shortage := float(resources["Food"]) < 0.0 or float(resources["Water"]) < 0.0
	for r in RES_NAMES:
		resources[r] = maxf(0.0, float(resources[r]))
	last_income = income_today.duplicate()
	for r in income_today:
		income_today[r] = 0.0

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

	if shortage:
		health = maxf(0.0, health - 8.0)
		morale = maxf(0.0, morale - 8.0)
		hope = maxf(0.0, hope - 5.0)
		discontent = minf(100.0, discontent + 4.0)
		_toast("نقص في المؤن! ضع عمالًا أكثر على الطعام والماء.", 5.0)
		if health <= 0.0:
			_remove_villager()
			_remove_villager()
		elif health <= 25.0:
			_remove_villager()
	else:
		morale = minf(100.0, morale + 1.5)
		health = minf(100.0, health + 2.0 + float(medics))
		hope = minf(100.0, hope + 1.0)
		discontent = maxf(0.0, discontent - 0.5)
		_add_xp(3.0)

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
	if day % 3 == 0 and _housing_capacity() > survivors.size() and morale > 45.0 and fed and not shortage:
		var v := _add_villager(NAMES[survivors.size() % NAMES.size()], SKILLS[rng.randi() % SKILLS.size()])
		_add_xp(15.0)
		_toast("وصل ناجٍ جديد: %s (%s). امنحه عملًا." % [v.vname, SKILL_AR[v.skill]], 5.0)
	elif day % 3 == 0 and _housing_capacity() <= survivors.size():
		_toast("ناجون يطلبون اللجوء، لكن لا مأوى. ابنِ خيمة.", 4.0)
	peak_pop = maxi(peak_pop, survivors.size())
	_check_goals()
	_assign_tasks()
	_refresh_ui()


func _trigger_caravan() -> void:
	var msg := "وصلت القافلة! يمكنك بيع الزيت أو شراء الخشب."
	_toast(msg, 6.0)
	# Simple auto-trade: sell Oil if we have surplus
	var oil := float(resources.get("Oil", 0.0))
	if oil >= 10.0:
		var earned := floorf(oil * 0.5) * 2.0
		resources["Oil"] = oil - floorf(oil * 0.5)
		resources["Dinar"] = float(resources["Dinar"]) + earned
		_toast("باعت القافلة %d وحدة زيت بـ%d دينار." % [int(floorf(oil * 0.5)), int(earned)], 5.0)
		_add_xp(10.0)


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
		_apply_moral_effect(eff_a)
		layer.queue_free()
	)
	btn_b.pressed.connect(func():
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
	if selected_building != "":
		var def: Dictionary = BUILDINGS[selected_building]
		var p := _plot_at_point(hp)
		if p != null and p.building == null and p.lv <= level and p.cls == str(def["cls"]):
			_set_ghost_plot(p.idx)
		elif p != null and p.lv > level:
			_toast("هذه القطعة تُفتح في المستوى %d." % p.lv)
		elif p != null and p.cls != str(def["cls"]):
			_toast("«%s» يحتاج قطعة %s." % [def["ar"], PLOT_AR[str(def["cls"])]])
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
	if p2 != null:
		if p2.building != null:
			_inspect_building(p2.building)
		elif p2.lv > level:
			_toast("قطعة أرض %s تُفتح في المستوى %d." % [PLOT_AR[p2.cls], p2.lv])
		else:
			_toast("قطعة أرض %s فارغة. اضغط «بناء» لاختيار مبنى." % PLOT_AR[p2.cls])
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
		blist.append({"type": b.type, "plot": b.plot, "progress": b.progress, "done": b.done})
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
		"goal": goal_index, "peak": peak_pop, "level": level, "xp": xp,
		"workers_opened": workers_opened, "buildings": blist, "villagers": vlist, "sources": amounts
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
	if str(d.get("region", "")) != "Haifa" or int(d.get("version", 0)) < SAVE_VERSION:
		_toast("هذا الحفظ من إصدار أقدم ولا يمكن تحميله.")
		return
	_cancel_placement()
	_close_inspect()
	for b in buildings:
		b.node.queue_free()
	buildings.clear()
	for p in plots:
		p.building = null
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
	goal_index = clampi(int(d.get("goal", 0)), 0, GOALS.size())
	peak_pop = int(d.get("peak", START_POP))
	level = clampi(int(d.get("level", 1)), 1, MAX_LEVEL)
	xp = float(d.get("xp", 0.0))
	workers_opened = bool(d.get("workers_opened", false))
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
		var pi := int(ed.get("plot", -1))
		if not BUILDINGS.has(t) or pi < 0 or pi >= plots.size() or plots[pi].building != null:
			continue
		_spawn_building(t, pi, float(ed.get("progress", 1.0)), bool(ed.get("done", true)))
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
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -35, 0)
	sun.light_energy = 1.15
	add_child(sun)
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#9cc3d5")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#b9c6c2")
	environment.ambient_light_energy = 0.75
	env.environment = environment
	add_child(env)

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

func _unhandled_input(event: InputEvent) -> void:
	if menu_open or game_over:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			touches[event.index] = event.position
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
