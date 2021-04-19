<?php file_put_contents($argv[2], join(array_map(function($e){return sprintf("%02x\n", ord($e));},str_split(file_get_contents($argv[1])))));

