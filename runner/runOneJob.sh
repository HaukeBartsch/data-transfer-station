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

LOG_TO_SQL="docker run --rm -v /root/data-transfer-station/runner/BackendLogging.py:/BackendLogging.py  -v /data/logs/:/data/logs/ -v /root/data-transfer-station/configuration/config.json:/root/data-transfer-station/configuration/config.json logger"

echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] Start processing"

# test if we are the correct user (need to be processing for this to work)
me=$(whoami)
if [[ "${me}" != "root" ]]; then
    echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] Error: This script needs to be run by the root user (instead found ${me})."
    exit
fi

input="/data/code/workflow_joblist.jobs"
if [ ! -f "${input}" ]; then
    echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] File \"${input}\" not found. Nothing to do."
    exit
fi
echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] INFO `cat ${input} | wc -l` job(s) in workflow_joblist.jobs"

storage="/export/Workflows"
ror="/data/code/trigger/ror"
if [ ! -x "${ror}" ]; then
    echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] Error: ROR not found in /data/code/trigger/ or file not executable, cannot run jobs."
    exit 1
fi

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
    destination=`echo "${line}" | jq -r '.destination' | jq -r '.[0]'`
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
	    echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] we did not find a folder with the following name: ${ror_folder}/${dirnam}"
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
        log_str=$(<"/tmp/${dirnam}run.log")
        $LOG_TO_SQL --status "ERROR" --message "trigger did not create folder for job: $job_number, \"$log_str\""
        # we should remove the job from the job list if this is the case
        jobsToDelete[$jobsCounter]="$line"
        jobsCounter=$((jobsCounter + 1)) 
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
    inputAllStudyInstanceUID=$(find "${ror_folder_path}/input" -type f ! -name '*.json' ! -name '*.log' ! -name '*.zip' -print | xargs -I'{}' dcmdump +P StudyInstanceUID {} | cut -d '[' -f2 | cut -d']' -f1 | sort | uniq)
    outputAllStudyInstanceUID=$(find "${ror_folder_path}_output" -type f ! -name '*.json' ! -name '*.log' ! -name '*.zip' -print | xargs -I'{}' dcmdump +P StudyInstanceUID {} | cut -d '[' -f2 | cut -d']' -f1 | sort | uniq)
    if [ -z "$inputAllStudyInstanceUID" ]; then
	    echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] Error: no studies in input"
        $LOG_TO_SQL --status "ERROR" --message "no studies in input"
	    continue
    fi
    if [ -z "$outputAllStudyInstanceUID" ]; then
	    echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] Warning: no studies in output"
        $LOG_TO_SQL --status "ERROR" --message "no studies in output"
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
	    echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] check for StudyInstanceUID: ${listOutputStudyInstanceUID[$i]}, needs to be in input"
	    #if [[ "${listOutputStudyInstanceUID[$i]}" != *"${inputAllStudyInstanceUID}"* ]]; then
	    #    echo "FOUND error output for \"${listOutputStudyInstanceUID[$i]}\", not in \"${inputAllStudyInstanceUID}\""
	    #    StudyInstanceUIDError="Error: Output StudyInstanceUID \"${listOutputStudyInstanceUID[$i]}\" is not found in the input folder."
	    #fi
	    if grep -q "${listOutputStudyInstanceUID[$i]}" <<< "${inputAllStudyInstanceUID}"; then
	        #echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] NO ERROR, found the string with GREP"
	        StudyInstanceUIDError=""
	    else
	        echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] ERROR, string  \"${listOutputStudyInstanceUID[$i]}\" not in \"${inputAllStudyInstanceUID}\" USING GREP"
	        StudyInstanceUIDError="Error: Output StudyInstanceUID \"${listOutputStudyInstanceUID[$i]}\" is not found in the input folder."
	    fi
    done
    IFS=$OLDIFS

    # Search for output.json in output folder, if it is present, then parse it into data fields.
    # If all the data necessery for RedCap transfer found, try to send it to redcap
    output_json=$(find "${ror_folder_path}_output" -type f -name "output.json" | head -1)
    # we need the AccessionNumber from the generated output - should be the same as the one in the input
    dcmdump=$(which dcmdump)
    if [ -z "${dcmdump}" ]; then
        echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] Error: dcmdump not found in path, cannot process DICOM files."
        $LOG_TO_SQL --status "ERROR" --message "dcmdump not found in path, install dcmtk"
    fi
    report_dcm=$(find "${ror_folder_path}_output/reports" -type f -name "*_0.dcm" | head -1)
    AccessionNumber=$(dcmdump +P AccessionNumber "${report_dcm}" | cut -d'[' -f2 | cut -d']' -f1)
    StudyInstanceUID=$(dcmdump +P StudyInstanceUID "${report_dcm}" | cut -d'[' -f2 | cut -d']' -f1)
    echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] AccessionNumber from dcm [${report_dcm}]: ${AccessionNumber}, StudyInstanceUID from dcm: ${StudyInstanceUID}"

    if [ -z "${StudyInstanceUIDError}" ]; then
        echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] only valid data in output folder, send to FIONA..."
	
	    # send the records in output_json to REDCap for the current project
	    if [ -e "${output_json}" ]; then
	        realpath_output_json=`realpath ${output_json}`
	        echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] Logging for \"${project}\" \"${realpath_output_json}\""
            output_string=$(jq -c '.' < "${output_json}")
            $LOG_TO_SQL --status "OK" --accession_number "${AccessionNumber}" --study_instance_uid "${StudyInstanceUID}" --message "found an output.json"

            # extract the tumor size from output_json and send a separate log message
            tumor_size=$(jq -r '.[]|select(.field_name=="physical_size")|.value' "${output_json}")
            $LOG_TO_SQL --tumor_size "${tumor_size}" --accession_number "${AccessionNumber}" --study_instance_uid "${StudyInstanceUID}"

            # destination contains the information for sending the data
            OwnAETitle="AICORE1"
            AETitle=$(echo "${destination}" | jq -r '.AETitle')
            IP=$(echo "${destination}" | jq -r '.IP')
            PORT=$(echo "${destination}" | jq -r '.PORT')
            # The own application entity title might not be specified. In that case use the default above. If specified and not empty string do:
            tmp_OwnAETitle=$(echo "${destination}" | jq -r '.OwnAETitle')
            if [ "${tmp_OwnAETitle}" != "null" ] && [ ! -z "${tmp_OwnAETitle}" ]; then
                OwnAETitle="${tmp_OwnAETitle}"
            fi

	        echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] extract destination from ${destination} AETitle: ${AETitle}, IP: ${IP}, PORT: ${PORT}. DTS reports to be: \"${OwnAETitle}\""

            # last step is sending the image data back to PACS, requires dcmtk to be installed and in the path
            storescu=$(which storescu)
            # path_to_configuration_config_json="/root/data-transfer-station/configuration/config.json"
            # hope all we need is in destination now
            if [ -z "${storescu}" ]; then
                echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] Error: storescu not found in path, cannot send data to PACS."
                $LOG_TO_SQL --status "ERROR" --message "storescu not found in path, cannot send data to PACS." --accession_number "${AccessionNumber}" --study_instance_uid "${StudyInstanceUID}"
            else
                echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] Sending output data to PACS using storescu \"$AETitle\" \"$IP\" \"$PORT\". Call: ${storescu} -nh -aec ${AETitle} -aet ${OwnAETitle} +sd +r ${IP} ${PORT} \"${ror_folder_path}_output\""
                echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] Sending output data to PACS using storescu \"$AETitle\" \"$IP\" \"$PORT\". Call: ${storescu} -nh -aec ${AETitle} -aet ${OwnAETitle} +sd +r ${IP} ${PORT} \"${ror_folder_path}_output\"" >> /data/logs/storescu_send_to_PACS.log 2>&1
                ${storescu} -nh -aec ${AETitle} -aet ${OwnAETitle} +sd +r ${IP} ${PORT} "${ror_folder_path}_output" >> /data/logs/storescu_send_to_PACS.log 2>&1
                $LOG_TO_SQL --status "OK" --message "send data in ${ror_folder_path}_output to PACS ${AETitle} ${IP} ${PORT}" --accession_number "${AccessionNumber}" --study_instance_uid "${StudyInstanceUID}"
            fi

	        #/usr/bin/php /var/www/html/applications/Workflows/php//sendToREDCap.php "${project}" "${realpath_output_json}"
	        #echo "`date +'%Y-%m-%d %H:%M:%S'`: Send to REDCap done (\"${project}\" \"${realpath_output_json}\")."
	    fi
    else
        echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] Error: at least one of the StudyInstanceUID's in the output does not appear in the input (${line}). Fix your container! Data is ignored..."
	echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] input: \"${inputAllStudyInstanceUID}\" != output: \"${outputAllStudyInstanceUID}\""
        $LOG_TO_SQL --status "ERROR" --message "at least one of the StudyInstanceUID's in the output does not appear in the input (${line}). Fix your container! Data is ignored..." --accession_number "${AccessionNumber}" --study_instance_uid "${StudyInstanceUID}"
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

# clear up old proc folders
for u in `find /data/proc/ -type f -mmin +60 | cut -d'/' -f1-4 | sort | uniq`; do
    echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] remove old proc folder: $u (older than 60 minutes)"
    rm -rf "$u"
done

# clear up old archive folders
for u in `find /data/site/archive/ -type f -mtime +7 | cut -d'/' -f1-5 | sort | uniq`; do
    echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] remove old archive folders: $u (older than one week)"
    rm -rf "$u"
done


echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: [runOneJob.sh] End processing"
