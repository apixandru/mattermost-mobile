#!/usr/bin/env bash

# Intune protection: prevent committing submodule content
if git diff --cached --name-only | grep -q "^libraries/@mattermost/intune/"; then
    # Exclude .gitkeep which is allowed
    if git diff --cached --name-only | grep "^libraries/@mattermost/intune/" | grep -v ".gitkeep$" | grep -q .; then
        echo ""
        echo "❌ COMMIT BLOCKED"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "You are attempting to commit files from the Intune submodule."
        echo "The Intune library should only be modified in its own repository:"
        echo "  github.com/mattermost/mattermost-mobile-intune"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        exit 1
    fi
fi

jsfiles=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.js$|\.ts$|\.tsx$')
exit_code=0

if [ -z "$jsfiles" ]; then
    exit 0
fi

if [ -n "$jsfiles" ]; then
    echo "Checking lint for:"
    for js in $jsfiles; do
        echo "$js"
        e=$(node_modules/.bin/eslint --quiet --fix $js)
        if [ -n "$e" ]; then
            echo "ERROR: Check eslint hints."
            echo "$e"
            exit_code=1
        fi
    done

    echo "Checking for TSC (fast incremental check)"
    # Use incremental TypeScript checking - much faster on subsequent runs
    tsc=$(node_modules/.bin/tsc --noEmit --incremental --tsBuildInfoFile .tsbuildinfo.precommit 2>&1)
    if [ $? -ne 0 ]; then
        echo "ERROR: TypeScript issues found."
        echo "$tsc"
        exit_code=1
    fi
fi

# scripts/precommit/i18n.sh

exit $exit_code
