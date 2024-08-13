#!/usr/bin/env -S python3 -u
from datetime import datetime
import re, sys, os, time, json, glob
import subprocess

#
# Continuously check .arrived folder specified in config.json
# Folder is filled with incoming DICOM files (empty files, information is coded in filename only).
# For example: A file for a study arrives, the .arrived file gets an updated modification time.
#              The next file arrives for another study and that study file gets a new modification time.
# The code below will check the folder for files that are older than 16 seconds. It will
# assume, because no new file arrived, that the study is complete and trigger processing.
#
config = {
    "arrived": "",
    "raw": "",
    "archive": "",
    "log": "/data/logs/trigger.log",
    "timeout": 16,
    "trigger-study": [
        {
            "type": "send",
            "send": "http",
            "destination": "http://localhost:11120"
        },
        {
            "type": "exec",
            "cmd": [ "echo", "triggered this service", "@StudyInstanceUID@", "@SeriesInstanceUID@", "@PATH@", "@DESCRIPTION@" ]
        }
    ],
    "trigger-series": []  
}

script_directory = os.path.dirname(os.path.abspath(sys.argv[0]))
with open(os.path.join(script_directory,"config.json"), "r") as f:
    config = json.load(f)
    f.close()

import logging
logging.basicConfig(filename=config["log"],
                    encoding='utf-8',
                    level=logging.INFO,
                    format='%(asctime)s %(levelname)s %(message)s',
                    datefmt='%Y-%m-%d %H:%M:%S')
logging.info("%s: Start trigger.py" % (str(datetime.now())))

    
if not(os.path.isdir(config["arrived"])):
    logging.error("Error: the provided arrived path \"%s\" is not a directory." % (config["arrived"]))
    sys.exit(-1)

def RunExec( cmd, StudyInstanceUID, SeriesInstanceUID=None ):
    # run the array cmd, fill in the placeholder first
    if SeriesInstanceUID is not None:
        SeriesInstanceUID = "/" + SeriesInstanceUID
    else:
        SeriesInstanceUID = ""
    rawStudyInstanceUID=StudyInstanceUID.replace("scp_", "")
    placeholders = {  
        "@PATH@": "%s/%s%s" % (config["raw"], StudyInstanceUID, SeriesInstanceUID),
        "@DESCRIPTION@": "%s/%s/data.json" % (config["raw"], rawStudyInstanceUID),
        "@StudyInstanceUID@": StudyInstanceUID,
        "@SeriesInstanceUID@": SeriesInstanceUID
    }
    cmd_replaced = []
    for piece in cmd:
        for key, value in placeholders.items():
            piece = piece.replace(key, value)
        cmd_replaced.append(piece)
    logging.info("  " + str(datetime.now()) + ": " + " ".join(cmd_replaced))
    p = None
    try:
        p = subprocess.run(cmd_replaced, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError as e:
        logging.error(e.output)
        pass
    logging.info("    exit status: {a}".format(a=p.returncode))
    logging.info("    stdout: {a}".format(a=json.dumps(p.stdout.decode('UTF-8'))))
    logging.info("    stderr: {a}".format(a=json.dumps(p.stderr.decode('UTF-8'))))
    logging.info(str(datetime.now()) + ": processing finished")

# we need to check the /data/site/.arrived folder for files with a last modification time 
while True:
    with open(os.path.join(script_directory,"config.json"), "r") as f:
        config = json.load(f)
        f.close()
        
    logging.info('check ' + config["arrived"])
    obj = os.scandir(config["arrived"])
    for file in obj:
        if file.is_file():
            # lets parse the filename and see if we get all structured fields
            re_series = "([^ ]+) ([^ ]+) ([^ ]+) ([^ ]+) ([^ ]+)"
            re_study = "([^ ]+) ([^ ]+) ([^ ]+) ([^ ]+)"
            x = re.match(re_series, file.name)
            type = "series"
            if x == None:
                x = re.match(re_study, file.name)
                type = "study"
            aet = x[1]
            aec = x[2]
            dummy = x[3]
            StudyInstanceUID = x[4]
            SeriesInstanceUID = None
            if type == "series":
                SeriesInstanceUID = x[5]
 
            mtime = os.path.getmtime(file)
            t = datetime.fromtimestamp(mtime)
            now = datetime.now()
            delta = now - t
            if delta.total_seconds() > config["timeout"]:
                if type == "study":
                    if len(config["trigger-study"]) > 0:
                        for action in config["trigger-study"]:
                            logging.info("Trigger action on %s, for type %s" % (type, action["type"]))
                            if "type" in action and "cmd" in action and action["type"] == "exec":
                                RunExec(action["cmd"], StudyInstanceUID, SeriesInstanceUID)
                            else:
                                logging.warning("action not implemented, skip")
                elif type == "series":
                    if len(config["trigger-series"]) > 0:
                        for action in config["trigger-series"]:
                            logging.info("Trigger action on %s, for type %s" % (type, action["type"]))
                            if "type" in action and "cmd" in action and action["type"] == "exec":
                                RunExec(action["cmd"], StudyInstanceUID, SeriesInstanceUID)
                            else:
                                logging.warning("action not implemented, skip")
                try:
                    os.remove(file)
                except OSError:
                    logging.error("Error: could not delete file %s after performing action" % (file))
                    pass
            else:
                logging.info("File is too new [%d/%d], wait longer..." % (delta.total_seconds(),config["timeout"]))

    # be kind
    time.sleep(4)
