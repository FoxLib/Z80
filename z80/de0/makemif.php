<?php unset($argv[0]);

$data = [];

// Подгрузка файлов
foreach ($argv as $item) {

    if (preg_match('~^(.+)=([0-9a-f]+)~i', $item, $c)) {

        $at = hexdec($c[2]);
        $in = file_get_contents($c[1]);
        for ($i = 0; $i < strlen($in); $i++) {

            $byte = ord($in[$i]);
            $data[$at + $i] = $byte;
        }
    }
}

$i = 0;
$rows = [];
$max  = max(array_keys($data));
while ($i <= $max) {

    $byte = (int) @ $data[$i];
    $cnt  = 1;
    for ($j = 1; $j < $max - $i; $j++) {

        $comp = (int) @ $data[$i + $j];
        if ($comp == $byte) $cnt++; else break;
    }

    // Возможен повтор
    if ($cnt > 1) {

        $rows[] = "  [" .
            strtoupper(str_pad(dechex($i), 4, '0', STR_PAD_LEFT)) . '..' .
            strtoupper(str_pad(dechex($i+$cnt-1), 4, '0', STR_PAD_LEFT))."] : " .
            strtoupper(str_pad(dechex($byte), 2, '0', STR_PAD_LEFT)) . ";";

        $i += $cnt;

    } else {

        $rows[] = "  " . strtoupper(str_pad(dechex($i), 4, '0', STR_PAD_LEFT)) . " : " . strtoupper(str_pad(dechex($byte), 2, '0', STR_PAD_LEFT)) . ";";
        $i++;
    }
}

?>
WIDTH=8;
DEPTH=<?=($max +1);?>;

ADDRESS_RADIX=HEX;
DATA_RADIX=HEX;
CONTENT BEGIN
<? echo join("\n", $rows) . "\n"; ?>
END;

