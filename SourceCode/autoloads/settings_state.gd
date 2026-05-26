extends Node

signal language_changed(language_code: String)

const LANGUAGE_KO := "ko"
const LANGUAGE_EN := "en"
const SETTINGS_PATH := "user://settings.json"
const LANGUAGE_NAMES := {
	LANGUAGE_KO: "한국어",
	LANGUAGE_EN: "English",
}
const STRINGS := {
	LANGUAGE_KO: {
		"main_title": "폐허의 길",
		"main_subtitle": "멸망해가는 판타지 세계를 지나는 생존 덱빌딩",
		"main_hook": "증표, 무너진 길, 마지막 계약.",
		"main_summary": "첫 계약은 야영지에서 시작된다. 성채는 부서진 길 너머에 있다.",
		"main_new_run": "새 여정",
		"main_continue": "이어하기",
		"main_settings": "설정",
		"main_quit": "종료",
		"main_saved_contract": "이어갈 계약이 남아 있습니다.",
		"main_no_contract": "진행 중인 계약이 없습니다. 새 여정을 시작하세요.",
		"main_records_missing": "일부 계약 기록을 읽지 못했습니다. 빌드를 다시 시작해 주세요.",
		"main_save_load_failed": "저장된 계약을 불러오지 못했습니다.",
		"settings_title": "설정",
		"settings_language": "언어",
		"settings_language_hint": "화면 언어는 즉시 적용되고 다음 실행에도 유지됩니다.",
		"settings_back": "뒤로",
	},
	LANGUAGE_EN: {
		"main_title": "The Ruined Road",
		"main_subtitle": "Survival deckbuilding through a dying fantasy world",
		"main_hook": "Blood Tags. Broken Roads. One Contract Left.",
		"main_summary": "The first contract begins at the camp. The keep waits beyond the broken route.",
		"main_new_run": "New Run",
		"main_continue": "Continue",
		"main_settings": "Settings",
		"main_quit": "Quit",
		"main_saved_contract": "A saved contract waits.",
		"main_no_contract": "No active contract. Start a new run.",
		"main_records_missing": "Some contract records are missing. Please restart the build.",
		"main_save_load_failed": "Could not load save snapshot.",
		"settings_title": "Settings",
		"settings_language": "Language",
		"settings_language_hint": "Screen language changes immediately and is kept for the next launch.",
		"settings_back": "Back",
	},
}

var language_code := LANGUAGE_KO


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	language_code = LANGUAGE_KO
	if FileAccess.file_exists(SETTINGS_PATH):
		var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				language_code = _normalize_language(String(parsed.get("language", LANGUAGE_KO)))
	TranslationServer.set_locale(language_code)


func set_language(code: String) -> void:
	var normalized := _normalize_language(code)
	if normalized == language_code:
		return
	language_code = normalized
	TranslationServer.set_locale(language_code)
	_save_settings()
	language_changed.emit(language_code)


func text(key: String) -> String:
	var language_strings: Dictionary = STRINGS.get(language_code, STRINGS[LANGUAGE_KO])
	if language_strings.has(key):
		return String(language_strings[key])
	var fallback: Dictionary = STRINGS[LANGUAGE_EN]
	return String(fallback.get(key, key))


func language_name(code: String) -> String:
	return String(LANGUAGE_NAMES.get(_normalize_language(code), code))


func is_korean() -> bool:
	return language_code == LANGUAGE_KO


func _save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save settings to %s" % SETTINGS_PATH)
		return
	file.store_string(JSON.stringify({"language": language_code}, "\t"))


func _normalize_language(code: String) -> String:
	var normalized := code.strip_edges().to_lower()
	if normalized.begins_with("en"):
		return LANGUAGE_EN
	return LANGUAGE_KO
