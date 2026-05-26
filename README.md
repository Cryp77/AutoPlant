# Auto Plant Mod

A client-side Fabric mod for Minecraft 1.21 that automatically plants seeds when you look at tilled farmland.

## Features

- **Auto-plant**: Hold a seed item and look at a Farmland block — the seed is planted automatically.
- **Toggle keybind**: Press `G` (rebindable in Controls settings) to turn the feature on or off. A hotbar message confirms the state.
- **Cooldown**: 250 ms between plants to avoid packet spam on multiplayer.
- **Supported seeds**: Wheat Seeds, Carrot, Potato, Beetroot Seeds, Melon Seeds, Pumpkin Seeds.

## Requirements

- Java 21
- Minecraft 1.21
- Fabric Loader ≥ 0.15.0
- Fabric API

## Build Instructions

### 1. Prerequisites

Install [Java 21](https://adoptium.net/) and ensure `JAVA_HOME` points to it.

### 2. Get the Gradle wrapper JAR

The `gradle-wrapper.jar` binary is not included in this source tree. Generate it once with a local Gradle installation:

```bash
gradle wrapper --gradle-version 8.8
```

Or download it manually from the [Gradle GitHub releases](https://github.com/gradle/gradle/releases) and place it at `gradle/wrapper/gradle-wrapper.jar`.

### 3. Build

```bash
./gradlew build          # Linux / macOS
gradlew.bat build        # Windows
```

The compiled mod JAR will be at:

```
build/libs/autoplant-1.0.0.jar
```

### 4. Install

Copy the JAR into your Minecraft `mods/` folder alongside `fabric-api-*.jar`.

## Checking for newer dependency versions

Visit these pages to confirm you're using the latest versions before building:

| Dependency | Check at |
|---|---|
| Yarn mappings | https://fabricmc.net/develop/ |
| Fabric Loader | https://fabricmc.net/develop/ |
| Fabric API | https://modrinth.com/mod/fabric-api |

Update `gradle.properties` if needed.

## License

MIT
