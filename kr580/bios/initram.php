<?php

$fb = [];

/* Заполнить rom */
$vb = file_get_contents("mon.bin");
$sz = strlen($vb);
for ($i = 0; $i < $sz; $i++) $fb[$i] = ord($vb[$i]);

?>
WIDTH=8;
DEPTH=65536;

ADDRESS_RADIX=HEX;
DATA_RADIX=HEX;
CONTENT BEGIN

<?php
for ($i = 0; $i < $sz; $i++) echo sprintf("    0%04x : %02x;\n", $i, $fb[$i]);
echo sprintf("    [0%04x..0FFFF]: 00;\n", $sz);
?>

END;
