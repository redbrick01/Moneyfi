# UI Snapshot / Golden Targets

## Target Device
- iPhone 17 logical size preset (project QA baseline)
- Light mode default + selected dark-mode scenarios

## Target Screens
1. Home (data)
2. Home (empty)
3. Portfolio (default)
4. Portfolio (target-allocation sheet open)
5. Analysis (default collapsed)
6. Analysis (expanded tile)
7. Stats (chart + selected month strip)
8. Stats (calendar section)
9. My (logged out)
10. My (logged in)

## Current Regression Setup
- `test/ui_component_smoke_test.dart` provides widget-level smoke regression for core UI building blocks.
- This is a non-golden baseline intended to prevent immediate structural regressions while screens are still under heavy refactor.

## Suggested Golden Command (next phase)
```bash
flutter test --update-goldens
flutter test
```

## Note
- Full page-level golden capture requires deterministic fixture data and dedicated screen harnesses.
- This phase documents targets and adds smoke tests; page-level goldens should be added as the next incremental step.
