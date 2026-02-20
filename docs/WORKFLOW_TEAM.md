# Workflow de Colaboracion (4 devs)

## Regla principal
- No hacer push directo a `main`.
- Todo cambio va por Pull Request (PR).

## Ramas
- Naming obligatorio: `color/<ticket>-<slug>`.
- Ejemplos:
  - `azul/1-workflow-pr-template`
  - `verde/2-hardening-mirror`

## Checklist obligatorio en cada PR
Antes de abrir o actualizar una PR, ejecutar y pegar salida relevante:

```bash
git status -sb
git diff --stat
git log -1 --oneline --decorate
./scripts/verify_all.sh
```

## Boton rojo
- `./scripts/verify_all.sh` es el control minimo para merge.
- Si falla, no mergear hasta corregir.

## GitHub Branch Protection (obligatorio)
Activar Branch Protection en `main` con estas reglas minimas:
- Require a pull request before merging.
- Require status checks to pass before merging.
- Marcar `./scripts/verify_all.sh` como required check.

