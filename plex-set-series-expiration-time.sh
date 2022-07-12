#!/bin/bash

# As-is. By Georgiy Sitnikov.

# Plex URL
PlexDomain="https://192.168.0.9"
# Plex Port if different from standart
PlexPort="32400"
# If using https with a selfsigned Certifikate - enable Cerificate ignoring
IgnoreCertificate=false
# Plex Token
PlexToken="xxxxxxxxxxxxx"
# Days to keep
# Possible Values:
#  0   - forever
#  1   - one day
#  7   - one Week
#  100 - Remove with a next Scan
# Other values could be experemental
keepDays=7

# If Series Section is different from default
PlexSections=2

### END OF CONFIGURATION ###

#if [[ -z "$keepDays" ]] || [[ "$keepDays" == 0 ]]; then

#	echo "Keep Days is not set or Zero, nothing to do."
#	exit 1

#fi

PlexURL=$PlexDomain:$PlexPort

# Connectivity check
connectivityCheck="$(curl $curlConnectivityConfiguration "%{http_code}\n" "$PlexURL/library/sections/$PlexSections/all?type=2&X-Plex-Token=$PlexToken" -o /dev/null)"
[[ "$connectivityCheck" == "401" ]] && { echo "$(date) - ERROR - Unauthorized. Please check Client Token."; exit 1; }
[[ "$connectivityCheck" == "404" ]] && { echo "$(date) - ERROR - Plex Section not found. Please check configuration."; exit 1; }
[[ "$connectivityCheck" == "500" ]] && { echo "$(date) - WARNING - Server Error. Can't work."; exit 1; }
[[ "$connectivityCheck" == "000" ]] && { echo "$(date) - ERROR - Host not reacheble under $PlexURL. Please check if Server and Port are correct."; exit 1; }

echo "$(date) - INFO - Successfully connected to Host under $PlexURL."

getAllSeries () {

	# Collect Series IDs and expiration Policies
	apiCall="$(curl $curlConfiguration "$PlexURL/library/sections/$PlexSections/all?type=2&X-Plex-Token=$PlexToken" -H "Accept: application/json, text/plain, */*" 2>/dev/null)"

	# Outpuput Number
	getItemsNumber="$(echo $apiCall | jq '.MediaContainer.size')"

	getAutoDeletePolicy="$(echo $apiCall | jq .MediaContainer.Metadata | grep '"autoDeletionItemPolicyWatchedLibrary"' | grep -v $keepDays | wc -l)"

	echo "$(date) - INFO - Found $getAutoDeletePolicy items to work with from $getItemsNumber items at all."

	[[ "$getAutoDeletePolicy" == "0" ]] && { echo "$(date) - INFO - Nothing to do."; exit 0; }

}

checkCurrentDeletePolicy () {

	getCurrentAutoDeletePolicy="$(echo $apiCall | jq '.MediaContainer.Metadata['$COUNT'] .autoDeletionItemPolicyWatchedLibrary' | sed 's/"//g')"
	# Output Example: 7
	getCurrentId="$(echo $apiCall | jq '.MediaContainer.Metadata['$COUNT'] .ratingKey' | sed 's/"//g')"
	# Output Example: 6379
	getCurrentTitle="$(echo $apiCall | jq '.MediaContainer.Metadata['$COUNT'] .title')"
	# Output Example: "Some Series"

}

setNewCurrentDeletePolicy () {

#	curl $curlPutConfiguration -X PUT "$PlexURL/library/metadata/$getCurrentId/prefs?autoDeletionItemPolicyWatchedLibrary=$keepDays&X-Plex-Token=$PlexToken" 2>/dev/null
	apiCallSetPolicy="$(curl $curlConnectivityConfiguration "%{http_code}\n" -X PUT "$PlexURL/library/metadata/$getCurrentId/prefs?autoDeletionItemPolicyWatchedLibrary=$keepDays&X-Plex-Token=$PlexToken" -o /dev/null)"
	[[ "$apiCallSetPolicy" == "401" ]] && { echo "$(date) - ERROR - Unauthorized. Please check Client Token."; exit 1; }
	[[ "$apiCallSetPolicy" == "404" ]] && { echo "$(date) - ERROR - $getCurrentTitle with ID $getCurrentId not found."; exit 1; }
	[[ "$apiCallSetPolicy" == "500" ]] && { echo "$(date) - ERROR - Server error."; exit 1; }
	[[ "$apiCallSetPolicy" == "000" ]] && { echo "$(date) - ERROR - Host not reacheble under $PlexURL."; exit 1; }

}

getAllSeries

COUNT=0

while :
do

	checkCurrentDeletePolicy

	if [[ "$getCurrentAutoDeletePolicy" == "$keepDays" ]]; then

		echo "$(date) - INFO - $getCurrentTitle with ID $getCurrentId has already correct policy, will skip it."

	else

		if [[ "$getCurrentAutoDeletePolicy" -ne "null" ]]; then

			setNewCurrentDeletePolicy

			echo "$(date) - INFO - $getCurrentTitle with ID $getCurrentId found. Auto Delete Policy set to $keepDays day(s)."

		fi

	fi

	if [[ "$getItemsNumber" == $COUNT ]]; then


		break

	fi

	((COUNT++));

done

echo "$(date) - INFO - Finished."

exit 0