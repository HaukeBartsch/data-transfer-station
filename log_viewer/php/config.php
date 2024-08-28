<?php

// get and set configuration options
$action = "";
if (isset($_GET['action'])) {
   $action = $_GET['action'];
}

if ($action == "get_config") {
   $data = file_get_contents("/data/code/trigger/config.json");
   echo($data);
} else {
  echo ("{ \"message\": \"Error: unknown action\" }");
}

?>