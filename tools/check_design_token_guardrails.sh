#!/bin/sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT_DIR"

legacy='\b(MoneyfyPalette|MoneyfySpacing|MoneyfyTheme|moneyfyValueColor)\b'
color='\b(Color\s*\(\s*0[xX]|Color\.from(RGBO|ARGB)\s*\(|Colors\.|ThemeData\.(light|dark)\s*\()'
font_size='\bfontSize:\s*[0-9]'
font_family="\\bfontFamily:\\s*['\"]|\\bfontFamilyFallback:\\s*(const\\s+)?\\[\\s*['\"]"
font_weight='\bFontWeight\.w[0-9]+'
spacing='\bEdgeInsets\.(all|symmetric|only|fromLTRB)\(\s*(?:(?:horizontal|vertical|top|bottom|left|right):\s*)?(8|12|16|20|24|32|48|96)(\.0)?\s*[,)]'

if [ "${1:-}" = "--self-test" ]; then
  expect_match() {
    printf '%b\n' "$2" | rg -Uq "$1" -
  }

  expect_match "$legacy" 'final color = MoneyfyPalette.primary;'
  expect_match "$color" 'final color = Color(\n  0xFF0052FF);'
  expect_match "$color" 'final color = Colors.white;'
  expect_match "$color" 'final color = ThemeData.light().colorScheme.primary;'
  expect_match "$font_size" 'TextStyle(fontSize:\n  15);'
  expect_match "$font_family" "TextStyle(fontFamilyFallback: const ['Roboto']);"
  expect_match "$font_weight" 'TextStyle(fontWeight: FontWeight.w600);'
  expect_match "$spacing" 'padding: EdgeInsets.symmetric(\n  horizontal: 12);'
  printf '%s\n' 'EdgeInsets.all(context.spacing.md)' 'EdgeInsets.all(2)' \
    'TextStyle(fontSize: context.fontSizes.s14)' 'context.colors.primary' |
    {
      if rg -Uq "$legacy|$color|$spacing|$font_size|$font_family|$font_weight" -; then
        exit 1
      fi
    }
  echo "Design token guardrail self-test: passed."
  exit 0
fi

status=0

report() {
  title="$1"
  pattern="$2"
  shift 2

  if rg -nU "$pattern" --glob '*.dart' --glob '!*.g.dart' "$@"; then
    echo "Design token guardrail: $title" >&2
    status=1
  else
    result=$?
    if [ "$result" -ne 1 ]; then
      exit "$result"
    fi
  fi
}

report "Removed design APIs" "$legacy" lib
report "Direct colors or unthemed palettes" "$color" lib --glob '!lib/design_system/**'
report "Direct font sizes" "$font_size" lib --glob '!lib/design_system/**'
report "Direct font family" "$font_family" lib --glob '!lib/design_system/font_families.dart'
report "Direct font weights" "$font_weight" lib --glob '!lib/design_system/font_weights.dart'
report "Standard spacing used as a literal in EdgeInsets" "$spacing" lib --glob '!lib/design_system/**'

if [ "$status" -eq 0 ]; then
  echo "Design token guardrail: passed."
fi
exit "$status"
