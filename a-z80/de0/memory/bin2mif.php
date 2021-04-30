<?php

$file = isset($argv[1]) ? $argv[1] : stdin;
$outf = isset($argv[2]) ? $argv[2] : stdout;
$max  = isset($argv[3]) ? $argv[3] : 16384;
$file = file_get_contents($file);
$size = (int)strlen($file);

$out = "WIDTH=8;\nDEPTH=$max;\nADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\nCONTENT BEGIN\n";
for ($i = 0; $i < $size; $i++) {

    $val = ord($file[$i]);
    $out .= sprintf("  %04X: %02X;\n", $i, $val);
}
if ($size < $max-1) $out .= sprintf("  [%04X..%04X]: 00;\n", $size, $max-1);
$out .= "END;\n";

file_put_contents($outf, $out);
