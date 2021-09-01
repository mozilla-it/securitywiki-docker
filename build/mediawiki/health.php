<?php

require_once("/etc/securitywiki/securitywiki.php");

$mysqli = new mysqli($Database_Server, $Database_User, $Database_Password, $Database_Name);
if (!$mysqli) {
    http_response_code(500);
    echo "Can't connect to the database";
    exit;
}

/* check if server is alive */
if (!$mysqli->ping()) {
    http_response_code(500);
    echo "Database ping failed";
    exit;
}

echo "All Checks : OK";

?>
