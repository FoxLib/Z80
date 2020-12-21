<?php

$fb = [];
$vb = file_get_contents("mon.bin");
$sz = strlen($vb);
for ($i = 0; $i < $sz; $i++) $fb[$i] = ord($vb[$i]);

echo "WIDTH=8;\nDEPTH=65536;\nADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\nCONTENT BEGIN\n";
for ($i = 0; $i < $sz; $i++) echo sprintf("    0%04x : %02x;\n", $i, $fb[$i]);
echo sprintf("    [0%04x..0FFFF]: 00;\n", $sz);
echo "END;\n";
