<?php

include "font.php";

$text[] = "Давным-давно две расыправили Землей:ЛЮДИ и МОНСТРЫ.";
$text[] = "Но однажды между нимивспыхнула война.";
$text[] = "После продолжительнойбитвы людям удалосьодержать победу.";
$text[] = "И с помощью волшебногозаклятья они заключилимонстров под землю.";
$text[] = "Много лет спустя...";
$text[] = "      Гора Эббот.   201Х";
$text[] = "Легенды гласят, что те,кто взбираются на гору,больше не возвращаются.";

$map    = [];
$char   = [];
$cnt    = 0;
$output = "";

$txt  = join("", $text);
for ($i = 0; $i < mb_strlen($txt); $i++) {
    @ $char[ mb_substr($txt, $i, 1) ]++;
}

arsort($char);

foreach ($char as $ch => $_) {

    if ($ch == 13)
        continue;

    $char_id = isset($fontmap[$ch]) ? $fontmap[$ch] : ord($ch);
    $map[$char_id] = $cnt++;

    for ($i = 0; $i < 16; $i++) $output .= chr($font[$char_id][$i]);
}

$a_str = [];
$str   = [];

// Перевод в строку
foreach ($text as $id => $str) {

    $arr = [];
    for ($i = 0; $i < mb_strlen($str); $i++) {

        $ch = mb_substr($str, $i, 1);

        if ($ch == "\n")
            $char_id = 255;
        else
            $char_id = $map[ isset($fontmap[$ch]) ? $fontmap[$ch] : ord($ch) ];

        $arr[] = sprintf("$%02x", $char_id);
    }

    $a_str[] = "; ".str_replace("\n", " ", $str);
    $a_str[] = "str{$id}: defb ".join(",", $arr)."\n";
}

// Предварительная табличка
$dst = imagecreatetruecolor(256, 128);
for ($y = 0; $y <  8; $y++)
for ($x = 0; $x < 32; $x++) {

    for ($i = 0; $i < 16; $i++)
    for ($j = 0; $j <  8; $j++)
        imagesetpixel($dst, 8*$x+$j, 16*$y+$i, $font[32*$y + $x][$i] & (1 << (7-$j)) ? 0xffffff : 0);
}
imagepng($dst, "font.png");

// ---------------------------------------------------------------------
file_put_contents("../fonts.bin", $output);
file_put_contents("../string.asm", join("\n", $a_str));
