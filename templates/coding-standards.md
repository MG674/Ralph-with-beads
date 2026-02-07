# Coding Standards

## Naming
- Functions: verb_noun (e.g., `parse_csv`, `calculate_average`)
- Classes: PascalCase nouns (e.g., `DataProcessor`, `ChartRenderer`)
- Constants: UPPER_SNAKE_CASE
- Private: prefix with underscore

## Structure
- One class per file (usually)
- Group related functions in modules
- Keep functions under 20 lines (prefer 10)
- Keep files under 200 lines

## Testing
- Test file mirrors source: `src/parser.py` → `tests/test_parser.py`
- Test function names: `test_<function>_<scenario>_<expected>`
- One assertion per test (usually)
- Use fixtures for setup, not duplication

## Error Handling
- Fail fast with clear error messages
- Validate inputs at boundaries
- Use custom exceptions for domain errors

## Documentation
- Docstrings: what, not how (the code shows how)
- Comments: why, not what (only for non-obvious decisions)

## Code Quality Checks
All code must pass before committing:
1. `ruff check .` — No lint errors
2. `black --check .` — Properly formatted
3. `mypy .` — No type errors
4. `pytest` — All tests pass
5. `pytest --cov` — Coverage >= 80%
