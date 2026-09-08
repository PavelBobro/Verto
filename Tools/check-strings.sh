#!/bin/bash
# Keys drift silently: rename one and the interface shows "output.placeholder"
# instead of a sentence, with nothing failing to build. This catches that.
set -u
cd "$(dirname "$0")/.."

used=$(grep -oE 't\("[a-zA-Z.]+"' Sources/Verto/Localized.swift | sed 's/t("//;s/"//' | sort -u)
status=0

for lproj in Resources/*.lproj; do
    lang=$(basename "$lproj" .lproj)
    defined=$(grep -oE '^"[a-zA-Z.]+"' "$lproj/Localizable.strings" | tr -d '"' | sort -u)

    missing=$(comm -23 <(echo "$used") <(echo "$defined"))
    unused=$(comm -13 <(echo "$used") <(echo "$defined"))

    if [ -n "$missing" ]; then
        echo "✗ $lang: нет перевода для ключей:"
        echo "$missing" | sed 's/^/    /'
        status=1
    fi
    if [ -n "$unused" ]; then
        echo "✗ $lang: строки, которые никто не использует:"
        echo "$unused" | sed 's/^/    /'
        status=1
    fi
    [ -z "$missing$unused" ] && echo "✓ $lang: $(echo "$defined" | wc -l | tr -d ' ') строк, всё сходится"
done

exit $status
