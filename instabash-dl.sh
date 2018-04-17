#!/bin/bash
# Author: Vinícius Madureira <viniciusmadureira@outlook.com>
# Version: 0.12
# Date: April 17th, 2018
# Script: Bash Instagram Downloader (instabash-dl)
# Dependencies: GNU bash 4.3.42(1); GNU coreutils 8.24; curl 7.43.0; GNU Wget 1.18; GNU grep 2.22; GNU sed 4.2.2

# Download medias
function download() {
	for page in $pages; do
		current_page=$(curl --silent --location "https://www.instagram.com/p/$page/")
		medias_url=$(echo "$current_page" | grep --perl-regexp --only-matching '(?U)https.*\.(jpg|mp4)' | head -n 2 | awk '!seen[$0]++')	
		for media_url in $medias_url; do
			printf -v filename "%s%06d%s" "$account_name"'_' $((count++)) ".${media_url##*.}"
			wget --quiet "$media_url" --output-document="$filename"
		done
	done
}

# Do login
curl --silent --cookie-jar "cookies.txt" "https://www.instagram.com" > /dev/null
csrftoken=$(cat cookies.txt | grep csrftoken | awk '{print $7}')
curl --silent --cookie 'cookies.txt' --cookie-jar 'cookies.txt' --dump-header 'dump.txt' --globoff 'https://www.instagram.com/accounts/login/ajax/' -H 'Referer: https://www.instagram.com/accounts/login/' -H "X-CSRFToken: $csrftoken" --data-urlencode "username=$1" --data-urlencode "password=$2" --data-urlencode "queryParams={}" > /dev/null

# Set session cookies and URL parameters
shbid=$(cat dump.txt  | grep --perl-regexp --only-matching 'shbid=.*(?=;)'| sed --expression 's/.*=//g')
sessionid=$(cat dump.txt  | grep --perl-regexp  '(?U)sessionid=.*(?=;)' | sed --expression 's/.*sessionid=//g')
query_hash='42323d64886122307be10013ad2dcc44'

# Get account data to download
account_name="$3"
account_page=$(curl --silent --cookie 'cookies.txt' --cookie-jar 'cookies.txt' "https://www.instagram.com/$account_name/")
account_id=$(echo "$account_page" | grep --perl-regexp --only-matching '{"id":"\d+"}' | sed --expression='s/[^[:digit:]]//g' --expression='1!d')
json_data=$(echo "$account_page" | grep --perl-regexp --only-matching '{"activity_counts".*(?=;)')
end_cursor=$(echo "$account_page" | grep --perl-regexp --only-matching '(?U){"has_next_page":true.*"}' | tail -n 1 | sed --expression='s/"}\|.*:"//g')

# Download pages
count=1
while [[ -n $end_cursor ]]; do
	pages=$(echo "$json_data" | grep --perl-regexp --only-matching '(?U)"shortcode":".*"' | sed --expression='s/.*:\|"//g')
	download "$pages" "$account_name"
	json_data=$(curl --silent --globoff --cookie "cookies.txt" --cookie-jar 'cookies.txt' "https://www.instagram.com/graphql/query/?query_hash=$query_hash&variables={\"id\":\"$account_id\",\"first\":12,\"after\":\"$end_cursor\"}" -H "Cookie: shbid=$shbid; sessionid=$sessionid}")
	end_cursor=$(echo "$json_data" | grep --perl-regexp --only-matching '(?U){"has_next_page":true.*"}' | tail -n 1 | sed --expression='s/"}\|.*:"//g')
done

# Remove temporary files
rm -rf 'cookies.txt' 'dump.txt'

exit 0

#./instabash-dl "username" "password" "account_to_download_medias"
