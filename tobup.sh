#!/bin/bash

#  Copyright (C) 2018 daberg
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Bash script to easily backup configuration files
#
# For each file received as input, moves it to a backup folder and links it
# back to its original path
#
# The backup path has to be specified by creating the file:
#
#     $HOME/.config/tobupconfig
#
# and appending a line like:
#
#     backup-path=/path/to/the/backup/folder
#
# To activate debugging output export the variable $tobupdebug

# Prints a debugging statement
function debug {
    if [ ! -z "$tobupdebug" ]; then echo "[Debug] $1"; fi
}

# Prints a fatal error statement and exits
function fail {
    echo "[Error] $1"
    echo "Aborting..."
    exit 1
}

# Parses configuration file
# If a single valid backup path is found, it is stored in the $bupath variable
function parseconfig {

    debug "Parsing configuration parameters from $configfile"
    count=0
    while read -r line
    do
        count=$(( count + 1 ))

        # Line is a comment
        if [[ "$line" =~ ^#.* ]]; then
            debug "Line $count is a comment"

        # Line has a backup path definition
        elif [[ "$line" =~ ^backup-path=.*$ ]]; then
            if [[ -z "$bupath" ]]; then
                debug "Found backup path definition at line $count"
                bupath="$line"
            else
                fail "Line ${count} at ${configfile}: only one backup path can be specified"
            fi

        # Line is not empty
        elif [[ ! -z "$line" ]]; then
            fail "Line ${count} at ${configfile}: invalid syntax"

        # Line is empty
        else
            debug "Line $count empty"
        fi
    done < "$configfile"

    if [[ -z "$bupath" ]]; then
        fail "No backup path specified at ${configfile}"
    fi

    bupath="${bupath/backup-path=/}"

    # Remove possible trailing slash
    if [[ "$bupath" = *[!/]*/ ]]; then
      debug "$bupath is not root folder and has a trailing slash"
      parsedpath="${bupath%/}"

      # If there is still a trailing slash, fail
      if [[ "$parsedpath" = */ ]]; then
          fail "Invalid syntax for backup path"
      fi

      bupath="$parsedpath"
    fi

    debug "Parsed backup path: $bupath"

    if [ ! -d "$bupath" ]; then
        fail "$bupath is not a directory. Aborting."
    fi
}

configfile="${HOME}/.config/tobupconfig"

if [ -z "$1" ]
then
    echo "Missing arguments"
    echo "Usage: tobup FILE..."
    exit 1
fi

if [ ! -f "$configfile" ]; then
    fail "No configuration file found at: $configfile"
fi

parseconfig

debug "Processing command line arguments"
for input in "$@"
do
    debug "Processing argument: $input"

    if [ -d "$input" ]; then
        debug "Directory detected"
        echo "$input is a directory. Skipping"

    elif [ -L "$input" ]; then
        debug "Symbolic link detected"
        echo "$input is a symbolic link. Skipping"

    elif [ -f "$input" ]; then

        debug "File detected"
        filepath=$(readlink -f "$input")
        destpath="$bupath$filepath"

        if [[ -d "$destpath" || -f "$destpath" ]]; then
            debug "$destpath is an existing file or folder"
            echo "$destpath exists. Skipping"
            echo
            continue
        fi

        echo "Moving $input to $destpath and linking back..."

        debug "Making path $destfolder"
        destfolder=$(dirname "$destpath")
        mkdir -p "$destfolder" || fail "Could not create path $destfolder"

        # TODO: here we should check folder and file permissions, instead
        if [[ "$filepath" = "$HOME"* ]]; then
            debug "File in home path: root permissions not needed"
            sudoprefix=""
        else
            debug "File not in home path: root permissions needed"
            sudoprefix="sudo"
        fi

        debug "Moving $filepath to $destpath"
        $sudoprefix mv "$filepath" "$destpath" || fail "Could not move $input"

        debug "Linking $destpath to $filepath"
        if $sudoprefix ln -s "$destpath" "$filepath"; then
            echo "Ok"
        else
            debug "Linking error, moving $destpath back to $filepath"
            $sudoprefix mv "$destpath" "$filepath" || fail "Could not move $input back"
            fail "Could not link $input, moving it back"
        fi

    else
        debug "$input should not exist"
        echo "$input not found. Skipping"
    fi
done
