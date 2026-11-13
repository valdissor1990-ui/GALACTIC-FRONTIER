# GALACTIC FRONTIER — REPOSITORY AUDIT BASELINE
Дата: 2026-11-13
Ветка документа: chatgpt/repository-completion-master-2026-11

> Это начальный снимок аудита по текущему дереву и метаданным GitHub. Он не является заявлением о полном runtime/визуальном тестировании. Статусы ниже уточняются по мере прохождения CI и чтения исходников.

## 1. Репозиторий и структура

- Репозиторий: valdissor1990-ui/GALACTIC-FRONTIER.
- Default branch: main.
- Движок/язык по README: Godot 4.7.2-stable / GDScript.
- Цель: Windows PC, Full HD 1920×1080.
- Проверенное дерево ветки chatgpt/space-visual-art-pass на момент снимка: 258 entries, recursive tree не обрезан.
- Основные зоны: .github/workflows, docs, art_source, assets, scenes, scripts, shaders, tests, tools, resources.
- В дереве есть семь исходников Blender (.blend), семь GLB кораблей и семь preview PNG.
- Существуют отдельные showcase-сцены для ангара, игрового процесса и космической среды.
- Существуют тесты для полёта, боя, окружения, кампании, сохранений, UI, обновления и ship assets.

## 2. Фактический продуктовый статус из README

README описывает проект как демонстрационную вертикальную нарезку The Silent Relay, а не законченную игру масштаба Freelancer.

Указано:
- одна демонстрационная миссия с перелётом к ретранслятору, двумя боевыми зонами, шестью волнами противников и возвращением;
- полёт, инерция, boost, chase/cockpit camera, target lock, оружие, щиты и корпус;
- ангар с семью кораблями;
- четыре пилотируемых класса: Player Fighter, Raider Interceptor, Aegis Heavy Fighter, Bastion Bomber;
- три крупных корабля display-only: Mule Cargo Hauler, Vanguard Frigate, Leviathan Cruiser;
- локальный профиль, кредиты, покупка кораблей, checkpoint save/load и Continue.

README прямо перечисляет как ещё не реализованные полноценные системы:
- карта звёздных систем;
- торговля;
- фракционная репутация;
- полноценная сюжетная кампания;
- интерактивные станционные сервисы/стыковка;
- полноценные различия характеристик кораблей.

Это официально задокументированные ограничения, а не предположения аудита.

## 3. Ветки и открытые PR — снимок

Открытые PR на момент запроса:
- #91 — Player Fighter Mk.I hero detail; head: chatgpt/player-fighter-hero-detail; base: chatgpt/space-visual-art-pass; draft.
- #90 — Grok graphics and campaign hardening; head: chatgpt/grok-completion-full-2026-11; base: chatgpt/space-visual-art-pass; draft.
- #89 — Grok gameplay and graphics integration; base main; draft.
- #88 — Space environment visual quality pass; base chatgpt/ten-minute-vertical-slice; draft.
- #87 — Flight ship framing pass; base chatgpt/ten-minute-vertical-slice; draft.
- #17 — ship visual fallback; base chatgpt/ship-art-production; draft.
- #10 — DeepSeek engineering agent workflow; base main; draft.
- #9 — ten-minute playable vertical slice; base chatgpt/phase2-combat-integration; draft.

Ветки имеют разные базы и могут содержать пересекающиеся изменения. Запрещено объединять их целиком без сравнения. PR #90 и #91 оба нацелены на chatgpt/space-visual-art-pass, поэтому их совместимость и порядок интеграции нужно проверять отдельно.

## 4. Корабельное производство

Обнаружено:
- исходные Blender-файлы в art_source/ships;
- экспортированные GLB в assets/models/ships;
- превью в assets/previews;
- генераторы build_player_fighter.py, build_enemy_interceptor.py, build_fleet_expansion.py;
- валидатор validate_fleet_assets.py;
- workflow .github/workflows/ship-art-production.yml.

В PR #91 уже изменены генераторы кораблей, CI workflow и документация. Diff показывает добавление UV-based packed albedo/roughness/normal textures, консолидацию статических мешей по материалам и дополнительные маркировки/элементы. Это существеннее, чем одни наклейки, но не доказывает завершённость художественной детализации.

### Текущая проверка PR #91
- Workflow run 43474224259: выполняется.
- Blender 4.5.16 установлен успешно.
- Генерация Player Fighter Mk.I завершилась успешно на текущем run.
- Генерация Raider Interceptor на момент снимка выполнялась.
- Валидация всех семи моделей, Godot import, asset tests и публикация артефактов ещё не завершены.
- Визуальная проверка превью и ручной осмотр в hangar/gameplay не подтверждены.

Ссылка: https://github.com/valdissor1990-ui/GALACTIC-FRONTIER/actions/runs/43474224259

## 5. Известные ограничения проверки

- README ссылается на ранее успешные Godot CI и visual QA runs, но для приёмки текущего HEAD нужно запускать/проверять CI именно на актуальном SHA.
- Автоматическая генерация превью не заменяет человеческий визуальный осмотр.
- Headless Godot не доказывает корректность захвата мыши, ощущение полёта, читаемость HUD и визуальное качество в реальном окне.
- Успешный Blender build не доказывает правильность материалов после импорта в Godot.
- Наличие моделей и сцен не доказывает, что все они подключены к игровому циклу.

## 6. Следующие обязательные аудиторские действия

1. Дождаться и разобрать все шаги run 43474224259, скачать/просмотреть артефакты, прочитать validation.json.
2. Если Blender/Godot проверки падают — исправить конкретные причины и повторить полный workflow.
3. Сравнить содержимое GLB и Blender по каждому кораблю, проверить root, scale, axes, UV, textures, mesh counts, material counts, bounds и hardpoints.
4. Открыть preview всех семи кораблей, проверить front/side/top/rear/three-quarter views и качество деталей.
5. Проверить подключение Player Fighter в hangar и flight scenes, не ломая gameplay transforms, weapons, camera и collision.
6. Проверить все открытые PR на пересекающиеся файлы и разницу base/head; подготовить карту интеграции.
7. Провести отдельный аудит scripts/environment/space_environment.gd, shaders и scenes/environment.
8. Провести отдельный аудит flight/combat/story/save/UI/audio систем и сопоставить код с tests.
9. Проверить все workflows, Windows export и актуальные run logs.
10. Обновлять этот документ только подтверждёнными результатами.

## 7. Статус

- Repo tree inventory: PARTIAL — структура и основные зоны перечислены; требуется углублённый анализ каждого подсистемного файла.
- Product scope baseline: DONE — извлечён из README.
- Branch/PR inventory: PARTIAL — все открытые PR перечислены; требуется полный branch ancestry/file-overlap analysis.
- Ship pipeline: IN PROGRESS — генерация и валидация PR #91 выполняется.
- Visual review: NOT DONE.
- Full Windows interactive QA: NOT DONE.
- Open-world systems: NOT DONE / PARTIAL — master plan описывает их как цель, README подтверждает отсутствие ряда ключевых систем.
