# .claude — Configuración compartida del proyecto

Esta carpeta contiene la configuración de **Claude Code** versionada en git para que todos los compañeros tengan la misma setup al clonar el repo.

## Estructura

```
.claude/
├── settings.json   # Permisos y configuración del proyecto
├── commands/       # Slash commands del proyecto
├── agents/         # Agentes especializados
├── skills/         # Skills invocables
├── workflows/      # Workflows
├── templates/      # Plantillas
└── bin/            # Scripts auxiliares
```

Las subcarpetas están vacías por ahora — agregá lo que el equipo necesite.

## Cómo usar

1. Clonar el repo y abrir la carpeta en Claude Code.
2. Claude detecta `.claude/` automáticamente y carga `settings.json` + todo lo de adentro.
3. Los slash commands que agreguen a `commands/` aparecen al tipear `/`.
4. Los agentes en `agents/` se invocan desde la tool Agent.
5. Las skills en `skills/` están disponibles vía la tool Skill.

## Cómo agregar cosas

- **Slash command**: crear `commands/<nombre>.md` con frontmatter y cuerpo del prompt.
- **Agente**: crear `agents/<nombre>.md` con frontmatter (`name`, `description`, `tools`) y las instrucciones.
- **Skill**: crear `skills/<nombre>/SKILL.md` con frontmatter + contenido.

## Reglas del equipo

- **No commitear secrets** dentro de `.claude/`.
- Cambios acá van por PR para que el equipo los revise.
- La config personal de cada uno (`~/.claude/`) es individual y no se toca desde acá.
