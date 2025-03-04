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
            "cmd": [ "echo", "@StudyInstanceUID@", "@SeriesInstanceUID@", "@PATH@", "@DESCRIPTION@" ]
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
                    level=logging.UBFI,
                    format='%(asctime)s %(levelname)s %(message)s',
                    datefmt='%Y-%m-%d %H:%M:%S:%f:')
logging.info("Start trigger.py")
    
if not(os.path.isdir(config["arrived"])):
    logging.error("Error: the provided arrived path \"%s\" is not a directory." % (config["arrived"]))
    sys.exit(-1)

def RunExec( cmd, destination, StudyInstanceUID, SeriesInstanceUID=None, StreamName=None ):
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
        "@SeriesInstanceUID@": SeriesInstanceUID,
        "@destination@": destination,
        "@StreamName@": StreamName
    }
    cmd_replaced = []
    for piece in cmd:
        for key, value in placeholders.items():
            piece = piece.replace(key, value)
        cmd_replaced.append(piece)
    # logging.info(" ".join(cmd_replaced))
    p = None
    try:
        p = subprocess.run(cmd_replaced, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError as e:
        logging.error(e.output)
        pass
    log_message = {
        'command line': " ".join(cmd_replaced),
        'standard out': "{a}".format(a=json.dumps(p.stdout.decode('UTF-8'))),
        'standard error': "{a}".format(a=json.dumps(p.stderr.decode('UTF-8'))),
        'exit code': "{a}".format(a=p.returncode)
    }
    logging.info("%s" % (json.dumps(log_message)))

# we need to check the /data/site/.arrived folder for files with a last modification time 
while True:
    with open(os.path.join(script_directory,"config.json"), "r") as f:
        config = json.load(f)
        f.close()
        
    # logging.info('check ' + config["arrived"])
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
            aet = x[1] # AETitleCaller
            aec = x[2] # AETitleCalled
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
                for stream in config["Streams"]:
                    target = stream["trigger"]
                    # is the current stream addressed?
                    fits = True
                    for key, value in target.items():
                        # check if the regular expression is ok for this rule
                        if key == "AETitleCalled":
                            try:
                                if not re.match(value, aec):
                                    fits = False
                            except:
                                logging.error("    Warning: error using regular expression %s in rule %s, key: %s" % (value,stream['name'],key))
                                pass
                        elif key == "AETitleCaller":
                            try:
                                if not re.match(value, aet):
                                    fits = False
                            except:
                                logging.error("    Warning: error using regular expression %s in rule %s, key: %s" % (value,stream['name'],key))
                                pass                                    
                        else:
                            logging.error("Unknown trigger key in config.json: %s with value %s. Ignored." % (key, value))
                    if not fits:
                        #logging.info("non-matching stream %s for %s" % (stream["name"], json.dumps(target)))
                        continue
                    trigger_study = stream["trigger-study"]
                    trigger_series = stream["trigger-series"]
                    destination = "[]" # default could be entered here as research PACS
                    if "destination" in stream:
                        destination = json.dumps(stream["destination"])
                        destination = destination.replace('"', '\\"')
                    # get a new logger
                    logging.info("Matching stream %s for %s" % (stream["name"], json.dumps(target)))
                                            
                    if type == "study":
                        if len(trigger_study) > 0:
                            logging.info("trigger study level (stream %s)" % (stream["name"]))
                            for action in trigger_study:
                                if "type" in action and "cmd" in action and action["type"] == "exec":
                                    logging.info("trigger action %s on %s, for type %s" % (stream["name"], type, action["type"]))
                                    RunExec(action["cmd"], destination, StudyInstanceUID, SeriesInstanceUID, stream["name"])
                                else:
                                    logging.warning("%s: action not implemented, skip" % (stream["name"]))
                    elif type == "series":
                        if len(trigger_series) > 0:
                            logging.info("trigger series level (stream %s)" % (stream["name"]))
                            for action in trigger_series:
                                if "type" in action and "cmd" in action and action["type"] == "exec":
                                    logging.info("trigger action %s on %s, for type %s" % (stream["name"], type, action["type"]))
                                    RunExec(action["cmd"], destination, StudyInstanceUID, SeriesInstanceUID, stream["name"])
                                else:
                                    logging.warning("%s: action not implemented, skip" % (stream["name"]))
                try:
                    os.remove(file)
                except OSError:
                    logging.error("Error: could not delete file %s after performing action" % (file))
                    pass
            else:
                logging.info("File is too new [%d/%d], wait longer..." % (delta.total_seconds(),config["timeout"]))

    # be kind
    time.sleep(4)
