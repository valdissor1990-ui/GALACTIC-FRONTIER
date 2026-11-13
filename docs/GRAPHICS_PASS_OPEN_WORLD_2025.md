# Graphics implementation log — Open World pass

Этот файл — журнал технических изменений, а не художественный стандарт и не ограничение качества. Актуальное направление задаёт [GRAPHICS_ART_BIBLE.md](GRAPHICS_ART_BIBLE.md).

**Ветка:** `grok/graphics-open-world-2025`  
**Движок:** Godot 4.7.2-stable

## Графические компоненты
| Компонент | Реализация |
|---|---|
| Starfield | `assets/shaders/space_starfield_sky.gdshader` |
| Материал корпуса | `assets/shaders/hull_fresnel.gdshader` |
| Двигатели | `assets/shaders/engine_plume.gdshader` |
| Атмосфера планет | `assets/shaders/planet_atmosphere.gdshader` |
| Газовые планеты | `assets/shaders/planet_gas.gdshader` |
| Каменистые планеты | `assets/shaders/planet_rocky.gdshader` |
| Поверхности астероидов | `assets/shaders/rock_surface.gdshader` |
| Солнечный диск | `assets/shaders/sun_disc.gdshader` |
| Солнечная засветка | `assets/shaders/sun_flare.gdshader` |
| Попадания | `scripts/vfx/hit_flash_fx.gd` |

## Реализованные функции, требующие визуальной оценки
- Hit flash и heat uniforms в hull shader.
- Реакция HitFlashFx на Damageable.
- Starfield с несколькими масштабами звёзд.
- Астероидные поля на MultiMesh.
- Солнечный диск в мировом пространстве и flare, зависящий от пресета качества.
- HDR/glow через Environment.

Наличие функции в коде не означает, что её художественный результат подтверждён визуальным тестом.

## Правила следующих изменений
- Не добавлять звёздные слои ради плотности.
- Не добавлять новые bloom/cinematic-проходы вместо улучшения геометрии и материалов.
- Не дублировать гравитационные линзы без отдельной художественной причины.
- Приоритет — главный корабль, затем планеты, астероиды и боевые эффекты.
- Каждая самостоятельная графическая задача — отдельный коммит.
- Runtime и visual review отмечать NOT RUN, если они не выполнялись.
