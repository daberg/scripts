#!/bin/bash

#  Copyright (C) 2016 daberg
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

# Bash script to easily convert .flac files to .mp3 format at the specified
# path
# 
# Takes the path to the folder to be searched as input
# 
# .flac files are recursively searched for, and the output files are placed
# in a new folder tree that mantains the original folder tree structure

# Check command line arguments
if [ -z "$1" ] || [ ! -z "$2" ]; then
    echo "Wrong number of arguments"
    echo "Usage: flactomp3 FILE"
    exit 1
fi

# Check whether ffmpeg is installed. If not, exit.
command -v ffmpeg >/dev/null 2>&1 || { echo "ffmpeg was not found. Aborting." >&2; exit 1; }

# Sanitize input
path="${1/%\/}"

echo "Target path: $path"

# TODO: change condition and handle empty directory case
if cd "$path"; then

	out_folder_name="${PWD##*/}_flac"
	output_path="${path}/${out_folder_name}"
	
	echo "Output path: $output_path"
	printf "\n\n"

	i=0
	while IFS= read -r -d $'\0' line; do
		lines[$i]=$line
		i=$[i+1]
	done < <(find . -type d -print0)
	count=$i

	i=0
	while [ $i -lt $count ]; do

		line=${lines[$i]}
		
		if cd "$line"; then
	
			echo "Processing folder: $line"
			
			flac_count=`find . -maxdepth 1 -type f -name "*.flac" 2>/dev/null | wc -l`
		
			# If there are .flac files
			if [ $flac_count != 0 ]; then		
			
				# Obtain output folder partial path (empty if initial folder)
				out_dir_partial_path=${line#.}
				out_dir_partial_path=${out_dir_partial_path#\/}
											
				# Obtain specific target path
				out_dir_path="${output_path}"'/'"${out_dir_partial_path}"
				out_dir_path=${out_dir_path/%\/}
				
				echo "Output folder path: $out_dir_path"
				
		 		mkdir -p "$out_dir_path"

				for a in ./*.flac; do
			
					echo "Processing file: $a"
				
					temp="${a/.\//$out_dir_path\/}"
					out="${temp[@]/%flac/mp3}"
				
					ffmpeg -i "$a" -qscale:a 0 "$out"
				
				done;
		
			else
				echo "No .flac files were found."
			fi
		fi
		
		printf "\n\n"
	
		cd "$path"
		i=$[i+1]
	
	done;

# If path was invalid, quit
else
	exit 1
fi
