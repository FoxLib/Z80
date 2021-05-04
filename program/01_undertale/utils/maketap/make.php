<?php

function crc8($block, $crconly = false) {

    $crc = 0;
    foreach ($block as $x) $crc ^= $x;
    $block[] = $crc;
    return $crconly ? $crc : $block;
}

$data = file_get_contents("ut.tap");
$scr  = file_get_contents("../../screen/src/screen.scr");

// Модификация строки автостарта
// ---------------------------------------------------------------------
$data[0x10] = chr(0x01);
$data[0x11] = chr(0x00);

// Пересчет контрольной суммы
$x = array_map('ord', str_split(substr($data, 2, 18)));
$data[0x14] = chr(crc8($x, true));
// ---------------------------------------------------------------------

// Первым идет экран Undertale
$block = [0x00, 0x03, 0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20, 0x00,0x1B, 0x00,0x40, 0x00,0x80 ];
$block = crc8($block);
$screen = pack("C*", 0x13,0x00, ...$block);

// Далее идет блок с данными
$block = [0xFF]; for ($i = 0; $i < 6912; $i++) $block[] = ord($scr[$i]); $block = crc8($block);
$screen .= pack("C*", 0x02,0x1B, ...$block);

// Блок с кодом
// ---------------------------------------------------------------------

$code = file_get_contents("../../undertale.bin");
$size = strlen($code);

// Первым идет блок с кодом
$block = [0x00, 0x03, 0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20, ($size&255),($size>>8), 0x00,0x66, 0x00,0x80 ];
$block = crc8($block);
$codeblock = pack("C*", 0x13,0x00, ...$block);

// Далее идет блок с данными
$block = [0xFF]; for ($i = 0; $i < $size; $i++) $block[] = ord($code[$i]); $block = crc8($block);

$size += 2;
$codeblock .= pack("C*", ($size&255),($size>>8), ...$block);

// Сохранить новый TAP файл
// ---------------------------------------------------------------------
file_put_contents("ut.tap", $data . $screen . $codeblock);

