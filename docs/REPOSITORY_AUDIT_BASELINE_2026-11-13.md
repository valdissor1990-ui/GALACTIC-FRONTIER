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


## 8. Первый фактический визуальный осмотр семи кораблей

Проверен ZIP-артефакт GitHub Actions run 43473442128: `GALACTIC-FRONTIER-seven-ship-fleet`.
- В отчёте Blender validator: 7/7 кораблей PASS.
- Blender: 4.5.16 LTS.
- Для Player Fighter GLB: 146,348 треугольников, 14 mesh objects, 7 материалов, bounds совпадают с Blender source.
- Для остальных GLB: Enemy Fighter 57,672 triangles; Heavy Fighter 15,208; Bomber 37,368; Cargo Hauler 20,924; Frigate 37,956; Cruiser 77,900.
- В отчёте по всем семи кораблям: один GF_ root, UV layer присутствует на каждом mesh object, bounds Blender/GLB совпадают, non-finite geometry не обнаружена.
- Эти результаты подтверждают геометрическую сборку и экспорт конкретного run, но не доказывают визуальное качество или корректность импорта текущего HEAD.

### Результат осмотра preview PNG

Все семь preview изображений открыты и просмотрены. Художественная приёмка пока FAIL / PARTIAL:
- Player Fighter: силуэт читается, но крылья остаются большими плоскими панелями, центральный корпус и мотогондолы выглядят упрощённо и блочно; кабина тёмная, внутреннее рабочее место пилота не читается.
- Enemy Fighter и Heavy Fighter визуально недостаточно отличаются от Player Fighter по общему delta-wing языку; роли должны считываться сильнее.
- Bomber: подвесы заметны, но бомбардировочная система и створки бомбоотсека не читаются как сложный функциональный узел.
- Cargo Hauler: грузовые модули выглядят как прямоугольные блоки поверх корпуса; нужен промышленный каркас, крепления и читаемые грузовые секции.
- Frigate: пока воспринимается как удлинённый истребитель; не хватает архитектуры палуб, мостика, ангаров и турельных батарей.
- Cruiser: крупный корпус есть, но он выглядит слишком тёмным и блочным; не хватает многоуровневой архитектуры, окон/световых полос, ангаров, командной надстройки и масштабных деталей.
- Весь флот показан в одном трёхчетвертном ракурсе на корабль. Для приёмки необходимы front/side/top/rear/rear-three-quarter и macro close-up.
- Студийные превью не доказывают качество в реальном игровом освещении, hangar и flight camera.

### Решения по визуальной доработке

1. Player Fighter — продолжить геометрию кабины и двигателя, не ограничиваться маркировкой и панельными полосами. Для этого создан PR #94: кресло, ремни, консоли, дисплеи, органы управления, воздухозаборники, сопловые приводы и крепёж.
2. Для UV/PBR добавлена отдельная проверка проекций: PR #93 исправляет XY-only UV, которые схлопывали вертикальные поверхности, и валидирует вырожденные/non-finite UV faces.
3. После Player Fighter провести отдельную геометрическую детализацию остальных шести классов с сохранением их уникальной роли.
4. В следующем визуальном QA генерировать набор ракурсов, а не один красивый render.

Ссылки:
- Артефакт run 43473442128: https://github.com/valdissor1990-ui/GALACTIC-FRONTIER/actions/runs/43473442128
- PR #93 UV: https://github.com/valdissor1990-ui/GALACTIC-FRONTIER/pull/93
- PR #94 cockpit/engine: https://github.com/valdissor1990-ui/GALACTIC-FRONTIER/pull/94

## 9. Дополнительная карта интеграции веток

Сравнение refs показало:
- `main` → `chatgpt/ten-minute-vertical-slice`: diverged, 232 commits ahead / 14 behind.
- `main` → `chatgpt/phase2-combat-integration`: diverged, 86 ahead / 14 behind.
- `main` → `chatgpt/space-visual-art-pass`: diverged, 283 ahead / 14 behind.
- `main` → `chatgpt/grok-completion-full-2026-11`: diverged, 424 ahead / 14 behind.
- `main` → `chatgpt/player-fighter-hero-detail`: diverged, 295 ahead / 14 behind.
- PR #89 (grok-completion-2026-11 → main) reports mergeable=false.
- PR #17 (ship-visual-fallback → ship-art-production) reports mergeable=false.
- PR #87 and #88 report mergeable=true but target the ten-minute vertical-slice branch, not main.
- PR #90 and #91 both target space-visual-art-pass; PR #90 has 140 commits on top of that base, PR #91 has 12. PR #93 and #94 are stacked ship-quality follow-ups.

Это означает, что проект нуждается в управляемом integration train. Сначала выбрать один рабочий baseline (вероятно ten-minute vertical slice + reviewed space art + verified campaign fixes), затем переносить изменения по тематическим пакетам. Нельзя делать merge всех веток или считать самый большой commit count признаком самого правильного состояния.


## 10. Актуальные проверки интеграционной ветки и ship pipeline

### Godot / Windows — PR #90 head c4ce910

GitHub Actions run 43478272851 (head SHA c4ce91083f535fddd0316599b8fbe10c7ba11413) завершился SUCCESS:
- Godot 4.7.2 import/parser;
- flight и visual-flight scene smoke;
- FlightModel, camera, pause/mouse, docking;
- space collision, route safety, audio;
- enemy combat AI, combat systems, projectile sweep;
- ship visual fallback;
- graphics quality presets;
- story M01-M05 и campaign runtime;
- save manager и mission resume;
- demo mission, failure/retry;
- hangar, player ship selection, ship modules, contract progression;
- main-menu navigation и Continue;
- main menu, bootstrap, ten-minute demo scene;
- scan всех сцен и внешних зависимостей;
- import всех семи GLB через Godot runtime parser;
- Windows Desktop export;
- Windows executable smoke test.

Run: https://github.com/valdissor1990-ui/GALACTIC-FRONTIER/actions/runs/43478272851

Отдельный визуальный workflow run 43478273435 на том же SHA ещё выполняется; его результат не считать PASS до завершения и осмотра артефактов:
https://github.com/valdissor1990-ui/GALACTIC-FRONTIER/actions/runs/43478273435

### Ship art — актуальный блокер PR #91

- Run 43474224259 на branch chatgpt/player-fighter-hero-detail, SHA fcf0b58b78a41fb80f7d05bef5377606f1d8c1c1, завершился FAILURE.
- Все семь Blender-генераторов завершились успешно.
- Blender validator отклонил все семь GLB: в каждом после обратного glTF import найдено 0 embedded image textures при минимальном требовании 3.
- Godot import и publish assets были корректно пропущены после провала validator.
- Артефакт диагностики загружен: artifact ID 14062964373.

Run: https://github.com/valdissor1990-ui/GALACTIC-FRONTIER/actions/runs/43474224259

Предыдущий успешный run 43473442128 на SHA 05fb9e2cf856237497ec3be922e7197045b70efd относится к более раннему состоянию той же ветки. Его 7/7 PASS и preview images не являются доказательством для нового HEAD. Именно его preview PNG использовались в первом визуальном осмотре раздела 8.

### Исправления, отправленные на проверку

- PR #93: face-projected UV вместо XY-only UV и проверка вырожденных/non-finite UV faces.
- PR #94: геометрия внутренней кабины, кресло, ремни, консоли, органы управления, воздухозаборники и механика сопел.
- PR #95: перевод generated/packed PBR maps в file-backed PNG перед GLB экспортом; явный PNG export; проверка подготовки изображений; concurrency ship-art workflow разделён по веткам, чтобы глобальная очередь не отменяла ожидающие независимые сборки.

Run 43478941870 запущен на раннем промежуточном SHA workflow-файла; следующий run 43479039175 создан после обновления генераторов и должен проверять окончательный набор изменений:
- https://github.com/valdissor1990-ui/GALACTIC-FRONTIER/actions/runs/43478941870
- https://github.com/valdissor1990-ui/GALACTIC-FRONTIER/actions/runs/43479039175

До завершения второго run исправление экспорта текстур считать IN PROGRESS, не PASS.


## 11. Сверка с утверждённым графическим эталоном 2022 и Full HD roadmap

Прочитаны документы `docs/GRAPHICS_TARGET_2022.md`, `docs/GRAPHICS_2022_ACCEPTANCE_MATRIX.md`, `docs/VISUAL_TARGET.md`, `docs/FLEET_VISUAL_QA_2026-11-13.md`, `docs/FULLHD_2026_IMPLEMENTATION_ROADMAP.md`.

Обязательные цели проекта:
- Forward+ / Vulkan, Full HD 1920×1080.
- 60 FPS / 16.7 ms target на GTX 1660 / RX 580 class hardware — цель, пока не подтверждённая физическим GPU профилированием.
- Hero textures до 2K, вторичные ассеты обычно 1K, mipmaps, anisotropic filtering, GPU compression.
- PBR: albedo, tangent normal, ORM, emissive; реальные GLB embedded images.
- UV checker/texel density/overlap validation.
- LOD0/LOD1/LOD2 и measured budgets по каждому классу.
- 6 ракурсов каждого корабля и реальные Forward+ screenshots.

### Явные P0/P1 задачи из Full HD roadmap, которые нельзя потерять

- Full HD viewport/UI anchors/safe areas и RU/EN localization.
- Forward+ Vulkan capture pipeline; старые Compatibility/OpenGL captures не считать продуктовой приёмкой.
- Swept projectile collision и regression test для быстрого снаряда против тонкой цели.
- Детерминированные seed для gameplay RNG, encounter и environment layouts.
- Ограничить projectile lights и применять SSAO по сценам, не вслепую.
- Mesh consolidation, LOD0/1/2 и budgets для всех кораблей.
- PBR texture pipeline: albedo/normal/ORM/emissive, Blender high-to-low bake, UV density/overlap validation.
- ACES/tonemap, restrained glow, MSAA/TAA evaluation и grading LUT.
- Planet atmosphere/surface maps и VFX engines/shields/hull damage.
- Превратить большой `demo_mission_director.gd` в data-driven MissionDefinition + reusable MissionRunner.
- Хранить story flags в persistent PlayerProfile, а не в flight/combat scripts.
- Добавить station set-pieces, seeded NPC traffic, AI LOD и economy tables.

Эти задачи включены в master prompt как обязательные пакеты, а не факультативные идеи.


## 12. Реальный Full HD gameplay capture — визуальная приёмка FAIL

Проверен artifact run 43478273435, SHA c4ce91083f535fddd0316599b8fbe10c7ba11413:
https://github.com/valdissor1990-ui/GALACTIC-FRONTIER/actions/runs/43478273435

Артефакт скачан и PNG-файлы открыты вручную. Технический запуск Forward+ Vulkan на CI llvmpipe состоялся, восемь gameplay screenshots созданы, но space capture workflow завершился FAILURE: созданы только 6 из 7 space screenshots, отсутствует `space-07-asteroid-corridor.png`, не появился marker `SPACE_SHOWCASE_COMPLETE count=7`.

### Визуальные дефекты, подтверждённые скриншотами

- Chase camera: корабль слишком мал в кадре и почти чёрный силуэт; фон чрезмерно яркий, однотонный сине-голубой, нет читаемого starfield/nebula depth.
- Cockpit camera: чёрные элементы корпуса/рамки занимают чрезмерную часть кадра; центральная зона и приборная панель перекрывают обзор; HUD и внутренние элементы не имеют правильной иерархии.
- Space views 01–04 и 06: на артефакте почти полностью однотонный синий/белый фон; планета, туманность, галактика и derelict landmark не читаются. Это визуальный FAIL, даже несмотря на успешную загрузку сцены и наличие сотен дочерних объектов.
- Space view 06: вместо читаемого wreck виден пересвеченный фон и небольшие тёмные точки.
- В gameplay capture отсутствует полный цикл семи space views; capture workflow не должен отмечаться PASS.

### Следующее исправление

После c4ce910 на branch chatgpt/grok-completion-full-2026-11 создан follow-up commit b3b74ac3cf04d685abd43c4b0676a714c124e353:
- camera направляется на первый shot до diagnostic capture;
- выставляется полный cull mask;
- SpaceEnvironment принудительно делается visible;
- viewport получает явное назначение WorldEnvironment.
Запущен новый gameplay visual capture run 43480389576 на b3b74; он ещё не завершён, поэтому результат этих исправлений пока NOT VERIFIED.

Новый capture должен подтвердить:
1. реальный небесный фон и звёзды;
2. видимую планету и её атмосферу;
3. туманности и спиральную галактику;
4. читаемый derelict и asteroid corridor;
5. все 7 снимков и marker завершения;
6. повторную проверку cockpit/chase framing.

Run: https://github.com/valdissor1990-ui/GALACTIC-FRONTIER/actions/runs/43480389576

Визуальная приёмка текущего игрового процесса: FAIL. Не заменять этот вывод зелёным Godot CI.
