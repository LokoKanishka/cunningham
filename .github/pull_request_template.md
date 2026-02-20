## Resumen
- Ticket:
- Objetivo:
- Riesgo:

## Checklist Obligatorio
- [ ] Rama de trabajo cumple `color/<ticket>-<slug>`
- [ ] No hay push directo a `main` (cambio via PR)
- [ ] Corrido `git status -sb`
- [ ] Corrido `git diff --stat`
- [ ] Corrido `git log -1 --oneline --decorate`
- [ ] Corrido `./scripts/verify_all.sh`
- [ ] Adjunte evidencia/salida de checks en la descripcion del PR

## Evidencia de checks
```bash
git status -sb
git diff --stat
git log -1 --oneline --decorate
./scripts/verify_all.sh
```

## Branch Protection
- [ ] `main` protegido: PR obligatorio + required checks
- [ ] `./scripts/verify_all.sh` marcado como required check

