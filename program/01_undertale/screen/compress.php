<?php

// Корректировки в SCR-файле
function scrcorrect() {

    $data = file_get_contents("src/main.scr");
    for ($i = 0; $i < 6144; $i++) {
        if ($i >= 4096) $data[$i] = chr(0);
    }

    for ($i = 0; $i < 768; $i++) {

        $data[$i+0x1800] = chr(0x40 | ord($data[$i+0x1800]));
        if ($i >= 512) $data[$i+0x1800] = chr(0);
    }

    file_put_contents("src/screen.scr", $data);
}

function convert($file, $fileout) {

    $width  = 200;
    $height = 104; // 107

    $src = imagecreatefrompng($file);
    $dst = imagecreatetruecolor($width, $height);
    $byte = 0;
    $out = "";

    for ($y = 0; $y < $height; $y++)
    for ($x = 0; $x < $width; $x++) {

        $color = imagecolorat($src, $x, $y);

        if ($color == 0) { // HI

            $bit = 1;
            imagesetpixel($dst, $x, $y, 0);

        } else { // LO

            $bit = 0;
            imagesetpixel($dst, $x, $y, 0xffffff);
        }

        $byte = ($byte << 1) | $bit;
        if (($x & 7) == 7) { $out .= chr($byte); $byte = 0; }
    }

    file_put_contents($fileout, $out);
}

for ($i = 1; $i < 10; $i++) {
    convert("src/screen$i.png", "screen$i.tmp");
    @unlink("screen$i.bin");
    echo `zx0 screen$i.tmp screen$i.bin`;
    @unlink("screen$i.tmp");
}

scrcorrect();

@unlink('screen.bin');
echo `zx0 src/screen.scr screen.bin`;
