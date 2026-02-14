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

## Design Principles

Follow these well-known principles. They prevent the most common AI-generated code smells.

- **DRY (Don't Repeat Yourself)** — If you write the same logic twice, extract a helper. Duplicated code means duplicated bugs. When fixing one copy you'll forget the other.
- **Single Responsibility** — Each function does one thing. Each module handles one concern. If a function name needs "and" in it, split it.
- **Open/Closed** — Extend behavior by adding new code, not by changing existing, working code. Design components to be extensible so new cases can be added without modifying the original implementation.
- **Liskov Substitution** — Subtypes must be substitutable for their base types. If a function works with a base class, it must also work with any subclass without special checks or knowledge of the subclass.
- **Dependency Inversion** — Depend on abstractions, not concretions. Pass dependencies in (function parameters, constructors) rather than hardcoding them inside.
- **YAGNI (You Aren't Gonna Need It)** — Don't build for hypothetical future requirements. Write the minimum code that satisfies the current task. Unused abstractions are worse than duplication.
- **Composition over Inheritance** — Prefer combining simple functions/objects over deep class hierarchies. Flat is better than nested.
- **Least Surprise** — Code should do what its name suggests, nothing more. Side effects should be obvious or absent.

When DRY and YAGNI conflict (extract a helper vs keep it simple): if the duplication is in the same file or module, extract it. If it's across distant modules, tolerate it until the third occurrence.

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
