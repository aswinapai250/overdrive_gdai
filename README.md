# FLOWSTATE
**"NEVER BREAK THE FLOW."**
*High-Speed Sci-Fi Parkour Runner in a Colossal Megastructure for Godot 4.x*

---

## 🌌 Art Direction & Visual Redesign
**FLOWSTATE** takes place inside an enormous sci-fi megastructure. The runner races along an elevated transportation platform suspended across a deep cavernous abyss with towering monolithic service spires, structural seismic bracing, overhead skybridges, and atmospheric haze.

### Key Visual Highlights
1. **Layered Megastructure Architecture**:
   - **Elevated Testing Deck**: Modular dark graphite steel floor panels, transverse expansion joints, recessed electric cyan guide lines, and raised beveled containment curbs with safety rails.
   - **Underside Framework**: Central longitudinal spine girder, cantilever support ribs, conduit pipelines, and vertical foundation piers descending 140m into the abyss.
   - **Midground Service Towers & Skybridges (30m - 65m)**: Monumental dark steel towers with illuminated vertical window slits, industrial ventilation cowls, diagonal bracing, and high-altitude skybridges.
   - **Distant Superstructure Silhouettes (100m - 250m)**: Gargantuan arching ribs framing the horizon with pulsing aircraft beacon strobes.
2. **Restrained Sci-Fi Palette**:
   - Charcoal, graphite, gunmetal, and dark steel base materials.
   - Electric cyan and cool blue lighting with amber hazard and gold energy highlights.
   - Controlled ACES bloom and exponential atmospheric fog.
3. **Integrated Obstacle Visuals**:
   - **Depressurization Slide Barrier**: Industrial maintenance gantry with amber hazard stripes, downward clearance chevrons, and suspended laser curtain.
   - **Electrified Jump Hurdle**: Floor-mounted containment base with dual pylons, upward chevrons, and glowing plasma barrier.
   - **Structural Core Column**: Imposing hexagonal dark steel pylon with ventilation fins, amber warning strobes, and directional evasion guides.
   - **Route Choice Portal**: Bulkhead archway signposting "OVERDRIVE SECTOR // 3X MULTIPLIER" (Amber/Red) vs. "STANDARD TRANSIT" (Cyan).
   - **Contained Energy Cores**: Gyroscopic halo rings rotating around pulsating quantum cores.
4. **Armored Parkour Suit & Movement Feedback**:
   - Sleek carbon-graphite armor plating with electric cyan visor slit and back thruster nozzles.
   - Tuned camera framing (distance 5.0m, pitch -15.5°) for generous forward visibility.
   - Dynamic FOV expansion (74° to 88°), speed lines active during high-velocity boost, and subtle non-disruptive camera shake.
5. **Sci-Fi Racing HUD & Telemetry**:
   - Header: **FLOWSTATE** | `// NEVER BREAK THE FLOW.`
   - Velocity Matrix (Speedometer), Boost Core Capacitor, and Hull Integrity pips.
   - Flow Momentum Multiplier with tier badges: `[FLOW 1.0x]`, `[TIER B]`, `[TIER A]`, `[TIER S]`, `[MAX FLOWSTATE]`.
   - Polished frosted glassmorphism Pause Modal `[ESC]` and Game-Over screen `[R]`.

---

## 🕹️ Controls

| Action | Primary Key | Secondary Key | Description |
|---|---|---|---|
| **Momentum Slide** | `S` | `Down Arrow` | Ducks collision height from 1.8m to 0.65m; glides beneath low barriers and awards "PERFECT SLIDE" bonus! |
| **Precision Jump** | `Spacebar` | `W` / `Up Arrow` | Leaps over electrified floor hurdles with coyote time and jump buffering. |
| **Switch Lanes** | `A` / `D` | `Left` / `Right Arrow` | Smooth 3-lane parkour with aerodynamic banking tilt. |
| **Boost Mode** | `Shift` | `Right Mouse Button` | Consumes boost energy to rocket into Overdrive (38 m/s). |
| **Pause Run** | `Escape` | - | Opens the telemetry pause screen. |
| **Restart Run** | `R` | Retry Button | Instantly reloads the run. |

---

## 🧪 Automated Test Verification
Both automated headless test suites pass 100%:
```bash
godot --headless -s res://tests/integration_test.gd
godot --headless -s res://tests/obstacle_collision_test.gd
```
- Core movement, 3 lanes, jumping arc, sliding height reduction & recovery verified.
- Overhead barrier clearance vs standing impact verified.
- Clean 60+ FPS performance target with shared static materials and zero external dependencies.
