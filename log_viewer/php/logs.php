<?php

header('Content-Type: application/json');

$max_log_lines = 400;

// the log reader
$action = $_GET['action'] ?? '';

if ($action !== 'summary') {
    echo(json_encode(["message" => "Unknown action"]));
    exit;
}

$summary = ['alife' => ""];
$logs_dir = __DIR__ . '/logs';

try {
    // 1. Check Heartbeat Log (Efficient last-line reading)
    $heartbeat_file = "$logs_dir/heartbeatPROJ.log";
    if (file_exists($heartbeat_file) && is_readable($heartbeat_file)) {
        $handle = fopen($heartbeat_file, 'r');
        if ($handle) {
            // Seek to near the end of the file (e.g., last 4KB)
            $buffer_size = 4096;
            $filesize = filesize($heartbeat_file);
            $seek_pos = max(0, $filesize - $buffer_size);
            fseek($handle, $seek_pos);
            
            $buffer = fread($handle, $filesize - $seek_pos);
            $lines = explode("\n", rtrim($buffer));
            $summary['alife'] = end($lines) ?: "";
            fclose($handle);
        }
    } else {
        // Optional: Log or handle missing heartbeat file
        $summary['alife_error'] = "Heartbeat log not found or unreadable";
    }

    // 2. Check Trigger Log (Optimized filtering)
    $trigger_log_file = "$logs_dir/trigger.log";
    if (file_exists($trigger_log_file) && is_readable($trigger_log_file)) {
        $file_size = filesize($trigger_log_file);
        // Read last 1MB if file is large
        $read_size = ($file_size > 1000000) ? 1000000 : $file_size;
        $offset = max(0, $file_size - $read_size);
        
        $data = file_get_contents($trigger_log_file, false, null, $offset);
        if ($data !== false) {
            $lines = explode("\n", $data);
            // Use preg_grep for high-performance pattern matching
            $matches = preg_grep('/triggered clinical service/', $lines);
            // Take the most recent matches up to $max_log_lines
            $summary["trigger_study"] = array_slice(array_reverse($matches), 0, $max_log_lines);
        }
    }

    // 3. Check the backend logging script
    $trigger_log_file = "$logs_dir/backend_logging.log";
    if (file_exists($trigger_log_file) && is_readable($trigger_log_file)) {
        $file_size = filesize($trigger_log_file);
        // Read last 1MB if file is large
        $read_size = ($file_size > 1000000) ? 1000000 : $file_size;
        $offset = max(0, $file_size - $read_size);
        
        $data = file_get_contents($trigger_log_file, false, null, $offset);
        if ($data !== false) {
            $lines = explode("\n", $data);
            // Use preg_grep for high-performance pattern matching
            $matches = preg_grep('/BackendLogging with arguments/', $lines);
            // Take the most recent matches up to $max_log_lines
            $summary["backend_logging"] = array_slice(array_reverse($matches), 0, $max_log_lines);
        }
    }
    

    echo(json_encode($summary));

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["message" => "Internal Server Error", "error" => $e->getMessage()]);
}