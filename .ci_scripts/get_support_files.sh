#!/usr/bin/env bash

set -xe

mkdir -p support/{languages,mp3,editor}
cd support

langpack_baseurl="https://github.com/bvschaik/julius-support/releases/download/patches"
declare -A lang_to_name=(
	[english]="English (US)"
	[french]="French"
	[german]="German"
	[italian]="Italian"
	[japanese]="Japanese"
	[korean]="Korean"
	[polish]="Polish"
	[portuguese_br]="Portuguese (Brazilian)"
	[russian]="Russian"
	[simplified_chinese]="Simplified Chinese"
	[spanish]="Spanish"
	[swedish]="Swedish"
	[traditional_chinese]="Traditional Chinese"
)

for key in "${!lang_to_name[@]}"; do
	value="${lang_to_name[$key]}"
	lang_filename="caesar3_update_${key}.zip"

	if [ ! -f "$lang_filename" ]; then
		curl -sSf -L -O "$langpack_baseurl/$lang_filename"
	fi
	unzip -o -d "languages/$value" "$lang_filename"
done

mp3_baseurl="https://github.com/bvschaik/julius-support/releases/download/music"
declare -a mp3_filenames=("Rome1.mp3" "Rome2.mp3" "Rome3.mp3" "Rome4.mp3" "Rome5.mp3")

for mp3 in "${mp3_filenames[@]}"; do
	if [ ! -f "mp3/$mp3" ]; then
		curl -sSf -L -o "mp3/$mp3" "$mp3_baseurl/$mp3"
	fi
done

editor_baseurl="https://github.com/bvschaik/julius-support/releases/download/editor"
editor_filename="caesar3_map_editor_english.zip"

if [ ! -f "$editor_filename" ]; then
	curl -sSf -L -O "$editor_baseurl/$editor_filename"
fi
unzip -o -d "editor/" "$editor_filename"
