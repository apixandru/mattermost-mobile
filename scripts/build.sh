#!/usr/bin/env bash

function execute() {
    cd fastlane && NODE_ENV=production bundle exec fastlane $1 $2
}

function apk() {
  case $1 in
    unsigned)
      echo "Building Android unsigned app"
      setup android
      execute android unsigned
    ;;
    *)
      echo "Building Android app"
      setup android
      execute android build
  esac
}

function setup() {
    if [[ -z "$SKIP_SETUP" ]]; then
        npm run clean || exit 1
        npm install --ignore-scripts || exit 1

        # postinstall.sh is skipped by --ignore-scripts; copy the font manually
        cp "node_modules/@mattermost/compass-icons/font/compass-icons.ttf" "assets/fonts/" || exit 1
        cp "node_modules/@mattermost/compass-icons/font/compass-icons.ttf" "android/app/src/main/assets/fonts/" || exit 1

        npx patch-package || exit 1

        node node_modules/\@sentry/cli/scripts/install.js || exit 1

        ASSETS=$(node scripts/generate-assets.js)
        if [ -z "$ASSETS" ]; then
            echo "Error Generating app assets"
            exit 1
        else
            echo "Generating app assets"
        fi

        COMPASS_ICONS="node_modules/@mattermost/compass-icons/font/compass-icons.ttf"
        GENERATE_GLYPH_MAP_SCRIPT="scripts/generate-compass-glyph-map.mjs"

        if [ ! -f "$COMPASS_ICONS" ]; then
            echo "Compass Icons font not found at: $COMPASS_ICONS"
            exit 1
        fi

        if [ ! -f "$GENERATE_GLYPH_MAP_SCRIPT" ]; then
            echo "Compass glyph map script not found at: $GENERATE_GLYPH_MAP_SCRIPT"
            exit 1
        fi

        echo "Generating Compass Icons glyph map"
        node "$GENERATE_GLYPH_MAP_SCRIPT"

        echo "Installing Fastane"
        if !gem list bundler -i --version 2.5.11 > /dev/null 2>&1; then
          gem install bundler --versio 2.5.11
        fi
        cd fastlane && bundle install && cd .. || exit 1
    fi

    ./node_modules/.bin/jetify
}

case $1 in
  apk)
    apk $2
  ;;
  *)
    echo "Build the mobile app for Android
    Usage: build.sh apk [unsigned]"
  ;;
esac
