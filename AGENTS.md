# AGENTS.md

## Cursor Cloud specific instructions

### Overview

Spellbook is a **dbt monorepo** (Python 3.9 + SQL/Jinja2) with 6 independent sub-projects under `dbt_subprojects/`. There is no local database — models compile locally but execute against Dune's remote Trino/DuneSQL infrastructure. See `CLAUDE.md` for full project details.

### Environment

- **Python 3.9** is required (specified in `Pipfile`). The system default is Python 3.12, so Python 3.9 must be installed from the `deadsnakes` PPA.
- **pipenv** manages all Python dependencies. Always use `PIPENV_PYTHON=python3.9 pipenv run <command>` when invoking tools from the Shell tool (since `pipenv shell` sessions don't persist across tool calls).
- The virtualenv path is typically `/home/ubuntu/.local/share/virtualenvs/workspace-dqq3IVyd-python3.9/`.

### Running dbt commands

All dbt commands must target a specific sub-project. Use `--profiles-dir .` when running from within a sub-project directory, or `--project-dir dbt_subprojects/<name>/` from the repo root.

```bash
# Compile a model
cd dbt_subprojects/dex/ && PIPENV_PYTHON=python3.9 pipenv run dbt compile -s dex_trades --profiles-dir .

# List models
PIPENV_PYTHON=python3.9 pipenv run dbt ls --project-dir dbt_subprojects/tokens/ --profiles-dir dbt_subprojects/tokens/
```

See `.cursor/skills/run-dbt-commands/SKILL.md` for the full guide.

### Gotchas

- `daily_spellbook` is very large (~thousands of models). `dbt compile` without `-s` (select) will take several minutes. Always use `-s model_name` when possible.
- `--profiles-dir` must point to the directory containing `profiles.yml` (each sub-project has its own). Without it, dbt looks for `~/.dbt/profiles.yml` which does not exist.
- The `trino.auth` keyring warning (`keyring module not found`) is harmless and expected.
- Pre-commit hooks are configured as **pre-push** hooks (not pre-commit). Install with `pre-commit install --hook-type pre-push`. They require `dbt compile` to run, which is slow.
- Some CRLF lint failures in the upstream repo are pre-existing and not caused by agent changes.

### Testing

- **pytest**: `PIPENV_PYTHON=python3.9 pipenv run pytest scripts/test_token_checker.py -v`
- **pre-commit**: `PIPENV_PYTHON=python3.9 pipenv run pre-commit run --hook-stage manual --all-files`
- **dbt tests** require a Trino connection (CI only) or `DUNE_API_KEY` for API-based testing via `scripts/dune_query.py`.
