#!/usr/bin/env bash

#
# Given a folder from the receiver (scp_...) look for the project name and create a proper select statement
#

if [ "$#" -lt 2 ]; then
    echo "Usage: <folder to /tmp/site/archive/scp_...> <path to statement.json> <stream>"
    exit -1
fi
input="$1"
if [ ! -d "${input}" ]; then
    echo "Error: directory ${input} does not exist"
    exit -1
fi
output="$2"

# If specified use the StreamName as select statement source
Stream=""
if [ "$#" -eq 3 ]; then
    Stream="$3"
fi

if [ ! -z "$Stream" ]; then
    # use the stream name instead of extracting the statement from the project name
    statement=$(jq -r ".\"${Stream}\".select" /var/www/html/applications/Workflows/php/select_statements.json)
    if [ "${statement}" == "null" ] || [ "${statement}" == "" ]; then
	echo "Error: no select statement found for stream \"$Stream\" in /var/www/html/applications/Workflows/php/select_statements.json"
	exit -1
    fi
    
    echo "Select: \"$statement\""
    echo "Write select statement to: $output"
    echo "${statement}" > $output
    exit    
fi



onefile=$(ls "${input}"/* | head -1)

# TODO: Check if we are the right user (processing)
# TODO: The first file might not contain InstitutionName, look in all files until you find one
InstitutionName=$(dcmdump +P InstitutionName "${onefile}" | head -1 | cut -d'[' -f2 | cut -d']' -f1)
echo "Project: $InstitutionName"

statement=$(jq -r ".\"${InstitutionName}\".select" /var/www/html/applications/Workflows/php/select_statements.json)
if [ "${statement}" == "null" ] || [ "${statement}" == "" ]; then
    echo "Error: no select statement found for project \"$InstitutionName\" in /var/www/html/applications/Workflows/php/select_statements.json"
    exit -1
fi

echo "Select: \"$statement\""
echo "Write select statement to: $output"
echo "${statement}" > $output
