extends RefCounted
class_name DialogueM01M05
## Bilingual dialogue nodes for campaign missions M01–M05.
## Each line: {"ru": str, "en": str}. Choices include id + optional next.


static func get_node(node_id: String) -> Dictionary:
	return catalog().get(node_id, {})


static func catalog() -> Dictionary:
	var d: Dictionary = {}
	_m01(d)
	_m02(d)
	_m03(d)
	_m04(d)
	_m05(d)
	_revisit(d)
	return d


static func _line(ru: String, en: String) -> Dictionary:
	return {"ru": ru, "en": en}


static func _m01(d: Dictionary) -> void:
	d["m01_quinn_intro"] = {
		"speaker": "sera_quinn",
		"text": _line(
			"Залог живой. Проверь буй Аурелия-A3, привези чистый скан — и я поставлю первый рабочий штамп.",
			"The lien is live. Check buoy Aurelia-A3, bring me a clean scan — and I file your first work stamp."
		),
		"choices": [
			{"id": "ask_debt", "text": _line("Насколько глубокий долг?", "How deep is the debt?"), "next": "m01_quinn_debt"},
			{"id": "just_coords", "text": _line("Просто дайте координаты.", "Just give the coordinates."), "next": "m01_quinn_coords"},
			{"id": "refuse", "text": _line("А если откажусь?", "What if I refuse?"), "next": "m01_quinn_refuse"},
		],
	}
	d["m01_quinn_debt"] = {
		"speaker": "sera_quinn",
		"text": _line(
			"Достаточно, чтобы зажимы остались на корпусе. Недостаточно, чтобы вас списать. Летите.",
			"Deep enough that the clamps stay on the hull. Not enough to write you off. Fly."
		),
		"choices": [{"id": "accept", "text": _line("Принято.", "Understood."), "next": ""}],
	}
	d["m01_quinn_coords"] = {
		"speaker": "sera_quinn",
		"text": _line("На вашей доске. И не геройствуйте — мне нужен скан, не обломки.", "On your board. And don’t play hero — I need a scan, not wreckage."),
		"choices": [{"id": "accept", "text": _line("Вылетаю.", "Launching."), "next": ""}],
	}
	d["m01_quinn_refuse"] = {
		"speaker": "sera_quinn",
		"text": _line("Тогда зажимы остаются. Добро пожаловать в Аурелию — с парковки.", "Then the clamps stay. Welcome to Aurelia — from the parking cradle."),
		"choices": [{"id": "accept", "text": _line("…Ладно. Лечу.", "…Fine. I’m flying."), "next": ""}],
	}
	d["m01_quinn_complete"] = {
		"speaker": "sera_quinn",
		"text": _line("Скан чистый. Штамп ваш. Доска контрактов открыта — пока только нижний ярус.", "Scan is clean. Stamp is yours. Contract board is open — bottom tier only."),
		"choices": [],
	}


static func _m02(d: Dictionary) -> void:
	d["m02_jex_radio"] = {
		"speaker": "jex_morra",
		"text": _line(
			"Слышу новый позывной в Веспере. Три узла обломков, пакет на мой сброс — и будет лицензия на Salvage-доску.",
			"New callsign in Vesper. Three debris nodes, package to my drop — and you get the Salvage board license."
		),
		"choices": [
			{"id": "ask_pay", "text": _line("Оплата?", "Pay?"), "next": "m02_jex_pay"},
			{"id": "ask_risk", "text": _line("Кто ещё на частоте?", "Who else is on frequency?"), "next": "m02_jex_risk"},
			{"id": "accept", "text": _line("Принял маршрут.", "Route accepted."), "next": ""},
		],
	}
	d["m02_jex_pay"] = {
		"speaker": "jex_morra",
		"text": _line("Честно для первого захода. Врёте скану — платите штрафом пояса, не мне.", "Fair for a first run. Lie to the scan and the Belt fines you, not me."),
		"choices": [{"id": "accept", "text": _line("Понял.", "Got it."), "next": ""}],
	}
	d["m02_jex_risk"] = {
		"speaker": "jex_morra",
		"text": _line("Стервятники. Иногда Helix. Стреляете первыми по нейтралам — я вас не прикрываю.", "Scavengers. Sometimes Helix. Fire first on neutrals and I don’t cover you."),
		"choices": [{"id": "accept", "text": _line("Без лишнего огня.", "No extra fire."), "next": ""}],
	}
	d["m02_jex_complete"] = {
		"speaker": "jex_morra",
		"text": _line("Пакет на месте. Vesper Salvage открыт. Не благодарите — просто не умирайте на моём маршруте.", "Package received. Vesper Salvage is open. Don’t thank me — just don’t die on my route."),
		"choices": [],
	}


static func _m03(d: Dictionary) -> void:
	d["m03_quinn_tag"] = {
		"speaker": "sera_quinn",
		"text": _line(
			"В метаданных утиля — личный тег. Ellis Hale. Это к вам близко?",
			"Salvage metadata carries a personal tag. Ellis Hale. Close to you?"
		),
		"choices": [
			{"id": "yes", "text": _line("Да. Очень.", "Yes. Very."), "next": "m03_quinn_yes"},
			{"id": "maybe", "text": _line("Возможно. Нужна проверка.", "Maybe. Needs verification."), "next": "m03_quinn_yes"},
			{"id": "deflect", "text": _line("Покажите данные учёному.", "Show the data to a scientist."), "next": "m03_nyra"},
		],
	}
	d["m03_quinn_yes"] = {
		"speaker": "sera_quinn",
		"text": _line("Тогда к Доктору Сол. И подумайте, кому ещё покажете — Helix и Союз уже нюхают пояс.", "Then see Doctor Sol. And think who else you show — Helix and the Union are already sniffing the Belt."),
		"choices": [{"id": "to_nyra", "text": _line("Иду к Нире.", "Going to Nyra."), "next": "m03_nyra"}],
	}
	d["m03_nyra"] = {
		"speaker": "nyra_sol",
		"text": _line(
			"Тег настоящий. Сигнатура рядом с паттернами Silent Relay. Вы можете продать след Helix, сдать Союзу — или оставить мне.",
			"The tag is genuine. Signature sits near Silent Relay patterns. You can sell the trail to Helix, hand it to the Union — or leave it with me."
		),
		"choices": [
			{"id": "share_helix", "text": _line("Продаю Helix.", "Sell to Helix."), "next": "m03_helix"},
			{"id": "share_union", "text": _line("Сдаю Союзу.", "Hand to the Union."), "next": "m03_union"},
			{"id": "keep_private", "text": _line("Оставляю вам. Без корпораций.", "Leave it with you. No corporations."), "next": "m03_private"},
		],
	}
	d["m03_helix"] = {
		"speaker": "helene_voss",
		"text": _line("Разумный выбор. Helix умеет платить… и помнить, кто торгует вовремя.", "A rational choice. Helix pays well… and remembers who trades on time."),
		"choices": [],
	}
	d["m03_union"] = {
		"speaker": "kade_vorn",
		"text": _line("Официально принято. Неофициально — спасибо. В Кестреле с вами будут говорить мягче.", "Logged officially. Unofficially — thank you. In Kestrel they’ll speak softer to you."),
		"choices": [],
	}
	d["m03_private"] = {
		"speaker": "nyra_sol",
		"text": _line("Тогда работаем тихо. Это медленнее. И честнее по отношению к тем, кого ищете.", "Then we work quiet. Slower. And fairer to whoever you’re hunting."),
		"choices": [],
	}


static func _m04(d: Dictionary) -> void:
	d["m04_vorn_brief"] = {
		"speaker": "kade_vorn",
		"text": _line(
			"Kestrel Patrol не платит за изящество. Караван до точки передачи. Фрахт жив — вы на доске Патруля.",
			"Kestrel Patrol doesn’t pay for elegance. Convoy to handoff. Freighter lives — you’re on the Patrol board."
		),
		"choices": [
			{"id": "who", "text": _line("Кто бьёт караваны?", "Who’s hitting convoys?"), "next": "m04_vorn_who"},
			{"id": "copy", "text": _line("Принято.", "Copy."), "next": ""},
			{"id": "politics", "text": _line("Это политика Союза.", "This is Union politics."), "next": "m04_vorn_politics"},
		],
	}
	d["m04_vorn_who"] = {
		"speaker": "kade_vorn",
		"text": _line("Перехватчики без нашивок. Иногда — слишком хорошо вооружённые «свободные».", "Unmarked interdictors. Sometimes — very well-armed “free” captains."),
		"choices": [{"id": "copy", "text": _line("Держу фрахт.", "Holding the freighter."), "next": ""}],
	}
	d["m04_vorn_politics"] = {
		"speaker": "kade_vorn",
		"text": _line("Всё здесь политика. Сегодня ваша работа — один корпус в целости.", "Everything here is politics. Today your job is one hull intact."),
		"choices": [{"id": "copy", "text": _line("Работаю.", "On it."), "next": ""}],
	}
	d["m04_vorn_complete"] = {
		"speaker": "kade_vorn",
		"text": _line("Фрахт на базе. Kestrel Patrol открыт. Не подведите доску — подведёте людей на палубах.", "Freighter docked. Kestrel Patrol is open. Fail the board and you fail people on those decks."),
		"choices": [],
	}


static func _m05(d: Dictionary) -> void:
	d["m05_nyra_approach"] = {
		"speaker": "nyra_sol",
		"text": _line(
			"Внешняя кромка Silent Relay. Сканируйте импульс. Не геройствуйте, если небо начнёт отвечать.",
			"Outer edge of Silent Relay. Scan the pulse. Don’t play hero if the sky starts answering."
		),
		"choices": [
			{"id": "ready", "text": _line("На позиции.", "In position."), "next": ""},
			{"id": "fear", "text": _line("Что именно «отвечает»?", "What exactly ‘answers’?"), "next": "m05_nyra_fear"},
		],
	}
	d["m05_nyra_fear"] = {
		"speaker": "nyra_sol",
		"text": _line("Не люди. Не наш протокол. Держите курс и пишите лог.", "Not people. Not our protocol. Hold course and keep a log."),
		"choices": [{"id": "ready", "text": _line("Держу.", "Holding."), "next": ""}],
	}
	d["m05_pulse"] = {
		"speaker": "narrator",
		"text": _line(
			"Реле отвечает координатами в глубине Веспера. Это не открытые Врата — это след.",
			"The Relay answers with coordinates deep in Vesper. Not an open Gate — a trail."
		),
		"choices": [],
	}
	d["m05_complete"] = {
		"speaker": "nyra_sol",
		"text": _line(
			"Акт разведки закончен. Дальше — пояс, корпорации и те, кто хочет заставить Реле замолчать. Готовьтесь.",
			"Recon act complete. Next comes the Belt, corporations, and those who want the Relay silent. Prepare."
		),
		"choices": [],
	}


static func _revisit(d: Dictionary) -> void:
	d["revisit_quinn_after_m01"] = {
		"speaker": "sera_quinn",
		"text": _line("Штамп уже ваш. Не стойте в дверях — берите работу с доски.", "You already have the stamp. Don’t block the door — take work off the board."),
		"choices": [],
	}
	d["revisit_quinn_after_m03_helix"] = {
		"speaker": "sera_quinn",
		"text": _line("Helix улыбается вам. Я бы не расслаблялась.", "Helix is smiling at you. I wouldn’t relax."),
		"choices": [],
	}
	d["revisit_quinn_after_m03_private"] = {
		"speaker": "sera_quinn",
		"text": _line("Тихий путь. Уважаемо. И опаснее, чем кажется.", "The quiet path. Respectable. And more dangerous than it looks."),
		"choices": [],
	}
	d["revisit_jex_after_m02"] = {
		"speaker": "jex_morra",
		"text": _line("Доска Salvage не кормит разговорами. Берите метку.", "The Salvage board doesn’t feed talk. Take a mark."),
		"choices": [],
	}
