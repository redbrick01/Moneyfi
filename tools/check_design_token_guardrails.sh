#!/bin/sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT_DIR"

if [ "${1:-}" = "--self-test" ]; then
  failed=0

  assert_detects() {
    title="$1"
    pattern="$2"
    sample="$3"

    if printf '%s\n' "$sample" | rg -n "$pattern" - >/dev/null; then
      echo "PASS: $title"
    else
      echo "FAIL: $title"
      failed=1
    fi
  }

  assert_ignores() {
    title="$1"
    pattern="$2"
    sample="$3"

    if printf '%s\n' "$sample" | rg -n "$pattern" - >/dev/null; then
      echo "FAIL: $title"
      failed=1
    else
      echo "PASS: $title"
    fi
  }

  assert_detects \
    "legacy palette" \
    "MoneyfyPalette|MoneyfySpacing|\\bmoneyfyValueColor\\(" \
    "final color = MoneyfyPalette.primary;"
  assert_detects \
    "legacy spacing" \
    "MoneyfyPalette|MoneyfySpacing|\\bmoneyfyValueColor\\(" \
    "final gap = MoneyfySpacing.md;"
  assert_detects \
    "legacy helper" \
    "MoneyfyPalette|MoneyfySpacing|\\bmoneyfyValueColor\\(" \
    "final color = moneyfyValueColor(value);"
  assert_detects \
    "direct Color literal" \
    "Color\\(0x" \
    "const color = Color(0xFF0052FF);"
  assert_detects \
    "direct Colors usage" \
    "Colors\\." \
    "final color = Colors.white;"
  assert_detects \
    "direct font size" \
    "fontSize: [0-9]" \
    "style: TextStyle(fontSize: 15);"
  assert_detects \
    "direct font family" \
    "fontFamily(Fallback)?: ['\"]|\\.SF Pro|Roboto|AppleSDGothic|Pretendard|Noto" \
    "style: TextStyle(fontFamily: '.SF Pro Text');"
  assert_detects \
    "direct font weight" \
    "FontWeight\\.w[0-9]+" \
    "style: TextStyle(fontWeight: FontWeight.w600);"
  assert_ignores \
    "tokenized spacing" \
    "MoneyfyPalette|MoneyfySpacing|\\bmoneyfyValueColor\\(" \
    "final gap = context.spacing.md;"

  if [ "$failed" -eq 0 ]; then
    echo "Design token guardrail self-test: passed."
  else
    echo "Design token guardrail self-test: failed."
  fi
  exit "$failed"
fi

status=0

report() {
  title="$1"
  pattern="$2"
  shift 2

  echo
  echo "== $title =="
  if rg -n "$pattern" "$@"; then
    status=1
  else
    echo "No matches."
  fi
}

report "Legacy palette/spacing outside compatibility and theme bridges" \
  "MoneyfyPalette|MoneyfySpacing|\\bmoneyfyValueColor\\(" \
  lib --glob "*.dart" \
  --glob "!lib/widgets/moneyfy_ui.dart" \
  --glob "!lib/theme/moneyfy_colors.dart" \
  --glob "!lib/theme/moneyfy_theme.dart"

report "Direct Color(0x...) outside design system/theme" \
  "Color\\(0x" \
  lib --glob "*.dart" \
  --glob "!lib/design_system/**" \
  --glob "!lib/theme/**"

report "Direct Colors.* outside design system/theme" \
  "Colors\\." \
  lib --glob "*.dart" \
  --glob "!lib/design_system/**" \
  --glob "!lib/theme/**"

report "Direct fontSize outside design system/theme" \
  "fontSize: [0-9]" \
  lib --glob "*.dart" \
  --glob "!lib/design_system/**" \
  --glob "!lib/theme/**"

report "Direct or legacy font family outside font tokens" \
  "fontFamily(Fallback)?: ['\"]|\\.SF Pro|Roboto|AppleSDGothic|Pretendard|Noto" \
  lib test --glob "*.dart" \
  --glob "!lib/design_system/font_families.dart"

report "Direct font weight outside font tokens" \
  "FontWeight\\.w[0-9]+" \
  lib test --glob "*.dart" \
  --glob "!lib/design_system/font_weights.dart"

echo
if [ "$status" -eq 0 ]; then
  echo "Design token guardrail report: clean."
else
  echo "Design token guardrail report: matches found. Review before enforcing."
fi

exit 0
