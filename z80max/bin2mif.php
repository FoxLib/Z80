<?php

/**
 * Преобразует бинарные данные в MEMFLASH.MIF
 */

$file = isset($argv[1]) ? $argv[1] : stdin;
$outf = isset($argv[2]) ? $argv[2] : stdin;
$dept = isset($argv[3]) ? $argv[3] : 16384;

$file = file_get_contents($file);
$size = (int)strlen($file);

$out = "WIDTH=8;\nDEPTH=$dept;\nADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\nCONTENT BEGIN\n";
for ($i = 0; $i < $size; $i++) {

    $val = ord($file[$i]);
    $out .= sprintf("  %04X: %02X;\n", $i, $val);
}
$out .= sprintf("  [%04X..%04X]: 00;\n", $size, $dept-1);
$out .= "END;\n";

file_put_contents($outf, $out);
