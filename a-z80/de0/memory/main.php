<?php

$data = file_get_contents("zx128.bin") .
        file_get_contents("zx48.bin");

$out = "WIDTH=8;\nDEPTH=32768;\nADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\nCONTENT BEGIN\n";
for ($i = 0; $i < 0x8000; $i++) $out .= sprintf("  %02X: %02X;\n", $i, ord($data[$i]));
$out .= "END;\n";
file_put_contents("../rom.mif", $out);
