#!/bin/bash

# As-is. By Georgiy Sitnikov.

# Plex URL
PlexDomain="https://192.168.0.9"
# Plex Port if different from standard
PlexPort=32400
# If using https with a self-signed Certificate - enable Certificate ignoring
IgnoreCertificate=false
# Plex Token
PlexToken="xxxxxxxxxxxxx"
# Days to keep
# Possible Values:
#  0   - forever
#  1   - one day
#  7   - one Week
#  100 - Remove with a next Scan
# Other values could be experimental
keepDays=7

# Plex Section, if different from default
PlexSections=2

### END OF CONFIGURATION ###

while getopts ":hk:sd" option; do
	case $option in
		h)	# Help
			echo "Simple Script for Plex that will massively manage Series Autodelete Policy."
			echo "By Georgiy Sitnikov."
			echo ""
			echo "Usage: ./plex-set-series-expiration-time.sh [options]"
			echo ""
			echo "Example:"
			echo "To keep all Series forever:"
			echo "  ./plex-set-series-expiration-time.sh -k 0"
			echo ""
			echo "... autodelete after seen in a 1 week"
			echo "  ./plex-set-series-expiration-time.sh -k 7"
			echo ""
			echo "Options:"
			echo "  -k <Number>     Set Number of days to keep messages, all messages older than
                  this number will be deleted. Default 7.
                  Possible Values are:
                  0 - do not automatically delete,
                  1 - delete after 1 day,
                  7 - delete after 1 week,
                  100 - delete with a next Scan.
                  Other values could be experimental"
			echo "  -s              Show current active configuration and exit."
            echo "  -d              Dry run, show output, but not change anything."
			echo "  -h              This help."
			exit 0
			;;
		k)	# set keepDays
			keepDays="$OPTARG"
			;;
		s)	# Show current Active Configuration
			echo "Plex Domain:           $PlexDomain"
			echo "Plex Port:             $PlexPort"
			echo "Plex Token:            $(echo $PlexToken | cut -c -4)..."
			echo "Policy to keep Series: $keepDays"
			echo "Ignore Certificate:    $IgnoreCertificate"
			exit 0
			;;
		d)	# enable dryrun
			dryRun=true
			;;
		\?)
			break
			;;
	esac
done

# Set curl Options, like timeout and number of retries
if [[ "$IgnoreCertificate" == true ]]; then

	curlConfiguration="-fsk -m 5 --retry 2"
	curlPutConfiguration="-k -m 5 --retry 2"
	curlConnectivityConfiguration="-k -m 5 -sL -w"

else

	curlConfiguration="-fs -m 5 --retry 2"
	curlPutConfiguration="-m 5 --retry 2"
	curlConnectivityConfiguration="-m 5 -sL -w"

fi

if [[ -z "$keepDays" ]] || [[ "$keepDays" -le 0 ]] || [[ "$keepDays" -ge 100 ]] ; then

	echo "$(date) - ERROR - Keep days is seems not to be valid. Current value is: $keepDays, allowed is from 0 to 100."
	exit 1

fi

[[ "$dryRun" == true ]] && { echo "$(date) - INFO - Dry Run, will not change anything, only show output with possible changes."; }

PlexURL=$PlexDomain:$PlexPort

# Connectivity check
connectivityCheck="$(curl $curlConnectivityConfiguration "%{http_code}\n" "$PlexURL/library/sections/$PlexSections/all?type=2&X-Plex-Token=$PlexToken" -o /dev/null)"
[[ "$connectivityCheck" == "401" ]] && { echo "$(date) - ERROR - Unauthorized. Please check Client Token."; exit 1; }
[[ "$connectivityCheck" == "404" ]] && { echo "$(date) - ERROR - Plex Section not found. Please check configuration."; exit 1; }
[[ "$connectivityCheck" == "500" ]] && { echo "$(date) - WARNING - Plex Server Error. Can't work."; exit 1; }
[[ "$connectivityCheck" == "000" ]] && { echo "$(date) - ERROR - Plex not reachable under $PlexURL. Please check if Server and Port are correct."; exit 1; }

echo "$(date) - INFO - Successfully connected to Plex under $PlexURL."

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
	[[ "$apiCallSetPolicy" == "500" ]] && { echo "$(date) - ERROR - Plex Server error."; exit 1; }
	[[ "$apiCallSetPolicy" == "000" ]] && { echo "$(date) - ERROR - Plex not reachable under $PlexURL."; exit 1; }

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

			[[ "$dryRun" == true ]] || setNewCurrentDeletePolicy

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