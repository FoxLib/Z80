<?php

$file = isset($argv[1]) ? $argv[1] : stdin;
$outf = isset($argv[2]) ? $argv[2] : stdout;
$file = file_get_contents($file);
$size = (int)strlen($file);

$out = "WIDTH=8;\nDEPTH=32768;\nADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\nCONTENT BEGIN\n";
for ($i = 0; $i < $size; $i++) {

    $val = ord($file[$i]);
    $out .= sprintf("  %04X: %02X;\n", $i, $val);
}
$out .= sprintf("  [%04X..7FFF]: 0000;\n", $size);
$out .= "END;\n";

file_put_contents($outf, $out);
