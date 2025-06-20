#!/usr/bin/env bash
 
#
# Job scheduling
#
 
if [ "$#" -lt 4 ]; then
    echo "Usage: <folder to /tmp/site/archive/scp_...> <ror folder> <destination as json> <stream name>"
    exit -1
fi
input="$1"
ror_folder="$2"
destination="$3"
stream_name=""
if [ "$#" -eq 4 ]; then
    stream_name="$4"
fi
 
if [ ! -d "${ror_folder}" ]; then
    echo "Error: folder not found \"${ror_folder}\""
    exit -1
fi
 
 
#onefile=$(ls "${input}"/* | head -1)
# 
# TODO: Check if we are the right user (processing)
#InstitutionName=$(dcmdump +P InstitutionName "${onefile}" | head -1 | cut -d'[' -f2 | cut -d']' -f1)
#echo "Project: ${InstitutionName}"
#if [ "$stream_name" == "" ]; then
#    stream_name="${InstitutionName}"
#fi
InstitutionName="${stream_name}"
 
ImageName=$(jq -r ".\"${stream_name}\".docker_image" /configuration/select.statements.json)
ROR_CONT_OPTIONS=$(jq -r ".\"${stream_name}\".ROR_CONT_OPTIONS" /configuration/select.statements.json)
# check if value is error message and set to empty string instead {}
if [ ! -z "$ROR_CONT_OPTIONS" ]; then
    ROR_CONT_OPTIONS=$(echo $ROR_CONT_OPTIONS | sed -e 's/"/\\"/g')
fi
 
date="$(date)"
 
# get the job ids
# ror status --jobs | jq -r ".[][].JobID"
# TODO: need to make this work with spaces in the project name
OIFS="$IFS"
IFS=$'\n'
for u in $(/usr/local/bin/ror status --working_directory "${ror_folder}" --jobs | jq -r ".[][].JobID"); do
  # append to the jobs file (with a newline at the end)
  echo "{\"type\":\"ror\",\"project\":\"${InstitutionName}\",\"stream\":\"${stream_name}\",\"image\":\"${ImageName}\",\"user\":\"processing\",\"date\":\"${date}\",\"job_number\":\"$u\",\"ror_folder\":\"${ror_folder}\",\"destination\":\"$destination\",\"ROR_CONT_OPTIONS\":\"$ROR_CONT_OPTIONS\"}" >> /data/code/workflow_joblist.jobs
 
  # We use the following (with Project: XXXXX) as an indicator in applications/Logging/php/*.php.
  echo "Added job: {\"type\":\"ror\",\"project\":\"${InstitutionName}\",\"stream\":\"${stream_name}\",\"image\":\"${ImageName}\",\"user\":\"processing\",\"date\":\"${date}\",\"job_number\":\"$u\",\"destination\":\"$destination\"}"
 
done
IFS="$OIFS"
