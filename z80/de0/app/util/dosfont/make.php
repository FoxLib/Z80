<?php

$ds = imagecreatefromgif("dos_8x8_font_green.gif");

for ($i = 2; $i < 8; $i++) {

    for ($j = 0; $j < 16; $j++) {

        $x = 1 + 9*$j;
        $y = 1 + 9*$i;

        for ($a = 0; $a < 8; $a++) {

            $r = 0;
            for ($b = 0; $b < 8; $b++) {

                $c = imagecolorat($ds, $x + $b, $y + $a);
                if ($c == 1) $r |= (1 << (7 - $b));
            }

            echo chr($r);
        }

    }

}
