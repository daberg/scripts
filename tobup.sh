#!/bin/bash

function fail {
    echo "[Error] $1"
    echo "Aborting..."
    exit 1
}

function debug {
    if [ ! -z "$tobupdebug" ]; then echo "[Debug] $1"; fi
}

configfile="${HOME}/.config/tobupconfig"

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

        # TODO test this branch
        if [[ -d $destpath || -f $destpath ]]; then
            debug "$destpath is an existing file or folder"
            echo "$destpath not empty. Skipping"
            echo
            continue
        fi

        echo "Moving $input to $destpath"

        destfolder=`dirname $destpath`
        mkdir -p $destfolder
        
        # Only if former succeeded and as root if needed
        mv $filepath $destpath

        echo "Linking back as $filepath"

        # Only if former succeeded and as root if needed
        ln -s $destpath $filepath

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

        echo "Creating $input at $destpath"
        #touch $input
        #install -D $filepath $destpath
        #rm $filepath

        echo "Linking back to $filepath"
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

