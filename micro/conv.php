<?php

$in  = file_get_contents($argv[1]);
$out = $argv[2];
$tmp = '';

for ($i = 0; $i < strlen($in); $i++)
    $tmp .= sprintf("%02x\n", ord($in[$i]));

file_put_contents($out, $tmp);
