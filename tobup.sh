#!/bin/bash

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
# To activate debugging output export the variable tobupdebug

configfile="${HOME}/.config/tobupconfig"

function fail {
    echo "[Error] $1"
    echo "Aborting..."
    exit 1
}

function debug {
    if [ ! -z "$tobupdebug" ]; then echo "[Debug] $1"; fi
}

if [ -z "$1" ]
then
    echo "Missing arguments"
    echo "Usage: tobup FILE..."
    exit 1
fi

if [ ! -f $configfile ]; then
    fail "No configuration file found at: $configfile"
fi

debug "Parsing configuration parameters from $configfile"
count=0
while read -r line
do
    count=$(( count + 1 ))

    if [[ "$line" =~ ^backup-path=[^=]* ]]; then
        if [[ -z "$bupath" ]]; then
            debug "Found backup path definition at line $count"
            bupath=$line
        else
            fail "Line ${count} at ${configfile}: only one backup path can be specified"
        fi

    elif [[ ! -z "$line" ]]; then
        fail "Line ${count} at ${configfile}: invalid syntax"

    else
        debug "Line $count empty"
    fi
done < "$configfile"

if [[ -z "$bupath" ]]; then
    fail "No backup path specified at ${configfile}"
fi

bupath=${bupath/backup-path=/}
debug "Parsed backup path: $bupath"

if [ ! -d $bupath ]; then
    fail "$bupath is not a valid directory. Aborting."
fi

debug "Processing command line arguments"
for input in "$@"
do
    debug "Processing argument: $input"

    if [ -d $input ]; then
        debug "Directory detected"
        echo "$input is a directory. Skipping"
        echo

    elif [ -f $input ]; then
        debug "File detected"
        filepath=`readlink -f $input`
        destpath="$bupath$filepath"

        if [[ -d $destpath || -f $destpath ]]; then
            debug "$destpath is an existing file or folder"
            echo "$destpath exists. Skipping"
            echo
            continue
        fi

        echo "Moving $input to $destpath and linking back..."
        
        debug "Making path $destfolder"
        destfolder=`dirname $destpath`
        mkdir -p $destfolder || fail "Could not create path $destfolder"

        # TODO: here we could check folder and file permissions, instead
        if [[ "$filepath" = "$HOME"* ]]; then
            debug "File in home path: root permissions not needed"
            sudoprefix=""
        else
            debug "File not in home path: root permissions needed"
            sudoprefix="sudo"
        fi

        debug "Moving $filepath to $destpath"
        $sudoprefix mv $filepath $destpath || fail "Could not move $input"

        debug "Linking $destpath to $filepath"
        if $sudoprefix ln -s $destpath $filepath; then
            echo "Ok"
        else
            debug "Linking error, moving $destpath back to $filepath"
            $sudoprefix mv $destpath $filepath || fail "Could not move $input back"
            fail "Could not link $input, moving it back"
        fi

        echo

    else
        debug "$input should not exist yet"

        if [[ "$input" = *"/"* ]]; then
            echo "$input is not a valid file name. Skipping"
            echo
            continue
        fi

        filepath="${PWD}/${input}"
        destpath="$bupath$filepath"

        # TODO: implement this branch

        echo "Creating $input at $destpath"
        #touch $input
        #install -D $filepath $destpath
        #rm $filepath

        echo "Linking as $filepath"
        #ln -s $destpath $filepath

        echo

        if [[ "$filepath" = "$HOME"* ]]; then
            debug "File in home path"
        else
            debug "File not in home path"
        fi

    fi
done

echo "Done"

