#!/bin/bash

# Swiftファイルの変更を監視してXcodeに通知するスクリプト
echo "ファイル変更監視を開始します..."
echo "Ctrl+C で停止できます"

fswatch -o LevelUpTodo/ | while read f; do
    echo "$(date): ファイルが変更されました"
    osascript -e '
        tell application "System Events"
            tell process "Xcode"
                if exists then
                    set frontmost to true
                    delay 0.1
                end if
            end tell
        end tell
    '
done