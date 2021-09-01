<?php
    $ENVIRONMENT = getenv('ENVIRONMENT', 'stage');

    $Database_Name     = getenv('MYSQL_DATABASE', 'securitywiki');
    $Database_Password = getenv('MYSQL_PASSWORD');
    $Database_Server   = getenv('MYSQL_HOST');
    $Database_User     = getenv('MYSQL_USER', 'admin');

    $Cache_Endpoint     = getenv('MEMCACHED_HOST');
    $Cache_Port         = getenv('MEMCACHED_PORT', '11211');
?>
