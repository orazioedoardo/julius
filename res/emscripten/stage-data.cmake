# Gathers the files that the web build packs into its .data bundle: the Caesar 3 files that Julius reads, and the
# support files that the release packages add (as .ci_scripts/get_support_files.sh and build_and_package.sh do).
#
#   cmake -DSRC=<Caesar 3 folder> -DDST=<staging folder> -DDOWNLOADS=<folder> -P stage-data.cmake
#
# Installers (GOG, Steam) add DLLs, manuals and redistributables that the game doesn't need, so only the game's
# own data is taken from SRC: images (.555, .sg2), texts (.eng), maps and empire files, c3_model.txt, the tutorial
# mission pack, and the 555/, smk/ and wavs/ folders.
#
# Support files, downloaded once into DOWNLOADS from the julius-support releases:
# - the language packs (Caesar 3 update 1.1 for each language), each in its own folder, which Julius offers in its
#   settings
# - the map editor's files, next to the game's
# - the music tracks as MP3, mp3/Rome1-5.mp3, which Julius plays instead of the WAVs (left out)
# The .exe files and readmes in the zips are left out. Files are hard-linked where possible, not copied.

if(NOT SRC OR NOT DST OR NOT DOWNLOADS)
    message(FATAL_ERROR "Usage: cmake -DSRC=... -DDST=... -DDOWNLOADS=... -P stage-data.cmake")
endif()
if(NOT EXISTS "${SRC}/c3.eng" AND NOT EXISTS "${SRC}/C3.eng" AND NOT EXISTS "${SRC}/C3.ENG")
    message(FATAL_ERROR "${SRC} doesn't look like a Caesar 3 folder (no c3.eng): set C3_DATA_DIR to one")
endif()

set(SUPPORT_URL "https://github.com/bvschaik/julius-support/releases/download")
# Zip name -> folder, as in get_support_files.sh
set(LANGUAGES
    "english|English (US)"
    "french|French"
    "german|German"
    "italian|Italian"
    "japanese|Japanese"
    "korean|Korean"
    "polish|Polish"
    "portuguese_br|Portuguese (Brazilian)"
    "russian|Russian"
    "simplified_chinese|Simplified Chinese"
    "spanish|Spanish"
    "swedish|Swedish"
    "traditional_chinese|Traditional Chinese"
)
set(MP3S Rome1 Rome2 Rome3 Rome4 Rome5)

function(download url file)
    if(EXISTS "${DOWNLOADS}/${file}")
        return()
    endif()
    message(STATUS "Downloading ${url}")
    file(DOWNLOAD "${url}" "${DOWNLOADS}/${file}.part" STATUS status TLS_VERIFY ON)
    list(GET status 0 code)
    if(NOT code EQUAL 0)
        file(REMOVE "${DOWNLOADS}/${file}.part")
        list(GET status 1 message)
        message(FATAL_ERROR "Downloading ${url} failed: ${message}")
    endif()
    file(RENAME "${DOWNLOADS}/${file}.part" "${DOWNLOADS}/${file}")
endfunction()

function(stage_file from to)
    get_filename_component(dir "${to}" DIRECTORY)
    file(MAKE_DIRECTORY "${dir}")
    file(CREATE_LINK "${from}" "${to}" COPY_ON_ERROR)
endfunction()

# Stages a downloaded zip's contents into DST/<into>, without its .exe files and readmes
function(stage_zip zip into)
    set(unpacked "${DOWNLOADS}/unpacked/${zip}")
    if(NOT EXISTS "${unpacked}")
        file(ARCHIVE_EXTRACT INPUT "${DOWNLOADS}/${zip}" DESTINATION "${unpacked}.part")
        file(RENAME "${unpacked}.part" "${unpacked}")
    endif()
    file(GLOB_RECURSE files RELATIVE "${unpacked}" "${unpacked}/*")
    foreach(file IN LISTS files)
        string(TOLOWER "${file}" lower)
        get_filename_component(name "${lower}" NAME)
        if(lower MATCHES "\\.(exe|doc)$" OR name MATCHES "^(readme|leiame|patch_readme).*\\.txt$")
            continue()
        endif()
        stage_file("${unpacked}/${file}" "${DST}/${into}${file}")
    endforeach()
endfunction()

file(MAKE_DIRECTORY "${DOWNLOADS}")
foreach(language IN LISTS LANGUAGES)
    string(REPLACE "|" ";" language "${language}")
    list(GET language 0 key)
    download("${SUPPORT_URL}/patches/caesar3_update_${key}.zip" "caesar3_update_${key}.zip")
endforeach()
download("${SUPPORT_URL}/editor/caesar3_map_editor_english.zip" "caesar3_map_editor_english.zip")
foreach(mp3 IN LISTS MP3S)
    download("${SUPPORT_URL}/music/${mp3}.mp3" "${mp3}.mp3")
endforeach()

file(REMOVE_RECURSE "${DST}")
file(MAKE_DIRECTORY "${DST}")

# Top level
file(GLOB top RELATIVE "${SRC}" "${SRC}/*")
foreach(name IN LISTS top)
    if(IS_DIRECTORY "${SRC}/${name}")
        continue()
    endif()
    string(TOLOWER "${name}" lower)
    if(lower MATCHES "\\.(555|sg2|eng|rus|map|emp)$" OR lower STREQUAL "c3_model.txt" OR lower STREQUAL "mission1.pak")
        stage_file("${SRC}/${name}" "${DST}/${name}")
    endif()
endforeach()

# Folders, whatever the case of their names. The WAVs of the tracks that have an MP3 are left out.
set(REPLACED_WAVS "")
foreach(mp3 IN LISTS MP3S)
    string(TOLOWER "${mp3}.wav" wav)
    list(APPEND REPLACED_WAVS "${wav}")
endforeach()
foreach(name IN LISTS top)
    string(TOLOWER "${name}" lower)
    if(NOT IS_DIRECTORY "${SRC}/${name}" OR NOT lower MATCHES "^(555|smk|wavs)$")
        continue()
    endif()
    file(GLOB_RECURSE files RELATIVE "${SRC}/${name}" "${SRC}/${name}/*")
    foreach(file IN LISTS files)
        string(TOLOWER "${file}" file_lower)
        if(lower STREQUAL "wavs" AND file_lower IN_LIST REPLACED_WAVS)
            continue()
        endif()
        stage_file("${SRC}/${name}/${file}" "${DST}/${name}/${file}")
    endforeach()
endforeach()

# Support files
foreach(language IN LISTS LANGUAGES)
    string(REPLACE "|" ";" language "${language}")
    list(GET language 0 key)
    list(GET language 1 folder)
    stage_zip("caesar3_update_${key}.zip" "${folder}/")
endforeach()
stage_zip("caesar3_map_editor_english.zip" "")
foreach(mp3 IN LISTS MP3S)
    stage_file("${DOWNLOADS}/${mp3}.mp3" "${DST}/mp3/${mp3}.mp3")
endforeach()
