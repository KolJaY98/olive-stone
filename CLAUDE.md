# CLAUDE.md — Olive & Stone (الزيتون والحجر)

Handover from a long claude.ai chat (Oct 2026). Read fully before doing anything.

## 1. Owner & how to work with him
- Owner: Jeff (General Surgery resident, Palestinian, lives in Saudi Arabia). **Not an experienced game developer.**
- **Always reply in Modern Standard Arabic (الفصحى)**, concise, no filler. Code, file names and commands stay in English.
- Wants a direct, honest advisor: no flattery, challenge weak assumptions, point out risks and trade-offs, give a prioritized plan.
- One step at a time; tell him exactly where to click / what to type.
- **Never claim something was tested unless you actually tested it.** Always distinguish: export succeeded / APK installed / game launched / gameplay verified.
- Don't change random settings speculatively — find the cause first.
- Agree on design changes with him before big rewrites; he likes to discuss, then says "توكل على الله" to start.

## 2. Project
Android colony-survival game set in Palestine, starting near Haifa after a disaster. Inspiration: Whiteout Survival (compact city, fixed plots, unlocks by progression, survival pressure), but offline single-player.
- Engine: **Godot 4.3 stable**, renderer **GL Compatibility**, isometric 3D (orthographic camera).
- Target: Android, arm64-v8a, debug APK (non-gradle export, export templates).
- Repo: https://github.com/KolJaY98/olive-stone (branch `main`).
- Hardware: 2019 16" MacBook Pro (Intel i7) + Android phone. Until now he worked phone-only.

## 3. Repository layout (this handover)
```
project.godot            # app name Arabic, stretch canvas_items + aspect expand, landscape(sensor), ETC2/ASTC ON, text-server data ON
export_presets.cfg       # preset "Android", non-gradle, arm64 only, launcher icons set, version 0.4.0
scripts/main.gd          # the whole game (~2.8k lines, single file)
scenes/main.tscn         # Node3D root with main.gd
fonts/Cairo.ttf, OFL.txt # Arabic font (SIL OFL)
icon.png, icons/         # launcher icons (legacy 192 + adaptive fg/bg 432): Jerusalem-stone arch + olive branch + Haifa sunset
tools/test_logic.gd      # headless logic test (economy, plots, unlocks, demolish, save/load, game over)
tools/screenshot.gd      # renders screenshots (needs GPU/display)
.github/workflows/android-apk.yml  # CI build (see §5)
```
History: the repo currently stores the project as `olive_stone_project.zip` at repo root because the owner could only upload from his phone. **First migration task:** commit the project files unpacked at repo root and change CI to build from the root (remove the unzip step). Do this in one PR-sized change and verify CI goes green.

## 4. Local build on the Mac (goal of the first session)
1. Check macOS ≥ 13 (Claude Code requirement).
2. Install: Godot 4.3 stable (macOS universal), JDK 17 (e.g. Temurin), Android command-line tools; with `sdkmanager`: `platform-tools`, `build-tools;34.0.0`, `platforms;android-34`, `cmdline-tools;latest`. (NDK not needed: non-gradle export.)
3. Export templates 4.3.stable → `~/Library/Application Support/Godot/export_templates/4.3.stable/` (unzip the .tpz; contents of its `templates/` folder go there).
4. Debug keystore: `keytool -genkeypair -v -keystore ~/.android/debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"`
5. Editor settings → `~/Library/Application Support/Godot/editor_settings-4.tres` with `export/android/java_sdk_path`, `export/android/android_sdk_path`, `export/android/debug_keystore`, `debug_keystore_user=androiddebugkey`, `debug_keystore_pass=android`.
6. `godot --headless --path . --import` then `godot --headless --path . --export-debug "Android" build/olive_stone_debug.apk`
7. Phone: enable Developer options + USB debugging → `adb install -r build/olive_stone_debug.apk` → launch → `adb exec-out screencap -p > shot.png` to see the real device screen. `adb logcat -s godot` for runtime errors.
- Signature note: Android refuses to update an app signed with a different key. CI caches its own keystore (`actions/cache`, key `debug-keystore-v1`); a locally built APK has a different signature → uninstall once when switching between CI and local builds.

## 5. CI (GitHub Actions) — works since v0.3.0
ubuntu-22.04, Temurin 17, sdkmanager packages above, downloads Godot 4.3 + templates from GitHub releases, cached debug keystore, writes `~/.config/godot/editor_settings-4.tres`, imports, exports, uploads artifact `olive-stone-debug-apk`; `version/code` = `github.run_number`.
Root causes found earlier (don't repeat): the blank "Cannot export project with preset Android due to configuration errors:" came from **missing `textures/vram_compression/import_etc2_astc=true`**; earlier also missing export templates and Android SDK path in headless editor settings.

## 6. Game design — current state v0.4.0 (verified by headless tests + rendered screenshots, NOT yet played on the phone)
- Start: 5 survivors (skills Medicine/Farming/Construction/Gathering/Engineering), fire, 2 patched tents (base housing 6), ruins of the old town around a **levelled terrace** (plateau radius 5.2 cells, blend to 7.6; tile = 75 units). No roads; **dirt trails appear where villagers walk a lot** (MultiMesh patches).
- **No passive income.** Villagers walk to resource points, gather, carry (coloured cube over head) to the camp or a Storehouse; only delivery adds resources (+N popup). Natural points: food/wood regrow slowly, stone/scrap finite, springs infinite. Built gathering buildings are infinite points close to home with worker slots.
- Consumption per villager/day: food 1.0, water 1.2. Day = 12 s. Start resources: food 50, water 60, wood 60, stone 40, scrap 20. Default jobs: food 2, water 2, wood 1.
- Jobs panel ("العمال"): +/- per resource; builders (max 2 per site) are taken from idle villagers, else from gatherers not carrying.
- **Settlement level 1–5** (XP thresholds 0/60/180/400/750). XP from deliveries (0.1/unit), completed buildings, surviving days (+3), newcomers (+15), goals (+15). Levels unlock building types and plots.
- **10 fixed plots** around the fire, 3 sizes: S 76×76, M 124×100, L 156×116 (no overlaps, all on flat ground). Plot unlock levels: S1,S1,S2,S2, M2,M3,M3, L2,L3,L4.
- Buildings (cls / unlock level / housing or gather): Tent S/1 housing 3 · Well S/1 water · Storehouse M/2 drop-off · Farm L/2 food · Olive Grove L/3 food · Stone House M/3 housing 6 · Quarry L/4 stone · Workshop M/4 scrap. Construction time with scaffold + progress label; demolish refunds 50% (two-tap confirm).
- Look: makeshift early buildings (tent, wooden well frame) → **Jerusalem stone** (procedural ashlar texture, triplanar) with domes, round arches, parapets, terraces. Story: restoration of what the disaster destroyed.
- Newcomers every 3 days if housing free, morale > 45 and ≥3 days of food+water. Shortage → health/morale fall → villagers leave → 0 villagers = game over screen.
- Goals: open Workers → Well → Tent → level 2 → Farm → Storehouse → 10 survivors → day 30.
- Saves: manual `user://olive_stone_save.json`, autosave every 120 s and on app pause `user://olive_stone_autosave.json`, SAVE_VERSION 4 (older saves rejected). Settings (text size 0.9/1.0/1.12 via `content_scale_factor`) in `user://settings.cfg`.
- UI: **Arabic, RTL** (`layout_direction = RTL`; note: anchor presets are mirrored in RTL), Cairo font everywhere incl. Label3D. Top bar: level badge+XP, 5 resources, population, day, pause/speed/menu icon buttons. Goal banner. Bottom dock: بناء / العمال / المهام. Sheets open on demand; place bar (confirm/cancel) and inspect bar (demolish/close). Icons are drawn in code (`IconCanvas`). Number popups use LTR direction.
- Input: one-finger drag pans, tap selects, two-finger pinch zooms (manual touch tracking; `emulate_mouse_from_touch` default ON so GUI works), mouse wheel/right-drag on desktop. Camera ortho size 700 (300–1800), pan limited to 1100 units around camp.

## 7. Code notes (scripts/main.gd)
Inner classes: `Building`, `Plot`, `Source`, `Villager`, `IconCanvas`. Data tables at top: `BUILDINGS`, `PLOTS`, `PLOT_SIZES`, `SOURCE_DEFS`, `GOALS`, Arabic name maps (`RES_AR`, `SKILL_AR`, `NAMES`). Sections: terrain (`_natural_height`, `_terrain_height` plateau blend, `_height_at_world`), world building, plots, trails, sources, models (`_make_building_model`), UI (`_build_*`, `_refresh_ui`), villager AI (`_assign_tasks`, `_tick_gather`, `_move`), placing (`_start_placing`, `_set_ghost_plot`, `_confirm_build`), days (`_advance_day`), input (`_unhandled_input`, `_on_tap`, `_ray_to_terrain` = ray-march against the height grid, no physics), save/load.
Lessons: GDScript `:=` from Variant is a parse error (type explicitly). Stray partial `.gd` files inside the project folder get parsed on import and print errors. The single file is getting big — a split into several scripts is reasonable, but do it as its own change, with tests passing before/after.

Testing: `godot --headless --path . --script tools/test_logic.gd` (prints numbers; read them critically). Visuals: `godot --path . --resolution 1280x720 --script tools/screenshot.gd`, then look at the images. Best: real phone via adb.

## 8. Open items / not verified
- Not yet played on the phone: touch feel, pinch zoom, performance, readability of Arabic text on device, economy pacing.
- Visuals are primitive meshes (better than before, not professional). Pending decision: use free CC0 low-poly assets (e.g. Kenney, Quaternius) — check licenses, keep a credits file.
- Trails look blocky.

## 9. Roadmap (agreed order; confirm with the owner before starting each)
1. Get local build + adb install working; migrate repo off the zip; owner plays v0.4 and gives feedback; fix what he reports.
2. Building upgrades (levels per building, visual growth, a central building "الديوان" gating progress) + longer mission chain.
3. Survival pressure: seasons (hot dry summer → more water use; rainy winter → shelter/heating, illness).
4. Paved stone roads as an unlock (faster walking), random events (drought, refugees, ruins discovered), sound/music (licensed assets only).
5. Later: expansion map, trade/diplomacy (from the original concept).
