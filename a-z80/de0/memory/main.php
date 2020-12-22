<?php
$data = file_get_contents("zxdump.bin");
$out = "WIDTH=8;\nDEPTH=65536;\nADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\nCONTENT BEGIN\n";
for ($i = 0; $i < 0x5B00; $i++) $out .= sprintf("  %02X: %02X;\n", $i, ord($data[$i]));
$out .= "  [5B00..FFFF]: 00;\n";
$out .= "END;\n";
file_put_contents("../memory.mif", $out);
