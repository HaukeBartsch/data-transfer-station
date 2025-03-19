#!/usr/bin/env bash

#
# Run a single job from the workflow_joblist.jobs file. The file contains json code per line.
#
# Need to run as user "root" with flock.
#
# Example cron job:
#   /usr/bin/flock -n /data/logs/runOneJob.pid \
#         /data/code/trigger/runOneJob.sh >> /data/logs/runOneJob.log 2>&1
#

echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] Start processing"

# test if we are the correct user (need to be processing for this to work)
me=$(whoami)
if [[ "${me}" != "root" ]]; then
    echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] Error: This script needs to be run by the root user (instead found ${me})."
    exit
fi

input="/data/code/workflow_joblist.jobs"
echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] INFO `cat ${input} | wc -l` job(s) in workflow_joblist.jobs"

storage="/export/Workflows"
ror="/usr/local/bin/ror"
declare -a jobsToDelete
jobsCounter=0
# for each job
while IFS= read -r line; do
    # We can interpret $line as coded in JSON. Example:
    #  {"type":"ror","project":"FUNDECT","job_number":"0",
    #   "image":"mriqc:21.0.0rc2","user":"admin",
    #   "date":"2022-01-21T13:08:34+01:00"}
    type=`echo "${line}" | jq -r ".type"`
    project=`echo "${line}" | jq -r ".project"`
    job_number=`echo "${line}" | jq -r ".job_number"`
    image=`echo "${line}" | jq -r ".image"`
    user=`echo "${line}" | jq -r ".user"`
    date=`echo "${line}" | jq -r ".date"`
    ror_folder=`echo "${line}" | jq -r ".ror_folder"`
    destination=`echo "${line}" | jq -r ".destination"`
    ROR_CONT_OPTIONS=`echo "${line}" | jq -r ".ROR_CONT_OPTIONS" | tr -d "'"`
    if [ "${ror_folder}" = "null" ]; then
    	# if we come from the website we will not have a ror_folder as an argument (equals empty string)
	    ror_folder="${storage}/${project}/ror"
    fi
    # verify correctness of this job?
    if [ -z "${type}" ] || [ -z "${project}" ] || [ -z "${job_number}" ] || [ -z "${image}" ] || [ -z "${user}" ] || [ -z "${date}" ]; then
	    echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] Skip this job (type: \"$type\", project: \"$project\", job_number: \"$job_number\", image: \"$image\", user: \"$user\", date: \"$date\") some values are empty."
	    continue
    fi

    # this image might contain double quotes for the separator between image and tag. Those will get replaced with underscores
    imageFolderName=`echo "${image}" | sed -e 's/:/_/g'`
    
    # what is the data folder for this job?
    folder="${ror_folder}"  # "${storage}/${project}/"
    if [ ! -d "${folder}" ]; then
	    mkdir -p "${folder}"
    fi
    dirnam="datajob_${job_number}_${imageFolderName}_"
    # resolve the real name of the folder
    ror_folder_path=`realpath "${folder}/${dirnam}"* | head -1`
    
    # we can check now if the folder exists - job has been started(!)
    if [ -d "${ror_folder_path}" ]; then
	    # skip, folder exists already so we are doing what we are supposed to do
	    # if we want to run again we need to delete the folder first
	    echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] Skip this job ($type, $project, $job_number, $image, $user, $date), folder \"${folder}/${dirnam}\" already exists" 
	    jobsToDelete[$jobsCounter]="$line"
	    jobsCounter=$((jobsCounter + 1))
	    continue
    else
	    echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] ERROR We did not find a folder with the following name: ${ror_folder}/${dirnam}"
    fi
    
    # based on our type prepare ror for this folder
    #if [ "${type}" = "ror" ]; then
#	cd ${storage}/${project}/ror/;
#	$ror config --temp_directory ${storage}/${project}/ror/ --call "/app/work.sh {}"
 #   else
#	echo "Error: unknown type ${type} (we only support type = ror"
 #   fi
    # and run
    echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] Trigger job with type: \"$type\", project: \"$project\", job_number: \"$job_number\", image: \"$image\", user: \"$user\", date: \"$date\" in \"${folder}/${dirnam}\"..."
    cd "${ror_folder}/";
    # pwd
    # add --memory and --cpus to this call to limit damage
    echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] Requested job: $ror trigger --keep --cont \"$image\" --envs ${ROR_CONT_OPTIONS} --job \"${job_number}\" --folder \"${dirnam}\""
    # export ROR_CONT_OPTIONS="{\"-z\":23.23}"
    #export ROR_CONT_OPTIONS=${ROR_CONT_OPTIONS}
    echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] ROR call is: $ror trigger --keep --cont \"$image\" --job \"${job_number}\" --envs $ROR_CONT_OPTIONS --folder \"${dirnam}\"" > "/tmp/${dirnam}run.log"
    $ror trigger --keep --cont "$image" --job "${job_number}" --envs $ROR_CONT_OPTIONS --folder "${dirnam}" >> "/tmp/${dirnam}run.log" 2>&1
    # make this readable for the www-data user (we are processing)
    ror_folder_path=`realpath "${folder}/${dirnam}"* | grep -v _output | head -1`
    if [ ! -d "${ror_folder_path}" ]; then
	    echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] Error: trigger did not create folder for job: $job_number"
	    cat "/tmp/${dirnam}run.log"
	    continue
    fi
    chmod gou+rx "${ror_folder_path}"
    mv "/tmp/${dirnam}run.log" "${ror_folder_path}"

    # now remove the job from the job list
    # add to a variable to delete later (delete after the current loop)
    jobsToDelete[$jobsCounter]="$line"
    jobsCounter=$((jobsCounter + 1)) 
    
    # ok, so there might be output data generated by the run above, that is REDCap data and also image data
    # get a list of all the StudyInstanceUIDS in the input folder (compare this with the generated StudyInstanceUIDs in the output folder)
    inputAllStudyInstanceUID=$(find "${ror_folder_path}/input" -type f ! -name '*.json' ! -name '*.log' -print | xargs -I'{}' dcmdump +P StudyInstanceUID {} | cut -d '[' -f2 | cut -d']' -f1 | sort | uniq)
    outputAllStudyInstanceUID=$(find "${ror_folder_path}_output" -type f ! -name '*.json' ! -name '*.log' -print | xargs -I'{}' dcmdump +P StudyInstanceUID {} | cut -d '[' -f2 | cut -d']' -f1 | sort | uniq)
    if [ -z "$inputAllStudyInstanceUID" ]; then
	    echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] Error: no studies in input"
	    continue
    fi
    if [ -z "$outputAllStudyInstanceUID" ]; then
	    echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] Warning: no studies in output"
	    # We can still have an output.json file here for REDCap!
	    # continue
    fi

    # check if all output study instance uids are in the list of input study instance uids
    StudyInstanceUIDError=""
    OLDIFS=$IFS
    IFS=$'\n'
    listOutputStudyInstanceUID=(${outputAllStudyInstanceUID})
    numStudyInstanceUIDs=${#listOutputStudyInstanceUID[@]}
    for (( i=0; i<${numStudyInstanceUIDs}; i++ ));
    do
	    echo "TEST StudyInstanceUID: ${listOutputStudyInstanceUID[$i]}"
	    #if [[ "${listOutputStudyInstanceUID[$i]}" != *"${inputAllStudyInstanceUID}"* ]]; then
	    #    echo "FOUND error output for \"${listOutputStudyInstanceUID[$i]}\", not in \"${inputAllStudyInstanceUID}\""
	    #    StudyInstanceUIDError="Error: Output StudyInstanceUID \"${listOutputStudyInstanceUID[$i]}\" is not found in the input folder."
	    #fi
	    if grep -q "${listOutputStudyInstanceUID[$i]}" <<< "${inputAllStudyInstanceUID}"; then
	        echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] NO ERROR, found the string with GREP"
	        StudyInstanceUIDError=""
	    else
	        echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] ERROR, string  \"${listOutputStudyInstanceUID[$i]}\" not in \"${inputAllStudyInstanceUID}\" USING GREP"
	        StudyInstanceUIDError="Error: Output StudyInstanceUID \"${listOutputStudyInstanceUID[$i]}\" is not found in the input folder."
	    fi
    done
    IFS=$OLDIFS

    # Search for output.json in output folder, if it is present, then parse it into data fields.
    # If all the data necessery for RedCap transfer found, try to send it to redcap
    output_json="${ror_folder_path}_output/output.json"
    
    if [ -z "${StudyInstanceUIDError}" ]; then
        echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] only valid data in output folder, send to FIONA..."
	    # /usr/bin/storescu -nh -aec DICOM_STORAGE -aet FIONA +sd +r -d XXXXX.ihelse.net PORT "${ror_folder_path}_output"
        # /var/www/html/server/utils/s2m.sh "${ror_folder_path}/output/"
	
	    # send the records in output_json to REDCap for the current project
	    if [ -e "${output_json}" ]; then
	        realpath_output_json=`realpath ${output_json}`
	        echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] No sending to REDCap... sendToREDCap.php \"${project}\" \"${realpath_output_json}\""
	        #/usr/bin/php /var/www/html/applications/Workflows/php//sendToREDCap.php "${project}" "${realpath_output_json}"
	        #echo "`date +'%Y-%m-%d %H:%M:%S'`: Send to REDCap done (\"${project}\" \"${realpath_output_json}\")."
	    fi
    else
        echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] Error: at least one of the StudyInstanceUID's in the output does not appear in the input (${line}). Fix your container! Data is ignored..."
	    echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh]    input: \"${inputAllStudyInstanceUID}\" != output: \"${outputAllStudyInstanceUID}\""
    fi
    
    # ok, if we are done we should mark this as done? Or is the exists of the folder sufficient?
done < "${input}"

# now delete all jobs that we did something for
pattern=""
for i in "${!jobsToDelete[@]}"; do
    # remove this line
    lineNum=$((i+1))
    echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] remove line number ${lineNum}: ${jobsToDelete[i]}"
    pattern="${pattern}${lineNum}d;"
done
if [ ! -z "${pattern}" ]; then
  echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] pattern to delete is: \"$pattern\" used on \"$input\""
  sed  "$pattern" "$input" > "$input"
fi
echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] End processing"
