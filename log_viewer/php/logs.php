<?php

$max_log_lines = 100;

// the log reader
$action = "";
if (isset($_GET['action'])) {
   $action = $_GET['action'];
}

if ($action == "summary") {
   // create a summary from the log files
   $summary = array( 'alife' => "" );
   // check for heart beat
   $heartbeat_file = "/data/logs/heartbeatPROJ.log";

   if (($fp = fopen($heartbeat_file, "r")) == FALSE) {
      echo("{ \"message\": \"Error, could not open heartbeat log file\" }");
   }
   fseek($fp, -1, SEEK_END); 
   $pos = ftell($fp);
   $LastLine = "";
   $C = fgetc($fp);
   $pos--;
   // Loop backword util "\n" is found.
   while((($C = fgetc($fp)) != "\n") && ($pos > 0)) {
      //syslog(LOG_EMERG, "reading a character ".$C);
      $LastLine = $C.$LastLine;
      fseek($fp, $pos--);
   }
   fclose($fp);
   $summary['alife'] = $LastLine;

   // check if we had a trigger
   $trigger_log_file = "/data/logs/trigger.log";
   $data = "";
   if (filesize($trigger_log_file) > 1000000) {
     $data = file_get_contents($trigger_log_file, false, null, -1000000); // read last megabyte
   } else {
     $data = file_get_contents($trigger_log_file);
   }
   $data = explode("\n", $data);
   //syslog(LOG_EMERG, "split in ".count($data)." lines");
   $data = array_reverse($data);
   // filter by "triggered this service"
   $summary["trigger_study"] = array();
   foreach ($data as $line) {
      if (count($summary["trigger_study"]) > $max_log_lines) {
         break;
      }
      if (str_contains($line, "triggered service")) {
         $summary["trigger_study"][] = $line;
      }
   }

   echo(json_encode($summary));
} else {
      echo("{ \"message\": \"Unknown action\" }");  
}