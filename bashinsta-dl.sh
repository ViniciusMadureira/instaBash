#!/bin/bash
# Author: Vinícius Madureira <viniciusmadureira@outlook.com>
# Version: 0.1
# Date: March 11th, 2018
# Script: Bash Instagram Downloader (bashinsta-dl)
# Dependencies: GNU bash 4.3.42(1); GNU coreutils 8.24; curl 7.43.0; GNU Wget 1.18; GNU grep 2.22; GNU sed 4.2.2

function download() {
	for page in $pages; do
		current_page=$(curl --silent --location "https://www.instagram.com/p/$page/")
		medias_url=$(echo "$current_page" | grep --perl-regexp --only-matching '(?U)https.*\.(jpg|mp4)' | head -n 2 | awk '!seen[$0]++')	
		for media_url in $medias_url; do
			printf -v filename "%s%06d%s" "$username"'_' $((count++)) ".${media_url##*.}"
			wget --quiet "$media_url" --output-document="$filename"
		done
	done
}

username="$1"
count=1
query_hash='472f257a40c653c64c666ce877d59d2b'
first_page=$(curl --silent "https://www.instagram.com/$username/")
json_data=$(echo "$first_page" | grep --perl-regexp --only-matching '{"activity_counts".*(?=;)')
id=$(echo "$first_page" | grep --perl-regexp --only-matching '{"id":"\d+"}' | sed --expression='s/[^[:digit:]]//g' --expression='1!d')
end_cursor=$(echo "$first_page" | grep --perl-regexp --only-matching '(?U){"has_next_page":true.*"}' | tail -n 1 | sed --expression='s/"}\|.*:"//g')
while :; do
	pages=$(echo "$json_data" | grep --perl-regexp --only-matching '(?U)"shortcode":".*"' | sed --expression='s/.*:\|"//g')
	download "$pages" "$username"
	json_data=$(curl --silent --globoff "https://www.instagram.com/graphql/query/?query_hash=$query_hash&variables={\"id\":\"$id\",\"first\":12,\"after\":\"$end_cursor\"}")
	if [ -z $end_cursor ]; then
		break;
	fi
	end_cursor=$(echo "$json_data" | grep --perl-regexp --only-matching '(?U){"has_next_page":true.*"}' | tail -n 1 | sed --expression='s/"}\|.*:"//g')
done
exit 0

#./bashinsta-dl.sh "viniciusit"
