<?php

$binout = "";
for ($y = 0; $y < 104; $y++) {

    $address = 0x4003 + ($y & 0x07)*256 + (($y & 0x38)>>3)*32 + (($y & 0xe0)>>6)*2048;
    $binout .= chr($address & 255) . chr(($address>>8) & 255);
    // echo sprintf("%02x: %04x\n", $y, $address);
}
file_put_contents("../ytable.bin", $binout);
